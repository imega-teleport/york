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
local lfs  = require "lfs"
local json = require "cjson"
local inspect = require "inspect"
local curl = require "lcurl"
local md5 = require "md5"

local filelist = {}

local uuid = ngx.req.get_headers()["X-Teleport-uuid"]
local path = "/data/" .. uuid .. "/"

--ngx.eof()

--function find(path)
--    ngx.say(inspect(lfs))
--    for file in lfs.dir(path) do
--        if file ~= "." and file ~= ".." then
--            local cpath = path..'/'..file
--            local attr = lfs.attributes(cpath)
--            if attr.mode == "directory" then
--                find(rpath)
--            else
--                filelist["/" .. file] = "md5"
--            end
--
--            --table.insert(filelist, {file = "md5" })
--        end
--    end
--end
--
--find(path)

function dirtree(dir)
    assert(dir and dir ~= "", "directory parameter is missing or empty")
    if string.sub(dir, -1) == "/" then
        dir=string.sub(dir, 1, -2)
    end

    local function yieldtree(dir)
        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                entry=dir.."/"..entry
                local attr=lfs.attributes(entry)
                if attr.mode == "file" then
                    coroutine.yield(entry,attr)
                end
                if attr.mode == "directory" then
                    yieldtree(entry)
                end
            end
        end
    end

    return coroutine.wrap(function() yieldtree(dir) end)
end
ngx.say("=====" .. "md5sum 60b725f10c9c85c70d97880dfe8191b3  /data/9915e49a-4de1-41aa-9d7d-c9a687ec048d/dump.sql")
ngx.say(md5.sumhexa("dump.sql\na"))

for filename, attr in dirtree(path) do
    local file = io.open(filename, "r")
    io.input(file)
    local hash = md5.sumhexa(io.read())
    io.close(file)
    filelist[string.sub(filename,string.len(path))] = hash
end

ngx.say(json.encode({
    url = "a.imega.club",
    uuid = uuid,
    uripath = "storage",
    files = filelist,
}))


--local credentials = base64.encode(validData['login'] .. ":" .. res)
--
--local site = curl.easy()
--:setopt_url(validData['url'] .. '/teleport')
--:setopt_httpheader{
--    "Authorization: Basic " .. credentials,
--}
--
--local perform = function ()
--    site:perform()
--end
--
--if not pcall(perform) then
--    ngx.status = ngx.HTTP_BAD_REQUEST
--    ngx.say("400 HTTP_BAD_REQUEST")
--    ngx.exit(ngx.status)
--end
--
--local codeResponse = site:getinfo_response_code()
--
--site:close()
--
--if not ngx.HTTP_OK == codeResponse then
--    ngx.status = ngx.HTTP_BAD_REQUEST
--    ngx.say("400 HTTP_BAD_REQUEST")
--    ngx.exit(ngx.status)
--end
