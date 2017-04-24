#!/bin/bash
#################################
##this scripts create by wpaccp
##wpaccp QQ:286937899
#################################
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
MYSQL_DATA="/data"
IP="10.0.10.0/24"
PORT=65534
for soft in rpcbind nfs-utils; do
 rpm -qa $soft >/dev/null 2>&1
 [ $? -eq 0 ] || yum install -y ${soft}
done 
/etc/init.d/rpcbind start >/dev/null 2>&1
/etc/init.d/nfs start >/dev/null 2>&1
[ $? -eq 0 ] && action "nfs server start" /bin/true || action "nfs server start" /bin/false 
[ -d $MYSQL_DATA/nfsdata ] || mkdir $MYSQL_DATA/nfsdata -p
[ `grep "${MYSQL_DATA}/nfsdata" /etc/exports | wc -l` -eq 0 ] && echo "${MYSQL_DATA}/nfsdata ${IP}(rw,sync,all_squash,anonuid=${PORT},anongid=${PORT})" >>/etc/exports
if [ `grep "${MYSQL_DATA}/nfsdata" /etc/exports | wc -l` -eq 1 ]; then 
   /etc/init.d/rpcbind restart >/dev/null 2>&1
   /etc/init.d/nfs restart >/dev/null 2>&1
fi
showmount -e 127.0.0.1 >/dev/null 2>&1
if [ `egrep "rpcbind start|nfs start" /etc/rc.local | wc -l` -eq 0 ]; then
cat >>/etc/rc.local<<EOF
#nfs configure
/etc/init.d/rpcbind start
/etc/init.d/nfs start
EOF
fi
