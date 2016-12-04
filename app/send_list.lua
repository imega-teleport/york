#!/usr/bin/env luajit

local i = require "inspect"

local json   = require "cjson"
local redis  = require "redis"
local base64 = require "kloss.base64"
local curl   = require "lcurl"

local teleportUrl = "http://a.imega.club"

local redis_ip   = arg[1]
local redis_port = tonumber(arg[2])
local uuid       = arg[3]


local client, err = redis.connect(redis_ip, redis_port)
if not client then
    error("Redis connect fail")
end

local userData, err = client:get("user:" .. uuid)
if "string" ~= type(userData) then
    error("User not found")
end

local data = json.decode(userData)
if json.null == data then
    error("fail json decode")
end

local credentials = base64.encode(data['login'] .. ":" .. data['pass'])

local data = json.decode(client:get('user:files:' .. uuid))
if json.null == data then
    error("fail json decode")
end

local sendData = {
    url     = teleportUrl,
    uuid    = uuid,
    uripath = "storage",
    files   = files,
}

--local ret = {}
--local site = curl.easy()
--:setopt_url(data['url'] .. '/teleport?mode=accept-file')
--:setopt_httpheader{
--    "Authorization: Basic " .. credentials,
--    'Content-Type: application/json',
--}
--:setopt_postfields(json.encode(sendData))
--:setopt_writefunction(
--    function (response)
--        table.insert(ret, response)
--    end
--)
--
--local perform = function ()
--    assert(site:perform())
--end
--
--if not pcall(perform) then
--    ngx.status = ngx.HTTP_BAD_REQUEST
--    ngx.say("400 HTTP_BAD_REQUEST")
--    ngx.exit(ngx.status)
--end
--
--site:close()
