#!/bin/bash
#
##################################################################
#   The postfix mail software installation steps was written 
#   by Paul peng wang                
#   QQ:286937899
#   github:http://wpaccp@github.com
##################################################################
[ -e /etc/rc.d/init.d/functions ] && . /etc/rc.d/init.d/functions
install_dir="/application"
cmake="/usr/local/cmake"
mysql="/usr/local/mysql"
datadir="/mydata/data"
cmakeurl="http://www.cmake.org/files/v2.8/cmake-2.8.10.2.tar.gz"
mysqlurl="http://cdn.mysql.com/archives/mysql-5.5/mysql-5.5.28.tar.gz"
function install_epel() {
  rpm -qa | grep epel >/dev/null 2>&1
  [ $? -ne 0 ] && rpm -ivh ~/postfix/files/epel-release-6-8.noarch.rpm
  yum repolist >/dev/null 2>&1 
  [ $? -eq 0 ] && action "epel was installed" /bin/true || exit 1
  for i in httpd mysql mysql-server mysql-devel openssl-devel dovecot perl-DBD-MySQL tcl tcl-devel libart_lgpl libart_lgpl-devel libtool-ltdl libtool-ltdl-devel expect cyrus* db*-devel; do
    rpm -qa | grep $i
    if [ $? -ne 0 ]; then
      ping -c 1 114.114.114.114
      [ $? -eq 0 ] && yum install -y $i || exit 2
    else
      echo "$i was installed"   
     fi
   done 
  [ `ps -C sendmail --no-heading | wc -l` -ne 0 ] && pkill sendmail || echo "sendmail service not running"
  [ `chkconfig --list sendmail | wc -l` -ne 0 ] && chkconfig sendmail off || echo "chkconfig sendmail not close"
  if [ `yum grouplist Development Tools | wc -l` -ne 0 -a `yum grouplist Platform Server | wc -l` -ne 0 ]; then
    yum groupinstall -y "Development Tools" "Platform Server"
    [ $? -eq 0 ] || echo "the packet install success" || echo "the packet install failure"
  else
      echo "the packet was exists"  
  fi 
}
function install_cmake(){
  sleep 5
  [ -d $cmake ]||mkdir $cmake
  cd $install_dir
  [ -e $install_dir/cmake-2.8.10.2.tar.gz ] || {
    wget --no-check-certificate $cmakeurl
  } 
  tar xf cmake-2.8.10.2.tar.gz
  cd cmake-2.8.10.2
  ./configure --prefix=$cmake 
  make 
  make install
  sleep 10
  if [ ! -e /etc/profile.d/cmake.sh ]; then
    touch /etc/profile.d/cmake.sh
    echo "export PATH=$PATH:/usr/local/cmake/bin" > /etc/profile.d/cmake.sh
    sleep 5
    . /etc/profile.d/cmake.sh
  else
    echo "export PATH=$PATH:/usr/local/cmake/bin" > /etc/profile.d/cmake.sh
    sleep 5
    . /etc/profile.d/cmake.sh
 fi
}
function install_mysql()
{
  [ -d $mysql ] || mkdir $mysql
  id mysql &>/dev/null
  if [ $? -ne 0 ]; then
    groupadd -g 501 mysql
    useradd -g 501 -u 501 -s /sbin/nologin -M mysql
  fi 
  if [ ! -e $datadir ]; then 
    mkdir -pv $datadir
    chown -R mysql.mysql $datadir
  fi
  cd $install_dir
  [ -e $install_dir/mysql-5.5.28.tar.gz ] || {
    wget $mysqlurl 
  }
  tar xf mysql-5.5.28.tar.gz 
  cd mysql-5.5.28 
  /usr/local/cmake/bin/cmake -DCMAKE_INSTALL_PREFIX=$mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=$datadir -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306 
  make 
  make install
  sleep 10
 if [ ! -e /etc/profile.d/mysql.sh ]; then
   touch /etc/profile.d/mysql.sh
   echo "export PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
   sleep 5
   . /etc/profile.d/mysql.sh &> /dev/null
 else
   echo "export PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
   sleep 5
   . /etc/profile.d/mysql.sh &> /dev/null
 fi
  chown -R mysql.mysql $mysql
  chown -R mysql.mysql $datadir
}
function init_mysql(){
  [ -e /etc/my.cnf ] && rm -rf /etc/my.cnf
  cp ~/postfix/templates/my.cnf /etc/my.cnf
  [ -e /etc/init.d/mysqld ] && rm -rf /etc/init.d/mysqld
  cp $mysql/support-files/mysql.server /etc/init.d/mysqld
  cd $mysql
  scripts/mysql_install_db --user=mysql --datadir=$datadir &> /dev/null
  chown mysql.mysql $datadir/*
  [ `ps -C mysqld --no-heading | wc -l` -eq 0 ] && service mysqld start 
  [ `chkconfig --list mysqld | wc -l` -eq 0 ] && chkconfig mysqld on
  [ `mysql -e "select User,Password from mysql.user where Password='wpaccp'"| wc -l` -eq 0 ] && mysqladmin -uroot password 'wpaccp'
}
function install_postfix() {
  [ `ps -C saslauthd --no-heading | wc -l` -eq 0 ] && service saslauthd start 
  [ `chkconfig --list saslauthd | wc -l` -eq 0 ] && chkconfig saslauthd on
  id postfix >/dev/null 2>&1
  [ $? -eq 0 ] || {
  groupadd -g 2525 postfix
  useradd -g postfix -u 2525 -s /sbin/nologin -M postfix
  }
  id postdrop>/dev/null 2>&1 || {
  groupadd -g 2526 postdrop
  useradd -g postdrop -u 2526 -s /sbin/nologin -M postdrop
  }
  /usr/local/mysql/lib/|grep libmysqlclient.so.18
  echo "/usr/local/mysql/lib" >>/etc/ld.so.conf
  ldconfig 
  [ -e $install_dir/postfix-2.10.0.tar.gz ] || cp -pvr ~/postfix/files/postfix-2.10.0.tar.gz $install_dir
  cd $install_dir
  tar xf postfix-2.10.0.tar.gz
  cd postfix-2.10.0
  make makefiles 'CCARGS=-DHAS_MYSQL -I/usr/local/mysql/include -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl  -DUSE_TLS ' 'AUXLIBS=-L/usr/local/mysql/lib -lmysqlclient -lz -lm -L/usr/lib/sasl2 -lsasl2  -lssl -lcrypto'
  sed -i 's@#\(myhostname =\) .*@\1 node1.wp.com@g'/etc/postfix/main.cf
  sed -i 's@#\(myorigin =\) .*@\1 wp.com@g' /etc/postfix/main.cf
  sed -i 's@#\(mydomain =\) .*@\1 wp.com@g' /etc/postfix/main.cf
  sed -i 's@#\(mydestination =\) .*@\1 $myhostname, localhost.$mydomain, localhost, $mydomain@g' /etc/postfix/main.cf
  sed -i 's@#\(mynetworks =\) .*@\1 192.168.100.0/24, 127.0.0.0/8@g' /etc/postfix/main.cf
  [ -e /etc/rc.d/init.d/postfix ] || { 
  cp -pvr ~/postfix/templates/postfix /etc/rc.d/init.d/postfix 
  }
  [ -x /etc/rc.d/init.d/postfix ] || chmod +x /etc/rc.d/init.d/postfix 
  [ `chkconfig --list postfix | wc -l` -eq 0 ] && {
   	chkconfig --add postfix 
   	chkconfig postfix on 
  }	  
  [ `ps -C postfix --no-heading | wc -l` -eq 0 ] && service postfix start  
}
function Main() {
  #install_epel
  #install_cmake
  #install_mysql
  #init_mysql
  install_postfix
}
Main
 
