#!/bin/bash 

argsnum=$#
echo 1 > /proc/sys/kernel/printk
if [[ ${!argsnum} == *.log ]]; then
	LOGFILE=${!argsnum}
fi
TEST_NAME="[WLAN] - [GPIO6 (WLAN_IRQ)\SDIO]"
REASONABLE_ERROR=6

count=0
if [[ ${!argsnum} == *.log ]]; then
	pingip=`expr $# - 1`
	if [[ "${!pingip}" == *.*.*.* ]]; then
		while [[ -n "$3" ]]
		do
			parameters[$count]=$1
			count=$[ $count + 1 ]
			shift
		done
		parameters[6]=$1
	else
		while [[ -n "$2" ]]
		do
			parameters[$count]=$1
			count=$[ $count + 1 ]
			shift
		done
	fi
elif [[ ${!argsnum} == *.*.*.* ]];then
	while [[ -n "$2" ]]
	do
		parameters[$count]=$1
		count=$[ $count + 1 ]
		shift
	done
	parameters[6]=$1
else
	while [[ -n "$1" ]]
	do
		parameters[$count]=$1
		count=$[ $count + 1 ]
		shift
	done
fi
function Test_Function
{
	INTERFACE=${parameters[0]}
	DRIVERTYPE=${parameters[1]}
	NETWORK=${parameters[2]}
	PASSWORD=${parameters[3]}
	TIMEOUT=${parameters[4]}
	WIFILEVEL=${parameters[5]}
	PINGLOC=${parameters[6]}
	if [ -z "$INTERFACE" ]; then
		INTERFACE=wlan0
	fi

	if [ -z "$DRIVERTYPE" ]; then
		DRIVERTYPE=nl80211
	fi

	if [ -z "$NETWORK" ] || [ -z "$PASSWORD" ]; then
		SKIPCONNECTIONTEST=1
		echo "Skipping connection test"
	fi
	
	if [ -z "$TIMEOUT" ]; then
		TIMEOUT=20
	fi
	
	if [ -z "$WIFILEVEL" ]; then
		WIFILEVEL=-48
	fi

	WIFILEVEL_MAX=`expr $WIFILEVEL + $REASONABLE_ERROR`
	WIFILEVEL_MIN=`expr $WIFILEVEL - $REASONABLE_ERROR`

	if [ -z "$PINGLOC" ]; then
		SKIPPINGTEST=1
		#    echo "Skipping ping test"
	fi
	# Disable RFKill
	if which rfkill > /dev/null; then
		rfkill unblock all
	fi
	if ! ifconfig $INTERFACE down; then    
            echo "Device $INTERFACE not found!"
            return 1                           
        fi                                     
        if ! ifconfig $INTERFACE up; then      
            echo "Device $INTERFACE not found!"
            return 1                                                  
        fi                                                              
        ps |grep "udhcpc -i $INTERFACE" |awk '{print $1;}' |xargs kill -9 &>/dev/null
	
	if [ -z "$SKIPCONNECTIONTEST" ]; then

		killall wpa_supplicant &>/dev/null
		sleep 1
		wpa_passphrase $NETWORK $PASSWORD > /tmp/wpa.conf
		wpa_supplicant -D $DRIVERTYPE -c/tmp/wpa.conf -i$INTERFACE -B
	
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
	
		./bin/net/iw wlan0 set power_save off
		if ! udhcpc -i $INTERFACE -t $TIMEOUT -n; then
			echo "Could not get IP Address from $NETWORK"
			killall wpa_supplicant &>/dev/null 
			rm /tmp/wpa.conf
			return 1
		fi

		echo "WiFi RSSI"
		for (( i=0;i<10;i++ ))
		do
			level[$i]=`cat /proc/net/wireless |grep $INTERFACE |awk '{print $4}' |cut -d . -f -1`
			echo "level[$i]=${level[$i]}"
			usleep 100000
		done
		level_sum=0
		for (( i=0;i<10;i++ ))
		do
			level_sum=`expr ${level[$i]} + $level_sum`
		done
		level_ave=`expr $level_sum / 10`
		echo "level_average=$level_ave  ExpectedLevel_MIN=$WIFILEVEL_MIN  ExpectedLevel_MAX=$WIFILEVEL_MAX"
		if [[ $level_ave -lt $WIFILEVEL_MIN ]] || [[ $level_ave -gt $WIFILEVEL_MAX ]];then
			echo "Signal quality level is not within the scope of the expected signal quality level"
			killall wpa_supplicant &>/dev/null 
			rm /tmp/wpa.conf
			return 1
		fi

		if [ -z "$SKIPPINGTEST" ] && ! ping $PINGLOC -c 5; then
			echo "Could not connect to internet"
			killall wpa_supplicant &>/dev/null 
			rm /tmp/wpa.conf
			return 1
		fi

		killall wpa_supplicant &>/dev/null
		rm /tmp/wpa.conf
	fi
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
		printf "%-60s: \n" "$TEST_NAME"
#		Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
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
sleep 2
echo 7 > /proc/sys/kernel/printk

