#!/bin/sh
# online install: wget https://github.com/meshr-net/meshr_tomato-RT-N/raw/release/install.bat -O - | sh
# offline install: ipkg install meshr_tomato-RT-N.ipk && meshr
# https://github.com/meshr-net/meshr_tomato-RT-N/releases/download/latest/meshr-tomato-rt-n_mipsel.ipk.sh
# ( meshrp='qq'; meshr='/opt/meshr'; [ -f $meshr/install.bat ] && $meshr/install.bat boot || (cd /tmp && wget http://meshr.net/dl/meshr-tomato-rt-n_mipsel.ipk.sh -O m.ipk.sh && sh ./m.ipk.sh ))&

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
  $meshr/bin/start-stop-daemon start $meshr/lucid.bat
  $meshr/bin/start-stop-daemon start $meshr/lib/watchdog.bat
  exit;;
Uninstall)
  if [ -n nvram ];then
    boot=`nvram get script_fire`
    [ -n "$boot" ] && ( echo "$boot" | grep "^( meshr=" && ( 
      boot=`echo "$boot" | grep -v '^( meshr='"`
      nvram unset meshr_backup
      nvram set script_fire="$boot"
      nvram commit ))
  fi
  #dnsmasq
  #start-stop-daemon stop "" conn
  #[ -n $meshr ] && find . -mindepth 1 -delete
  exit;;  
configure) #run from ipkg
  [ -z $meshr ] && meshr=`pwd`/meshr
esac

[ -n $1 ] && [ ${1:0:1} = / ] && meshr=$1
[ -z $meshr ] && [ -w /opt ] && meshr=/opt/meshr
[ -z $meshr ] && meshr=/tmp/meshr

#autostart
if [ -n nvram ];then
  boot=`nvram get script_fire`
  [ -n "$boot" ] && ( echo "$boot" | grep 'meshr' || ( 
    boot=`echo -e "$boot\n( meshr='$meshr'; [ -f $meshr/install.bat ] && $meshr/install.bat boot || (cd /tmp && wget https://github.com/meshr-net/meshr_tomato-RT-N/releases/download/latest/meshr-tomato-rt-n_mipsel.ipk.sh -O m.ipk.sh && sh ./m.ipk.sh))&"`
    nvram set script_fire="$boot" && nvram commit ))
fi
#nvram commit

export meshr=$meshr
PATH="$meshr/bin:$PATH"
cd $meshr
chmod +x ./bin/* ./usr/sbin/*
touch -am $meshr/usr/lib/ipkg/lists/meshr
ln -f $meshr/bin/git  $meshr/bin/git-merge
git config http.sslCAInfo $meshr/bin/openssl/curl-ca-bundle.crt
git config user.email "user_tomato-RT-N@meshr.net"
git config user.name "`uname -n`@`uname -m`"
git remote set-url origin git://github.com/meshr-net/meshr_tomato-RT-N.git
git fetch origin
git reset --hard origin/master < /dev/null
git rm . -r --cached
git add . -f
git commit -m ".gitignore is now working"
( cd $meshr/etc/config && git ls-files | tr '\n' ' ' | xargs git update-index --assume-unchanged )
( cd $meshr/etc/ && git ls-files | tr '\n' ' ' | xargs git update-index --assume-unchanged )

. $meshr/lib/bssids.bat > $meshr/tmp/bssids.log 2>&1
IPAddress=`ip -o -4 addr list br0 | awk '{print $4}' | cut -d/ -f1`
uci set lucid.http.address="$IPAddress:8084"
uci commit
#try to restore configs (openssl base64 -d -A )
[ -n nvram ] && ( nvram get meshr_backup | tr ' ' '\n' | openssl enc -d -base64 | tar xzf -  -C . ) # || ./defaults.bat
./install.bat boot
exit