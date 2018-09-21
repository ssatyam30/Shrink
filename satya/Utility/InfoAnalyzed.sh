#!/bin/ksh -x


PDIR="/home/aconyx/Satya/HT"
RESULTS="Result"
SWAP="Swap"
LOGS="Log"

export test_call_id=""
export collectPacket="false"
export compare="false"
export bufferFile=""
export IA_Results="$PDIR/$serviceName/$RESULTS/IA_Results_$1.csv"

pcapLogger(){
	echo "$1" >> $PDIR/$serviceName/$LOGS/parseInfoAnalysed.log
        echo "$1"
}



getBuffer(){
	
	pcapLogger "creating ISUP buffer for test case $test_call_id"
	egrep -v "^#|^[ ]*$" $tcID.XML | while read LINE ; do

		
		### verify the parameters if compare is true ###
		if [ "$compare" == "true" ]
		then
			validBuffer=`echo $LINE | grep "0d0a"`
			if [ "X$validBuffer" != "X" ]
			then
				echo "$notify_callID;$LINE" >> $bufferFile
				compare="false"
				notify_callID=""
				collectPacket="false"
			else continue
			fi

		fi

		##getting the message Info Analysed from CAS ###
#		notify_callID=`echo $LINE| grep "sip.Call-ID" | grep "ASE_" | grep "GB"`

		callID_Tag=`echo $LINE| grep "sip.Call-ID" | grep "ASE_" | grep "GB"`
		t1="${callID_Tag#*GB-}"
		t2=${t1:0:1}
		if [ "x$t2" != "x" ] 
		then
			pcapLogger "got the Analysed Info Message with call id $notify_callID"
			collectPacket="true"
			notify_callID=`echo $t2 | cut -d "/" -f1`
			notify_callID="GB-$notify_callID"
			continue
		fi


		### if collectPacket is false,continue ###
		if [ "$collectPacket" == "false" ] 
		then
			continue
		fi

		### check if sip msg body found and then start compare ####
		sipMsgBody=`echo $LINE| grep "sip.msg_body"`
		if [ "x$sipMsgBody" != "x" ] && [ "$collectPacket" == "true" ]
		then
			pcapLogger "got the sip msg body, starting compare tags"
			compare="true"
			continue

		fi



	done
	compareBuffer $bufferFile

}


compareBuffer(){

	pcapLogger " buffer file: $bufferFile"
	> $IA_Results
	egrep -v "^#|^[ ]*$" $IA_Data_File | while read LINE ; do
		
		###LINE=hats2-1;8088870001;76260;8088870001;###
		IFS=";"
		set -A params $LINE
		countP="${#params[@]}"
		unset IFS

		testCaseID=${params[0]}
		stream=`grep $testCaseID $bufferFile`
		resultStatus=""
		for (( i=1; i<$countP; i++ ))
		do
			streamCheck=`echo $stream | grep ${params[$i]}`
			if [ "X$streamCheck" == "X" ]
			then
				pcapLogger "check failed for param: ${params[$i]}"
				if [ "X$resultStatus" == "X" ]
				then
					resultStatus="$testCaseID:FAIL;PARAM:${params[$i]}" 
				else	resultStatus="$resultStatus;PARAM:${params[$i]}" 
				fi

			fi
		done
		if [ "X$resultStatus" == "X" ]
		then
			echo "$testCaseID:PASS" >> $IA_Results
		else	echo "$resultStatus" >> $IA_Results
		fi

	done
}


parseInfoAnalysed(){	

	export IA_Data_File="$PDIR/$serviceName/$SWAP/IA_$1.csv"
	pcapLogger "checking PCAP File"
	bufferFile=pcap_$1.buffer
	> $bufferFile
	export tcID=$1
	if [ ! -e "$PDIR/$serviceName/$tcID.pcap" ]
	 then
		echo "PCAP FILE: $PDIR/$serviceName/$tcID.pcap DOES NOT EXIST"
		tcResult="FAIL"
		tcReason="PCAP FILE $tcID.pcap DOES NOT EXIST"
	else
		### getting the SIP messages from this PCAP
		tshark -n -r $PDIR/$serviceName/$tcID.pcap  -T pdml > $tcID.XML
		getBuffer
	fi

}
parseInfoAnalysed $1
