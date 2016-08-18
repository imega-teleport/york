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
local json   = require "cjson"
local strlib = require "imega.string"

local headers = ngx.req.get_headers()
if strlib.empty(headers["X-Teleport-uuid"]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST");
    ngx.exit(ngx.status)
end

ngx.req.read_body()
local body = ngx.req.get_body_data()

local uuid = ngx.req.get_headers()["X-Teleport-uuid"]

local jsonErrorParse, data = pcall(json.decode, body)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

os.execute("if [ ! -d /data/x-" .. uuid .. " ];then mkdir -p /data/x-" .. uuid .. "; fi")
os.execute("cp -f /data/" .. uuid .. data['file'] .. " /data/x-" .. uuid .. data['file'])
os.execute("rm -f /data/" .. uuid .. data['file'])
