#!/bin/bash


############# Print table using for loop ################

# read -p "please Enter number: " number

# for num in {1..10}
# do  
#    echo $((num*number))
# done 

############## Print file contain which in .sh extantion  #######################


for i in $(ls *.txt)
do 
  echo "$i"
done 