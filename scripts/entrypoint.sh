#!/bin/bash
rm -f /etc/sysconfig/iptables

if [[ -x /root/initial.sh ]] ; then 
  /root/initial.sh
  chmod -x /root/initial.sh
fi

systemctl restart iptables
systemctl restart nginx
systemctl restart php-fpm
systemctl restart mariadb

/bin/bash
