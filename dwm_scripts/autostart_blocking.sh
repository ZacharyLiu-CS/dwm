#!/bin/bash
# Screenshot: http://s.natalian.org/2013-08-17/dwm_status.png
# Network speed stuff stolen from http://linuxclues.blogspot.sg/2009/11/shell-script-show-network-speed.html

# This function parses /proc/net/dev file searching for a line containing $interface data.
# Within that line, the first and ninth numbers after ':' are respectively the received and transmited bytes.



LOC=$(readlink -f "$0")
DIR=$(dirname "$LOC")
export IDENTIFIER="unicode"
FLASH_RATE=2

print_volume() {
	volume="$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
	if test "$volume" -gt 0
	then
		echo -e "\uE05D${volume}"
	else
		echo -e "Mute"
	fi
}

print_mem(){
	memfree=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))
	echo -e "$memfree"
}

print_temp(){
	test -f /sys/class/thermal/thermal_zone0/temp || return 0
	echo $(head -c 2 /sys/class/thermal/thermal_zone0/temp)C
}


print_bat(){
	if $(acpi -b | grep -v unavailable| grep --quiet Discharging)
	then
		chargingIcon="🔋";
		timeLeft="$(acpi -b | grep -v unavailable | grep "remaining" |  awk '{print $5}'  |cut -c1-5) Left"
	else # acpi can give Unknown or Charging if charging, https://unix.stackexchange.com/questions/203741/lenovo-t440s-battery-status-unknown-but-charging
		chargingIcon="🔌";
		timeLeft="$(acpi -b  |grep -v unavailable| grep "until charged" |awk '{print $5}'  |cut -c1-5)"
		if [ -n "$timeLeft" ];
		then
			timeLeft=$(printf "%sRemain" $timeLeft)
		fi
	fi
		
		# get charge of all batteries, combine them
	total_charge=$(cat /sys/class/power_supply/BAT*/capacity);
	# get amount of batteries in the device
	battery_number=$(ls /sys/class/power_supply | grep BAT |wc -l);
	percent=$(expr $total_charge / $battery_number);
	batPercent=$percent%;

	echo "$chargingIcon $batPercent"
	if [ -n "$timeLeft" ];
	then
		echo ", $timeLeft"
	fi

}

print_date(){
	date '+%Y/%m/%d %H:%M'
}


dwm_alsa () {
    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    printf "%s" "$SEP1"
    if [ "$IDENTIFIER" = "unicode" ]; then
        if [ "$VOL" -eq 0 ]; then
            printf "🔇"
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
            printf "🔈 %s%%" "$VOL"
        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
            printf "🔉 %s%%" "$VOL"
        else
            printf "🔊 %s%%" "$VOL"
        fi
    else
        if [ "$VOL" -eq 0 ]; then
            printf "MUTE"
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
            printf "VOL %s%%" "$VOL"
        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
            printf "VOL %s%%" "$VOL"
        else
            printf "VOL %s%%" "$VOL"
        fi
    fi
    printf "%s\n" "$SEP2"
}

function get_bytes {
	# Find active network interface
	interface=$(ip route get 8.8.8.8 2>/dev/null| awk '{print $5}') 
	if [ $1 == "recv" ];
	then
		line=$(grep $interface /proc/net/dev | awk '{print $2}')
	else
		line=$(grep $interface /proc/net/dev | awk '{print $10}')
	fi
	echo $line
}

# Function which calculates the speed using actual and old byte number.
# Speed is shown in KByte per second when greater or equal than 1 KByte per second.
# This function should be called each second.
old_bytes_recv=""
old_bytes_trans=""
export old_bytes_recv
export old_bytes_trans

function calculate_velocity {
	now_value=$1
	old_value=$2
	velKB=$(echo "($now_value-$old_value)/1024/$FLASH_RATE" | bc)
	if test "$velKB" -gt 1024
	then
		echo $(echo "scale=2; $velKB/1024" | bc)MB/s
	


	else
		echo ${velKB}KB/s
	fi
}
function network_speed {
	now_bytes_recv=$(get_bytes recv)
	now_bytes_trans=$(get_bytes trans)
	if [ -n "$old_bytes_recv" ];
	then
		vel_recv=$(calculate_velocity $now_bytes_recv  $old_bytes_recv)
		vel_trans=$(calculate_velocity $now_bytes_trans  $old_bytes_trans)
	fi
	old_bytes_recv=$now_bytes_recv
	old_bytes_trans=$now_bytes_trans
	vel_recv=$(printf "⬇%-8s" $vel_recv)
	vel_trans=$(printf "⬆%-8s" $vel_trans )
	
}
while true
do
	network_speed
	xsetroot -name "$vel_recv $vel_trans 🌡$(print_temp) 💿 $(print_mem)M $(dwm_alsa) [ $(print_bat) ] $(print_date) "

	sleep $FLASH_RATE
done

