local DnaServer = {}
DnaServer.__index = DnaServer

setmetatable(DnaServer, {
    --- DnaServer() - Alias of `DnaServer.new()`.
    __call = function (server, ... )
        return server.new(...)
    end
})

--- DnaServer.new() - Creates a server
-- @param host Address to bind
-- @param port Port to listen
-- @return DnaServer object
function DnaServer.new(host, port)
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
    local self, socket = setmetatable({}, DnaServer), require('socket')
    self.conn = socket.udp()
    self.conn:settimeout(0)
    assert(self.conn:setsockname(host, port))
    self.host, self.port = self.conn:getsockname()
    self.host = socket.dns.tohostname(self.host)
    return self
end

--- DnaServer:shutdown() - Shutdowns the server
function DnaServer:shutdown()
    self.conn:close()
end

--- DnaServer:request() - Receives a new request
-- @return nil or request object
function DnaServer:request()
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

--- DnaServer:request() - Responds the current request
-- @param response Response object
function DnaServer:respond(response)
    if response then
        self.conn:sendto(response.blob, response.host, response.port)
    end
end

return DnaServer
