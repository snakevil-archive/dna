#!/usr/bin/env lua

pcall(function ()
    local DNaConfig = {
        host = '127.0.0.1',
        port = 1053,
        upstreams = {
            mode = 'tcp',
            timeout = 3,
            {
                host = '8.8.8.8',
                port = 53
            },
            {
                host = '8.8.4.4',
                port = 53
            }
        },
        log = {
            path = 'stderr',
            level = 'notice'
        }
    }

    --- socket() - Retrieves `LuaSocket` module
    -- @return LuaSocket
    local function socket()
        local socket
        if not pcall(function ()
            socket = require('socket')
        end) then
            error{
                code = 1
            }
        end
        return socket
    end

    -----------------------------------------------------------[[ DNaServer ]]--

    local DNaServer = {}
    DNaServer.__index = DNaServer

    setmetatable(DNaServer, {
        --- DNaServer() - Alias of `DNaServer.new()`.
        __call = function (server, ... )
            return server.new(...)
        end
    })

    --- DNaServer.new() - Creates a server
    -- @param host Address to bind
    -- @param port Port to listen
    -- @return DNaServer object
    function DNaServer.new(host, port)
        if not host then
            host = '127.0.0.1'
        elseif 'string' ~= type(host) then
            host = tostring(host)
        end
        if not port then
            port = 53
        elseif 'number' ~= type(host) then
            port = tonumber(port)
        end
        local self, socket = setmetatable({}, DNaServer), socket()
        self.conn = socket.udp()
        self.conn:settimeout(0)
        assert(self.conn:setsockname(host, port))
        self.host, self.port = self.conn:getsockname()
        self.host = socket.dns.tohostname(self.host)
        return self
    end

    --- DNaServer:shutdown() - Shutdowns the server
    function DNaServer:shutdown()
        self.conn:close()
    end

    --- DNaServer:request() - Receives a new request
    -- @return nil or request object
    function DNaServer:request()
        local req, phost, pport = self.conn:receivefrom()
        if not req then
            error{
                code = 255
            }
        end
        return {
            server = self,
            host = phost,
            port = pport,
            blob = req
        }
    end

    --- DNaServer:request() - Responds the current request
    -- @param response Response object
    function DNaServer:respond(response)
        if response then
            self.conn:sendto(response.blob, response.host, response.port)
        end
    end

    ------------------------------------------------------------[[ DNaAgent ]]--

    local DNaAgent = {
        mode = {
            tcp = 'tcp',
            udp = 'udp'
        }
    }
    DNaAgent.__index = DNaAgent

    setmetatable(DNaAgent, {
        --- DNaAgent() - Alias of `DNaAgent.new()`.
        __call = function (agent, ... )
            return agent.new(...)
        end
    })

    --- DNaAgent.new() - Creates an agent
    -- @param host Address of remote name server
    -- @param port Port of remote name server
    -- @param mode Connection mode to query
    -- @param timeout Total communication time of the query
    -- @return DNaAgent object
    function DNaAgent.new(host, port, mode, timeout)
        if not host then
            error{
                code = 3
            }
        elseif 'string' ~= type(host) then
            host = tostring(host)
        end
        if not port then
            port = 53
        elseif 'number' ~= type(port) then
            port = tonumber(port)
        end
        if not mode then
            mode = DNaAgent.mode.udp
        elseif 'string' ~= type(mode) then
            mode = string.lower(tostring(mode))
        else
            mode = string.lower(mode)
        end
        if DNaAgent.mode.tcp ~= mode and DNaAgent.mode.udp ~= mode then
            mode = DNaAgent.mode.udp
        end
        if not timeout then
            timeout = 3
        elseif 'number' ~= type(timeout) then
            timeout = tonumber(timeout)
        end
        local self = setmetatable({
            host = host,
            port = port,
            mode = mode,
            timeout = timeout,
            counter = 0
        }, DNaAgent)
        return self
    end

    --- DNaAgent:query() - Communicates the remote name server
    -- @param query Query blob
    -- @return Result blob
    function DNaAgent:query(query)
        if not query then
            return nil
        elseif 'string' ~= type(query) then
            query = tostring(query)
        end
        if DNaAgent.mode.udp == self.mode then
            return self:udp(query)
        end
        return self:tcp(query)
    end

    --- DNaAgent:tcp() - Communicates in TCP
    -- @param query Query blob
    -- @return Result blob
    function DNaAgent:tcp(query)
        self.conn = socket().tcp()
        self.conn:settimeout(self.timeout)
        assert(self.conn:connect(self.host, self.port))
        self.conn:send(string.char(0, 28) .. query)
        local result, rstat, rpart = self.conn:receive('*a')
        result = string.sub(result or rpart, 3)
        self.conn:close()
        return result
    end

    --- DNaAgent:udp() - Communicates in UDP
    -- @param query Query blob
    -- @return Result blob
    function DNaAgent:udp(query)
        if 0 == self.counter then
            self.conn = socket().udp()
            self.conn:settimeout(self.timeout)
            assert(self.conn:setpeername(self.host, self.port))
        end
        self.conn:send(query)
        return self.conn:receive()
    end

    --- DNaAgent:appease() - Adapts the query
    -- @param request Request object
    function DNaAgent:appease(request)
        if not request then
            return
        end
        local response = {
            host = request.host,
            port = request.port,
            blob = self:query(request.blob)
        }
        self.counter = 1 + self.counter
        if response.blob and #response.blob then
            return request.server:respond(response)
        end
    end

    ------------------------------------------------------------[[ DNaction ]]--

    DNaction = {
        _VERSION = 'DNaction 0.0.1-alpha'
    }

    DNaction.log = {
        debug = 0,
        notice = 1,
        warning = 2,
        error = 3
    }

    setmetatable(DNaction.log, {
        --- DNaction.log() - Logs messages
        -- @param message What to be logged
        -- @param level Priority of the message
        -- @param inline Whether append a newline automatically
        __call = function(log, message, inline, level)
            if not level then
                level = log.notice
            end
            if inline then
                inline = ''
            else
                inline = "\n"
            end
            local out
            if 'stderr' == DNaConfig.log.path or 'stdout' == DNaConfig.log.path then
                out = io.output(io[DNaConfig.log.path])
            end
            if not DNaConfig.log.level then
                DNaConfig.log.level = 'notice'
            end
            if level >= log[DNaConfig.log.level] then
                out:write(message .. inline)
            end
        end
    })

    --- DNaction.motd() - Greets
    function DNaction.motd()
        DNaction.log(DNaction._VERSION .. ' (' .. _VERSION .. ', ' .. socket()._VERSION .. ")")
    end

    --- DNaction.shutdown()
    function DNaction.shutdown()
        DNaction.server():shutdown()
        DNaction.log("\nBye!")
    end

    --- DNaction.server() - Retrieves the only server
    -- @return DNaServer object
    function DNaction.server()
        if not DNaction['-SERVER-'] then
            if not pcall(function ()
                DNaction['-SERVER-'] = DNaServer.new(DNaConfig.host, DNaConfig.port)
                DNaction.log('Listening on ' .. DNaction['-SERVER-'].host .. ':' .. DNaction['-SERVER-'].port, nil, DNaction.log.warning)
            end) then
                error{
                    code = 2
                }
            end
        end
        return DNaction['-SERVER-']
    end

    --- DNaction.agent() - Picks a random agent
    -- @return DNaAgent object
    function DNaction.agent()
        local index, worker
        if not DNaction['-AGENTS-'] then
            DNaction['-AGENTS-'] = {}
            for index in ipairs(DNaConfig.upstreams) do
                DNaction['-AGENTS-'][index] = DNaAgent.new(DNaConfig.upstreams[index].host, DNaConfig.upstreams[index].port, DNaConfig.upstreams.mode, DNaConfig.upstreams.timeout)
            end
        end
        local counter = -1
        for index in ipairs(DNaction['-AGENTS-']) do
            if DNaction['-AGENTS-'][index].counter > counter then
                worker = DNaction['-AGENTS-'][index]
                counter = worker.counter
            end
        end
        return worker
    end
end)

pcall(function ()
    require 'luarocks.loader'
end)

DNaction.state, DNaction.error = pcall(function ()
    DNaction.motd()
    repeat
        DNaction.state, DNaction.error = pcall(function ()
            DNaction.agent():appease(DNaction.server():request())
        end)
        if false == DNaction.state and 255 ~= DNaction.error.code then
            break
        end
    until nil
    DNaction.shutdown()
end)
if not DNaction.state then
    if 1 == DNaction.error.code then
        DNaction.log(' [HALT] Extension `LuaSocket` required.', nil, DNaction.log.error)
    elseif 2 == DNaction.error.code then
        DNaction.log(' [HALT] Failed to bind ' .. DNaConfig.host .. ':' .. DNaConfig.port .. '.', nil, DNaction.log.error)
    end
    os.exit(DNaction.error.code)
end
