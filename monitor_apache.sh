#!/bin/bash
   SERVICE="httpd"
   STATUS=$(systemctl is-active $SERVICE)
   DATE=$(date '+%Y-%m-%d %H:%M:%S')
   DIR="/mnt/nfs_share/thiagobarbosa"

   if [ "$STATUS" = "active" ]; then
     echo "$DATE - $SERVICE - ONLINE - Serviço está funcionando" > $DIR/apache_online.txt
   else
     echo "$DATE - $SERVICE - OFFLINE - Serviço está fora do ar" > $DIR/apache_offline.txt
   fi
