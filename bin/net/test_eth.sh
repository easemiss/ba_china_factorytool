#!/bin/sh

echo 1 > /proc/sys/kernel/printk
if [[ $3 == *.log ]]; then
	LOGFILE=$3
fi
TEST_NAME="[RJ45 GBE] - [GBE]"
TEST_PARAMS="$1 $2"

function Test_Function
{
	INTERFACE=$1
	DHCP_TIMEOUT=$2
	PING_TIMEOUT=$3
	PINGLOC=$4
	if [ -z "$INTERFACE" ]; then
	    INTERFACE=eth0
	fi
	
	if [ -z "$DHCP_TIMEOUT" ]; then
		DHCP_TIMEOUT=5
	fi
	
	if [ -z "$PING_TIMEOUT" ]; then
		PING_TIMEOUT=5
	fi

	if [ -z "$PINGLOC" ]; then
	    SKIPPINGTEST=1
#	    echo "Skipping ping test"
	fi

	if ! ifconfig $INTERFACE down; then                      
            echo "Device $INTERFACE not found!"                
            return 1                                           
        fi

	if ! ifconfig $INTERFACE up; then
	    echo "Device $INTERFACE not found!"
	    return 1
	fi
	
	sleep 5
	end=`dmesg |wc -l`
	for((i=1;i<=5;i++)) do
	    sleep 1
	    end2=`dmesg |wc -l`
	    if [ "$end" != "$end2" ]; then
	        info=`dmesg |awk '{print NR, $0}'|tail -$((end2-end))`
		if [[ $info =~ "$INTERFACE: link becomes ready" ]]; then
			break
		fi
		end=$end2
	    fi
	done

	ps |grep "udhcpc -i $INTERFACE" |awk '{print $1;}' |xargs kill -9 &>/dev/null
	
	if ! udhcpc -i $INTERFACE -t $DHCP_TIMEOUT -n; then
	    echo "Could not get IP Address"
#	    ifconfig $INTERFACE down
	    return 1
	fi

	if [ -z "$SKIPPINGTEST" ] && ! ping $PINGLOC -I $INTERFACE -c $PING_TIMEOUT; then
	    echo "Could not connect to internet"
#	    ifconfig $INTERFACE down
	    return 1
	fi

#	ifconfig $INTERFACE down	
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
sleep 1
echo 7 > /proc/sys/kernel/printk

