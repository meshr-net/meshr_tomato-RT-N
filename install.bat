#!/bin/sh
# online install: wget https://github.com/meshr-net/meshr_tomato-RT-N/raw/release/install.bat -O - | sh
# offline install: ipkg install meshr_tomato-RT-N.ipk && meshr
#set -x

[ ${1:0:1} = / ] && meshr=$1
[ -z $meshr ] && ls /opt && meshr=/opt/meshr
[ -z $meshr ] && meshr=/tmp/meshr
export meshr
PATH="$PATH:$meshr/bin"

branch=release
bundle=tmp/meshr.bundle
git bundle list-heads $bundle | grep "/master" && branch=master
git clone -b $branch $bundle meshr || ( echo "can't clone"
  tmp=meshr-$RANDOM
  git clone -b $branch $bundle $tmp
  call services.bat stop
  cp -rf meshr/etc/config $tmp/etc/config
  cp -rf $tmp/* meshr/ )
rm $bundle

git config user.email "user_tomato-RT-N@meshr.net"
git config user.name "`uname -n`@`uname -m`"
git remote set-url origin https://github.com/meshr-net/meshr_tomato-RT-N.git
git rm . -r --cached && git add . 
cd $meshr/etc/config
git ls-files | tr '\n' ' ' | xargs git update-index --assume-unchanged 
cd $meshr
git fetch origin
git reset --hard origin/$branch

. lib\bssids.bat > tmp\bssids.log
touch -am $meshr/usr/lib/ipkg/lists/meshr
