#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

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
