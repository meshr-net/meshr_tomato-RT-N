rem Save old serivces for Uninstall compatibility !
if not "%3"=="conn" %~dp0\start-stop-daemon.exe %1 meshr %2 
if not "%3"=="update" if not "%3"=="conn" %~dp0\start-stop-daemon.exe %1 meshr-watchdog %2 
%~dp0\start-stop-daemon.exe %1 olsrd %2
%~dp0\start-stop-daemon.exe %1 meshr-splash %2
set bin=%~dp0
set bin=%bin:\=\\%
if "%1"=="stop" if exist c:\olsrd-ipv4.lock del c:\olsrd-ipv4.lock
if "%1"=="stop" for %%E in (%bin%tor %bin%DualServer %bin%DNS2SOCKS %bin%badvpn-tun2socks) do wmic process where ExecutablePath='%%E.exe' delete
if "%1"=="stop" if not "%3"=="conn" for %%E in (%bin%git %bin%sh %bin%lua %bin%lua %bin%uci %bin%sleep %bin%start-stop-daemon) do wmic process where ExecutablePath='%%E.exe' delete

if "%3"=="conn" (
  if not exist %meshr:/=\%\var\run\wifi.txt echo DHCPEnabled=TRUE>%meshr:/=\%\var\run\wifi.txt
  call %meshr:/=\%\lib\setip.bat "%meshr:/=\%\var\run\wifi.txt" > %TEMP%\setip%random%.log
  copy /y %meshr:/=\%\var\run\wifi.txt %meshr:/=\%\var\run\wifi2.txt
  chmod 777 %meshr:/=\%\var\run\wifi.txt
  del %meshr:/=\%\var\run\wifi.txt %meshr:/=\%\var\run\wifi-formed.txt
)
  