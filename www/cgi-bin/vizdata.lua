local html=[[
<HTML>
<HEAD>
	<TITLE>OLSR-VIZ Data</TITLE>
	<META CONTENT="text/html; charset=iso-8859-1" HTTP-EQUIV="Content-Type">
	<META CONTENT="no-cache" HTTP-EQUIV="cache-control">
</HEAD>
<BODY>

<script langauge='JavaScript1.2' type='text/javascript'>
]]

-- sed + txtinfo plugin
local io = require "io"
local hc = require "luci.httpclient"
local rootfs = rootfs or ''
local source, code, msg  = hc.request_to_buffer("http://127.0.0.1:2006/all")
if not msg then
  local f = nixio.open(rootfs .. "/tmp/olsr.tmp", "w", 600)
  f:writeall(source)
  f:close()

  local handle = io.popen("sed -n -f " .. rootfs .. "/lib/olsr.sed " .. rootfs .. "/tmp/olsr.tmp")
  html = html .. handle:read("*a")
  handle:close()
  handle = io.popen("sed -n -f " .. rootfs .. "/lib/olsr2.sed " .. rootfs .. "/etc/hosts")
  html = html .. handle:read("*a")
end
html = html .. [[
	parent.viz_callback();
</script>
</BODY></HTML>
]]
return html