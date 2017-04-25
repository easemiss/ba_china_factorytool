#!/bin/sh

if [[ $2 == *.log ]]; then
	LOGFILE=$2
fi
TEST_NAME="[SDcard] - [SDcard Read\Write]"
TEST_PARAMS="$1"

fifoStr="01234567890abcdefghijklmnopqrstuvwxyz!@#$%^&*()"
declare -A mmc_type_group
for i in `ls /sys/bus/mmc/devices/`
do
        mmc_type_group[$i]=`cat /sys/bus/mmc/devices/$i/type`

done
declare -i sd_dev_num
return_sd_dev() {
        for i in "${!mmc_type_group[@]}"
        do
                if [[ "${mmc_type_group[$i]}" == "SD" ]];then
                        sd_dev_num=`ls /sys/bus/mmc/devices/$i/block/ | grep -o '[0-9]\+'`			
			if [[ $sd_dev_num -ge 1 ]];then                        
				echo | ls /sys/bus/mmc/devices/$i/block/
			fi
                fi
        done
}
file_RW_test() {
	RESULT=0	
	TMPDIR=`mktemp -d`
	if [[ $3 != "" ]]; then
		if [[ ! -e "/dev/$1" ]]; then
			if [[ $3 == "USB" ]]; then			
				echo "$3(port$5) $4 ($1) : /dev/$1 no exist" "Failed"
				RESULT=1
			else
				echo "$3($1) : /dev/$1 no exist"    "Failed"
				RESULT=1				
			fi			
			rm -rf $TMPDIR
			return $RESULT
		fi
		sync&& umount "/dev/$1" &>/dev/null
		if `mount "/dev/$1" $TMPDIR &>/dev/null` ;then
			for((i=1;i<=$2;i++)) do
				echo $fifoStr > "$TMPDIR/test.txt"
				ReadStr=`cat $TMPDIR/test.txt`
				if [ $fifoStr == $ReadStr ]; then
					if [[ $3 == "USB" ]]; then			
						echo "$3(port$5) $4 ($1) : Read/Write"    "Pass"
					else
						echo "$3($1) : Read/Write"    "Pass"				
					fi
				else
					if [[ $3 == "USB" ]]; then			
						echo "$3(port$5) $4 ($1) : Read/Write"    "Failed"
						RESULT=1
					else
						echo "$3($1) : Read/Write"    "Failed"
						RESULT=1				
					fi
				fi
				sleep 1
				rm $TMPDIR/test.txt
			done			
			sync && umount "/dev/$1" &>/dev/null && sync && sleep 1
		else
			if [[ $3 == "USB" ]]; then			
				echo "$3(port$5) $4 ($1) : /dev/$1 cannot be mounted correctly"    "Failed"
				RESULT=1
			else
				echo "$3($1) : /dev/$1 cannot be mounted correctly"    "Failed"
				RESULT=1
			fi
		fi		
	fi
	rm -rf $TMPDIR
	return $RESULT
}

function Test_Function
{
	RETVAL=0
	sddev=`return_sd_dev`
	
	TEST_COUNT=$1
	if [ -z "$TEST_COUNT" ]; then
		TEST_COUNT=1
	fi	
	if [[ "$sddev" == mmcblk* ]];then
		file_RW_test ${sddev}p1 $TEST_COUNT "SDcard"
		if [ $? -ne 0 ]; then                                   
                	RETVAL=1                                        
                fi
	else
		echo "SDcard(no sdcard)"    "Failed"
		RETVAL=1
	fi
	return $RETVAL
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
		Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
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

