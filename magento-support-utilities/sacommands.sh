#!/bin/bash
mysql -e "show global status" >>text.txt
mysql -e "show global variables" >>text.txt
netstat -nap >>text.txt
iostat -dx >>text.txt
dmesg >>text.txt
free -mo >>text.txt
uptime >>text.txt
php -v >>text.txt
php -m >>text.txt
php -i >>text.txt