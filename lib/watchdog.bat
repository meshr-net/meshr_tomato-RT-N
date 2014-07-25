#!/bin/sh
cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`

#if exist %meshr:/=\%\var\run\wifi.txt call %bin%\services.bat stop "" conn
rm $meshr/var/run/wifi.txt $meshr/var/run/wifi-formed.txt
. $meshr/etc/wifi.txt
. $meshr/etc/wlan/$ssid.txt
wl=1
status=0
which find && alias find=`which find`
PATH="$meshr/bin:/sbin:/bin:/usr/sbin:/usr/bin" #$PATH" grep Segmentation fault
#set -x
#exec 1>$meshr/tmp/wd.log
#exec 2>&1

wl_status() {
  local guid=$1
  if [ -n "$wl" ]; then
    wl -i $guid status  > $meshr/tmp/wlan.log
    grep -q "\"off\"\|error" $meshr/tmp/wlan.log && status="error"
    grep -q "SSID: \"$ssid\"" $meshr/tmp/wlan.log && status="connected to $ssid"
    grep -q "formed: \"$ssid\"" $meshr/tmp/wlan.log && status="formed $ssid"
    grep -q "Not associated\|disconnected: \"$ssid\"" $meshr/tmp/wlan.log && status="disconnected"
  fi  
  [ -n "$iwconfig" ] && iwconfig $guid 
}

[ -n "$smngr" ] && service network-manager stop
ifconfig $guid up
wlan $guid $ssid && echo $ssid>$meshr/var/run/wifi-formed.txt
# infinite loop
while :
do
  [ "$status" == "0" ] && status="" || sleep 10
  [ -z "$ssid" ] && [ ! -f $meshr/etc/wifi.txt ] && continue
  [ -z "$ssid" ] && . $meshr/etc/wifi.txt
  wl_status $guid
  echo $status
  # trying to connect
  if [ ! -f $meshr/var/run/wifi.txt ]; then
   [ "$status" == "formed $ssid" ] && continue    
   # disconnected : trying to connect
   [ "$status" == "disconnected" ] && (
      find $meshr/var/run/wifi-formed.txt -mmin +15 | grep "wifi" && rm $meshr/var/run/wifi-formed.txt
      find $meshr/var/run/wifi-formed.txt -mmin +2 | grep "wifi" && continue
      wlan conn $guid $ssid > tmp/conn.log &&  echo $ssid>$meshr/var/run/wifi-formed.txt
      sleep 1 && wl_status
   ) 
   # connecting to meshr.net
   if [ "$status" == "connected to $ssid" ]; then
      #get current settings
      ( echo IPAddress=`ip -o -4 addr list $guid | awk '{print $4}' | cut -d/ -f1` 
        echo IPSubnet=`ifconfig $guid | grep "Mask:" | sed "s/.*Mask:\(.*\)/\1/g"`
        brctl show > /tmp/brctl.log 
        while read line; do
          echo $line | grep -q " " && br=`echo $line | sed "s/ .*//g"`
          if [ "$line" == "$guid" ]; then
            echo echo Bridge=$br
            brctl delif $br $guid
            break
          fi  
        done < /tmp/brctl.log ) > /tmp/wifi.txt
      cp /tmp/wifi.txt $meshr/var/run/wifi.txt
      # TODO: save routes? route | grep $guid to $DefaultIPGateway + restore in setip
      # run DHCP server ASAP
    
      start-stop-daemon stop $meshr/bin/olsrd
      . $meshr/lib/setip.bat $meshr/etc/wlan/$ssid.txt #> $meshr/tmp/setip.log
      if [ "$online" == "1" ];then
        start-stop-daemon start $meshr/meshr-splash.bat
        start-stop-daemon start $meshr/bin/tor -f $meshr/etc/Tor/torrc-defaults
      else
        $meshr/lib/tor-tun.bat #> $meshr/tmp/tt.log &
        start-stop-daemon start $meshr/lucid-splash.sh
      fi 
   else   
      [ -f $meshr/var/run/wifi-formed.txt ] && rm $meshr/var/run/wifi-formed.txt
   fi 
  else
   [ "$status" == "connected to $ssid" ] && continue
   # disconnected: restore old settings
   start-stop-daemon stop "" conn
  fi
  #exit     
done

# >$bin/../tmp/wd1.$TIME::=..log 2>&1
