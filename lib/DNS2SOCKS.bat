rem DNS2SOCKS.bat %torIP% "%NetConnectionID%" %IPAddress% %DefaultIPGateway%
cd %~dp0..
set meshr=%CD:\=/%
set PATH=%PATH%;%meshr:/=\%\bin
start DNS2SOCKS.exe /l:%meshr:/=\%\tmp\dns.log %1:9150 8.8.8.8 10.177.254.1
netsh interface ip set dns %2 static 10.177.254.1
if not "%4"=="" route delete 0.0.0.0 mask 0.0.0.0 %4
for /f "tokens=1 delims=. " %%f in ('route print ^| find "TAP-"') do route add 0.0.0.0 mask 0.0.0.0 10.177.254.2 metric 2 IF %%f
for /f "tokens=*" %%f in ('type %meshr:/=\%\etc\wifi.txt') do set "%%f"
netsh interface ip set dns %NetConnectionID% static 10.177.254.1
set IPAddress=%3
rem get non random ip
( echo %IPAddress% | grep -E "10.177.(1(28|29|[3-5][0-9])|2[0-9][0-9])" || echo IP=%IPAddress% | grep -v "." ) && (
  sleep 1
  upload.bat
)
exit