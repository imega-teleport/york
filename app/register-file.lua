#!/usr/bin/env luajit
--
-- Copyright (C) 2015 iMega ltd Dmitry Gavriloff (email: info@imega.ru),
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

local json  = require "cjson"
local redis = require "redis"
local md5   = require "md5"
local inspect = require "inspect"

local redis_ip   = arg[1]
local redis_port = tonumber(arg[2])
local uuid       = arg[3]
local path       = arg[4]
local filename   = arg[5]

local ok, client = pcall(redis.connect, redis_ip, redis_port)
if not ok then
    print(client)
    os.exit(1)
end

local jsonErr, files = pcall(
    json.decode,
    client:get('user:files:' .. uuid)
)
if not jsonErr then
    files = {}
end

print(inspect(files))
os.exit(1)

local hash
local item = {}
print(path .. '/' .. uuid .. '/' .. filename)
local f = io.open(path .. '/' .. uuid .. '/' .. filename, "r")
if f then
    local data = f:read('*all')
    f:close()
    hash = md5.sumhexa(data)
end

item[filename] = hash
table.insert(files, item)

local jsonErr, data = pcall(json.encode, files)
if not jsonErr then
    os.exit(1)
end

client:set('user:files:' .. uuid, data)
