local DnaServer, DnaAgents

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

local DNA = setmetatable({
        _VERSION = 'DNA 0.0.1-alpha',
        host = DnaConfig.host,
        port = DnaConfig.port,
        triggers = {}
    }, {
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
            local listener = require('dna.listener')(DNA.triggers, require('dna.logger')(DnaConfig.log.path, DnaConfig.log.level))
            DNA.serve(listener)
        end
    })

--- DNA.serve() - Serves as a daemon
-- @param listener Event listener
function DNA.serve(listener)
    listener:fire('dna.setup')
    local server = DNA.server(listener)
    repeat
        DNA.agent(listener):appease(server:request())
    until nil
    listener:fire('dna.shutdown', server)
end

--- DNA.server() - Retrieves the only server
-- @param listener Event listener
-- @return DnaServer object
function DNA.server(listener)
    if not DnaServer then
        DnaServer = require('dna.server')(
            DNA.host,
            DNA.port,
            listener
        )
    end
    return DnaServer
end

--- DNA.agent() - Picks a random agent
-- @param listener Event listener
-- @return DNaAgent object
function DNA.agent(listener)
    local index, worker, counter
    if not DnaAgents then
        DnaAgents = {}
        for index in ipairs(DnaConfig.upstreams) do
            DnaAgents[index] = require('dna.agent')(
                DnaConfig.upstreams[index].host,
                DnaConfig.upstreams[index].port,
                DnaConfig.mode,
                DnaConfig.timeout,
                listener
            )
        end
    end
    for index in ipairs(DnaAgents) do
        if not counter or DnaAgents[index].counter < counter then
            worker = DnaAgents[index]
            counter = worker.counter
        end
    end
    return worker
end

pcall(function ()
    require('dna.triggers')(DNA)
end)

return DNA
