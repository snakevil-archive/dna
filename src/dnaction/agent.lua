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
    self.conn = require('socket').tcp()
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
        self.conn = require('socket').udp()
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

return DNaAgent
