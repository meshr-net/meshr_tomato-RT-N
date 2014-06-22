--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

$Id: servicectl.lua 9484 2012-11-21 19:29:47Z jow $
]]--

local hostos = hostos or ''
local rootfs = rootfs or ''
module("luci.controller.admin.servicectl", package.seeall)

function index()
   entry({"servicectl"}, alias("servicectl", "status")).sysauth = "root"
   entry({"servicectl", "status"}, call("action_status")).leaf = true
   entry({"servicectl", "restart"}, call("action_restart")).leaf = true
end

function action_status()
   local data = nixio.fs.readfile("/var/run/luci-reload-status")
   if data then
      luci.http.write("/etc/config/")
      luci.http.write(data)
   else
      luci.http.write("finish")
   end
end

function action_restart(args)
   local uci = require "luci.model.uci".cursor()
   if args then -- and not luci.model.ipkg.file_exists("/var/run/luci-reload-status")
      local service
      local services = { }

      for service in args:gmatch("[%w_-]+") do
         services[#services+1] = service
      end

      local command = uci:apply(services, true)
      if nixio.fork() == 0 then
        if not hostos:sub(1,3) == 'win' then
          local i = nixio.open("/dev/null", "r")
          local o = nixio.open("/dev/null", "w")

          nixio.dup(i, nixio.stdin)
          nixio.dup(o, nixio.stdout)

          i:close()
          o:close()
        end
        nixio.syslog("info", "action_restart " .. unpack(command) )
        if false and nixio.fs.isdirectory( rootfs .. "/%SystemDrive%" ) then
          nixio.exec("/bin/sh", "rm -rf $meshr/%SystemDrive%")
        else
          require "os".execute("Quiet " .. rootfs .. "/bin/sh.bat ".. table.concat(command," "))
          --nixio.exec("/bin/sh", unpack(command))
        end         
      else
         luci.http.write("OK")
         os.exit(0)
      end
   end
end
