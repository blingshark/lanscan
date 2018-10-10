#!/bin/bash
echo "Welcome to netsharkscan (beta_1.0)"
echo " "
echo "------List Interfaces------"
echo " "

ip link show | awk '{print "\033[m" $2 "\033[32m" $9 "\033[m"}'

echo " "
echo "--------------------------"
read -p "Choose interface (ex: wlan0) : " interface
clear
YourMacAddress=$(ip link show dev $interface |grep link/ether |awk '{print $2}')
YourAddress=$(ifconfig $interface | grep "inet " | awk '{print $2}')
MASK=$(ifconfig $interface | grep "inet " | awk '{print $4}')

tonum() {
    if [[ $1 =~ ([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+) ]]; then
        addr=$(( (${BASH_REMATCH[1]} << 24) + (${BASH_REMATCH[2]} << 16) + (${BASH_REMATCH[3]} << 8) + ${BASH_REMATCH[4]} ))
        eval "$2=\$addr"
    fi
}
toaddr() {
    b1=$(( ($1 & 0xFF000000) >> 24))
    b2=$(( ($1 & 0xFF0000) >> 16))
    b3=$(( ($1 & 0xFF00) >> 8))
    b4=$(( $1 & 0xFF ))
    eval "$2=\$b1.\$b2.\$b3.\$b4"
}



tonum $YourAddress IPADDRNUM
tonum $MASK MASKNUM

#printf "IPADDRNUM: %x\n" $IPADDRNUM
#printf "MASKNUM: %x\n" $MASKNUM

# The logic to calculate network and broadcast
INVMASKNUM=$(( 0xFFFFFFFF ^ MASKNUM ))
NETWORKNUM=$(( IPADDRNUM & MASKNUM ))
BROADCASTNUM=$(( INVMASKNUM | NETWORKNUM ))
LastAddress=$(( INVMASKNUM -1 | NETWORKNUM ))
lss=$(( INVMASKNUM -1 ))
FistAddress=$(( NETWORKNUM +1 ))
FF=$(( 0x0090 ))

toaddr $FistAddress FistAddress
toaddr $LastAddress LastAddress
toaddr $NETWORKNUM NETWORK
toaddr $BROADCASTNUM BROADCAST

echo "Your MAC Address=$YourMacAddress"
printf "%-25s %s\n" "FF=$FF"
printf "%-25s %s\n" "Fist Address=$FistAddress"
printf "%-25s %s\n" "Last Address=$LastAddress"     
printf "%-25s %s\n" "Your Address=$YourAddress"      
printf "%-25s %s\n" "Your Mask=$MASK"     
printf "%-25s %s\n" "Network Address=$NETWORK"    
printf "%-25s %s\n" "BroadCast Address=$BROADCAST"
#printf "%-25s %s\n" "lss=$lss" 
echo "--------------------------------------------"
echo "Hostname"  " " "|" " " "IPaddr"  " " "|" " " "MACaddr"
echo " "
function Hostname {
if [[ "${SUBNET}.$i" = "$YourAddress" ]]; then
hostname
else
arp -D ${SUBNET}.$i | grep ether | awk '{print $1}'
fi
}

function MACaddr {
if [[ "${SUBNET}.$i" = "$YourAddress" ]]; then
echo "$YourMacAddress"
else
arp -D ${SUBNET}.$i | grep ether | awk '{print $3}'
fi
}

function IPaddr {
echo "${SUBNET}.$i"
}

function port {
for ((counter=1; counter<=100; counter++))
do
(echo >/dev/tcp/${SUBNET}.$i/$counter) > /dev/null 2>&1 && echo "|$counter|"
done
}




delay=0.05
host1=$FistAddress
host2=$LastAddress
SUBNET=${host1%.*}
netId1=${host1#$SUBNET.}
netId2=${host2#$SUBNET.}
for ((i=netId1; i<=netId2; i++)); do
timeout ${delay} ping -s 1 -c 1 -W 1 -i 0.000001 -q ${SUBNET}.$i >& /dev/null 
if [[ $? -eq 0 ]]; then
ARRAYS=($(Hostname) "|" $(IPaddr) "|" $(MACaddr))
echo ${ARRAYS[@]}
fi
done
echo "--------------------------------------------"

function ports {
for ((counter=1; counter<=100; counter++))
do
(echo >/dev/tcp/$ipadd/$counter) > /dev/null 2>&1 && echo "|$counter| open"
done
}

read -p "Scan ports? (yes or no) : " res
if [[ $res == yes ]]; then
read -p "Entre ip address : " ipaddrs
ports ipaddrs
else
echo "ok bye"
fi
