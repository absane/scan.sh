#!/usr/bin/env python

# Requirements
# lxml from https://github.com/lxml/lxml.git
# xlwt from https://github.com/python-excel/xlwt.git

from lxml import etree
from optparse import OptionParser
from sys import exit
from tempfile import TemporaryFile
from xlwt import Workbook

FONTSIZE = 256
TARGET_HEADER = "Target Host"
OS_HEADER = "OS   "
TCP_HEADER = "TCP Ports   "
UDP_HEADER = "UDP Ports   "
TARGET_COLUMN = 0
OS_COLUMN = 1
TCP_COLUMN = 2
UDP_COLUMN = 3

def main(file_name):

    # initialize the Excel object #
    ###############################

    # base the xls filename on the xml document loaded
    xls_name = make_xls_name(file_name)
    # create a new Excel workbook
    book = Workbook()
    # create a new worksheet
    sheet1 = book.add_sheet('Open Hosts')
    # write the header row
    sheet1.write(0, TARGET_COLUMN, TARGET_HEADER)
    sheet1.write(0, OS_COLUMN, OS_HEADER)
    sheet1.write(0, TCP_COLUMN, TCP_HEADER)
    sheet1.write(0, UDP_COLUMN, UDP_HEADER)
    
    # create a new xml document object
    doc = etree.parse(file_name)
 
    # initialize variables #
    ########################
    
    # initialize row number
    row = 0

    # accumulators for holding column sizes
    target_column_size = len(TARGET_HEADER)
    os_column_size = len(OS_HEADER)
    tcp_column_size = len(TCP_HEADER)
    udp_column_size = len(UDP_HEADER)

    # xml path names
    path_to_data = "//host[ports/port[state[@state='open']]]"
    path_to_host = "hostnames/hostname/@name"
    path_to_addr = "address/@addr"
    path_to_os = "os/osmatch/@name"
    path_to_ports = "ports/port[state[@state='open']]"

    # itereate through the xml document and find all hosts with open ports
    for x in doc.xpath(path_to_data):
        # initializing variables
        targethost = ''
        os = ''
        tcpports = ''
        udpports = ''

        # increment the row counter
        row = row + 1

        # parse out the hostname if there is one
        for hostname in x.xpath(path_to_host):
            targethost = hostname
        # parse out the IP address
        for addr in x.xpath(path_to_addr):
            targethost = targethost + ' (' + addr + ')'
        # write the target host to the spreadsheet
        sheet1.write(row, TARGET_COLUMN, targethost)
        # resize column if the targethost string is larger than previous value
        if (len(targethost) > target_column_size):
            target_column_size = len(targethost)

        # find the OS if it is available
        for osmatch in x.xpath(path_to_os):
            os = osmatch
        # write the operating system to the spreadsheet 
        sheet1.write(row, OS_COLUMN, os)
        # resize column if the os string is larger than previous value
        if (len(os) > os_column_size):
            os_column_size = len(os)

        # find all the open tcp and udp ports
        for open_p in x.xpath(path_to_ports):
            openports = open_p.attrib.values()
            # join the tcp ports into one string
            if openports[0] == 'tcp':
                tcpports = tcpports + "".join(openports[1]) + ", "
            # join the udp ports into one string
            if openports[0] == 'udp':
                udpports = udpports + "".join(openports[1]) + ", "
        # strip out the trailing commas
        tcpports = tcpports.strip(", ")
        udpports = udpports.strip(", ")
        # write the tcp ports to the spreadsheet
        sheet1.write(row, TCP_COLUMN, tcpports)
        # resize column if the tcp ports string is larger than previous value
        if (len(tcpports) > tcp_column_size):
            tcp_column_size = len(tcpports)
        # write the udp ports to the spreadsheet
        sheet1.write(row, UDP_COLUMN, udpports)
        # resize column if the udp ports string is larger than previous value 
        if (len(udpports) > udp_column_size):
            udp_column_size = len(udpports)

    # calculate column size based on (string length * FONTSIZE)
    target_column_size = calculate_column_size(target_column_size) 
    os_column_size = calculate_column_size(os_column_size)
    tcp_column_size = calculate_column_size(tcp_column_size)
    udp_column_size = calculate_column_size(udp_column_size)
    
    # adjust the size of the columns
    sheet1.col(0).width = target_column_size
    sheet1.col(1).width = os_column_size
    sheet1.col(2).width = tcp_column_size
    sheet1.col(3).width = udp_column_size
    # save the xls file
    book.save(xls_name)

def make_xls_name(file_name):
    # creates a xls filename based on the xml inputs filename
    return file_name.replace('.xml','.xls')

def calculate_column_size(column_size):
    # calculates column size based on (string length * FONTSIZE)
    # The max value is 65535
    column_size = column_size * FONTSIZE
    if (column_size > 65534):
        return 65534
    else:
        return column_size

def parse_opts():
	parser = OptionParser()
	parser.add_option("-f", "--file-name", action="store", dest="file_name", help = "the filename of the nmap scan")
	(options, args) = parser.parse_args()
	if options.file_name is None:
		print "you MUST enter a file name, see -h"
		exit(1)
	return options.file_name

if __name__ == "__main__":
	main(parse_opts() )
