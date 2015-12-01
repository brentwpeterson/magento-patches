#!/bin/bash
vmstat 1 10 >sa_output.txt
mysql -e "show global status" >>sa_output.txt
mysql -e "show global variables" >>sa_output.txt
netstat -nap >>sa_output.txt
iostat -dx >>sa_output.txt
dmesg >>sa_output.txt
free -mo >>sa_output.txt
uptime >>sa_output.txt
crontab -l >>sa_output.txt
php -v >>sa_output.txt
php -m >>sa_output.txt
php -i >>sa_output.txt
ls -latr app app/etc var >>sa_output.txt