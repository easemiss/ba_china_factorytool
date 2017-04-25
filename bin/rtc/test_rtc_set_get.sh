#!/bin/sh

if [[ $2 == *.log ]]; then
	LOGFILE=$2
fi
TEST_NAME="[RTC] - [RTC time set\get]"
TEST_PARAMS=$1

RETVAL=0
set_rtc_time() {
	hwclock -w
	if [ $? -eq 0 ]; then
		echo -e "Set RTC time Pass"
	else
		echo -e "Set RTC time Fail"
		RETVAL=1
	fi
}

get_rtc_time() {
	hwclock -r
	if [ $? -eq 0 ]; then
		echo -e "Get RTC time Pass"
	else
		echo -e "Get RTC time Fail"
		RETVAL=1
	fi
}
function Test_Function
{
	RETVAL=0
	NTPSERVER=$1
	#start-stop-daemon --stop -p /var/run/ntp.pid
	/etc/init.d/ntpd stop
	SET_TIME="010203042010"
	echo "set host date from NTP server($NTPSERVER)"
	ntpdate $NTPSERVER &>/dev/null
	if [ $? -eq 0 ]; then
		date
		set_rtc_time
		get_rtc_time
		echo "set host time to 01/02/2010 03:04"
		date $SET_TIME
		set_rtc_time
		get_rtc_time

	else
		echo "network error! "
		return 1
	fi
	ntpdate $NTPSERVER &>/dev/null
	if [ $? -eq 0 ]; then
		hwclock -w &>/dev/null
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

