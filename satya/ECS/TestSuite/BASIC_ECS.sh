#!/bin/ksh -x

#########################DO NOT CHNAGE########
#Parent Directory
#PDIR=`dirname $(dirname "$(readlink -f $0)")`

. $PDIR/Utility/commonUtils.sh
. $PDIR/Utility/SystemConfig.dat
. $PDIR/$serviceName/Config/$1

#############################################

#############################################
logger "Start: Call verification 	"

###### make sure input data file should exists with the feature name in the form of feature.csv ###
cleanUpLogsFolder
feature=basic_ecs

createSIPPDataFile $feature.csv
dataFile=$PDIR/$serviceName/$SWAP/$feature.csv

cleanCASLogs 
startTCPDump $feature

#start PSAP HTTP listener
logger "starting PSAP HTTP listener with $PSAP_HTTP_PORT http://$CAS_ip:$CAS_port/ username password $PDIR/$httpInfoFile"
> $PDIR/$httpInfoFile
$PDIR/$serviceName/TestSuite/PSAP.py "$PSAP_HTTP_PORT" "http://$CAS_ip:$CAS_port/" "username" "password" "$PDIR/$httpInfoFile" &

#TotalCalls=$(expr `cat $dataFile | wc -l` - 1 - `grep "#" $dataFile | wc - l`)
TotalCalls=`egrep -v "^#|^[ ]*$|^SEQUENTIAL" $dataFile | wc -l` 
#TotalCalls=1
if [ "$TotalCalls" -gt "0" ]
then
	#run callee
	$SIPP_Path -inf $dataFile -sf $PDIR/$serviceName/XML/psap_basic.xml $PSAP_SIP_IP:$PSAP_SIP_PORT -rsa $PSAP_SIP_IP:$PSAP_SIP_PORT -t u1 -i $Local_Host -p $T1_Port  -aa  $messageLevel $errorLevel $logLevel -bg 

	#run caller
	$SIPP_Path -inf $dataFile -sf $PDIR/$serviceName/XML/ecs_caller_basic.xml $CAS_ip:$CAS_port -rsa $CAS_ip:$CAS_port -m $TotalCalls -t u1 -i $Local_Host -p $Local_Port  -aa -l 1 $messageLevel $errorLevel $logLevel
fi

#stop PSAP HTTP server
$PDIR/$serviceName/TestSuite/shutdown_PSAP.sh
saveTCPDump $feature

saveCASLogs $feature

wait 5
checkSIPP $feature

logger "===========End: Call verification	=========="
logger "===========Start: Checking CDRs	=========="

checkHTTPInfo $feature
moveSIPPLogs $feature

logger "===========End: END of Checking CDRs	=========="

