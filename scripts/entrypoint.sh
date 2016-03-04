#!/bin/bash
if [[ -x /root/initial.sh ]] ; then 
  /root/initial.sh
fi

systemctl restart nginx
systemctl restart php-fpm
systemctl restart mariadb

/bin/bash
