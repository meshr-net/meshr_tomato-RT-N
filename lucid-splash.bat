rem <<BATFILE
SET meshr=%~dp0
set meshr=%meshr:~0,-1%

set LD_LIBRARY_PATH="%meshr%\usr\lib:$LD_LIBRARY_PATH"
set PATH=%meshr%\bin;%meshr%\usr\bin;%meshr%;%PATH%
set LUA_PATH="%meshr%\usr\lib\lua\?.lua;%meshr%\usr\lib\lua\?\init.lua;;"
set LUA_CPATH="%meshr%\usr\lib\lua\?.so;;"
set LUCI_SYSROOT="%meshr%"
SET meshr=%meshr:\=/%
rem TODO: sudo start-stop-daemon.exe stop MsDepSvc
:loop
"%meshr%/bin/lua.exe" %meshr%/lucid.lua --splash
goto :loop
goto :EOF
BATFILE
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