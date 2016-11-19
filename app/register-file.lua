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

--no field package.preload['imega.string']
--no file './imega/string.lua'
--no file '/usr/share/luajit-2.0.4/imega/string.lua'
--no file '/usr/local/share/lua/5.1/imega/string.lua'
--no file '/usr/local/share/lua/5.1/imega/string/init.lua'
--no file '/usr/share/lua/5.1/imega/string.lua'
--no file '/usr/share/lua/5.1/imega/string/init.lua'
--no file './imega/string.so'
--no file '/usr/local/lib/lua/5.1/imega/string.so'
--no file '/usr/lib/lua/5.1/imega/string.so'
--no file '/usr/local/lib/lua/5.1/loadall.so'
--no file './imega.so'
--no file '/usr/local/lib/lua/5.1/imega.so'
--no file '/usr/lib/lua/5.1/imega.so'
--no file '/usr/local/lib/lua/5.1/loadall.so'

local json  = require "cjson"
local redis = require "resty.redis"

local redis_ip   = arg[1]
local redis_port = tonumber(arg[2])
local uuid       = arg[3]
local file       = arg[4]

