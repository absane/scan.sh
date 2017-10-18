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
SHODANAPIKEY='XXXXX'

rm -r $SCAN_RESULTS_LOCATION

if [ ! -d $SCAN_RESULTS_LOCATION ]; then
	mkdir -p $SCAN_RESULTS_LOCATION;
fi

## Port Scanning to enum all live hosts
nmap -e $INTERFACE -vvv --reason --max-retries 5 --randomize-hosts -PEPM -sn -n -oG /tmp/ping.gnmap -iL $HOME/$NETWORK
nmap -e $INTERFACE -vvv --reason --max-retries 0 --randomize-hosts --open -T4 -Pn -n -sS -F -oG /tmp/tcp1.gnmap -iL $HOME/$NETWORK --top-ports=500
nmap -e $INTERFACE -vvv --reason --max-retries 0 --randomize-hosts --open -T4 -Pn -n -sY -F -oG /tmp/tcp2.gnmap -iL $HOME/$NETWORK --top-ports=500
nmap -e $INTERFACE -vvv --reason --max-retries 0 --randomize-hosts --open -T4 -Pn -n -sU -p53,69,111,123,137,161,500,514,520 -oG /tmp/udp.gnmap -iL $HOME/$NETWORK
grep Host /tmp/*.gnmap | grep Up | awk '{print $2}' | sort | uniq > $HOME/$NETWORK

## UDP Scan on live hosts
nmap -e $INTERFACE -vvv --reason --max-retries 0 --randomize-hosts --open -T4 -Pn -n -sU -sV -oA $SCAN_RESULTS_LOCATION/${NETWORK}_udp --source-port=53 --script=default,safe --script-args "shodan-api.apikey=${SHODANAPIKEY}" -p53,67-69,11,123,135,137-139,161-162,445,500,514,520,631,996-999,1434,1701,1900,3283,4500,5353,49152-49154 -iL $HOME/$NETWORK

## TCP Scan on live hosts
nmap -e $INTERFACE --randomize-hosts -iL $HOME/$NETWORK -vvv -T4 --open -Pn -n -sS -sV -oA $SCAN_RESULTS_LOCATION/$NETWORK --source-port=80 --script=default -script-args "shodan-api.apikey=${SHODANAPIKEY}" -p-

## Create HTML of Nmap Scan Results
xsltproc $SCAN_RESULTS_LOCATION/$NETWORK.xml -o $SCAN_RESULTS_LOCATION/$NETWORK.html
xsltproc $SCAN_RESULTS_LOCATION/${NETWORK}_udp.xml -o $SCAN_RESULTS_LOCATION/${NETWORK}_udp.html

## Parse Nmap results for PeepingTom and service brute forcing
echo 'y' | $HOME/includes/gnmapparser.sh -g $SCAN_RESULTS_LOCATION/
mv $HOME/Parsed-Results/ $SCAN_RESULTS_LOCATION/Parsed_Nmap_Results

## Parse Nmap for report table on Nmap results
python $HOME/includes/parse_nmap.py -f $SCAN_RESULTS_LOCATION/$NETWORK.xml

## USE EYE WITNESS HERE.. screesnhot web + vnc + rdp
cd $HOME/includes/EyeWitness/
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --headless -d $SCAN_RESULTS_LOCATION/EyeWhitnessWeb1 --no-prompt --active-scan --prepend-https
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --web -d $SCAN_RESULTS_LOCATION/EyeWhitnessWeb2 --no-prompt --active-scan --prepend-https
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --rdp -d $SCAN_RESULTS_LOCATION/EyeWhitnessRDP --no-prompt --active-scan
./EyeWitness.py -x $SCAN_RESULTS_LOCATION/$NETWORK.xml --vnc -d $SCAN_RESULTS_LOCATION/EyeWhitnessVNC --no-prompt --active-scan
mkdir -p $SCAN_RESULTS_LOCATION/EyeWhitness
mv $SCAN_RESULTS_LOCATION/EyeWhitnessWeb* $SCAN_RESULTS_LOCATION/EyeWhitnessRDP $SCAN_RESULTS_LOCATION/EyeWhitnessVNC $SCAN_RESULTS_LOCATION/EyeWhitness/
cd $HOME

## Clean
mkdir $SCAN_RESULTS_LOCATION/nmap_results
mv $SCAN_RESULTS_LOCATION/*.{gnmap,nmap,xls,xml,html} $SCAN_RESULTS_LOCATION/nmap_results/
cp $HOME/$NETWORK $SCAN_RESULTS_LOCATION/
rm -r $HOME/Desktop

cd $HOME

## Open results in IceWeasel
firefox &
sleep 2
firefox -new-tab $SCAN_RESULTS_LOCATION/ &
sleep 2

## Open Zenmap
zenmap $SCAN_RESULTS_LOCATION/nmap_results/$NETWORK.xml & 
