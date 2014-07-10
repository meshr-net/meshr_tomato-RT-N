# DNS2SOCKS.bat $torIP "$tun" $IPAddress

start-stop-daemon start DNS2SOCKS /l:$meshr/tmp/dns.log $1:9150 8.8.8.8 10.177.254.1
route add -net 0.0.0.0 netmask 0.0.0.0 10.177.254.2 dev $2

grep "10.177.254.1" /etc/resolv.conf || echo nameserver 10.177.254.1 >>  /etc/resolv.conf
IPAddress=$3
# get non random ip
( echo $IPAddress | grep -E "10.177.(1(28|29|[3-5][0-9])|2[0-9][0-9])" || echo IP=$IPAddress | grep -v "." ) && (
  sleep 1
  ./lib/upload.bat
)
