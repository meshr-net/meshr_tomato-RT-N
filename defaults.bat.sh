rem check admin rights
net session >nul 2>&1 || ( 
  %~dp0\bin\sudo /b /c %0 %*
  goto :EOF
)
if not "%1"=="" cd "%1" && SET meshr=
if "%meshr%"=="" SET meshr=%CD:\=/%&& %CD:\=/%/bin/SETX meshr %CD:\=/%
echo Waiting for established meshr Internet 
IF NOT EXIST %meshr:/=\%\tmp\wlan.log %meshr:/=\%\bin\sleep 3
call :isonline
call %meshr%/lib/upload.bat getip > %~dp0\tmp\upload.log
%meshr:/=\%\bin\start-stop-daemon.exe stop meshr
%meshr:/=\%\bin\bash -c "export meshr=%meshr%; export PATH=/${meshr/:/}/bin:$PATH; %meshr%/lib/defaults.sh"
%meshr:/=\%\bin\start-stop-daemon.exe start meshr
call :isonline
%meshr:/=\%\bin\sleep 2
rem TODO: uci get lucid.http.address
start ""  "http://127.0.0.1:8084/luci/admin/freifunk/basics/"
echo Press any key ...
pause
GOTO:EOF

:isonline
IF NOT EXIST %meshr:/=\%\var\run\wifi.txt %meshr:/=\%\bin\sleep 9
type %meshr:/=\%\tmp\wlan.log | find "connected to " || %meshr:/=\%\bin\sleep 9
type %meshr:/=\%\tmp\wlan.log | find "connected to meshr.net " || goto :ok
for /l %%i in (1,1,30) do ( %meshr:/=\%\bin\curl http://74.125.224.72 -o NUL -m 10 && goto :ok || %meshr:/=\%\bin\sleep 5 )
:ok
