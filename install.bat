#!/bin/sh
# online install: wget https://github.com/meshr-net/meshr_tomato-RT-N/raw/release/install.bat -O - | sh
# offline install: ipkg install meshr_tomato-RT-N.ipk && meshr
# ( meshrp='qq'; meshr='/opt/meshr'; [ -f $meshr/install.bat ] && $meshr/install.bat || (cd /tmp && wget https://github.com/meshr-net/meshr_tomato-RT-N/raw/release/install.bat -O - | sh))&
# check admin rights
if [ `whoami` != 'root' ];then
  sudo $0 $@ && exit
fi
set -x

nvram=1
case $1 in
setpasswd) 
  [ -n nvram ] && nvram set meshrp="$2" && nvram commit
  exit;;
checkpasswd)
  [ -n nvram ] && [ "$2" = "$(nvram get meshrp)" ] && echo "ok"
  exit;;
boot)
  iptables -I INPUT 1 -i eth1 -p tcp --dport 1979 -j ACCEPT
  iptables -I INPUT 1 -i eth1 -p udp --dport 698 -j ACCEPT
  $meshr/bin/start-stop-daemon start $meshr/lib/watchdog.bat
  exit;;
Uninstall)
  if [ -n nvram ];then
    boot=`nvram get script_fire`
    [ -n "$boot" ] && ( echo "$boot" | grep "^( meshr=" && ( 
      boot=`echo "$boot" | grep -v '^( meshr='"`
      nvram set script_fire="$boot" && nvram commit ))
  fi
  #dnsmasq
  #killall
  #[ -n $meshr ] && rm -rf $meshr
  exit;;  
configure) #run from ipkg
  meshr=`pwd`
esac

[ -n $1 ] && [ ${1:0:1} = / ] && meshr=$1
[ -z $meshr ] && [ -w /opt ] && meshr=/opt/meshr
[ -z $meshr ] && meshr=/tmp/meshr

#autostart
if [ -n nvram ];then
  boot=`nvram get script_fire`
  [ -n "$boot" ] && ( echo "$boot meshr" | grep 'meshr' || ( 
    boot=`echo -e "$boot\n( meshr='$meshr'; [ -f $meshr/install.bat ] && $meshr/install.bat boot)&"`
    nvram set script_fire="$boot" && nvram commit ))
fi
#nvram commit

export meshr
PATH="$meshr/bin:$PATH"
cd $meshr
git config http.sslCAInfo $meshr/bin/openssl/curl-ca-bundle.crt
git config user.email "user_tomato-RT-N@meshr.net"
git config user.name "`uname -n`@`uname -m`"
git remote set-url origin https://github.com/meshr-net/meshr_tomato-RT-N.git
git fetch origin
git reset --hard origin/master < /dev/null
git rm . -r --cached
git add . -f
( cd $meshr/etc/config && git ls-files | tr '\n' ' ' | xargs git update-index --assume-unchanged )

. lib/bssids.bat > tmp/bssids.log
touch -am $meshr/usr/lib/ipkg/lists/meshr
exit
./defaults.bat
./install.bat boot