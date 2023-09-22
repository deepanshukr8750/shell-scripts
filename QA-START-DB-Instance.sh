#!/bin/bash
echo $TENANT
apt-get install jq -y

ASSUME_ROLE_OUTPUT=$(aws sts assume-role --role-arn arn:aws:iam::159438352634:role/VeridayOperationsAdministrationRole --role-session-name startrdsec2)
ASSUME_ROLE_ENVIRONMENT=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials | .["AWS_ACCESS_KEY_ID"] = .AccessKeyId | .["AWS_SECRET_ACCESS_KEY"] = .SecretAccessKey | .["AWS_SESSION_TOKEN"] = .SessionToken | del(.AccessKeyId, .SecretAccessKey, .SessionToken, .Expiration)
 | to_entries[] | "export \(.key)=\(.value)"')
eval $ASSUME_ROLE_ENVIRONMENT

echo "Assume role success"
echo "=========================================================="
echo "Starting RDS instances"

region=us-east-1

array=($(echo $TENANT | tr ',' "\n"))

for element in "${array[@]}"
do 
	slist=$(aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`stopped`].[DBInstanceIdentifier]' --output text  --region $region)

for row in $slist; do
   db_instance_identifier=`echo $row | awk '{print $1}'`

   for element in "${array[@]}"; do
       shopt -s nocasematch
       if [[ $db_instance_identifier == *"-$element-"* ]]
       then
       	 echo $db_instance_identifier
         aws rds start-db-instance --db-instance-identifier $db_instance_identifier --region $region > /dev/null 2>&1
       fi
   done
	done
done
echo "Starting RDS instances Done"
echo "=========================================================="
echo "Waiting for DBs to start!"
sleep 12m
len=${#array[@]}
i=0
echo "=========================================================="
echo "Starting EC2 instances"

while [ $i -lt $len ]
do

	slist=$(aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`available`].[DBInstanceIdentifier]' --output text  --region $region)

	for row in $slist; do
   		db_instance_identifier=`echo $row | awk '{print $1}'`

   		for element in "${array[@]}"; do
        shopt -s nocasematch
        if [[ $db_instance_identifier == *"-$element-"* ]]
        then

          slist=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output text --filters "Name=tag:FQDN,Values=*.$(echo "$element" | awk '{print tolower($0)}').*" "Name=instance-state-name,Values=stopped"  --region $region)
    
    	for row in $slist
    	do
      	 instance_id=`echo $row | awk '{print $1}'`
       	 state_name=`echo $row | awk '{print $2}'`
         aws ec2 start-instances --instance-ids $instance_id --region $region > /dev/null 2>&1
         let i++   
      	done
   
       fi
       
   	   done
   done

done
echo "Starting EC2 instances Done"
echo "=========================================================="
<<comment
echo "Waiting for Apps to start!"
sleep 8m
tenant_array=($(echo $TENANT | tr ',' "\n"))
retry_count=5

while [ ${#tenant_array[@]} -ne 0 ]
do
    for i in "${!tenant_array[@]}"
    do
        resp_code=$(curl -I "node-1.nginx.portal.da-1.$(echo "${tenant_array[$i]}" | awk '{print tolower($0)}').qa.aws.veriday.net/login" --max-time 5 2>&1 | awk '/HTTP\// {print $2}')
        if [[ "${resp_code}" = "200" || "${resp_code}" = "301" ]]
        then
          echo Tenant ${tenant_array[$i]} is up
          unset "tenant_array[$i]"
        else
          echo Tenant ${tenant_array[$i]} is not up yet
        fi
    done
    sleep 2m
    let retry_count--
    if [[ "${retry_count}" -eq 0 ]]
    then
      echo Tenant ${tenant_array[@]} not up yet or returning 301 code instead of 200; 
      echo "Please check login URL if it is available else Please contact operations."
      exit 1
    fi 
done
comment

echo "Waiting for Apps to start!"
sleep 8m
tenant_array=($(echo $TENANT | tr ',' "\n"))
retry_count=5

while [ ${#tenant_array[@]} -ne 0 ]
do
    for i in "${!tenant_array[@]}"
    do
        content=$(curl --silent --insecure "https://node-1.nginx.portal.da-1.$(echo "${tenant_array[$i]}" | awk '{print tolower($0)}').qa.aws.veriday.net/delegate/services/admin/healthcheck" --max-time 5)
        if [[ "$content" == *"alive"* && "$content" == *"reachable"* ]]
        then
          echo Tenant ${tenant_array[$i]} is up
          unset "tenant_array[$i]"
        else
          echo Tenant ${tenant_array[$i]} is not up yet
        fi
    done
    sleep 2m
    let retry_count--
    if [[ "${retry_count}" -eq 0 ]]
    then
      echo Tenant ${tenant_array[@]} not up yet; 
      echo "Please check login URL if it is available else please contact operations."
      exit 1
    fi 
done