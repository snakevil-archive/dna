local DNaConfig = {
    host = '127.0.0.1',
    port = 53,
    mode = 'tcp',
    timeout = 3,
    upstreams = {
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

local DNaction = {
    _VERSION = 'DNaction 0.0.1-alpha',
    host = DNaConfig.host,
    port = DNaConfig.port,
    log = {
        debug = 0,
        notice = 1,
        warning = 2,
        error = 3
    }
}

setmetatable(DNaction, {
    --- DNaction() - Configs and runs
    -- @param config Configuration table
    -- @return self object
    __call = function (DNaction, config)
        local key, value
        if 'table' == type(config) then
            for key, value in pairs(config) do
                if 'log' ~= key then
                    DNaConfig[key] = value
                    if 'host' == key or 'port' == key then
                        DNaction[key] = value
                    end
                elseif config.log.path then
                    DNaConfig.log.path = config.log.path
                elseif config.log.level then
                    DNaConfig.log.level = config.log.level
                end
            end
        end
        local state, fault = pcall(function ()
            DNaction.motd()
            repeat
                state, fault = pcall(function ()
                    DNaction.agent():appease(DNaction.server():request())
                end)
                if false == state then
                    if 'table' ~= type(fault) then
                        DNaction.log(' [WARNING] ' .. fault, nil, DNaction.log.warning)
                        break
                    elseif -1 ~= fault.code then
                        error{
                            code = fault.code
                        }
                    end
                end
            until nil
            DNaction.shutdown()
        end)
        if not state then
            if 'table' ~= type(fault) then
                DNaction.log(' [HALT] ' .. fault, nil, DNaction.log.error)
            elseif 1 == fault.code then
                DNaction.log(' [HALT] Extension `LuaSocket` required.', nil, DNaction.log.error)
            elseif 2 == fault.code then
                DNaction.log(' [HALT] Failed to bind ' .. DNaction.host .. ':' .. DNaction.port .. '.', nil, DNaction.log.error)
            end
            os.exit(fault.code)
        end
    end
})

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
    if not pcall(function ()
        DNaction.log(DNaction._VERSION .. ' (' .. _VERSION .. ', ' .. require('socket')._VERSION .. ")", nil, DNaction.log.warning)
    end) then
        error{
            code = 1
        }
    end
end

--- DNaction.shutdown()
function DNaction.shutdown()
    DNaction.server():shutdown()
    DNaction.log(': Bye!')
end

local DNaServer
--- DNaction.server() - Retrieves the only server
-- @return DNaServer object
function DNaction.server()
    if not DNaServer then
        if not pcall(function ()
            DNaServer = require('dnaction.server').new(DNaction.host, DNaction.port)
            DNaction.log('Listening on ' .. DNaServer.host .. ':' .. DNaServer.port, nil, DNaction.log.warning)
        end) then
            error{
                code = 2
            }
        end
    end
    return DNaServer
end

local DNaAgents
--- DNaction.agent() - Picks a random agent
-- @return DNaAgent object
function DNaction.agent()
    local index, worker
    if not DNaAgents then
        DNaAgents = {}
        for index in ipairs(DNaConfig.upstreams) do
            DNaAgents[index] = require('dnaction.agent').new(DNaConfig.upstreams[index].host, DNaConfig.upstreams[index].port, DNaConfig.upstreams.mode, DNaConfig.upstreams.timeout)
        end
    end
    local counter = -1
    for index in ipairs(DNaAgents) do
        if DNaAgents[index].counter > counter then
            worker = DNaAgents[index]
            counter = worker.counter
        end
    end
    return worker
end

return DNaction
