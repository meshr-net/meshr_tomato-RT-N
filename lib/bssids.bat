set -x
cd `dirname $0`/..
[ -z $meshr ] && meshr=`pwd`
wl=1
nvram=1

find_wlan_int() {(
  local wlan=
  [ -n "$nvram" ] && wlan=`nvram get wl_ifname`
  [ -n "$iwconfig" ] && wlan=`iwconfig 2>/dev/null | sed -ne 's|^\('$cur'[^[:space:][:punct:]]\{1,\}\).*$|\1|p'`
	echo $wlan
)}

touch ./tmp/bssids.txt
grep "guid" $meshr/etc/wifi.txt || {
  # default config
  wlan=`find_wlan_int`
  [ -n "$wlan" ] &&  {
    echo guid=$wlan>$meshr/etc/wifi.txt
    echo mode=ad-hoc>>$meshr/etc/wifi.txt
    echo ssid=meshr.net>>$meshr/etc/wifi.txt
  }
} 
. $meshr/etc/wifi.txt
[ -z "$guid" ] && rm $meshr/etc/wifi.txt
[ -n "$iwconfig" ] && iwlist $guid scan >> ./tmp/bssids.txt
[ -n "$wl" ] && wl up && wl scan -n 9 && sleep 2 && wl scanresults >> ./tmp/bssids.txt
grep -m 1 "SSID" ./tmp/bssids.txt || rm ./tmp/bssids.txt