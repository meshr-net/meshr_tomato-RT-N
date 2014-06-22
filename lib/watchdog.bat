cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`
# check admin rights
if [ `whoami` != 'root' ];then
  sudo $0 $@ && exit
fi
#if exist %meshr:/=\%\var\run\wifi.txt call %bin%\services.bat stop "" conn
rm $meshr/var/run/wifi.txt $meshr/var/run/wifi-formed.txt
. $meshr/etc/wifi.txt
. $meshr/etc/wlan/$ssid.txt
wl=1
status=
set -x
wl_conn() {
  local guid=$1
  [ -n "$wl" ] && {
    wl -i $guid radio on
    wl -i $guid up 
    wl join meshr.net imode ibss ap 0
  }  
  [ -n "$iwconfig" ] && iwconfig $guid mode ${mode/adhoc/ad-hoc} essid $ssid enc off key off rate auto channel 1
  
#      ( type tmp/conn.log  | find "is not correct" ) && $bin/wlan conn $guid $ssid $mode $ssid >> tmp/conn.log
#      ( type tmp/conn.log  | find "completed successfully" )
  return 0
}

wl_status() {
  local guid=$1
  if [ -n "$wl" ]; then
    wl -i $guid status  > $meshr/tmp/wlan.log
    grep -q "\"off\"\|error" $meshr/tmp/wlan.log && status="error"
    grep -q "SSID: \"$ssid\"" $meshr/tmp/wlan.log && status="connected to $ssid"
    
    grep -q "formed: \"$ssid\"" $meshr/tmp/wlan.log && status="formed $ssid"
    grep -q "disconnected: \"$ssid\"" $meshr/tmp/wlan.log && status="disconnected"
  fi  
  [ -n "$iwconfig" ] && iwconfig $guid 
}
run_script() {
  local name=$(basename $1)
  [ -f $meshr/var/run/$name.pid ] && kill -9 `cat $meshr/var/run/$name.pid`
  # $meshr/bin/failsafe.sh ?
  ( nohup $@ && echo $!>$meshr/var/run/$name.pid ) & 
}
[ -n "$smngr" ] && service network-manager stop
ifconfig $guid up
wl_conn $guid && echo $ssid>$meshr/var/run/wifi-formed.txt
# infinite loop
while :
do
  #sleep 3
  [ -z "$ssid" ] && [ ! -f $meshr/etc/wifi.txt ] && continue
  [ -z "$ssid" ] && . $meshr/etc/wifi.txt
  wl_status $guid
  echo $status
  # trying to connect
  if [ ! -f $meshr/var/run/wifi.txt ]; then
   [ "$status" == "formed $ssid" ] && continue    
   # disconnected : trying to connect
   [ "$status" == "disconnected" ] && {
      find $meshr/var/run/wifi-formed.txt -mmin +15 | grep "wifi" && rm $meshr/var/run/wifi-formed.txt
      find $meshr/var/run/wifi-formed.txt -mmin +2 | grep "wifi" && continue
      wl_conn $guid > tmp/conn.log &&  echo $ssid>$meshr/var/run/wifi-formed.txt
      continue
   }  
   # connecting to meshr.net
   if [ "$status" == "connected to $ssid" ]; then
      #get current settings
      echo IPAddress=`ip -o -4 addr list $guid | awk '{print $4}' | cut -d/ -f1` > $meshr/var/run/wifi.txt
      echo IPSubnet=`ifconfig $guid | grep "Mask:" | sed "s/.*Mask:\(.*\)/\1/g"` > $meshr/var/run/wifi.txt
      brctl show | while read line; do
          echo $line | grep -q " " && br=`echo $line | sed "s/ .*//g"`
          if [ "$line" == "$guid" ]; then
            echo echo Bridge=$br> $meshr/var/run/wifi.txt
            brctl delif $br $guid
            break
          fi  
        done
      # TODO: save routes? route | grep $guid to $DefaultIPGateway + restore in setip
      # run DHCP server ASAP
    
      killall olsrd
      $meshr/lib/setip.bat "$meshr/etc/wlan/$ssid.txt" #> $meshr/tmp/setip.log
      if [ "$online" == "1" ] ;then
        run_script $meshr/lucid-splash.sh
        run_script $meshr/bin/tor -f  $meshr/etc/Tor/torrc-defaults
      else
        $meshr/lib/tor-tun.bat #> $meshr/tmp/tt.log &
        run_script $meshr/lucid-splash.sh
      fi
      exit      
   else   
      [ -f $meshr/var/run/wifi-formed.txt ] && rm $meshr/var/run/wifi-formed.txt
   fi 
  else
   [ "$status" == "connected to $ssid" ] && continue
   # disconnected: restore old settings
   ./bin/services.bat stop "" conn
  fi
done

# >$bin/../tmp/wd1.$TIME::=..log 2>&1
