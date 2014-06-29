local rootfs = rootfs or ''
local hostos = hostos or ''
if hostos:sub(1,3) == 'win' then
  require "os".execute("Quiet " .. rootfs .. "/www/cgi-bin/vizdata.bat")
  return require "luci.model.ipkg".file_exists("/tmp/vizdata.tmp") and require "nixio.fs".readfile(rootfs .. "/tmp/vizdata.tmp") or "Content-type: text/html\n\n<BODY><script langauge='JavaScript1.2' type='text/javascript'>parent.viz_callback();</script></BODY>"
else
  return require "io".popen(rootfs .. "/www/cgi-bin/vizdata.sh"):read("*a")
end