local DnaConfig = {
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

local DNA = {
    _VERSION = 'DNA 0.0.1-alpha',
    host = DnaConfig.host,
    port = DnaConfig.port,
    log = {
        debug = 0,
        notice = 1,
        warning = 2,
        error = 3
    }
}

setmetatable(DNA, {
    --- DNA() - Configs and runs
    -- @param config Configuration table
    -- @return self object
    __call = function (DNA, config)
        local key, value
        if 'table' == type(config) then
            for key, value in pairs(config) do
                if 'log' ~= key then
                    DnaConfig[key] = value
                    if 'host' == key or 'port' == key then
                        DNA[key] = value
                    end
                elseif config.log.path then
                    DnaConfig.log.path = config.log.path
                elseif config.log.level then
                    DnaConfig.log.level = config.log.level
                end
            end
        end
        local state, fault = pcall(function ()
            DNA.motd()
            repeat
                state, fault = pcall(function ()
                    DNA.agent():appease(DNA.server():request())
                end)
                if false == state then
                    if 'table' ~= type(fault) then
                        DNA.log(' [WARNING] ' .. fault, nil, DNA.log.warning)
                        break
                    elseif -1 ~= fault.code then
                        error{
                            code = fault.code
                        }
                    end
                end
            until nil
            DNA.shutdown()
        end)
        if not state then
            if 'table' ~= type(fault) then
                DNA.log(' [HALT] ' .. fault, nil, DNA.log.error)
            elseif 1 == fault.code then
                DNA.log(' [HALT] Extension `LuaSocket` required.', nil, DNA.log.error)
            elseif 2 == fault.code then
                DNA.log(' [HALT] Failed to bind ' .. DNA.host .. ':' .. DNA.port .. '.', nil, DNA.log.error)
            end
            os.exit(fault.code)
        end
    end
})

setmetatable(DNA.log, {
    --- DNA.log() - Logs messages
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
        if 'stderr' == DnaConfig.log.path or 'stdout' == DnaConfig.log.path then
            out = io.output(io[DnaConfig.log.path])
        end
        if not DnaConfig.log.level then
            DnaConfig.log.level = 'notice'
        end
        if level >= log[DnaConfig.log.level] then
            out:write(message .. inline)
        end
    end
})

--- DNA.motd() - Greets
function DNA.motd()
    if not pcall(function ()
        DNA.log(DNA._VERSION .. ' (' .. _VERSION .. ', ' .. require('socket')._VERSION .. ")", nil, DNA.log.warning)
    end) then
        error{
            code = 1
        }
    end
end

--- DNA.shutdown()
function DNA.shutdown()
    DNA.server():shutdown()
    DNA.log(': Bye!')
end

local DnaServer
--- DNA.server() - Retrieves the only server
-- @return DnaServer object
function DNA.server()
    if not DnaServer then
        if not pcall(function ()
            DnaServer = require('dna.server')(
                DNA.host,
                DNA.port
            )
            DNA.log('Listening on ' .. DnaServer.host .. ':' .. DnaServer.port, nil, DNA.log.warning)
        end) then
            error{
                code = 2
            }
        end
    end
    return DnaServer
end

local DnaAgents
--- DNA.agent() - Picks a random agent
-- @return DNaAgent object
function DNA.agent()
    local index, worker
    if not DnaAgents then
        DnaAgents = {}
        for index in ipairs(DnaConfig.upstreams) do
            DnaAgents[index] = require('dna.agent')(
                DnaConfig.upstreams[index].host,
                DnaConfig.upstreams[index].port,
                DnaConfig.upstreams.mode,
                DnaConfig.upstreams.timeout
            )
        end
    end
    local counter = -1
    for index in ipairs(DnaAgents) do
        if DnaAgents[index].counter > counter then
            worker = DnaAgents[index]
            counter = worker.counter
        end
    end
    return worker
end

return DNA
