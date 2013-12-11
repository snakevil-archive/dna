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
    local self, socket = setmetatable({}, DNaServer), require('socket')
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
            code = -1
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

return DNaServer
