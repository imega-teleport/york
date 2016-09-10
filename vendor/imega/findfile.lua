--
-- Copyright (C) 2016 iMega ltd Dmitry Gavriloff (email: info@imega.ru),
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

local md5 = require "md5" -- need lua5.1-md5

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

--
-- Получить список файлов для отправки клиенту
--
-- @return table
--
local function forClient(path, recursive)
    assert(path and path ~= "", "directory parameter is missing or empty")

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

    return filelist
end

return {
    forClient = forClient,
}
