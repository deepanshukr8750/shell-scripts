#!/bin/bash
service mysql start
cd jenkins-sql/

echo "$dumpconfig" > config.txt
#ls -la
source config.txt
fileexist=true
echo "***********************************************************************************"
echo "PROD dump started"
if [ $DUMP_TYPE = 'LATEST_BACKUP' ] 
then
  ansible-playbook -i $(eval echo \$${TENANT}_AppServers), copy-db-playbook.yml -e 'ansible_python_interpreter=/bin/python' -u service-user
  for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
  do
   temp=$database.sql.$(date -d yesterday +"%Y%m%d")*.gz
   if [ \( -f $temp \) -a \( $fileexist = 'true' \) ]
   then
    fileexist=true
    gzip -d $database.sql.$(date -d yesterday +"%Y%m%d")*.gz
    mv $database.sql.$(date -d yesterday +"%Y%m%d")*.sql ${database}.sql
   else
    fileexist=false
   fi
  done
fi 
if [ \( $fileexist = 'false' \) -o \( $DUMP_TYPE = 'CURRENT' \) ]
then
   echo "Dumping PROD database"
   for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
   do
    mysqldump -h $(eval echo \$${TENANT}_Hostname) -u $(eval echo \$${TENANT}_User) -p$(eval echo \$${TENANT}_Password) --single-transaction --set-gtid-purged=OFF --databases $database -r ${database}.sql
    sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i ${database}.sql
   done
fi
echo "PROD dump done"
ls -la
echo "***********************************************************************************"
echo "check if dump process is success"
ls -la
dump=false
for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
do
 size=`ls -la ${database}.sql | awk '{ print $5}'`
 if [ \( -f ${database}.sql \) -a \( $size -gt 0 \) ]
 then
   dump=true
 else
   dump=false
 fi
done
if [ $dump = 'true' ]
then
  echo "Dump files available"
else
  echo "Dump failed"
  exit 1
fi
echo "***********************************************************************************" 
echo "Creating local databases"
cat<<OVER > mysql_create.sh
mysql -u root -ppassword<<EOF
create database \$1 DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci;
EOF
OVER
for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
do
	bash mysql_create.sh $database 
done
echo "Local databases created"
echo "***********************************************************************************"
echo "Importing PROD data to local database"
cat<<OVER > mysql_import.sh
mysql -u root -ppassword<<EOF
use \$1;
source \$1.sql;
EOF
OVER
for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
do
   bash mysql_import.sh $database
done
echo "Importing PROD data to local database done"
echo "***********************************************************************************"
echo "Scrub PROD data"
bash file_env_replace.sh $TENANT $TARGET_ENV
cat<<OVER > mysql_scrub.sh
mysql -u root -ppassword<<EOF
source scrub.sql;
EOF
OVER
bash mysql_scrub.sh 
echo "Scrubing done"
echo "***********************************************************************************"
echo "Export final dump for target env"

case "${TENANT}" in
    "clic" | "cia")
        SQL_QUERY="CREATE USER '"${TENANT}-user"'@'"%"'; GRANT SELECT ON ${TENANT}_Schema.* TO '"${TENANT}-user"'@'%';" 
        ;;
esac
if [ -n "${SQL_QUERY}" ]; then
    mysql -u root -ppassword -e "${SQL_QUERY}"
fi

for database in $(eval echo \$${TENANT}_Schema | sed "s/,/ /g")
do
  mysqldump -h localhost -u root -ppassword --set-gtid-purged=OFF --databases $database -r ${database}_`date +%d%b%Y`_final.sql
  sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i ${database}_`date +%d%b%Y`_final.sql
done
echo "Export final dump for target env done"
echo "***********************************************************************************"
if [ $COPY_TO_S3 = 'YES' ]
then
	echo "Copying data to S3"
    zip ${TENANT}_${TARGET_ENV}_`date +%d%b%Y`_final.zip *_final.sql
    aws s3 cp ${TENANT}_${TARGET_ENV}_`date +%d%b%Y`_final.zip s3://veridaydatadump/
	echo "Copying data to S3 Done"
	exit 0
fi
echo "***********************************************************************************"
echo "Backup target env databases to S3 if next import fails"
for database in $(eval echo \$${TENANT}_${TARGET_ENV}_Schema | sed "s/,/ /g")
do
   mysqldump -h $(eval echo \$${TENANT}_${TARGET_ENV}_Hostname) -u $(eval echo \$${TENANT}_${TARGET_ENV}_User) -p$(eval echo \$${TENANT}_${TARGET_ENV}_Password) --single-transaction --set-gtid-purged=OFF --databases $database -r ${TARGET_ENV}_${database}_`date +%d%b%Y`_backup.sql
   zip ${TARGET_ENV}_${database}_`date +%d%b%Y`_backup.zip ${TARGET_ENV}_${database}_`date +%d%b%Y`_backup.sql
   aws s3 cp ${TARGET_ENV}_${database}_`date +%d%b%Y`_backup.zip s3://veridaydatadump/
done
echo "Backup target env databases to S3 done"
echo "***********************************************************************************"
echo "Drop exsting databases in target env(if exists)"
cat<<OVER > mysql_drop_target.sh
mysql -h $(eval echo \$${TENANT}_${TARGET_ENV}_Hostname) -u $(eval echo \$${TENANT}_${TARGET_ENV}_User) -p$(eval echo \$${TENANT}_${TARGET_ENV}_Password)<<EOF
DROP DATABASE \$1;
EOF
OVER
for database_in_taget in $(eval echo \$${TENANT}_${TARGET_ENV}_Schema | sed "s/,/ /g")
do
   bash mysql_drop_target.sh $database_in_taget
done
echo "Drop exsting databases in target env(if exists) is done"
echo "***********************************************************************************"
echo "Creating empty databases in target env"
cat<<OVER > mysql_create_target.sh
mysql -h $(eval echo \$${TENANT}_${TARGET_ENV}_Hostname) -u $(eval echo \$${TENANT}_${TARGET_ENV}_User) -p$(eval echo \$${TENANT}_${TARGET_ENV}_Password)<<EOF
create database \$1 DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci;
EOF
OVER
for database in $(eval echo \$${TENANT}_${TARGET_ENV}_Schema | sed "s/,/ /g")
do
   bash mysql_create_target.sh $database 
done
echo "Creation of empty databases in target env done"
echo "***********************************************************************************"
echo "stop application"
ansible-playbook -i $(eval echo \$${TENANT}_${TARGET_ENV}_AppServers), stop-tomcat-playbook.yml -e 'ansible_python_interpreter=/bin/python3' -u service-user
echo "stop application done"
echo "***********************************************************************************"
echo "Import final dumps to target env"
cat<<OVER > mysql_import_target.sh
mysql -h $(eval echo \$${TENANT}_${TARGET_ENV}_Hostname) -u $(eval echo \$${TENANT}_${TARGET_ENV}_User) -p$(eval echo \$${TENANT}_${TARGET_ENV}_Password)<<EOF
use \$1;
source \$1_`date +%d%b%Y`_final.sql;
EOF
OVER
for database in $(eval echo \$${TENANT}_${TARGET_ENV}_Schema | sed "s/,/ /g")
do
   bash mysql_import_target.sh $database
done
echo "Import final dumps to target env done"
echo "***********************************************************************************"
echo "Start application"
ansible-playbook -i $(eval echo \$${TENANT}_${TARGET_ENV}_AppServers), start-tomcat-playbook.yml --extra-vars "TENANT=${TENANT}" -e 'ansible_python_interpreter=/bin/python3' -u service-user
echo "Start application done"
echo "***********************************************************************************"