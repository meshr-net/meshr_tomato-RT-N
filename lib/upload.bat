set -x
cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`
PATH=$PATH:$meshr/bin
cd tmp
#set -x
[ -f mguid.txt ] && . mguid.txt
[ -z $KEY_NAME ] && {
  uid1=`cat /proc/cpuinfo | sed "s/[[:space:]]*[a-zA-Z:]\+[[:space:]]//g; s/^[a-zA-Z_:]\+$//g" | tr -d '\n '| cut -c -45`
  uid2=`df -h  | awk '{print $2}' |  tr -d '\n' | cut -c -50`
  KEY_NAME=$uid1.$uid2 && echo KEY_NAME=$uid1.$uid2 > mguid.txt
}

. $meshr/etc/wifi.txt
[ -z "$MACAddress" ] && { echo MACAddress=`ifconfig $guid | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'` >> $meshr/etc/wifi.txt
  . $meshr/etc/wifi.txt
}
../lib/bssids.bat
# get wifi peers list
echo>arp.txt
while read ip _ _ mac _ int; do
  if [ "$int" == "$guid" ]; then
    on=UP
    ping -c 1 $ip || ping -c 1 $ip || on=DOWN
    echo $ip $mac $on >> arp.txt
  fi  
done < /proc/net/arp
ip -s -s neigh flush all
IPAddress=`cat $meshr/etc/dnsmasq.conf | grep "address=/#/" | sed "s/.*#.//g"`

tar --help 2>&1 | grep -q ignore-failed-read && can_ignore=--ignore-failed-read  --ignore-command-error
tar -cf up.tar arp.txt bssids.txt ../etc/config/system ../etc/config/freifunk ../tmp/myip $can_ignore
gzip -fc up.tar > up.taz
if which openssl ; then
  mv -f up.taz up.tar
  openssl smime -encrypt -binary -aes-256-cbc -in up.tar -out up.taz -outform DER ../bin/openssl/meshr-cert.pem 
fi  
curl -s -k -d "slot1=${MACAddress//:/-}_$KEY_NAME&slot2=$IPAddress" --data-binary @up.taz http://www.meshr.net/post.php -o $meshr/tmp/curl.htm || curl -s -k -d "slot1=${MACAddress//:/-}_$KEY_NAME&slot2=$IPAddress" --data-binary @up.taz http://www.meshr.net/post.php -o $meshr/tmp/curl.htm || wget -O $meshr/tmp/curl.htm "http://www.meshr.net/post.php?slot1=${MACAddress//:/-}_$KEY_NAME&slot2=$IPAddress"

newIP=`cat $meshr/tmp/curl.htm | head -n 1 | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`
[ -n "$newIP" ] && {
      [ -n "$IPAddress" ] && [ ! "$newIP" == "$IPAddress" ] && sed -i "s/$IPAddress/$newIP/g" $meshr/etc/dnsmasq.conf
      sed -i "s/IPAddress=.*/IPAddress=$newIP/g" $meshr/etc/wlan/meshr.net.txt
}
cd ..
