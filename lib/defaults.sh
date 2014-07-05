#!/bin/sh
set -x
rm -rf $meshr/tmp/.uci/*
if [ -f $meshr/usr/sbin/olsrd.exe ];then
  $meshr/usr/sbin/olsrd.exe -int > $meshr/tmp/olsrd.int
  $meshr/usr/sbin/olsrd.exe -d 2 -int >  $meshr/tmp/olsrd2.int
  wlan ei  | grep "GUID" | sed "s/.*: //g" > $meshr/tmp/guids.log
  alias echo=uecho
fi

#Location auto-config
if [ 1 ]; then
  curl -o - -A Mozilla -m 12 http://www.ip-adress.com/ip_tracer/ > $meshr/tmp/myip
  if [  -f $meshr/tmp/myip ] ; then
    lat=`cat $meshr/tmp/myip | grep 'latLng' | sed 's/.\+ lat: \([^,]\+\).\+/\1/g'`
    lon=`cat $meshr/tmp/myip | grep 'latLng' | sed 's/.\+ lng: \([^ ]\+\).\+/\1/g'`
  fi
  city=`cat $meshr/tmp/myip | grep setInfoContentHTML | sed 's/.\+:<br>\(.\+\) in.\+/\1/g' | grep -v "setInfoContentHTML"`
  echo $city | grep ">"
  myip=`cat $meshr/tmp/myip | grep 'My IP is: [0-9]' | sed 's/.\+My IP is: \([0-9.]\+\).\+/\1/g'`
  if [  -f $meshr/tmp/bssids.txt ] ; then  
    echo { \"wifiAccessPoints\": [> $meshr/tmp/json.txt
    grep "MAC Address.*:.*-\|^BSSID:" $meshr/tmp/bssids.txt | sed 's/.*:.*\(..[-:]..[-:]..[-:]..[-:]..[-:]..\).*/{"macAddress": "\1"},/g' >>$meshr/tmp/json.txt
    echo {\"macAddress\": \"00-00-00-00-00-00\"}]}>>$meshr/tmp/json.txt
    [ -f $meshr/tmp/latlon.txt ]  && rm $meshr/tmp/latlon.txt
    sudo -geoloc
    grep 'lat' $meshr/tmp/latlon.txt  || sudo -geoloc
    if cat $meshr/tmp/latlon.txt | grep 'lat' ; then
      lat=`cat $meshr/tmp/latlon.txt | grep 'lat' | sed 's/.*lat": \([^,]\+\).\+/\1/g' | sed "s/\(\....\).*/\1$RANDOM/g"`
      lon=`cat $meshr/tmp/latlon.txt | grep 'lng' | sed 's/.*lng": \([^,]\+\).*/\1/g' | sed "s/\(\....\).*/\1$RANDOM/g"`
    fi
  fi
  uci set system.system.location="${city:=Earth}"
  uci set system.system.latitude="${lat:=52}"
  uci set system.system.longitude="${lon:=10}"
  uci set system.system.hostname="${USERNAME:=`uname -n`}-${USERDOMAIN:=`uname -m`}"
  uci commit system
  uci set meshwizard.community="community"
  comm=`ls etc/config/profile_* | grep -i "$city" | sed 's/.*_//g'`
  uci commit meshwizard
fi

#Looking for known wifi networks (communities)
if [  -f $meshr/tmp/bssids.txt ] ; then
  #netsh wlan show  networks | grep -e "^SSID" | sed -e "s/.\+ : //g" > $meshr/tmp/wlans.txt
  #netsh wlan show  networks  mode=bssid  > $meshr/tmp/bssids.txt
  grep "^SSID" $meshr/tmp/bssids.txt | sed "s/.*: \+//g" | sed "s/^\"\(.*\)\"$/\1/g" > $meshr/tmp/wlans.txt
  uci show > $meshr/tmp/uci.txt
  grep -e "profile_.*.profile.ssid" $meshr/tmp/uci.txt | sed -e "s/.\+=//g"  > $meshr/tmp/ssids.txt
  echo meshr.net >> $meshr/tmp/wlans.txt
  for net in $(grep -Fx -f $meshr/tmp/wlans.txt $meshr/tmp/ssids.txt | tr " " "\n")
  do
    comm=`grep -m 1 -e "profile_.*=$net" $meshr/tmp/uci.txt | sed -e "s/profile_\(.*\).profile.ssid=.\+/\1/g"`
    [ -n $comm ] && break
  done
fi
[ -z $comm ] && comm=meshr
uci set meshwizard.community.name="$comm"

if [ -f $meshr/tmp/olsrd2.int ]; then
cat $meshr/tmp/olsrd2.int | grep -e "if[0-9]\+" | while read line; do
  ifs=`echo $line | sed -e "s/\(if[^:]\+\).\+/\1/g"`
  guid=`echo $line | sed -e "s/.*{\(.*\)}.*/\1/g"`
  uci set network.$ifs="interface"
  uci set network.$ifs.ifname="$ifs"
  ( echo $line | grep -q "if[^:]\+: +" || grep -iq "$guid" $meshr/tmp/guids.log ) && uci set meshwizard.netconfig.${ifs}_config=1
done
else
  . $meshr/etc/wifi.txt
  ifs=$guid
  uci set network.$ifs="interface"
  uci set network.$ifs.ifname="$ifs"
  uci set meshwizard.netconfig.${ifs}_config=1
fi
uci commit network 
uci commit meshwizard

$meshr/usr/bin/meshwizard/wizard.sh
