#!/bin/bash
len=`echo $TENANT |awk '{print length}'`
if [ $len -eq 0 ]; then
TENANT='CLIC, IPC, OPS, RBC, CIBC, RBCUS, RGMP'
fi
echo $TENANT
apt-get install jq -y

ASSUME_ROLE_OUTPUT=$(aws sts assume-role --role-arn arn:aws:iam::159438352634:role/VeridayOperationsAdministrationRole --role-session-name stoprdsec2)
ASSUME_ROLE_ENVIRONMENT=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials | .["AWS_ACCESS_KEY_ID"] = .AccessKeyId | .["AWS_SECRET_ACCESS_KEY"] = .SecretAccessKey | .["AWS_SESSION_TOKEN"] = .SessionToken | del(.AccessKeyId, .SecretAccessKey, .SessionToken, .Expiration)
 | to_entries[] | "export \(.key)=\(.value)"')
eval $ASSUME_ROLE_ENVIRONMENT

echo "Assume role success"
echo "=========================================================="
echo "Stopping EC2 instances"

region=us-east-1

array=($(echo $TENANT | tr ',' "\n"))

for element in "${array[@]}"
do
    shopt -s nocasematch
    slist=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output text --filters "Name=tag:FQDN,Values=*.$(echo "$element" | awk '{print tolower($0)}').*" "Name=instance-state-name,Values=running"  --region $region)
    
    for row in $slist
    do
       instance_id=`echo $row | awk '{print $1}'`
       state_name=`echo $row | awk '{print $2}'`

       aws ec2 stop-instances --instance-ids $instance_id --region $region > /dev/null 2>&1

    done
done 
echo "Stopping EC2 instances Done"
echo "=========================================================="
echo "Stopping RDS instances"
for element in "${array[@]}"
do 
	slist=$(aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`available`].[DBInstanceIdentifier]' --output text  --region $region)

for row in $slist; do
   db_instance_identifier=`echo $row | awk '{print $1}'`

   for element in "${array[@]}"; do
       shopt -s nocasematch
       if [[ $db_instance_identifier == *"-$element-"* ]]
       then
         echo $db_instance_identifier
         aws rds stop-db-instance --db-instance-identifier $db_instance_identifier --region $region > /dev/null 2>&1
       fi
   done
	done
done
echo "Stopping RDS instances Done"
echo "=========================================================="