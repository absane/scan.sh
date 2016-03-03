#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

rm -r includes/EyeWitness includes/Responder includes/yasuo includes/chuckle

git clone https://github.com/ChrisTruncer/EyeWitness.git includes/EyeWitness
git clone https://github.com/SpiderLabs/Responder.git includes/Responder
git clone https://github.com/0xsauby/yasuo.git includes/yasuo
#git clone https://github.com/nccgroup/chuckle.git includes/chuckle

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
