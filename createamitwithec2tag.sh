#!/bin/bash

DATE=$(date +%Y-%m-%d_%H-%M)
AMI_NAME="Myimage-$DATE"
AMI_DESCRIPTION="Myimage created on $DATE"
INSTANCE_TAG_KEY="Name"
INSTANCE_TAG_VALUE="ansible-master"

set -x

instance_id=$(aws ec2 describe-instances --filters "Name=tag:$INSTANCE_TAG_KEY,Values=$INSTANCE_TAG_VALUE" --query 'Reservations[].Instances[].InstanceId' --output text)

if [ $? -eq 0 ] && [ -n "$instance_id" ]; then
    aws ec2 create-image --instance-id "$instance_id" --name "$AMI_NAME" --description "$AMI_DESCRIPTION" --no-reboot

    if [ $? -eq 0 ]; then
        printf "AMI request complete!\n"
    fi
else
    printf "No instances found with the specified tag key and value.\n"
fi


