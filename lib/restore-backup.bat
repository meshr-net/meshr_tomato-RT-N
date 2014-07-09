rem <<BATFILE
for /f "tokens=*" %%a in ('dir /b /od %~dp0..\tmp\b*.tar ^| find "backup_"') do set newest=%%a
cd %~dp0..
if exist bin\tar.exe ( bin\tar.exe xf tmp/%newest%  -C . --ignore-failed-read  --ignore-command-error ) else ( %meshr:/=\%\bin\tar.exe xvf tmp/%newest%  -C . --ignore-failed-read  --ignore-command-error )
goto :EOF
BATFILE
set -x
cd `dirname $0`/..
newest=`ls -alt ./tmp/backup_* | grep "backup_" | sed "s/.*backup_/backup_/g" | grep -m 1 .`
tar xf ./tmp/$newest  -C . --ignore-failed-read  --ignore-command-error || tar xf ./tmp/$newest  -C . || tar xzf ./tmp/$newest  -C . 