#!/bin/ksh -x

export PDIR="/home/aconyx/Satya/"
#############################################
export session_idFile="$PDIR/INC/session_id.ingw"
export dialogIDFile="$PDIR/INC/dialogIDFile"

export inc_sess_id=""
export hex_file_msg=""
export hex_file_rc=""
export hex_file_dtmf=""
export hex_file_oa=""
export hex_file_od=""

### below data length is for Service ###
export data_length=0
export orig_length=0
export odd_even_length=0
export dialog_ID=""
export sk=""
export opc=""
export dpc=""
export cas_fip=""
export testcase_id=""
export tc_csv=""
export tc_csv_LINE=""

getPorts(){
	echo "in getPorts"

}
num_hex(){

	#num_hex VALUE CONVERT_TO_HEX REVERSE_BYTES PLACE_HOLDER TAG_CODE EVEN ODD PADDING_LOCATION HEX_FILE_NAME TYPE
	hex=""
	num=$1
	code=""
	PLACE_HOLDER="$2"
	params=`grep $PLACE_HOLDER "$PDIR/Utility/inc_buffer_variables.dat"`
#	CALLER_LNP:0:1:0:83:03 13:83 13
	CONVERT_TO_HEX=`echo $params | cut -d ":" -f2`
	REVERSE_BYTES=`echo $params | cut -d ":" -f3`
	PADDING_LOCATION=`echo $params | cut -d ":" -f4`
	TAG_CODE=`echo $params | cut -d ":" -f5`
	EVEN=`echo $params | cut -d ":" -f6`
	ODD=`echo $params | cut -d ":" -f7`

	### if hex file name is blank, its initial buffer file
	if [ "X$3" != "X" ]
	then
		HEX_FILE_NAME="$dialog_ID.$3"
	else	HEX_FILE_NAME="$dialog_ID"
	fi

	### setting pedding and even odd values
	
	if [ "X$EVEN" != "X" ]
	then
		odd_even="$EVEN "
		odd_even_length=2
	fi
	if [ $((${#num}%2)) -eq 1 ];
	then
		if [ "X$PADDING_LOCATION" == "X1" ]
		then
		    num="0${num}"
			odd_even="$ODD "
			odd_even_length=2
		elif [ "X$PADDING_LOCATION" == "X0" ]
		then
			num="${num}0"
		else 	logger "for $PLACE_HOLDER padding is not required"
		fi
	fi
	### setting correct tag code and adjusting lenght value along with tag
	if [ "x$TAG_CODE" != "x" ]
	then
		orig_length=`expr $((${#num}/2)) + $odd_even_length`
		o_length=`printf "%x" $orig_length`

		if [ $((${#o_length}%2)) -eq 1 ];
		then
			o_length="0$o_length "
		fi
		code="$TAG_CODE $o_length$odd_even"							
	fi



	### convert string to hex
	if [ "x$CONVERT_TO_HEX" == "x1" ]
	then
		num=`printf "%x" $num`
	fi
	####if number is still odd, add padding in beginning
	j="1"
	if [ $((${#num}%2)) -eq 1 ];
	then
		num="0$num"
	fi

	### convert string to set of two bytes
	for (( i=0; i<${#num}; i++ )) 
	do   
		a="${num:$i:1}"
		i=`expr $i + $j`
		b="${num:$i:1}"
		if [ "x$b" == "x" ]
		then
			b=0
		fi
		### if string need to reverse
		if [ "x$REVERSE_BYTES" == "x1" ]
		then
			hex="$hex$b$a "
		else hex="$hex$a$b "
		fi
	done

	### take length of complete hex 
	i=`expr ${#hex} - 1`
	hex="${hex:0:$i}"

	logger "$num and $hex for $PLACE_HOLDER"
	### setting the buffer name based on type of message.
	sed s/$2/"$code$hex"/g $PDIR/$serviceName/$SWAP/$HEX_FILE_NAME.hex > tmp
	cat tmp > $PDIR/$serviceName/$SWAP/$HEX_FILE_NAME.hex 

}
updateDataLength(){

	#	DATA_LENGTH
	logger "DATA_LENGTH code: total_data_length=$data_length + $orig_length + $dest_length + 1"
	data_length=`expr $data_length + $orig_length + $dest_length`
	total_data_length=`expr $data_length + "2"`
	num_hex $total_data_length "DATA_LENGTH"
        buffer_len=`expr 14 + $total_data_length`
        num_hex $buffer_len "BUFFER_SIZE"
}
updateTC_CSV(){

	if [ "X$1" != "X" ]
	then
		$PDIR/INC/hex_to_buff.sh $PDIR/$serviceName/$SWAP/$dialog_ID.$1.hex $PDIR/$serviceName/$SWAP/$dialog_ID.$1.buffer
		tl=`hexdump -v -e '1/1 "\n"' $PDIR/$serviceName/$SWAP/$dialog_ID.$1.buffer |wc -l`	

	else	
		$PDIR/INC/hex_to_buff.sh $PDIR/$serviceName/$SWAP/$dialog_ID.hex $PDIR/$serviceName/$SWAP/$dialog_ID.buffer
		tl=`hexdump -v -e '1/1 "\n"' $PDIR/$serviceName/$SWAP/$dialog_ID.buffer |wc -l`	
	fi

	### create CSV file for scenarios
	tc_csv_LINE="$tc_csv_LINE;t1"

}

createBufferToSendLNP(){

	num_hex `echo $1 | cut -d ";" -f2` "CALLER_LNP" 
	num_hex `echo $1 | cut -d ";" -f3` "CALLEE_LNP" 
	num_hex `echo $1 | cut -d ";" -f4` "CPC" 
	num_hex $sk "SERVICE_KEY"
	num_hex $opc "ORIG_POINT_CODE" 
	num_hex $tpc "TERM_POINT_CODE" 

}

createBufferToSendAXVPN(){

	num_hex `echo $1 | cut -d ";" -f2` "CALLER" 
	num_hex `echo $1 | cut -d ";" -f3` "CALLEE" 
	num_hex `echo $1 | cut -d ";" -f4` "CPC" 
	num_hex $sk "SERVICE_KEY"
	num_hex $opc "ORIG_POINT_CODE" 
	num_hex $tpc "TERM_POINT_CODE" 
	num_hex $dialog_ID "DIALOG_ID" "dtmf"
	num_hex $dialog_ID "DIALOG_ID" "oa"
	num_hex $dialog_ID "DIALOG_ID" "od"
	updateTC_CSV "dtmf"
	updateTC_CSV "oa"
	updateTC_CSV "od"

}

createBufferToSendSNS(){
	
	num_hex `echo $1 | cut -d ";" -f2` "CALLER_HT"
	num_hex `echo $1 | cut -d ";" -f3` "TRUNK_GRP_ID_SNS"
	num_hex `echo $1 | cut -d ";" -f4` "CALLED_PARTY_ID_SNS"
	num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_HT"
	num_hex `echo $1 | cut -d ";" -f6` "DIALLED_NO_SNS"
}

createBufferToSendMLCN(){
	
	#test_case_id;SCCP_CALLED_PARTY;DN;TRIGGER_CRITERA;CALLING_PARTY_NO;DIALLED_NO_MLCN;
	num_hex `echo $1 | cut -d ";" -f2` "SCCP_CALLED_PARTY"
	num_hex `echo $1 | cut -d ";" -f3` "DN"
	num_hex `echo $1 | cut -d ";" -f4` "TCR"
	num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_HT"
	num_hex `echo $1 | cut -d ";" -f6` "CALLER_HT"
	num_hex `echo $1 | cut -d ";" -f7` "DIALLED_NO_MLCN"

}

createBufferToSendGETS(){
	
	num_hex `echo $1 | cut -d ";" -f2` "CALLER_HT"
	num_hex `echo $1 | cut -d ";" -f3` "PIC_CARRIER"
	num_hex `echo $1 | cut -d ";" -f4` "CALLED_PARTY_ID_GETS"
	num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_HT"
	num_hex `echo $1 | cut -d ";" -f6` "LATA"

}

createBufferToSendHATS2(){
#test_case_id;sccp_called_party;user_id_dn;triggering_crieria;charge_no;calling_party_no;collected_digits;
#INC_hats2-1;8088870002;8088870002;3;8088870002;8088870002;14480
	num_hex `echo $1 | cut -d ";" -f2` "SCCP_CALLED_PARTY"
	num_hex `echo $1 | cut -d ";" -f3` "USER_ID_DN"
	num_hex `echo $1 | cut -d ";" -f4` "TCR"
	num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_HT"
        num_hex `echo $1 | cut -d ";" -f6` "CALLER_HT"
        num_hex `echo $1 | cut -d ";" -f7` "DIALLED_NO_HATS2"

}

createBufferToSendCRS(){

        num_hex `echo $1 | cut -d ";" -f2` "TCR"
        num_hex `echo $1 | cut -d ";" -f3` "CHARGE_NO_HT"
        num_hex `echo $1 | cut -d ";" -f4` "CALLER_HT"
        num_hex `echo $1 | cut -d ";" -f5` "CALLEE_HT"
        num_hex `echo $1 | cut -d ";" -f6` "REDIRECTION_PARTY"

}

createBufferToSendCNI(){
	
	num_hex $dialog_ID "DIALOG_ID" "rc"
	updateTC_CSV "rc"


        num_hex `echo $1 | cut -d ";" -f2` "SCCP_CALLED_PARTY"
        num_hex `echo $1 | cut -d ";" -f3` "DN"
        num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_CNI" 
        num_hex `echo $1 | cut -d ";" -f6` "CALLER_CNI"
	num_hex `echo $1 | cut -d ";" -f4` "CALLED_PARTY_CNI"
}

createBufferToSendCIDTV(){

        num_hex `echo $1 | cut -d ";" -f2` "SCCP_CALLED_PARTY"
        num_hex `echo $1 | cut -d ";" -f3` "DN"
        num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_CIDTV"
        num_hex `echo $1 | cut -d ";" -f6` "CALLING_PARTY_CIDTV_HT"
        num_hex `echo $1 | cut -d ";" -f4` "CALLED_PARTY_ID_CIDTV"

}

createBufferToSendZCR(){

        num_hex `echo $1 | cut -d ";" -f2` "CALLER_ZCR"
        num_hex `echo $1 | cut -d ";" -f3` "TRUNK_GRP_ID_ZCR"
        num_hex `echo $1 | cut -d ";" -f4` "CALLED_PARTY_ID_ZCR"
        num_hex `echo $1 | cut -d ";" -f5` "CHARGE_NO_ZCR"
        num_hex `echo $1 | cut -d ";" -f6` "DIALLED_NO_ZCR"

}

createHex(){

	LINE=$1
	testcase_id=`echo $LINE| cut -d ";" -f1`
	> $PDIR/$serviceName/$SWAP/$dialog_ID.buffer
	### copying initial hex buffer with dialog id name
	cat $hex_file_msg > $PDIR/$serviceName/$SWAP/$dialog_ID.hex


	case $feature in
		ht_gets)
			logger "creating buffer for ht_gets"
			createBufferToSendGETS $LINE
			;;
		ht_gets)
			logger "creating buffer for ht_gets"
			createBufferToSendGETS $LINE
			;;
		ht_hats2)
			logger "creating buffer for ht_gets"
			createBufferToSendHATS2 $LINE
			;;
		ht_sns)
			logger "creating buffer for ht_gets"
			createBufferToSendSNS $LINE
			;;
		ht_crs)
			logger "creating buffer for ht_gets"
			createBufferToSendCRS $LINE
			;;
		ht_cni)
			logger "creating buffer for ht_gets"
			createBufferToSendCNI $LINE
			;;
		ht_zcr)
			logger "creating buffer for ht_gets"
			createBufferToSendZCR $LINE
			;;
		ani)
			logger "creating buffer for ht_gets"
			createBufferToSendAXVPN $LINE
			;;
		lnp)
			logger "creating buffer for ht_gets"
			createBufferToSendLNP $LINE
			;;
		atf)
			logger "creating buffer for ht_gets"
			createBufferToSendATF $LINE
			;;
		*)
			logger "feature not found to create buffer "
			return 1
			;;

	  esac

	num_hex $dialog_ID "DIALOG_ID"
	updateDataLength
	updateTC_CSV

}

getDialogID(){

	if [ ! -e "$dialogIDFile" ]
         then
 	 	logger "this is first message, creating dialogIDFile"
		dialog_ID=$FIRST_DIAG_ID
	else 
		logger "this is not first message of INC"
		dialog_ID=`tail -1 $dialogIDFile`
		if [ "dialog_ID" -gt "1200000" ] 
		then
			dialog_ID="1100001"
		fi
		dialog_ID=$((dialog_ID+1))
	fi
	 echo $dialog_ID > $dialogIDFile
}


createBufferFiles(){

	inc_sess_id=`head -1 $session_idFile`

	if [ "X$inc_sess_id" == "X" ]
	then
		echo "INC not yet started, not able to create files with INC Session ID"
		return 1
	fi

	getDialogID
	tc_csv=$incDataFile
	data_length="$DEFAULT_BUFFER_SIZE"

	hex_file_msg="$PDIR/INC/$HEX_FILE"
	sk=$SERVICE_KEY
	opc=$OPC
	tpc=$DPC
	cas_fip=`echo $CAS_ip | cut -d "=" -f2 | cut -d "." -f4`
	echo "SEQUENTIAL;" > $tc_csv


	egrep -v "^#|^[ ]*$" $INC_TC_File | while read -r line
	do
		createHex $line
		echo "$tc_csv_LINE" >> $tc_csv
		echo -n "."
		orig_length=""
		dest_length=""
		dialog_ID=`expr 1 + $dialog_ID`
	done
	echo $dialog_ID > $dialogIDFile
}
. $PDIR/$serviceName/Config/Hawaii.properties

export serviceName="HT"
export SWAP="Swap"
export feature="ht_gets"
export incDataFile="$PDIR/$serviceName/$SWAP/$feature.inc.csv"
export INC_TC_File="$PDIR/$serviceName/$SWAP/$feature.csv"

export HEX_FILE=$feature.hex
export DEFAULT_BUFFER_SIZE=$DEFAULT_BUFFER_SIZE_GETS
createBufferFiles


