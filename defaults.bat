[ -z $meshr ] && meshr=`pwd`
if ! curl http://74.125.224.72 -o NUL -m 10; then
#wait watchdog conn
fi
$meshr/lib/upload.bat getip > $meshr/tmp/upload.log
$meshr/lib/defaults.sh
