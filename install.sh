#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

rm -r includes/EyeWitness includes/Responder includes/yasuo includes/chuckle

apt-get install xsltproc firewalk -y

git clone https://github.com/commonexploits/dtpscan.git includes/dtpscan
git clone https://github.com/ChrisTruncer/EyeWitness.git includes/EyeWitness
git clone https://github.com/lgandx/Responder.git includes/Responder
git clone https://github.com/0xsauby/yasuo.git includes/yasuo
git clone https://github.com/portcullislabs/udp-proto-scanner.git includes/udp-proto-scanner
#git clone https://github.com/nccgroup/chuckle.git includes/chuckle

mv phantomjs includes/EyeWitness/ 
cd includes/EyeWitness/setup/
./setup.sh
cd ../../../
mkdir -p /usr/share/rubygems-integration/all/gems/rake-10.3.2/bin/
ln /usr/bin/rake /usr/share/rubygems-integration/all/gems/rake-10.3.2/bin/rake
gem install ruby-nmap net-http-persistent mechanize text-table
pip install xlwt
pip install --upgrade html5lib==1.0b8
#clear
echo -e '\n\nINSTALLED! How to use\n*********************\n'
./scan.sh
