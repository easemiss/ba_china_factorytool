#!/bin/sh

echo 1 > /proc/sys/kernel/printk
if [[ $2 == *.log ]]; then
	LOGFILE=$2
fi
TEST_NAME="[LVDS] - [Play video to LVDS]"
TEST_PARAMS=$1
TEST_PROMPT_PRE="Look at the LVDS Display"
TEST_PROMPT_POST="Did you see the video on the LVDS display?"
function Test_Function
{
	FILE=$1
	
	echo -n 1 > /sys/class/graphics/fb2/blank
	#gst-launch playbin2 uri=file://$FILE video-sink="mfw_v4lsink device=/dev/video17" &>/dev/null
	timeout 10s gst-launch-1.0 playbin uri=file:///home/root/Q7/bin/fb/Film2.AVI video-sink="imxv4l2sink device=/dev/video16" audio-sink="alsasink device=plughw:0" &>/dev/null	
	#HDMI: vidieo18
	#gst-launch-1.0 playbin uri=file:///home/root/Q7/bin/fb/Film2.AVI video-sink="imxv4l2sink device=/dev/video18" audio-sink="alsasink device=plughw:0"
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
echo 7 > /proc/sys/kernel/printk
