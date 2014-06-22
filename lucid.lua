rootfs = os.getenv("meshr") or ''
if #rootfs > 0 then
  if string.match(... or "", "--splash") then
    smode = '/controller2/'
  end
  if os.getenv("OS") == "Windows_NT" then
    hostos = 'win32'
  end  
  package.path= rootfs .. '/usr/lib/lua/?.lua;' .. rootfs .. '/usr/lib/lua/?/init.lua;;'
  package.cpath= rootfs .. '/usr/lib/lua/?.so;;'
  dofile (rootfs .. "/setup.lua")
else
  dofile "build/setup.lua"
end  
require "luci.lucid".start()
