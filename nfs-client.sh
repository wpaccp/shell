#!/bin/bash
#################################
##this scripts create by wpaccp
##wpaccp QQ:286937899
#################################
#[ -f /etc/init.d/functions ] && . /etc/init.d/functions
IP=10.0.10.2
PORT=111
if [ `lsof -i :${PORT}|wc -l` -eq 3 ]; then
  #action "rpcbind start" /bin/true
  echo "rcpbind start" 
else
  yum install -y rpcbind >/dev/null 2>&1 
fi 
lsof -i :${PORT} >/dev/null 2>&1
[ $? -eq 0 ] || /etc/init.d/rpcbind start
[ `grep "rpcbind" /etc/rc.local | wc -l` -eq 0 ] && echo "/etc/init.d/rpcbind start" >>/etc/rc.local
[ `mount | grep /data/nfsdata | wc -l` -eq 0 ] && mount -t nfs ${IP}:/data/nfsdata /mnt  
