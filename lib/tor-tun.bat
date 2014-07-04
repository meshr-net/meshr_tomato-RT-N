# setting up tunnel to tor proxy
set -x
modprobe tun || insmod $meshr/lib/modules/2.6.22.19/tun.ko
torIP=
# wait for Internet from olsrd HNA->DefaultIPGateway (or dhcp)
sleep 10
[ -f $meshr/var/etc/olsrd.conf ] && {
  echo /status | nc 127.0.0.1 9090 > $meshr/tmp/olsrd.status && {
   # wait for peer HNA
    grep "destination\": \"10.177." $meshr/tmp/olsrd.status || ( sleep 15 && echo /status | nc 127.0.0.1 9090 > $meshr/tmp/olsrd.status )
    grep "destination\": \"10.177." $meshr/tmp/olsrd.status || ( sleep 15 && echo /status | nc 127.0.0.1 9090 > $meshr/tmp/olsrd.status )
    f=`grep "destination\": \"10.177." $meshr/tmp/olsrd.status | sed "s/.*\(10.177.[^\"]*\).*/\1/g"` && nc -z $f 9150 && torIP=$f
    [ -z $torIP ] && f=`grep "destination\": \"10.177." $meshr/tmp/olsrd.status | sed "s/.*\(10.177.[^\"]*\).*/\1/g"` && nc -z $f 9150 && torIP=$f
    f=`grep "ipv4Address\": \"10.177." $meshr/tmp/olsrd.status | sed "s/.*\(10.177.[^\"]*\).*/\1/g"` && IPAddress=$f
    echo -"$torIP" | grep "." && ( curl -m 20 --proxy socks5h://$torIP:9150 http://74.125.224.72 -o /dev/null || {
      echo "DefaultIPGateway=$(ip route | grep $guid | awk '/default/ { print $3 }')" >> $meshr/tmp/wifi.txt
      . $meshr/tmp/wifi.txt
      echo -"$torIP" | grep "." && torIP=$DefaultIPGateway
      [ -z "$torIP" ] && torIP=127.0.0.1
    })
  }
}

[ ! "$torIP"=="127.0.0.1" ] && ( 
  #ip tunnel add tun2meshr mode ipip
  tun=tun2meshr
  ipconfig | grep "$NetConnectionID" || wmic path win32_networkadapter where NetConnectionID="$NetConnectionID" call enable
  netsh interface ip address "$NetConnectionID" static 10.177.254.1 255.255.255.0 
  netsh interface ip dns "$NetConnectionID" dhcp
  (echo $DefaultIPGateway | grep "10.177." ) || DefaultIPGateway=$torIP
  ( $meshr/bin/sleep 5 && $meshr/lib/DNS2SOCKS.bat $torIP "$tun" $IPAddress )&
  start-stop-daemon start badvpn-tun2socks --tundev $tun --netif-ipaddr 10.177.254.2 --netif-netmask 255.255.255.0 --socks-server-addr $torIP:9150
)
