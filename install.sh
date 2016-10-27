#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

rm -r includes/EyeWitness includes/Responder includes/yasuo includes/chuckle

apt-get install xsltproc

git clone https://github.com/ChrisTruncer/EyeWitness.git includes/EyeWitness
git clone https://github.com/lgandx/Responder.git
git clone https://github.com/0xsauby/yasuo.git includes/yasuo
#git clone https://github.com/nccgroup/chuckle.git includes/chuckle

mv phantomjs $HOME/includes/EyeWitness/ 
cd includes/EyeWitness/setup/
./setup.sh
cd ../../../
mkdir -p /usr/share/rubygems-integration/all/gems/rake-10.3.2/bin/
ln /usr/bin/rake /usr/share/rubygems-integration/all/gems/rake-10.3.2/bin/rake
gem install ruby-nmap net-http-persistent mechanize text-table
pip install xlwt
clear
echo -e 'INSTALLED! How to use\n*********************\n'
./scan.sh
