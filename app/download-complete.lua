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

local filelist = {}

local uuid = ngx.req.get_headers()["X-Teleport-uuid"]
local path = "/data/" .. uuid .. "/"

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

for filename, attr in dirtree(path) do
    ngx.say(inspect(filename))
end



ngx.say(json.encode({
    url = "a.imega.club",
    uuid = uuid,
    uripath = "storage",
    files = filelist,
}))
