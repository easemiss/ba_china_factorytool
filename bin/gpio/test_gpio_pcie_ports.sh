#!/bin/sh

if [[ $1 == *.log ]]; then
	LOGFILE=$1
fi
TEST_NAME="[GPIO] - [CN28 GPIO pcie_ports input\output]"
TEST_PARAMS=""


declare -a gpioGroup=("170" "1" "5" "204")
declare -a out_gpioGroup=("5" "204")
declare -a in_gpioGroup=("170" "1")

declare -a out_name_gpioGroup=("Q7_3V3_PCIE_WAKE#_IN" "Q7_3V3_PCIE_RST#_OUT")
declare -a in_name_gpioGroup=("Q7_3V3_WDTRIG" "Q7_3V3_PWMOUT")

echo 1 > /sys/bus/pci/devices/0000\:00\:00.0/remove

gpio_unexport() {
	echo "$1" > /sys/class/gpio/unexport 
}

gpio_export() {
	if [ -d /sys/class/gpio/gpio$1 ] ; then
		gpio_unexport $1
	fi
	echo $1 > "/sys/class/gpio/export"
}

gpio_dir_out() {
	echo "out" > "/sys/class/gpio/gpio$1/direction"
}

gpio_dir_in() {
	echo "in" > "/sys/class/gpio/gpio$1/direction"
}

gpio_read() {
	cat /sys/class/gpio/gpio$1/value
}	

gpio_write() {
	echo "$2" > /sys/class/gpio/gpio$1/value
}	
function Test_Function
{
	RETVAL=0
	
	for((i=0;i<${#gpioGroup[@]};i++))
	do
		gpio_export ${gpioGroup[$i]}
		gpio_dir_in ${gpioGroup[$i]}
	done

	for((i=0;i<${#out_gpioGroup[@]};i++))
	do
		gpio_dir_out ${out_gpioGroup[$i]}
	done
	
	for((i=0;i<${#out_gpioGroup[@]};i++))
	do
		PAIR_RETVAL=0
		gpio_v='0'
		
		#if [ $i -eq 0 ]; then
		#	/unit_tests/memtool -32 0x209C000=0x7E8A01CF
		#elif [ $i -eq 1 ]; then
		#	/unit_tests/memtool -32 0x20B4000=0x0002200
		#fi
		gpio_write "${out_gpioGroup[$i]}" $gpio_v
		gpio_in=`cat /sys/class/gpio/gpio${in_gpioGroup[$i]}/value`

		if [[ $gpio_in != $gpio_v ]];then
			PAIR_RETVAL=1
			RETVAL=1
		fi

		gpio_v='1'
		#if [ $i -eq 0 ]; then
		#	/unit_tests/memtool -32 0x209C000=0x7E8A01EF
		#elif [ $i -eq 1 ]; then
		#	/unit_tests/memtool -32 0x20B4000=0x0003200
		#fi
		gpio_write "${out_gpioGroup[$i]}" $gpio_v	
		gpio_in=`cat /sys/class/gpio/gpio${in_gpioGroup[$i]}/value`

		if [[ $gpio_in != $gpio_v ]];then
			PAIR_RETVAL=1
			RETVAL=1
		fi
		TEST_INFO="${out_name_gpioGroup[$i]}<---->${in_name_gpioGroup[$i]}"
		if [ $PAIR_RETVAL -eq 0 ]; then
			printf "%-60s " "$TEST_INFO"                                   
                 	echo -en "pass\n"
		else
			printf "%-60s " "$TEST_INFO"                                   
                 	echo -en "failed\n"
		fi
	done
	
	for((i=0;i<${#gpioGroup[@]};i++))
	do
		gpio_unexport ${gpioGroup[$i]}
	done
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

