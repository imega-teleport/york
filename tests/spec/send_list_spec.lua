local i = require "inspect"

_G.arg = {
    "127.0.0.1",
    "6379",
    "9915e49a-4de1-41aa-9d7d-c9a687ec048d"
}

describe("Отправление списка доступных файлов для скачивания", function()

    local userData = "{\"login\":\"9915e49a-4de1-41aa-9d7d-c9a687ec048d\",\"url\":\"mock-server\",\"email\":\"info@example.com\",\"create\":\"\",\"pass\":\"\"}"

    it("Эталонные условия, база - ok, плагин - ok", function()
        local client = {
            get = function(value)
                return userData
            end,
        }
        local redis = {
            connect = function(ip, port)
                return client
            end
        }
        local mockRedis = mock(redis)
        local mockClient = mock(client)

        package.loaded.redis = nil
        package.preload['redis'] = function ()
            return redis
        end

        local cjson = {
            decode = function(value)
                return {
                    login  = "9915e49a-4de1-41aa-9d7d-c9a687ec048d",
                    url    = "mock-server",
                    email  = "info@example.com",
                    create = "",
                    pass   = "",
                }
            end
        }
        local mockCjson = mock(cjson)
        package.loaded.cjson = nil
        package.preload['cjson'] = function ()
            return cjson
        end

        local send_list = require 'send_list'

        assert.spy(mockRedis.connect).was.called_with("127.0.0.1", 6379)
        assert.spy(mockClient.get).was.called_with(mockClient, "user:9915e49a-4de1-41aa-9d7d-c9a687ec048d")
        assert.spy(mockCjson.decode).was.called_with(userData)
        assert.True(send_list)
    end)

    it("База данных недоступна", function()
        local redis = {
            connect1 = function(ip, port)
                return nil, "Fail to connect"
            end
        }

        package.loaded.redis = nil
        package.preload['redis'] = function ()
            return redis
        end

        package.loaded.send_list = nil
        local send_list, err = pcall(require, 'send_list')
        assert.False(send_list)
    end)

    it("Пользователь не найден", function()
        local client = {
            get = function(value)
                return nil
            end,
        }
        local redis = {
            connect = function(ip, port)
                return client
            end
        }
        local mockRedis = mock(redis)
        local mockClient = mock(client)

        package.loaded.redis = nil
        package.preload['redis'] = function ()
            return redis
        end

        package.loaded.send_list = nil
        local send_list, err = pcall(require, 'send_list')

        assert.spy(mockRedis.connect).was.called_with("127.0.0.1", 6379)
        assert.spy(mockClient.get).was.called_with(mockClient, "user:9915e49a-4de1-41aa-9d7d-c9a687ec048d")
        assert.False(send_list)
    end)

    it("Данные пользователя повреждены", function()
        local client = {
            get = function(value)
                return userData
            end,
        }
        local redis = {
            connect = function(ip, port)
                return client
            end
        }
        local mockRedis = mock(redis)
        local mockClient = mock(client)

        package.loaded.redis = nil
        package.preload['redis'] = function ()
            return redis
        end

        local cjson = {
            decode = function(value)
                return nil
            end
        }
        local mockCjson = mock(cjson)
        package.loaded.cjson = nil
        package.preload['cjson'] = function ()
            return cjson
        end

        local send_list, err = pcall(require, 'send_list')

        assert.False(send_list)
    end)

end)
