#!/bin/bash

#  Here is two method to file is exist or not in this directory 
###################### this is using condition #############################

#  read -p "Enter a File path with name: " file
 
#  file="/home/deftbox/Desktop/deepanshu/shellsripts/ami.sh"



#  filename=$(basename $file)
#  if [ -e $file ]
#  then 
#  echo "$filename is exist."
#  head -10 $filename
#  else 
#  echo "$filename does't exist."
#  exit 1
#  fi


#################### And this is using for loop   ##################################

# for filepath in /home/deftbox/Desktop/deepanshu/shellsripts/ami.sh
# do
#     filename=$(basename $filepath)

#     echo "yes $filename is exist"
# done

############# Print last 10 line of the file ######################################

 read -p "Enter a File path with name: " file
 read -p "Enter the Word Which you want: " Word
 
###  file="/home/deftbox/Desktop/deepanshu/shellsripts/ami.sh"

 filename=$(basename $file)
 if [ -e $file ]
 then 
 echo "$filename is exist."
 tail -10 $filename
 
 else 
 echo "$filename does't exist."
 exit 1
 fi

 grep -o -i $Word $filename | wc -l