[ -z $meshr ] && meshr=`pwd`
export meshr=$meshr
PATH=$meshr/bin:$PATH
if ! wget http://74.125.224.72 -O /dev/null -T 10; then
  echo wait watchdog conn
fi
$meshr/lib/bssids.bat
$meshr/lib/upload.bat getip > $meshr/tmp/upload.log
$meshr/lib/defaults.sh
$meshr/update.bat backup
nvram 2>&1 && ( meshr_backup="`tar czf - -X etc/tarignore etc/* | openssl enc -base64 | tr '\n' ' '`"
  [ -n "$meshr_backup" ] && ( nvram set meshr_backup="$meshr_backup" && nvram commit )& )