#!/usr/bin/env luajit

local i = require "inspect"

local json  = require "cjson"
local redis = require "redis"

local redis_ip   = arg[1]
local redis_port = tonumber(arg[2])
local uuid       = arg[3]

local ok, client = pcall(redis.connect, redis_ip, redis_port)
if not ok then
   error("Redis connect fail")
end

local userData, err = client:get("user:" .. uuid)
if "string" ~= type(userData) then
    error("User not found")
end

local jsonErr, data = pcall(json.decode, userData)
if not jsonErr then
    error("fail json decode")
end


