#!/bin/ksh 
		export PDIR=/root/colt/satya
		. /root/colt/satya/Utility/commonUtils.sh
		export serviceName=ECS
		export customerName=COLT 
/root/colt/satya/ECS/TestSuite/BASIC_ECS.sh COLT.properties
getReleaseVersionInfo ECS COLT
cat /root/colt/satya/Utility/htmlTemplate.sat >> /root/colt/satya/ECS/ECS.COLT.html

		export END_TIME=`date +%Y%m%d-%H:%M:%S`
		export END_SECONDS=$SECONDS
		ELAPSED_TIME=$((END_SECONDS-START_SECONDS))
		Time_taken=$(convertsecs $ELAPSED_TIME)
		Duration=`printf "Total Seconds: %.0f seconds " $ELAPSED_TIME `
		sed "s/START_TIME/20180920-11:28:12/g"  /root/colt/satya/ECS/ECS.COLT.html > tmp
		sed "s/END_TIME/$END_TIME/g"  tmp > tmp2
		sed "s/DURATION/$Time_taken/g"  tmp2 > tmp
		sed "s/TOTAL_SECONDS/$Duration/g"  tmp > /root/colt/satya/ECS/ECS.COLT.html
		rm -rf tmp tmp2
		cp /root/colt/satya/ECS/ECS.COLT.html /root/colt/satya/REPORTS/
		mv /root/colt/satya/ECS/ECS.COLT.html /root/colt/satya/ECS/ECS.COLT.20180920-112812.html
