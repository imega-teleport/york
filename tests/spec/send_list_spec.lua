_G.arg = {
    "127.0.0.1",
    "6379",
    "0429915e49a-4de1-41aa-9d7d-c9a687ec048d"
}

describe("Отправление списка доступных файлов для скачивания", function()
    it("Эталонные условия, база - ok, плагин - ok", function()
        local client = {
            get = function(value)
                return "qweqwe111"
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

        local send_list = require 'send_list'

        assert.spy(mockRedis.connect).was.called_with("127.0.0.1", 6379)
        assert.spy(mockClient.get).was.called_with(mockClient, "user:0429915e49a-4de1-41aa-9d7d-c9a687ec048d")

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
        assert.spy(mockClient.get).was.called_with(mockClient, "user:0429915e49a-4de1-41aa-9d7d-c9a687ec048d")
        assert.False(send_list)
    end)
end)
