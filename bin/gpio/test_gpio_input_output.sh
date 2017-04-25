#!/bin/sh

if [[ $2 == *.log ]]; then
	LOGFILE=$2
fi
case $1 in
        CN25)
                TEST_NAME="[GPIO] - [CN25 DB9 GPIO ports input\output]"
                declare -a gpioGroup=("32" "33" "34" "35" "36" "37" "38" "39")
		declare -a out_gpioGroup=("32" "33" "34" "35")      
		declare -a in_gpioGroup=("36" "37" "38" "39")   
		declare -a out_name_gpioGroup=("gpio32" "gpio33" "gpio34" "gpio35")
		declare -a in_name_gpioGroup=("gpio36" "gpio37" "gpio38" "gpio39")
		;;                    
        CN28)                     
                TEST_NAME="[GPIO] - [CN28 GPIO ports input\output]"
                declare -a gpioGroup=("105" "164" "152" "174" "44" "46" "153" "104" "150" "7" "162" "165" "176" "175" "47" "30" "8" "121" "45")
		declare -a out_gpioGroup=("176" "30" "121" "44" "46" "47" "153" "7" "175" "176")
		declare -a in_gpioGroup=("150" "162" "152" "165" "164" "105" "104" "8" "174" "45")
		declare -a out_name_gpioGroup=("Q7_3V3_SDIO_LED" "Q7_SMB_ALERT" "Q7_3V3_SPI5_CS1" "Q7_3V3_SD4_SDIO_DATA4" "Q7_3V3_SD4_SDIO_DATA6" "Q7_3V3_SD4_SDIO_DATA7" "Q7_3V3_I2S_RST#_OUT"  "Q7_3V3_CAN1_TX" "Q7_3V3_SD4_SDIO_WP" "Q7_3V3_SDIO_LED")
		declare -a in_name_gpioGroup=("Q7_3V3_THRMTRIP" "Q7_3V3_FAN_METER_IN" "Q7_3V3_BATLOW#_IN" "Q7_3V3_LID_BTN#_IN" "Q7_3V3_SLP_BTN_IN" "Q7_3V3_WAKE#_IN" "Q7_3V3_THRM#_IN" "Q7_3V3_CAN1_RX" "Q7_3V3_SD4_SDIO_PWR" "Q7_3V3_SD4_SDIO_DATA5") 
		;;
	*)
		echo "Usage:"                                          
                echo "    $0 [CN25 CN28]"
                echo "       CN25:   [GPIO] - [CN25 DB9 GPIO ports input\output]"
                echo "       CN28:   [GPIO] - [CN28 GPIO ports input\output]"               
                exit 1
		;;
esac
#TEST_NAME="[GPIO] - [CN28 GPIO ports input\output]"
TEST_PARAMS=""


#declare -a gpioGroup=("105" "164" "152" "174" "44" "46" "153" "104" "150" "7" "162" "165" "176" "175" "47" "30" "8" "19")
#declare -a out_gpioGroup=("176" "30" "19" "44" "46" "47" "153"  "7" "175")
#declare -a in_gpioGroup=("150" "162" "152" "165" "164" "105" "104" "8" "174")
#declare -a out_name_gpioGroup=("Q7_3V3_SDIO_LED" "Q7_SMB_ALERT" "Q7_3V3_SPI5_CS1" "Q7_3V3_SD4_SDIO_DATA4" "Q7_3V3_SD4_SDIO_DATA6" "Q7_3V3_SD4_SDIO_DATA7" "Q7_3V3_I2S_RST#_OUT"  "Q7_3V3_CAN1_TX" "Q7_3V3_SD4_SDIO_WP")
#declare -a in_name_gpioGroup=("Q7_3V3_THRMTRIP" "Q7_3V3_FAN_METER_IN" "Q7_3V3_BATLOW#_IN" "Q7_3V3_LID_BTN#_IN" "Q7_3V3_SLP_BTN_IN" "Q7_3V3_WAKE#_IN" "Q7_3V3_THRM#_IN" "Q7_3V3_CAN1_RX" "Q7_3V3_SD4_SDIO_PWR")

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

		gpio_write "${out_gpioGroup[$i]}" $gpio_v
		gpio_in=`cat /sys/class/gpio/gpio${in_gpioGroup[$i]}/value`

		if [[ $gpio_in != $gpio_v ]];then
			PAIR_RETVAL=1
			RETVAL=1
		fi

		gpio_v='1'
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

