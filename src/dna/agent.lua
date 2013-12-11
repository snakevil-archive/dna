local DnaAgent = {
    mode = {
        tcp = 'tcp',
        udp = 'udp'
    }
}
DnaAgent.__index = DnaAgent

setmetatable(DnaAgent, {
    --- DnaAgent() - Alias of `DnaAgent.new()`.
    __call = function (agent, ... )
        return agent.new(...)
    end
})

--- DnaAgent.new() - Creates an agent
-- @param host Address of remote name server
-- @param port Port of remote name server
-- @param mode Connection mode to query
-- @param timeout Total communication time of the query
-- @return DnaAgent object
function DnaAgent.new(host, port, mode, timeout)
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
        mode = DnaAgent.mode.udp
    elseif 'string' ~= type(mode) then
        mode = string.lower(tostring(mode))
    else
        mode = string.lower(mode)
    end
    if DnaAgent.mode.tcp ~= mode and DnaAgent.mode.udp ~= mode then
        mode = DnaAgent.mode.udp
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
    }, DnaAgent)
    return self
end

--- DnaAgent:query() - Communicates the remote name server
-- @param query Query blob
-- @return Result blob
function DnaAgent:query(query)
    if not query then
        return nil
    elseif 'string' ~= type(query) then
        query = tostring(query)
    end
    if DnaAgent.mode.udp == self.mode then
        return self:udp(query)
    end
    return self:tcp(query)
end

--- DnaAgent:tcp() - Communicates in TCP
-- @param query Query blob
-- @return Result blob
function DnaAgent:tcp(query)
    self.conn = require('socket').tcp()
    self.conn:settimeout(self.timeout)
    assert(self.conn:connect(self.host, self.port))
    self.conn:send(string.char(0, 28) .. query)
    local result, rstat, rpart = self.conn:receive('*a')
    result = string.sub(result or rpart, 3)
    self.conn:close()
    return result
end

--- DnaAgent:udp() - Communicates in UDP
-- @param query Query blob
-- @return Result blob
function DnaAgent:udp(query)
    if 0 == self.counter then
        self.conn = require('socket').udp()
        self.conn:settimeout(self.timeout)
        assert(self.conn:setpeername(self.host, self.port))
    end
    self.conn:send(query)
    return self.conn:receive()
end

--- DnaAgent:appease() - Adapts the query
-- @param request Request object
function DnaAgent:appease(request)
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

return DnaAgent
