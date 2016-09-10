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
local findfile = require "imega.findfile"
local userManager = require "imega.auth"
local curl   = require "lcurl"
local redis  = require "resty.redis"
local base64 = require "kloss.base64"

local inspect = require "inspect"

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

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local user = userManager.getUser(db, uuid)
if next(user) == nil then
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.say("404 HTTP_NOT_FOUND")
    ngx.exit(ngx.status)
end

ngx.eof()

local filelist = findfile.forClient(path, true);

local sendData = {
    url     = "http://a.imega.club",
    uuid    = uuid,
    uripath = "storage",
    files   = filelist,
}

local credentials = base64.encode(user['login'] .. ":" .. user['pass'])

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
    :setopt_url(user['url'] .. '/teleport?mode=' .. mode)
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
