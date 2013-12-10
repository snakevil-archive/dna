#!/usr/bin/env lua

require 'luarocks.loader'

local config = {
    ['lhost'] = '127.0.0.1',
    ['lport'] = 1053,
    ['rhost'] = '20.13.5.8',
    ['rport'] = 53,
    ['timeout'] = 3
}

DNaction = {
    ['_VERSION'] = 'DNaction 0.0.1-alpha',
    ['LOG_DEBUG'] = 'debug',
    ['LOG_NOTICE'] = 'notice',
    ['LOG_WARNING'] = 'warning',
    ['LOG_ERROR'] = 'error',
    ['log'] = function (msg, level, inline)
        if not level then
            level = DNaction.LOG_NOTICE
        end
        if not inline then
            inline = "\n"
        else
            inline = ''
        end
        io.output(io.stderr):write(tostring(msg) .. inline)
    end
}

-- use `LuaSocket`
if not pcall(function ()
    DNaction._SOCKET = require('socket')
    DNaction.log(DNaction._VERSION .. ' (' .. _VERSION .. ', ' .. DNaction._SOCKET._VERSION .. ")\n")
end) then
    DNaction.log(' [HALT] Extension `LuaSocket` required.', DNaction.LOG_ERROR)
    os.exit(255)
end

-- prepare proxy server
if not pcall(function ()
    local socket = DNaction._SOCKET
    DNaction._SERVER, DNaction._AGENT = socket.udp(), socket.udp()
    DNaction._SERVER:settimeout(0)
    assert(DNaction._SERVER:setsockname(config['lhost'], config['lport']))
    local host, port = DNaction._SERVER:getsockname()
    DNaction.log(' Listening on ' .. socket.dns.tohostname(host) .. ':' .. port .. "\n")
    DNaction._AGENT:settimeout(config['timeout'])
end) then
    DNaction.log(' [HALT] Failed to bind ' .. config['lhost'] .. ':' .. config['lport'] .. '.', DNaction.LOG_ERROR)
    os.exit(1)
end

-- process requests
pcall(function ()
    local socket, server, agent = DNaction._SOCKET, DNaction._SERVER, DNaction._AGENT
    local req, resp, phost, pport
    repeat
        req, phost, pport = server:receivefrom()
        if req then
            DNaction.log(socket.dns.tohostname(phost) .. ': ')
            if not pcall(function ()
                assert(agent:getpeername())
            end) then
                agent:setpeername(config['rhost'], config['rport'])
            end
            agent:send(req)
            resp = agent:receive()
            server:sendto(resp, phost, pport)
        end
        socket.sleep(0.01)
    until nil
end)

-- bye
DNaction._SERVER:close()
DNaction._AGENT:close()
DNaction.log("\nbye!")
os.exit()
