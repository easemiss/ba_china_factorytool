#!/bin/sh

if [[ $1 == *.log ]]; then
	LOGFILE=$1
fi

TEST_NAME="[SPI EEPROM] - [U10 SPI EEPROM]"
TEST_PARAMS=""


function Test_Function
{
	DEVICE="/sys/bus/spi/drivers/at25/spi2.0/eeprom"
	#DEVICE="/sys/bus/spi/drivers/at25/spi32765.0/eeprom"

	if [ ! -e "$DEVICE" ]; then
	    echo "File ${DEVICE} not found"
	    return 1
	fi

	echo "Device=${DEVICE}"
	READ=`hexdump -n256 -C $DEVICE | head -n 1 | awk '{print $18 $19}' | cut -c 2-12`
	if [[ $READ == "HELLOWORLD!" ]];then
		WRITE_DATA="GOODMORNING"
	else
		WRITE_DATA="HELLOWORLD!"
	fi
	echo "Write = $WRITE_DATA"
	
	echo "$WRITE_DATA" > $DEVICE
	READ=`hexdump -n256 -C $DEVICE | head -n 1 | awk '{print $18 $19}' | cut -c 2-12`
	
	echo "Read = $READ"
	if [[ $READ == $WRITE_DATA ]];then
		return 0
	else
		return 1
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

