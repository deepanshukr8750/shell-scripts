################# print all arguments ############
#!/bin/bash

# # Print all argument ins one short Usning of "$@"
# for name in $@
# do
#   echo "my name is $name"
# done

######################

#!/bin/sh

DATE=`date`    ####### This is use to see date 
echo "Date is $DATE"

USERS=`who | wc -l`      ### This command help to see how many user are logged in 
echo "Logged in user are $USERS"

UP=`date ; uptime`    #### This command is use to see what is date and uptime of this system
echo "Uptime is $UP"
