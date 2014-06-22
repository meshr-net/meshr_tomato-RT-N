#!/bin/sh
#set -x
cd `dirname $0`
[ -z $meshr ] && meshr=`pwd`

if [ `whoami` != 'root' ];then
  sudo $0 $@ && exit
fi

P=`pwd`
export LD_LIBRARY_PATH="$P/usr/lib:$LD_LIBRARY_PATH"
PATH="$P/bin:$P/usr/bin:$PATH"
export LUA_PATH="$P/usr/lib/lua/?.lua;$P/usr/lib/lua/?/init.lua;;"
export LUA_CPATH="$P/usr/lib/lua/?.so;;"
export LUCI_SYSROOT="$P"
export meshr="$P"

#firewall
./bin/lua $P/lucid.lua --splash