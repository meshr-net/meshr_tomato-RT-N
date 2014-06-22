cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`
set -x

. $meshr/etc/wifi.txt
. $1

[ -z "$IPAddress" ] && [ "$1"== "$meshr/var/run/wifi.txt" ] && {
  ifconfig eth1 0.0.0.0 up
  # + sed /etc/resolv.conf
  exit
}

[ -n "$IPAddress" ] && ifconfig $guid $IPAddress netmask $IPSubnet up && {
  kill -9 `cat $meshr/var/run/dnsmasq.pid`
  dnsmasq --conf-file=$meshr/etc/dnsmasq.conf > tmp/dnsmasq.log 2>&1 || {
    old=`ps | grep -m 1 "dnsmasq" | sed "s/^.* dnsmasq /dnsmasq /g"`
    # failed to bind DHCP server socket: Address already in use
    [ -f /tmp/etc/dnsmasq.conf ] && { grep "bind-dynamic" /tmp/etc/dnsmasq.conf || echo bind-dynamic>>/tmp/etc/dnsmasq.conf }
    killall dnsmasq && dnsmasq --conf-file=$meshr/etc/dnsmasq.conf
    $old
  }
}

echo $DNSServerSearchOrder | grep "." && echo nameserver $DNSServerSearchOrder >>  /etc/resolv.conf
[ -z "$IPAddress" ] && {
  ifconfig $guid 0.0.0.0 up
  udhcpc -q -n -i $guid -s $meshr/usr/sbin/udhcpc.script
}
[ "$1" == "$meshr/etc/wlan/meshr.net.txt" ] || exit

# test if offline
( curl http://74.125.224.72 -o NUL -m 10 || ( curl http://74.125.224.72 -o NUL -m 10 ) ) && {
  [ -z "$IPAddress" ] && { 
    ./lib/upload.bat
    ifconfig $guid $IPAddress netmask $IPSubnet up
  }
  [ -n "$IPAddress" ] && grep "$IPAddress" $meshr/var/etc/olsrd.conf | grep "255.255.255.255"  || {
    sed -i "s/.*10.177.\+255.255.255.255.*//g" $meshr/var/etc/olsrd.conf
    echo Hna4 { $IPAddress 255.255.255.255 } >> $meshr/var/etc/olsrd.conf
  }
  [ -f $meshr/var/etc/olsrd.conf ] && nohup $meshr/usr/sbin/olsrd -f $meshr/var/etc/olsrd.conf &
  online=1
  exit
}
online=
[ ! -f $meshr/var/etc/olsrd.conf ] && exit
grep "$IPAddress" $meshr/var/etc/olsrd.conf | grep "255.255.255.255" && sed -i "s/.*10.177./+255.255.255.255.*//g" $meshr/var/etc/olsrd.conf
nohup $meshr/usr/sbin/olsrd -f $meshr/var/etc/olsrd.conf &
