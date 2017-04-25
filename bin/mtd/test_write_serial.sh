#!/bin/sh

if [[ $1 == *.log ]]; then
	LOGFILE=$1
fi
TEST_NAME="[NOR Flash] - [Write Serial Number]"
TEST_PARAMS=""
TEST_PROMPT_PRE=""

function Test_Function
{
	PART=0
	DEVICE=/dev/mtdblock$PART

	echo "== Checking Current PN/SN =="	
	PN=`strings $DEVICE | cut -c 1-11`
	SN=`strings $DEVICE | cut -c 12-22`

	echo "[PCBA_PART_NUMBER] = $PN"
	echo "[BOARD_SERIAL_NUMBER] = $SN"

	read -p "Enter NEW [PCBA_PART_NUMBER]:(such as 9696BA1601E) " number
        while [[ ${#number} -ne 11 ]]; do
                echo "   Board PCBA part number length must be equal to 11, please enter again" 
                read -p "   board PCBA part number:(such as 9696BA1601E) " number
        done
	PCBA_PART_NUMBER=$number

	read -p "Enter NEW [BOARD_SERIAL_NUMBER]:(such as LKE0000956) " number
        while [[ ${#number} -ne 10 ]]; do
                echo "   Board serial number length must be equal to 10, please enter again" 
                read -p "   board serial number:(such as LKE0000956) " number
        done
	BOARD_SERIAL_NUMBER=$number

        flash_eraseall /dev/mtd$PART
	if [ $? -ne 0 ]; then
		echo "Erasing the SPI ROM:    failed"
		return 1
	fi	
	echo "== [END] Erasing the SPI ROM =="

	echo -n $PCBA_PART_NUMBER$BOARD_SERIAL_NUMBER > SN
	dd if=SN of=$DEVICE bs=1

	echo "== Checking NEW PN/SN =="
        PN=`strings $DEVICE | cut -c 1-11`
        SN=`strings $DEVICE | cut -c 12-22`

        echo "[PCBA_PART_NUMBER] = $PN"
        echo "[BOARD_SERIAL_NUMBER] = $SN"

	return 0
}

if [ -n "$LOGFILE" ]; then
	echo "$TEST_NAME" > $LOGFILE
	echo "" >> $LOGFILE
	echo "$(date)" >> $LOGFILE
	echo "============================" >> $LOGFILE
fi
unset INTERACTIVE
if [ -n "$TEST_PROMPT_PRE" ]; then
	INTERACTIVE=1
	echo "Interactive Test $TEST_NAME"
	unset RESULT

	while [ -z "$RESULT" ]; do
		echo "   $TEST_PROMPT_PRE"

		if [ -z "$TEST_PROMPT_POST" ]; then
			echo -n "   Press any key to continue"
			read
            	else
                	sleep 2
            	fi

		#$TEST_COMMAND >> $LOGFILE 2>&1
		#RESULT=$?
		if [ -n "$LOGFILE" ]; then
			Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
			#set -o pipefail                                         
                        #Test_Function $TEST_PARAMS 2>&1 | tee -a $LOGFILE
		else
			Test_Function $TEST_PARAMS
		fi
		RESULT=$?
		if [ -n "$TEST_PROMPT_POST" ]; then
			echo -n "   $TEST_PROMPT_POST (y/n/r[etry]): "
			read RESPONSE
			if [[ "$RESPONSE" == "y" ]]; then
				RESULT=0
			elif [[ "$RESPONSE" == "n" ]]; then
				RESULT=1
			else
				unset RESULT
			fi
            	fi
	done

	printf "%-60s: " "$TEST_NAME"
else
	if [ -n "$LOGFILE" ]; then
		printf "%-60s: \n" "$TEST_NAME"
		#Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
		set -o pipefail                                         
                Test_Function $TEST_PARAMS 2>&1 | tee -a $LOGFILE
	else
		echo "Automated Test $TEST_NAME"
		echo ""
		Test_Function $TEST_PARAMS
	fi
	RESULT=$?
fi
if [ "$RESULT" == 0 ]; then
	if [ -n "$LOGFILE" ]; then
		echo "============================" >> $LOGFILE
        	echo "SUCCESS" >> $LOGFILE
	fi
	if [ -n "$INTERACTIVE" ]; then
		echo -en "SUCCESS\n"
		echo ""
	else
		echo -en "SUCCESS\n"
        fi
else
	if [ -n "$LOGFILE" ]; then
		echo "============================" >> $LOGFILE
        	echo "FAILURE" >> $LOGFILE
	fi
	if [ -n "$INTERACTIVE" ]; then
		echo -en "FAILURE\n"                    
		echo ""
	else
		echo -en "FAILURE\n"
	fi
fi

