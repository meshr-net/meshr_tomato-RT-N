[ -z $meshr ] && meshr=`pwd`
export meshr=$meshr
PATH=$meshr/bin:$PATH
if ! curl http://74.125.224.72 -o /dev/null -m 10; then
  echo wait watchdog conn
fi
$meshr/lib/upload.bat getip > $meshr/tmp/upload.log
$meshr/lib/defaults.sh
