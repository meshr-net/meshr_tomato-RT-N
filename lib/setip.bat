cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`
set -x

. $meshr/etc/wifi.txt
. $1

[ -z "$IPAddress" ] && [ "$1" == "$meshr/var/run/wifi.txt" ] && (
  ifconfig $guid 0.0.0.0 up
  # + sed /etc/resolv.conf
  exit
)

iptables_splash() { #HTTP Redirecting to splash screen
  iptables -t mangle -N meshr
  iptables -t mangle -A PREROUTING -i $guid -p tcp -m tcp --dport 80 -j meshr
  iptables -t mangle -A meshr -j MARK --set-mark 98
  iptables -t nat -A PREROUTING -i $guid -p tcp -m mark --mark 98 -m tcp --dport 80 -j DNAT --to-destination $IPAddress
}

[ -n "$IPAddress" ] && [ ! "$1" == "$meshr/var/run/wifi.txt" ] && ifconfig $guid $IPAddress netmask $IPSubnet up && (
  iptables_splash
  old="`ps | grep -v "grep\|$meshr" |grep -m 1 "dnsmasq"`"
  [ -z "$old" ] && old=dnsmasq || old="`echo $old | sed 's/^.* dnsmasq/dnsmasq/g'`"
  # failed to bind DHCP server socket: Address already in use -> Fix: use iptables and single dnsmasq (no bind-dynamic)
  [ -f /tmp/etc/dnsmasq.conf ] && (
    sed -i.bak "s/.*#meshr$//g" /tmp/etc/dnsmasq.conf
    cat >>/tmp/etc/dnsmasq.conf <<EOF
      interface=$guid #meshr
      dhcp-range=tag:$guid,10.177.254.1,10.177.254.254,255.255.0.0,1440m #meshr
      dhcp-option=tag:$guid,3,$IPAddress #meshr
      dhcp-option=tag:$guid,6,$IPAddress #meshr
      dhcp-option=tag:$guid,44,$IPAddress #meshr
EOF
  )
  killall dnsmasq && $old --conf-file=/tmp/etc/dnsmasq.conf
)

echo $DNSServerSearchOrder | grep "." && ( grep $DNSServerSearchOrder /etc/resolv.conf || echo nameserver $DNSServerSearchOrder >>  /etc/resolv.conf )
[ -z "$IPAddress" ] && (
  ifconfig $guid 0.0.0.0 up
  #wl conn
  #udhcpc -q -n -i $guid -s $meshr/usr/sbin/udhcpc.script
)
[ "$1" == "$meshr/etc/wlan/meshr.net.txt" ] || exit

# test if offline
( wget http://74.125.224.72 -O /dev/null -T 10 || ( wget http://74.125.224.72 -O /dev/null -T 10 ) ) && {
  [ -z "$IPAddress" ] && ( 
    ./lib/upload.bat
    ifconfig $guid $IPAddress netmask $IPSubnet up
  )
  [ -n "$IPAddress" ] && grep "$IPAddress.\+255.255.255.255" $meshr/var/etc/olsrd.conf || (
    sed -i "s/.*10.177.\+255.255.255.255.*//g" $meshr/var/etc/olsrd.conf
    echo Hna4 { $IPAddress 255.255.255.255 } >> $meshr/var/etc/olsrd.conf
  )
  [ -f $meshr/var/etc/olsrd.conf ] && start-stop-daemon start $meshr/usr/sbin/olsrd -f $meshr/var/etc/olsrd.conf
  online=1
  return 0
}
online=
[ ! -f $meshr/var/etc/olsrd.conf ] && exit
grep "$IPAddress" $meshr/var/etc/olsrd.conf | grep "255.255.255.255" && sed -i "s/.*10.177./+255.255.255.255.*//g" $meshr/var/etc/olsrd.conf
start-stop-daemon start $meshr/usr/sbin/olsrd -f $meshr/var/etc/olsrd.conf
