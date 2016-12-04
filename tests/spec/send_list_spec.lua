local i = require "inspect"

describe("Отправление списка доступных файлов для скачивания", function()
    local client, mockClient,
          redis,  mockRedis,
          cjson,  mockCjson

    before_each(function()
        _G.arg = {
            "127.0.0.1",
            "6379",
            "9915e49a-4de1-41aa-9d7d-c9a687ec048d"
        }

        client = {
            get = function(value) end,
        }
        redis = {
            connect = function(ip, port) end
        }
        mockRedis = mock.new(redis, true)
        mockClient = mock.new(client, true)

        mockClient.get.on_call_with(mockClient).returns(
            function() return nil, "not found" end)

        mockRedis.connect.returns(nil, "not init")
        mockRedis.connect.on_call_with("127.0.0.1", 6379).returns(mockClient)

        package.loaded.redis = nil
        package.preload['redis'] = function ()
            return mockRedis
        end

        cjson = {
            decode = function(value) end,
        }
        mockCjson = mock.new(cjson, true)
        package.loaded.cjson = nil
        package.preload['cjson'] = function ()
            return mockCjson
        end

        package.loaded.send_list = nil
    end)

   local userData = "{\"login\":\"9915e49a-4de1-41aa-9d7d-c9a687ec048d\",\"url\":\"mock-server\",\"email\":\"info@example.com\",\"create\":\"\",\"pass\":\"\"}"

    it("Эталонные условия, база - ok, плагин - ok", function()
        mockClient.get.on_call_with(mockClient, "user:9915e49a-4de1-41aa-9d7d-c9a687ec048d").returns(userData)
        mockCjson.decode.on_call_with(userData).returns({
            login  = "9915e49a-4de1-41aa-9d7d-c9a687ec048d",
            url    = "mock-server",
            email  = "info@example.com",
            create = "",
            pass   = "",
        })
        local send_list = require 'send_list'
        assert.True(send_list)
    end)

    it("База данных недоступна", function()
        _G.arg = {}
        local send_list, err = pcall(require, 'send_list')
        assert.False(send_list)
    end)

    it("Пользователь не найден", function()
        _G.arg = {
            "127.0.0.1",
            "6379",
            "not_user"
        }
        local send_list, err = pcall(require, 'send_list')
        assert.False(send_list)
    end)

    it("Данные пользователя повреждены", function()
        mockClient.get.on_call_with(mockClient, "user:9915e49a-4de1-41aa-9d7d-c9a687ec048d").returns(userData)
        mockCjson.decode.on_call_with(userData).returns(nil)
        local send_list, err = pcall(require, 'send_list')

        assert.False(send_list)
    end)

end)
