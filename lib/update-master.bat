rem <<BATFILE
cd %~dp0..
update.bat master
goto :EOF
BATFILE

cd `dirname $0`/..
./update.bat master