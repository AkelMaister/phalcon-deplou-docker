#!/bin/bash
start() {
  mkdir -p /var/www/;
  chmod -R apache:apache /var/www/;
  if [[ $archiveurl'z' != 'z' ]] ; then 
    archive_deploy
    rm -f /usr/local/src/archive
  else 
    logger "CRITYCAL! Archiveurl not exist!"
    exit 1; 
  fi
  if [[ $dburl'z' != 'z' && $dbuser'z' != 'z' && $dbname'z' != 'z' && $dbpass'z' != 'z' ]] ; then
    mysql_deploy
    rm -f /usr/local/src/dump
  else
    logger "CRITYCAL! Not full dbdata!"
    exit 1;
  fi
  if [[ $nginxconfurl'z' != 'z' ]] ; then 
    nginx_conf_deploy
    rm -f /usr/local/src/nginx.conf
    nginx -t 2> /dev/null ; nginx_res=`echo $?`
    if [[ $nginx_res != "0" ]]; then
        mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_save
        mv /etc/nginx/nginx.conf_default /etc/nginx/nginx.conf
        logger "Warning! Nginx cant pass test with new nginx.conf file! Now default conf uses"
    fi
  else 
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_orig
    mv /root/nginx.conf_base /etc/nginx/nginx.conf
    logger "Notification! Variable nginxconfurl not exist! Used nginx.conf from repo!"
    exit 0; 
  fi
}

archive_deploy() {
  cd /usr/local/src && curl "$archiveurl" -o archive
  type=$(echo `file /usr/local/src/archive | awk '{print $2}'`)
  case $type in
              "Zip")
                unzip /usr/local/src/archive -d /var/www
              ;;
              "gzip")
                tar xzf /usr/local/src/archive -C /var/www
              ;;
              *)
                logger "Archive format is not correct"
                exit 1
              ;;
  esac
}

mysql_deploy() {
  mysql -e "create database $dbname;"
  mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuser\"@'localhost' IDENTIFIED BY \"$dbpass\";"
  mysql -e "flush privileges;"
  
  curl "$dburl" -o /usr/local/src/dump
  type=$(echo `file /usr/local/src/dump | awk '{print $2}'`)
  case $type in
              "UTF-8"|"HTML")
                mysql $dbname < /usr/local/src/dump
              ;;
              "gzip")
                zcat usr/local/src/dump > /usr/local/src/tmp
                type2=`file /usr/local/src/tmp | awk '{print $2}'`
                case $type2 in
                            "POSTX")
                              tar xf tmp --to-stdout >> /usr/local/src/tmp2
                              mysql $dbname < /usr/local/src/tmp2
                            ;;
                            "UTF-8"|"HTML")
                              mysql $dbname < /usr/local/src/tmp
                            ;;
                            *)
                              logger "Cant extract dump. Do it yourself"
                            ;;
                esac
              *)
                logger "Dump format is not correct"
                exit 1
              ;;
  esac
}

nginx_conf_deploy() {
  curl "$nginxconfurl" -o /usr/local/src/nginx.conf
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_default
  mv /usr/local/src/nginx.conf /etc/nginx/nginx.conf
}

logger() {
  logfile="/var/log/initial.log"
  echo "--------------------------" >> $logfile
  echo "Var archiveurl = $archiveurl" >> $logfile
  echo "Var dburl = $dburl" >> $logfile
  echo "Var dbuser = $dbuser" >> $logfile
  echo "Var dbname = $dbname" >> $logfile
  echo "Var dbpass = $dbpass" >> $logfile
  echo "Var nginxconfurl = $nginxconfurl" >> $logfile
  echo "Error: $1" >> $logfile
  echo "--------------------------" >> $logfile
}

start;
