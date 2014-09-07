--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Manuel Munz <freifunk at somakoma de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0
]]
                          
local rootfs = rootfs or ""
local hostos = hostos or ""
local fs = require "luci.fs"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()
local profiles = rootfs .. "/etc/config/profile_"
local os   = require "os"

m = Map("freifunk", translate ("Community"))
c = m:section(NamedSection, "community", "public", nil, translate("These are the basic settings for your local wireless community. These settings define the default values for the wizard and DO NOT affect the actual configuration of the router."))

community = c:option(ListValue, "name", translate ("Community"))
community.rmempty = false

local list = { }
local list = fs.glob(profiles .. "*")
local clist = { }
local slist = { }

for k,v in ipairs(list) do
   local name = uci:get_first(string.gsub(v,".*/",""), "community", "name") or "?"
   local n = string.gsub(v, ".*" .. profiles, "")
   table.insert(slist, { n, name })
end
table.sort(slist, function(a,b) return string.lower(a[2]) < string.lower(b[2]) end)
for k,v in ipairs(slist) do
   community:value(v[1], v[2])
end


n = Map("system", translate("Basic system settings"))
function n.on_after_commit(self)
   luci.http.redirect(luci.dispatcher.build_url("admin", "freifunk", "basics"))
   local ssid = m.uci:get("freifunk", "community", "ssid") or m.uci:get("profile_" .. m.uci:get("freifunk", "community", "name"), "profile", "ssid") or ""
   if require "luci.model.ipkg".file_exists("/etc/wlan/" .. ssid .. ".txt") then
    local ipv4 = fs.readfile(rootfs .. "/etc/wlan/" .. ssid .. ".txt"):match("IPAddress=[^\n]-([%d%.]+)") or ''
    print(ipv4)
    --os.execute(rootfs .. "/lib/upload.bat >> " .. rootfs .. "/messages.log 2>&1")
    if ipv4 then
      local pref = hostos:sub(1,3) == 'win' and 'Quiet ' or ''
      os.execute(pref .. "sed -i \"s/\\(.*_ip4addr'\\).*/\\1 '" .. ipv4 .. "'/g\" " .. rootfs .. "/etc/config/meshwizard")
    end
  end  
end

b = n:section(TypedSection, "system")
b.anonymous = true

hn = b:option(Value, "hostname", translate("Hostname"))
hn.rmempty = false
hn.datatype = "hostname"

loc = b:option(Value, "location", translate("Location"))
loc.rmempty = false
loc.datatype = "minlength(1)"

lat = b:option(Value, "latitude", translate("Latitude"), translate("e.g.") .. " 48.12345")
lat.datatype = "float"
lat.rmempty = false

lon = b:option(Value, "longitude", translate("Longitude"), translate("e.g.") .. " 10.12345")
lon.datatype = "float"
lon.rmempty = false

--[[
Opens an OpenStreetMap iframe or popup
Makes use of resources/OSMLatLon.htm and htdocs/resources/osm.js
]]--

local class = util.class
local ff = uci:get("freifunk", "community", "name") or ""
local co = "profile_" .. ff

local deflat = uci:get_first("system", "system", "latitude") or uci:get_first(co, "community", "latitude") or 52
local deflon = uci:get_first("system", "system", "longitude") or uci:get_first(co, "community", "longitude") or 10
local zoom = 12
if ( deflat == 52 and deflon == 10 ) then
   zoom = 4
end

OpenStreetMapLonLat = luci.util.class(AbstractValue)
    
function OpenStreetMapLonLat.__init__(self, ...)
   AbstractValue.__init__(self, ...)
   self.template = "cbi/osmll_value"
   self.latfield = nil
   self.lonfield = nil
   self.centerlat = ""
   self.centerlon = ""
   self.zoom = "0"
   self.width = "100%" --popups will ignore the %-symbol, "100%" is interpreted as "100"
   self.height = "600"
   self.popup = false
   self.displaytext="OpenStreetMap" --text on button, that loads and displays the OSMap
   self.hidetext="X" -- text on button, that hides OSMap
end

   osm = b:option(OpenStreetMapLonLat, "latlon", translate("Find your coordinates with OpenStreetMap"), translate("Select your location with a mouse click on the map. The map will only show up if you are connected to the Internet."))
   osm.latfield = "latitude"
   osm.lonfield = "longitude"
   osm.centerlat = uci:get_first("system", "system", "latitude") or deflat
   osm.centerlon = uci:get_first("system", "system", "longitude") or deflon
   osm.zoom = zoom
   osm.width = "100%"
   osm.height = "600"
   osm.popup = false
   osm.displaytext=translate("Show OpenStreetMap")
   osm.hidetext=translate("Hide OpenStreetMap")
   
  -- General settings
  g = n:section(TypedSection, "system", translate("Additional info for network optimization (non-public)"))
  g.anonymous = true 

  ent = g:option(Value, "entrance", translate("Entrance number (yours/max)"), translate("e.g.") .. " 2/6")
  ent.datatype = "string"
  ent.rmempty = true

  hei = g:option(Value, "floor", translate("Floor number (yours/max)"), translate("e.g.") .. " 5/12")
  hei.datatype = "string"
  hei.rmempty = true

  ent = g:option(Value, "layout", translate("Floor plan: type or image url"), translate("e.g.") .. " https://en.wikipedia.org/wiki/File:Sample_Floorplan.jpg")
  ent.datatype = "string"
  ent.rmempty = true
    
return m, n
