return function (DNA)

    --- DNA.triggers['dna.setup']() - Handles 'dna.setup' event
    DNA.triggers['dna.setup'] = function ()
        xpcall(function ()
            io.output(io.stderr):write(DNA._VERSION .. ' (' .. _VERSION .. ', ' .. require('socket')._VERSION .. ")\n")
        end, function ()
            DNA.log(': module \'LuaSocket\' missing', nil, DNA.log.error)
            os.exit(1)
        end)
    end

    --- DNA.triggers['dna.server.setup.fail']() - Handles 'dna.server.setup.fail' event
    -- @param context Table of event context
    DNA.triggers['dna.server.setup.fail'] = function (context)
        DNA.log(': failed to bind \'' .. context.host .. '.' .. context.port .. '\' for ' .. context.reason, nil, DNA.log.error)
        os.exit(2)
    end

    --- DNA.triggers['dna.server.setup.done']() - Handles 'dna.server.setup.done' event
    -- @param server DnsServer object
    DNA.triggers['dna.server.setup.done'] = function (server)
        DNA.log(': listening on ' .. server.host .. '.' .. server.port, nil, DNA.log.warning)
    end

    --- DNA.triggers['dna.server.accept']() - Handles 'dna.server.accept' event
    -- @param request Request object
    DNA.triggers['dna.server.accept'] = function (request)
        local domain = request.blob:sub(14, -5):gsub('[' .. string.char(3, 6) .. ']', '.')
        DNA.log(request.host .. '.' .. request.port .. ': query \'' .. domain .. '\'', nil, DNA.log.warning)
    end

    --- DNA.triggers['dna.agent.setup.fail']() - Handles 'dna.agent.setup.fail' event
    -- @param context Table of event context
    DNA.triggers['dna.agent.setup.fail'] = function (context)
        DNA.log('@DnaAgent#' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': ' .. context.reason, nil, DNA.log.error)
    end

    --- DNA.triggers['dna.agent.query']() - Handles 'dna.agent.query' event
    -- @param context Table of event context
    DNA.triggers['dna.agent.query'] = function (context)
        DNA.log('@DnaAgent#' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': send ' .. #context.query .. ' bytes')
    end

    --- DNA.triggers['dna.agent.query.fail']() - Handles 'dna.agent.query.fail' event
    -- @param context Table of event context
    DNA.triggers['dna.agent.query.fail'] = function (context)
        DNA.log('@DnaAgent#' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': connection ' .. context.reason, nil, DNA.log.error)
    end

    --- DNA.triggers['dna.agent.query.done']() - Handles 'dna.agent.query.done' event
    -- @param context Table of event context
    DNA.triggers['dna.agent.query.done'] = function (context)
        DNA.log('@DnaAgent#' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': receive ' .. #context.result .. ' bytes')
    end

    --- DNA.triggers['dna.server.touch']() - Handles 'dna.server.touch' event
    -- @param response Response object
    DNA.triggers['dna.server.touch'] = function (response)
        local hosts, match, pattern = {}, '', string.char(192, 46, 0, 1, 0, 1, 0, 0, 46, 46, 0, 4, 46, 46, 46, 46)
        for match in response.blob:gmatch(pattern) do
            hosts[1 + #hosts] = string.format('%d.%d.%d.%d', match:byte(-4, -1))
        end
    end

    --- DNA.triggers['dna.server.touch.fail']() - Handles 'dna.server.touch.fail' event
    -- @param context Table of event context
    DNA.triggers['dna.server.touch.fail'] = function (context)
        DNA.log(context.host .. '.' .. context.port .. ': ' .. context.reason, nil, DNA.log.error)
    end

    --- DNA.triggers['dna.server.touch.done']() - Handles 'dna.server.touch.done' event
    -- @param response Response object
    DNA.triggers['dna.server.touch.done'] = function (response)
        local quatity, match, pattern = 0, '', string.char(192, 46, 0, 1, 0, 1, 0, 0, 46, 46, 0, 4, 46, 46, 46, 46)
        for match in response.blob:gmatch(pattern) do
            quatity = 1 + quatity
        end
        DNA.log(response.host .. '.' .. response.port .. ': got ' .. quatity .. ' records', nil, DNA.log.warning)
    end

    --- DNA.triggers['dna.shutdown']() - Handles 'dna.shutdown' event
    -- @param server DnsServer object
    DNA.triggers['dna.shutdown'] = function (server)
        server:shutdown()
        DNA.log(': bye!')
    end

end
