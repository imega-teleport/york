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
local lfs    = require "lfs"
local json   = require "cjson"
local strlib = require "imega.string"
local curl   = require "lcurl"
local md5    = require "md5"
local redis  = require "resty.redis"
local base64 = require "kloss.base64"

--local inspect = require "inspect"

local headers = ngx.req.get_headers()
if strlib.empty(headers["X-Teleport-uuid"]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST");
    ngx.exit(ngx.status)
end

local redis_ip   = ngx.var.redis_ip
local redis_port = tonumber(ngx.var.redis_port)

local uuid = ngx.req.get_headers()["X-Teleport-uuid"]
local path = "/data/" .. uuid .. "/"

ngx.eof()

function dirtree(dir, recursive)
    assert(dir and dir ~= "", "directory parameter is missing or empty")
    if string.sub(dir, -1) == "/" then
        dir=string.sub(dir, 1, -2)
    end

    local function yieldtree(dir, recursive)
        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                entry=dir.."/"..entry
                local attr = lfs.attributes(entry)
                if attr.mode == "file" then
                    coroutine.yield(entry,attr)
                end
                if true == recursive and attr.mode == "directory" then
                    yieldtree(entry, true)
                end
            end
        end
    end

    return coroutine.wrap(function() yieldtree(dir, recursive) end)
end

local filelist = {}

for filename, attr in dirtree(path, true) do
    local hash
    local item = {}
    local f = io.open(filename, "r")
    if f then
        local data = f:read('*all')
        f:close()
        hash = md5.sumhexa(data)
    end
    item[string.sub(filename,string.len(path))] = hash
    table.insert(filelist, item)
end

local sendData = {
    url     = "http://a.imega.club",
    uuid    = uuid,
    uripath = "storage",
    files   = filelist,
}

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local userData, err = db:get("user:" .. uuid)
if "string" ~= type(userData) then
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.say("404 HTTP_NOT_FOUND")
    ngx.exit(ngx.status)
end

local jsonErrorParse, data = pcall(json.decode, userData)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local credentials = base64.encode(data['login'] .. ":" .. data['pass'])

local mode = "accept-file"

if next(filelist) == nil then
    mode = "import"
    local path = "/data/x-" .. uuid .. "/"
    local ret = dirtree(path, false)
    local firstFile = ret()
    if strlib.empty(firstFile) then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say("400 HTTP_BAD_REQUEST");
        ngx.exit(ngx.status)
    else
        sendData['file'] = string.sub(firstFile,string.len(path) + 1)
    end
end

local ret = {}
local site = curl.easy()
    :setopt_url(data['url'] .. '/teleport?mode=' .. mode)
    :setopt_httpheader{
        "Authorization: Basic " .. credentials,
        'Content-Type: application/json',
    }
    :setopt_postfields(json.encode(sendData))
    :setopt_writefunction(
        function (response)
            table.insert(ret, response)
        end
    )

local perform = function ()
    assert(site:perform())
end

if not pcall(perform) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

--local codeResponse = site:getinfo_response_code()
--ngx.say(codeResponse)
--ngx.say(inspect(ret))

site:close()
