  --[[
LuCI - Lua Configuration Interface

(c) 2008-2011 Jo-Philipp Wich <xm@subsignal.org>
(c) 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local os   = require "os"
local io   = require "io"
local nixio = require "nixio"
local fs   = require "nixio.fs"
local util = require "luci.util"
local coroutine = require "coroutine"
local tonumber = tonumber
local math = math

local type  = type
local pairs = pairs
local error = error
local table = table
local rootfs = rootfs or ''
local hostos = hostos or ''
local sh_ipkg = rootfs:gsub("/","\\") .. '\\bin\\ipkg.bat -force-defaults ' 
local ipkg = hostos:sub(1,3) == 'win' and sh_ipkg or "opkg --force-removal-of-dependent-packages --force-overwrite --nocase"
local icfg = rootfs .. "/etc/ipkg.conf"
local string   = require "string"

local ilists = hostos:sub(1,3) == 'win' and rootfs .. '/usr/lib/ipkg/lists/' or "/var/opkg-lists/"
local idir = rootfs .. "/usr/lib/ipkg/"


--- LuCI OPKG call abstraction library
module "luci.model.ipkg"


-- Internal action function
local function _action(cmd, ...)
   local pkg = ""
   for k, v in pairs({...}) do
      pkg = pkg .. " '" .. v:gsub("'", "") .. "'"
   end

   local c = "%s %s %s >"  %{ ipkg, cmd, pkg } .. rootfs .. "/tmp/opkg.stdout 2>" .. rootfs .. "/tmp/opkg.stderr"
  nixio.syslog("err", c)
   local r = os.execute(c)
   local e = fs.readfile(rootfs .. "/tmp/opkg.stderr")
   local o = fs.readfile(rootfs .. "/tmp/opkg.stdout")
  
  --os.execute(rootfs .. "/bin/cat " .. rootfs .. "/tmp/opkg.stderr >> " .. rootfs .. "/messages.log")
  --os.execute(rootfs .. "/bin/cat " .. rootfs .. "/tmp/opkg.stdout >> " .. rootfs .. "/messages.log")
   
  --fs.unlink(rootfs .. "/tmp/opkg.stderr")
   --fs.unlink(rootfs .. "/tmp/opkg.stdout")

   return r, o or "", e or ""
end

-- Internal parser function
local function _parselist(rawdata)
   if type(rawdata) ~= "function" then
      error("OPKG: Invalid rawdata given")
   end

   local data = {}
   local c = {}
   local l = nil

   for line in rawdata do
      if line:sub(1, 1) ~= " " then
         local key, val = line:match("(.-): ?(.*)%s*")

         if key and val then
            if key == "Package" then
               c = {Package = val}
               data[val] = c
            elseif key == "Status" then
               c.Status = {}
               for j in val:gmatch("([^ ]+)") do
                  c.Status[j] = true
               end
            else
               c[key] = val
            end
            l = key
         end
      else
         -- Multi-line field
         c[l] = c[l] .. "\n" .. line
      end
   end

   return data
end

-- Internal lookup function
local function _lookup(act, pkg)
   local cmd = ipkg .. " " .. act
   if pkg then
      cmd = cmd .. " '" .. pkg:gsub("'", "") .. "'"
   end

   -- OPKG sometimes kills the whole machine because it sucks
   -- Therefore we have to use a sucky approach too and use
   -- tmpfiles instead of directly reading the output
   local tmpfile = os.tmpname()
   os.execute(cmd .. (" >%s 2>/dev/null" % tmpfile))

   local data = _parselist(io.lines(tmpfile))
   os.remove(tmpfile)
   return data
end


--- Return information about installed and available packages.
-- @param pkg Limit output to a (set of) packages
-- @return Table containing package information
function info(pkg)
   return _lookup("info", pkg)
end

--- Return the package status of one or more packages.
-- @param pkg Limit output to a (set of) packages
-- @return Table containing package status information
function status(pkg)
   return _lookup("status", pkg)
end

--- Install one or more packages.
-- @param ... List of packages to install
-- @return Boolean indicating the status of the action
-- @return OPKG return code, STDOUT and STDERR
function install(...)
   return _action("install", ...)
end

--- Determine whether a given package is installed.
-- @param pkg Package
-- @return Boolean
function installed(pkg)
   local p = status(pkg)[pkg]
   return (p and p.Status and p.Status.installed)
end

--- Remove one or more packages.
-- @param ... List of packages to install
-- @return Boolean indicating the status of the action
-- @return OPKG return code, STDOUT and STDERR
function remove(...)
   return _action("remove", ...)
end

function string_gsplit(string, pattern, capture)
string = string or ''
pattern = pattern or '%s+'
if (''):find(pattern) then
error('pattern matches empty string!', 2)
end
return coroutine.wrap(function()
local index = 1
repeat
local first, last = string:find(pattern, index)
if first and last then
if index < first then coroutine.yield(string:sub(index, first - 1)) end
if capture then coroutine.yield(string:sub(first, last)) end
index = last + 1
else
if index <= #string then coroutine.yield(string:sub(index)) end
break
end
until index > #string
end)
end

function version_sort(strings, strip_extensions)
local function tokenize(s)
local parts = {}
if strip_extensions then
s = s:gsub('%.%w+$', '')
end
for p in string_gsplit(s, '%d+', true) do
table.insert(parts, tonumber(p) or p)
end
return parts
end
table.sort(strings, function(left, right)
local left_tokens = tokenize(left)
local right_tokens = tokenize(right)
for i = 1, math.max(#left_tokens, #right_tokens) do
local left_value = left_tokens[i] or '!'
local right_value = right_tokens[i] or '!'
if type(left_value) ~= type(right_value) then
left_value, right_value = tostring(left_value), tostring(right_value)
end
if left_value < right_value then return true end
if left_value > right_value then return false end
end
end)
return strings
end

--- Update package lists.
-- @return Boolean indicating the status of the action
-- @return OPKG return code, STDOUT and STDERR " .. pth .. "tmp/Packages" 
function update(...)
   return _action("update", ...)
end

--- Upgrades all installed packages.
-- @return Boolean indicating the status of the action
-- @return OPKG return code, STDOUT and STDERR
function upgrade(...)
   return _action("upgrade", ...)
end

function list_state(dir)
   local no_lists = true
   local old_lists = false  
   local tmp = nixio.fs.dir(ilists)
   if tmp then
      for tmp in tmp do
      if not dir or tmp == dir then
        no_lists = false
        tmp = nixio.fs.stat(ilists..tmp)
        if tmp and tmp.mtime < (os.time() - (24 * 60 * 60)) then
          old_lists = true
          break
        end
      end
      end
   end
  return no_lists, old_lists
end

function case_insensitive_pattern(pattern)

  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end

function file_exists(name)
    -- hostos:sub(1,3) == 'win' and ??
   local f=io.open( name:sub(1,1) == '/' and rootfs .. name or name,"r")
   if f~=nil then io.close(f) return true else return false end
end
function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end
-- List helper pat:gsub("%*", "")
function _list(action, pat, cb)
   pkg = readAll(icfg)
   patl = "^" .. (pat or "*"):gsub("%*", ".%*") .. "$"
  local lpat = "Package: (.-)\r?\nVersion: (.-)\r?\n.-\nDescription: (.-)\r?\n"
   for src in string.gmatch(  pkg, "src ([^ ]+)[^\r\n]*") do
      si = ilists .. src
--  local pat2 = "Package: (.-)\r?\nVersion: (.-)\r?\nDescription: (.-)" pat == '#' or  
      if file_exists(si) then
         pkg = readAll(si)
         for name, version, desc in string.gmatch(pkg, lpat) do
            if string.find(name, patl) or string.find(name, case_insensitive_pattern(patl)) then 

               cb(name, version, desc)

               name    = nil
               version = nil
               desc    = nil
            end
         end
      end
   end
end

--- List all packages known to opkg.
-- @param pat   Only find packages matching this pattern, nil lists all packages
-- @param cb   Callback function invoked for each package, receives name, version and description as arguments
-- @return   nothing
function list_all(pat, cb)
   _list("list", pat, cb)
end

--- List installed packages.
-- @param pat   Only find packages matching this pattern, nil lists all packages
-- @param cb   Callback function invoked for each package, receives name, version and description as arguments
-- @return   nothing
function list_installed(pat, cb)
--   si = rootfs .. "/var/lib/opkg/status"
   si = rootfs .. "/usr/lib/ipkg/status"
   patl = "^" .. (pat or "*"):gsub("%*", ".%*") .. "$"
--   nixio.syslog("err", ">> " ..   patl)
  local pat = "Package: (.-)\r?\n.-Version: (.-)\r?\n"
  local desc = '' 
   if file_exists(si) then
      pkg = readAll(si)
      for name, version in string.gmatch(pkg, pat) do
         if string.find(name, case_insensitive_pattern(patl)) then 
            cb(name, version, desc)

            name    = nil
            version = nil
            desc    = nil
         end
      end
   end
end

--- Find packages that match the given pattern.
-- @param pat   Find packages whose names or descriptions match this pattern, nil results in zero results
-- @param cb   Callback function invoked for each patckage, receives name, version and description as arguments
-- @return   nothing
function find(pat, cb)
   _list("find", pat, cb)
end


--- Determines the overlay root used by opkg.
-- @return      String containing the directory path of the overlay root.
function overlay_root()
   local od = "/"
   local fd = io.open(icfg, "r")

   if fd then
      local ln

      repeat
         ln = fd:read("*l")
         if ln and ln:match("^%s*option%s+overlay_root%s+") then
            od = ln:match("^%s*option%s+overlay_root%s+(%S+)")

            local s = fs.stat(od)
            if not s or s.type ~= "dir" then
               --od = "/"
            end

            break
         end
      until not ln

      fd:close()
   end

   return od
end
