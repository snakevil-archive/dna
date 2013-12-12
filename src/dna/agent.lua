local LuaSocket = require('socket')
local DnaAgentSocket

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
-- @param listener Object to listen events report
-- @return DnaAgent object
function DnaAgent.new(host, port, mode, timeout, listener)
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
        mode = tostring(mode):lower()
    else
        mode = mode:lower()
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
    if 'table' == type(listener) then
        self.hq = listener
    end
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
    local state, fault, partial
    self:report('dna.agent.setup', self)
    DnaAgentSocket, fault = LuaSocket.connect(self.host, self.port)
    if not DnaAgentSocket then
        self:report('dna.agent.setup.fail', {
            agent = self,
            reason = fault
        })
        return
    end
    self:report('dna.agent.setup.done', self)
    DnaAgentSocket:settimeout(0)
    query = string.char(0, 28) .. query .. "\n"
    self:report('dna.agent.query', {
        agent = self,
        query = query
    })
    state, fault = DnaAgentSocket:send(query)
    if not state then
        self:report('dna.agent.query.fail', {
            agent = self,
            query = query,
            reason = fault
        })
        return
    end
    DnaAgentSocket:shutdown('send')
    local sockets = LuaSocket.select({DnaAgentSocket}, {})
    state, fault, partial = sockets[1]:receive('*a')
    if not state and 0 == #partial then
        self:report('dna.agent.query.fail', {
            agent = self,
            query = query,
            reason = fault
        })
        return
    end
    self:report('dna.agent.query.done', {
        agent = self,
        query = query,
        result = partial
    })
    return partial:sub(3)
end

--- DnaAgent:udp() - Communicates in UDP
-- @param query Query blob
-- @return Result blob
function DnaAgent:udp(query)
    local state, fault
    if 0 == self.counter then
        self:report('dna.agent.setup', self)
        DnaAgentSocket = LuaSocket.udp()
        DnaAgentSocket:settimeout(self.timeout)
        state, fault = DnaAgentSocket:setpeername(self.host, self.port)
        if not state then
            self:report('dna.agent.setup.fail', {
                agent = self,
                reason = fault
            })
            return
        end
        self:report('dna.agent.setup.done', self)
    end
    self:report('dna.agent.query', {
        agent = self,
        query = query
    })
    state, fault = DnaAgentSocket:send(query)
    if not state then
        self:report('dna.agent.query.fail', {
            agent = self,
            query = query,
            reason = fault
        })
        return
    end
    state, fault = DnaAgentSocket:receive()
    if not state then
        self:report('dna.agent.query.fail', {
            agent = self,
            query = query,
            reason = fault
        })
        return
    end
    self:report('dna.agent.query.done', {
        agent = self,
        query = query,
        result = state
    })
    return state
end

--- DnaAgent:appease() - Adapts the query
-- @param request Request object
function DnaAgent:appease(request)
    if 'table' ~= type(request) or not request.blob then
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

--- DnaAgent:report() - Reports event
-- @param event Active event name
-- @param context Table of context information
function DnaAgent:report(event, context)
    if self.hq then
        self.hq:fire(event, context)
    end
end

return DnaAgent
