local LuaSocket = require('socket')
local DnaServerSocket

local DnaServer = {}
DnaServer.__index = DnaServer

setmetatable(DnaServer, {
    __index = require('dna.reporter'),
    --- DnaServer() - Alias of `DnaServer.new()`.
    __call = function (server, ... )
        return server.new(...)
    end
})
--- DnaServer.new() - Creates a server
-- @param host Address to bind
-- @param port Port to listen
-- @param listener Object to listen events report
-- @return DnaServer object
function DnaServer.new(host, port, listener)
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
    local self = setmetatable({}, DnaServer):addListener(listener)
    self:report('dna.server.setup', {
        host = host,
        port = port
    })
    DnaServerSocket = LuaSocket.udp()
    DnaServerSocket:settimeout(60)
    local state, fault = DnaServerSocket:setsockname(host, port)
    if not state then
        self:report('dna.server.setup.fail', {
            host = host,
            port = port,
            reason = fault
        })
    else
        self.host, self.port = DnaServerSocket:getsockname()
        self.host = LuaSocket.dns.tohostname(self.host)
        self:report('dna.server.setup.done', self)
    end
    return self
end

--- DnaServer:shutdown() - Shutdowns the server
function DnaServer:shutdown()
    self:report('dna.server.shutdown', self)
    DnaServerSocket:close()
    self:report('dna.server.shutdown.done')
end

--- DnaServer:request() - Receives a new request
-- @return nil or request object
function DnaServer:request()
    local req, phost, pport = DnaServerSocket:receivefrom()
    local request = {
        server = self,
        host = phost,
        port = pport,
        blob = req
    }
    if not req then
        self:report('dna.server.await')
    else
        self:report('dna.server.accept', request)
    end
    return request
end

--- DnaServer:request() - Responds the current request
-- @param response Response object
function DnaServer:respond(response)
    if response then
        self:report('dna.server.touch', response)
        local state, fault = DnaServerSocket:sendto(response.blob, response.host, response.port)
        if not state then
            response.reason = fault
            self:report('dna.server.touch.fail', response)
        else
            self:report('dna.server.touch.done', response)
        end
    end
end

return DnaServer
