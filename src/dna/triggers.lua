return function (DNA)
    local DNSHosts = {}

    --- DNA.triggers['dna.setup']() - Handles 'dna.setup' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.setup'] = function (context, debugger)
        xpcall(function ()
            io.stdout:write(DNA._VERSION .. ' (' .. _VERSION .. ', ' .. require('socket')._VERSION .. ")\n")
        end, function ()
            debugger.log(': module \'LuaSocket\' missing', nil, debugger.log.EMERGENCY, 1)
        end)
    end

    --- DNA.triggers['dna.server.setup.fail']() - Handles 'dna.server.setup.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.setup.fail'] = function (context, debugger)
        debugger.log(': failed to bind \'' .. context.host .. '.' .. context.port .. '\' for ' .. context.reason, nil, debugger.log.EMERGENCY, 2)
    end

    --- DNA.triggers['dna.server.setup.done']() - Handles 'dna.server.setup.done' event
    -- @param server DnsServer object
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.setup.done'] = function (server, debugger)
        io.stdout:write(' listening on ' .. server.host .. '.' .. server.port .. "\n")
    end

    --- DNA.triggers['dna.server.accept']() - Handles 'dna.server.accept' event
    -- @param request Request object
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.accept'] = function (request, debugger)
        local domain = request.blob:sub(14, -5):gsub('[' .. string.char(3, 6) .. ']', '.')
        debugger.log(request.host .. '.' .. request.port .. ': query \'' .. domain .. '\'', nil, debugger.log.NOTICE)
    end

    --- DNA.triggers['dna.agent.setup.fail']() - Handles 'dna.agent.setup.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.agent.setup.fail'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': ' .. context.reason, nil, debugger.log.ALERT)
    end

    --- DNA.triggers['dna.agent.query']() - Handles 'dna.agent.query' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.agent.query'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': #' .. 1 + context.agent.counter .. ' send ' .. #context.query .. ' bytes', nil, debugger.log.INFO)
    end

    --- DNA.triggers['dna.agent.query.fail']() - Handles 'dna.agent.query.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.agent.query.fail'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': connection ' .. context.reason, nil, debugger.log.ERROR)
    end

    --- DNA.triggers['dna.agent.query.done']() - Handles 'dna.agent.query.done' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.agent.query.done'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': #' .. 1 + context.agent.counter .. ' receive ' .. #context.result .. ' bytes', nil, debugger.log.INFO)
    end

    --- DNA.triggers['dna.server.touch']() - Handles 'dna.server.touch' event
    -- @param response Response object
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.touch'] = function (response, debugger)
        local match, pattern = '', string.char(192, 46, 0, 1, 0, 1, 0, 0, 46, 46, 0, 4, 46, 46, 46, 46) -- 0xC0 .(unknown) 0x000100010000 ..(TTL) 0x0004 ....(IP)
        DNSHosts = {}
        for match in response.blob:gmatch(pattern) do
            DNSHosts[1 + #DNSHosts] = string.format('%d.%d.%d.%d', match:byte(-4, -1))
        end
    end

    --- DNA.triggers['dna.server.touch.fail']() - Handles 'dna.server.touch.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.touch.fail'] = function (context, debugger)
        debugger.log(context.host .. '.' .. context.port .. ': ' .. context.reason, nil, debugger.log.ERROR)
    end

    --- DNA.triggers['dna.server.touch.done']() - Handles 'dna.server.touch.done' event
    -- @param response Response object
    -- @param debugger DnaLogger object
    DNA.triggers['dna.server.touch.done'] = function (response, debugger)
        debugger.log(response.host .. '.' .. response.port .. ': got ' .. #DNSHosts .. ' records', nil, debugger.log.NOTICE)
    end

    --- DNA.triggers['dna.shutdown']() - Handles 'dna.shutdown' event
    -- @param server DnsServer object
    -- @param debugger DnaLogger object
    DNA.triggers['dna.shutdown'] = function (server, debugger)
        server:shutdown()
        io.stdout:write(": bye!\n")
    end

end
