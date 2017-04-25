#!/bin/sh

if [[ $1 == *.log ]]; then
	LOGFILE=$1
fi
TEST_NAME="[WDT] - [WDOUT]"
TEST_PARAMS=""

function Test_Function
{
	RETVAL=0
	GPIO_PORT=45	
	
	/unit_tests/memtool -32 0x20E0330=0x5
	
	if [ -d /sys/class/gpio/gpio$GPIO_PORT ] ; then
		echo "$GPIO_PORT" > /sys/class/gpio/unexport 
	fi
	echo $GPIO_PORT > "/sys/class/gpio/export"
	echo "in" > "/sys/class/gpio/gpio$GPIO_PORT/direction"
	
	GPIO_VALUE=`cat /sys/class/gpio/gpio$GPIO_PORT/value`
	# 1
	if [ $GPIO_VALUE -ne 0 ]; then
		RETVAL=1
	fi

	/unit_tests/memtool SRC.SCR.MASK_WDOG_RST=0x5
	/unit_tests/memtool WDOG1.WCR.WDA=0x0
	GPIO_VALUE=`cat /sys/class/gpio/gpio$GPIO_PORT/value`
	# 0
	if [ $GPIO_VALUE -ne 1 ]; then
		RETVAL=1
	fi

	/unit_tests/memtool WDOG1.WCR.WDA=0x1
	GPIO_VALUE=`cat /sys/class/gpio/gpio$GPIO_PORT/value`
	# 1
	if [ $GPIO_VALUE -ne 0 ]; then
		RETVAL=1
	fi
	echo "$GPIO_PORT" > /sys/class/gpio/unexport

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

