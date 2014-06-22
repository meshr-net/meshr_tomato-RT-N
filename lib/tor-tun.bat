rem setting up tunnel to tor proxy
cd %~dp0..
set meshr=%CD:\=/%
set PATH=%PATH%;%meshr:/=\%\bin
set torIP=
rem wait for Internet from olsrd HNA->DefaultIPGateway (or dhcp)
sleep 15
if not exist %meshr:/=\%\var\etc\olsrd.conf goto :try_gateway
echo /status | nc 127.0.0.1 9090 > %meshr%/tmp/olsrd.status || goto :try_gateway
rem wait for peer HNA
type %meshr:/=\%\tmp\olsrd.status | find "destination"": ""10.177." || ( sleep 15 && echo /status | nc 127.0.0.1 9090 > %meshr%/tmp/olsrd.status ) 
type %meshr:/=\%\tmp\olsrd.status | find "destination"": ""10.177." || ( sleep 15 && echo /status | nc 127.0.0.1 9090 > %meshr%/tmp/olsrd.status ) 
type %meshr:/=\%\tmp\olsrd.status | find "destination"": ""10.177." || ( sleep 15 && echo /status | nc 127.0.0.1 9090 > %meshr%/tmp/olsrd.status ) 
for /f "tokens=2 delims=:," %%f in ('type %meshr:/=\%\tmp\olsrd.status ^| find "destination"": ""10.177."') do ( nc -z %%f 9150 && set torIP=%%f && goto :break )
for /f "tokens=2 delims=:," %%f in ('type %meshr:/=\%\tmp\olsrd.status ^| find "remoteIP"": ""10.177."') do ( nc -z %%f 9150 && set torIP=%%f && goto :break )
:break
for /f "tokens=2 delims=:, " %%f in ('type %meshr:/=\%\tmp\olsrd.status ^| find "ipv4Address"": ""10.177."') do set IPAddress=%%f
if defined torIP set torIP=%torIP:"=%
if defined torIP set torIP=%torIP: =%
echo -"%torIP%" | find "." && ( curl -m 20 --proxy socks5h://%torIP%:9150 http://208.91.199.147 -o NUL && goto :torok )
:try_gateway
wmic nicconfig where SettingID="{%guid%}" get DefaultIPGateway,DHCPServer /value | sed "s/[""{}]//g" | find "10.177." >> %meshr:/=\%\tmp\wifi.txt
for /f "tokens=*" %%f in ('type %meshr:/=\%\tmp\wifi.txt ^| find "DefaultIPGateway=" ') do set "%%f"
(echo %DefaultIPGateway% | find "10.177." ) || goto try_dhcp
set torIP=%DefaultIPGateway%
echo -"%torIP%" | find "." && goto :torok
:try_dhcp
for /f "tokens=*" %%f in ('type %meshr:/=\%\tmp\wifi.txt ^| find "DHCPServer=" ') do set "%%f"
(echo %DHCPServer% | find "10.177." ) || goto try_loc
set torIP=%DHCPServer%
:try_loc
if not defined torIP set torIP=127.0.0.1
:torok
type %~dp0\..\tmp\tap.int | find "=" || wmic nic where "Name like 'TAP-Win%%'" get NetConnectionID /value | find "=" > %~dp0\..\tmp\tap.int
for /f "tokens=*" %%f in ('type  "%~dp0\..\tmp\tap.int"') do set "%%f"
set NetConnectionID=%NetConnectionID:~0,-1%
echo %NetConnectionID%-
ipconfig | find "%NetConnectionID%" || wmic path win32_networkadapter where NetConnectionID="%NetConnectionID%" call enable
netsh interface ip set address "%NetConnectionID%" static 10.177.254.1 255.255.255.0 
netsh interface ip set dns "%NetConnectionID%" dhcp
(echo %DefaultIPGateway% | find "10.177." ) || set DefaultIPGateway=%torIP%
if not "%torIP%"=="127.0.0.1" ( 
  start cmd /c "%meshr:/=\%\bin\sleep 5 && %meshr:/=\%\lib\DNS2SOCKS.bat %torIP% "%NetConnectionID%" "%IPAddress%" %DefaultIPGateway%"
  badvpn-tun2socks --tundev "tap0901:%NetConnectionID%:10.177.254.1:10.177.254.0:255.255.255.0" --netif-ipaddr 10.177.254.2 --netif-netmask 255.255.255.0 --socks-server-addr %torIP%:9150
  exit
  rem if TODO BTap_Init failed then enable interface
)
