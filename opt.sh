#!/bin/bash
#########################################
#this scripts is create by wpaccp
#wpaccp QQ:286937899
#########################################
#set env
export PATH=$PATH:/bin:/sbin:/usr/sbin
export LANG="zh_CN.GB18030"

#Require root to run this script.
if [[ "$(whoami)" != "root" ]]; then
  echo "please run this script as root.">&2
  exit 1
fi
#define cmd var
SERVICE=`which service`
CHKCONFIG=`which chkconfig`
#source function library
. /etc/init.d/functions

#Config Yum CentOS-Base.repo
ConfigYum(){
  echo "Config Yum CentOS-Base.repo"
  cd /etc/yum.repos.d/
  [ -e CentOS-Base.repo.backup ] || mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
  ping -c 1 baidu.com >/dev/null
  [ $? -ne 0 ] && echo "Networking not configured - exiting" && exit 1
  [ -e Centos-6.repo ] || wget -o /dev/null http://mirrors.aliyun.com/repo/Centos-6.repo
  \cp Centos-6.repo CentOS-Base.repo
  yum repolist >/dev/null 2>&1
  [ $? -eq 0 ] && action "aliyun yum configure" /bin/true || action "aliyun yum configure" /bin/false

}
installTool(){
  echo "# install sysstat,snmp,lrzsz"
  for soft in install sysstat net-snmp lrzsz rsync; do
    rpm -qa | grep $soft >/dev/null 2>&1  
    [ $? -eq 0 ] && yum -y $soft >/dev/null 2>&1
  done
  [ $? -eq 0 ] && action "install sysstat,snmp,lrzsz.." /bin/true || action "install sysstat,snmp,lrzsz.." /bin/false 
}
initl18n(){
  echo "#------------LANG=zh_CN.GB18030-----------------"
  cp /etc/sysconfig/i18n /etc/sysconfig/i18n.`date +"%Y-%m-%d_%H-%S"`
  [ `grep "en_US.UTF-8" /etc/sysconfig/i18n | wc -l` -eq 1 ] && sed -i 's#LANG="en_US.UTF-8"#LANG="zh_CN.GB18030"#' /etc/sysconfig/i18n
  source /etc/sysconfig/i18n
  [ `grep "zh_CN.GB18030" /etc/sysconfig/i18n | wc -l` -eq 1 ] && action "LANG=zh_CN.GB18030 configure" /bin/true || action "LANG=zh_CN.GB18030 configure" /bin/false
} 
initFirewall(){
  echo "#---close selinux and iptables-----------------------#"
  cp /etc/selinux/config /etc/selinux/config.`date "+%Y-%m-%d_%H-%M-%S"`
  #/etc/init.d/iptables stop
  [ `grep "SELINUX=enforcing" /etc/selinux/config | wc -l` -eq 1 ] && sed -i 's/SELINUX= .*/SELINUX=disable/' /etc/selinux/config
  setenforce 0
 [ `grep "SELINUX=disable" /etc/selinux/config | wc -l` -eq 1 ] && action "close selinux->OK" /bin/true || action "close selinux->OK" /bin/false
  sleep 1
 }
#lnit Auto Startup Service 
initService(){
  echo "#--close nouseful service---------#"
  export LANG="en_US.UTF-8"
  for oldboy in `chkconfig --list|grep 3:on|awk '{print $1}'`; do 
    chkconfig --level 3 $oldboy off
  done
  for oldboy in crond network rsyslog sshd; do 
    chkconfig --level 3 $oldboy on
  done
  export LANG="zh_CN.GB18030"
  action "close nouseful service->OK" /bin/true
 }
initSsh(){
  echo #-----------------sshConfig------------------------------------#
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config_`date "+%Y-%m-%d_%H-%M-%S"`
  if [ `egrep "UseDNS|22|PermitRootLogin|PermitEmptyPasswords" /etc/ssh/sshd_config |grep -v setting |wc -l` -eq 4 ]; then
    sed -i 's%PORT 22%PORT 52113%' /etc/ssh/sshd_config
    sed -i 's%#PermitRootLogin yes%PermitRootLogin no%' /etc/ssh/sshd_config
    sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%' /etc/ssh/sshd_config
    sed -i 's%#UseDNS yes%UseDNS no%' /etc/ssh/sshd_config
  fi
  egrep "UseDNS|52113|RootLogin|EmptyPass" /etc/ssh/sshd_config
  /etc/init.d/sshd reload && action "alt SSH default login port,stop root login:" /bin/true || action "alt SSH default login port,stop root login:" /bin/false
}
addSAUser(){
  echo "#-------------add system user------------------------"
  date1=`date +"%Y-%m-%d_%H-%M-%S"`
  cp /etc/sudoers /etc/sudoers_$date1
  saUserArr=(oldboy1 oldboy2 oldboy3)
  groupadd -g 833 sa
  for ((i=0;i<${#saUserArr[@]};i++)); do
    useradd -g sa -u 83${i} ${saUserArr[$i]}
    echo "${saUserArr[$i]}"|passwd ${saUserArr[$i]} --stdin
    [ `grep "${saUserArr[$i]} ALL=(ALL) NOPASSWD:ALL" /etc/sudoers|wc -l` -eq 0 ] && echo "${saUserArr[$i]} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
  done
  [ `grep "\%sa" /etc/sudoers|grep -v grep|wc -l` -eq 0 ] && echo "%sa      ALL=(ALL)      NOPASSWD:ALL" >>/etc/sudoers || echo "The user group has been in existence"
  /usr/sbin/visudo -c
  [ $? -ne 0 ] && /bin/cp /etc/sudoers.$(date1) /etc/sudoers
  action "user add success-->ok" /bin/true 
}
syncSystemTime(){
 echo "configure system sync time"
 [ `grep 'ntpdate' /var/spool/cron/root | wc -l` -eq 0 ] && echo "*/5 * * * * /usr/sbin/ntpdate cn.pool.ntp.org" >>/var/spool/cron/root
  
}
openFiles(){
  echo "----------------------openFiles() start-------------"
  cp /etc/security/limits.conf /etc/security/limits.conf_`date +"%Y-%m-%d_%H-%M-%S"`
  [ `grep '\t65535' /etc/security/limits.conf | wc -l` -eq 0 ] && sed -i "/# End of file/i\*\t\t-\tnofile\t\t65535" /etc/security/limits.conf
  ulimit -HSn 65535
  [ `grep '65535' /etc/rc.local | wc -l` -eq 0 ] && echo "ulimit -HSn 65535" >>/etc/rc.local
  sleep 1
}
optimizationKernel(){
  echo "optimizationKernel start--->"
  cp /etc/sysctl.conf /etc/sysctl.conf.`date "+%Y-%m-%d_%H-%M-%S"`
if [ `cat /etc/sysctl.conf | egrep "ipv4|core" | wc -l` -eq 6 ]; then
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 87380 16777216
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 1 
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
EOF
fi
/sbin/sysctl -p >/dev/null 2>&1 
[ $? -eq 0 ] && action "optimizationKernel:" /bin/true || action "optimizationKernel:" /bin/false  
}
init_safe(){
  echo "--------------------stop "ctl-alt-del" three keys to restart system---------------"
  cp /etc/init/control-alt-delete.conf  /etc/init/control-alt-delete.conf_`date +"%Y-%m-%d_%H-%M-%S"`
 [ `grep "Control-Alt-Delete pressed" /etc/init/control-alt-delete.conf | wc -l` -eq 1 ] && sed -i 's%exec /sbin/shutdown -r now "Control-Alt-Delete pressed"%exec /usr/bin/logger -p authpriv.notice -t init "Ctrl-Alt-Del was pressed and ignored"%' /etc/init/control-alt-delete.conf
 [ $? -eq 0 ] && action "stop "ctl-alt-del" three keys to restart system:" /bin/true || action "stop "ctl-alt-del" three keys to restart system:" /bin/false
}
init_snmp(){
  echo "---------------------------init SNMPD-----------------------"
  cp /etc/snmp/snmpd.conf /etc/snmp/snmp.conf_`date +"%Y-%m-%d_%H-%M-%S"`
  if [ `egrep "#view all|#access MyROGroup" /etc/snmp/snmpd.conf | wc -l` -eq 2 ]; then 
  sed -i 's/#view all/view all/' /etc/snmp/snmpd.conf
  sed -i 's/#access MyROGroup/access MyROGroup/' /etc/snmp/snmpd.conf
  fi
  ${CHKCONFIG} snmpd on
  ${SERVICE} snmpd start
  [ $? -eq 0 ] && action "init snmpd:" /bin/true || action "init snmpd:" /bin/false
}
disableIPV6(){
  echo "--------------------------stop user IPV6------------------------"
  cp /etc/modprobe.conf /etc/modprobe.conf_`date +"%Y-%m-%d_%H-%M-%S"`
  if [ `egrep "net-pf-10|ipv6" /etc/modprobe.conf | wc -l` -eq 0 ]; then
   echo "alias net-pf-10 off" >>/etc/modprobe.conf
   echo "alias ipv6 off" >>/etc/modprobe.conf
  fi
}
echo "system optimization configure OK"
ConfigYum
initl18n
initFirewall
initService
initSsh
addSAUser
syncSystemTime
openFiles
optimizationKernel
init_safe
init_snmp
disableIPV6

