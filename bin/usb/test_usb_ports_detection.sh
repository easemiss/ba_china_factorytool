#!/bin/sh

if [[ $1 == *.log ]]; then
	LOGFILE=$1
fi
TEST_NAME="[USB Ports] - [USB Ports detection]"
TEST_PARAMS=""
TEST_PROMPT_PRE="Please plug the USB devices into CN5,CN6x2,CN8"

function Test_Function
{
	#echo "Please plug the USB devices into CN5,CN6x2,CN8"
	echo ""
	BUS_NUM=`lsusb -t | grep -B1 "hub/4p" |grep Bus |awk '{print $3}' |cut -c 2-2`
	#BUS_NUM=1
	if [ -z "$BUS_NUM" ]; then
		echo "USB Ports HUB detection failed!"  
                return 1
	fi
	declare -a USB_PORT
	USB_HUB_TEST_RESULT=true
	if [[ ! -d "/sys/bus/usb/devices/${BUS_NUM}-1:1.0" ]]; then
		echo "USB Ports HUB detection failed!"
		return 1
	else
		USB_PORT=`ls /sys/bus/usb/devices/${BUS_NUM}-1:1.0 | grep "port[0-9]"`

		for i in ${USB_PORT[@]} ;do 
			#echo $i
			usb_device=`ls /sys/bus/usb/devices/${BUS_NUM}-1:1.0/$i | grep "device"`
			if [[ $usb_device == "" ]];then
				echo "$i    device detection failed"
				USB_HUB_TEST_RESULT=false
			else
				echo "$i    device detection OK"
			fi
		done

		if [[ $USB_HUB_TEST_RESULT == "true" ]]; then
			echo "USB Ports connected device detection OK!"
			return 0
		else
			echo "USB Ports connected device detection failed!"
			return 1
		fi
	fi
	
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
			#Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
			set -o pipefail                                         
                        Test_Function $TEST_PARAMS 2>&1 | tee -a $LOGFILE
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
		printf "%-60s: " "$TEST_NAME"
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

