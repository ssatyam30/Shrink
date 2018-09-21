#!/bin/ksh 

#########################DO NOT CHNAGE########
#current Directory
export PDIR=`pwd`
. $PDIR/Utility/commonUtils.sh
#############################################

#############################################
#Get all features and execute
#############################################
export TERM=xterm

export SERVICE_LIST="ECS"

export CUSTOMER="COLT"

echo "starting execution for COLT: service ECS"
main 
echo "execution for COLT is completed successfully"


