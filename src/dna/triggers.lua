local DNSHosts, out = {}, io.stdout

--- version() - Prints the version
    -- @param DNA object
local function version(DNA)
    xpcall(function ()
        out:write(DNA._VERSION, ' (', _VERSION, ', ', require('socket')._VERSION, ")\n")
    end, function ()
        debugger.log(': module \'LuaSocket\' missing', nil, debugger.log.EMERGENCY, 1)
    end)
end

--- copyright() - Prints the copyright
local function copyright()
    local year = os.date('%Y')
    if '2013' ~= year then
        year = '2013-' .. year
    end
    out:write([=[

Copyright (C) ]=], year, [=[ Snakevil Zen.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written and Maintained by Snakevil Zen.
Report bugs to <https://github.com/snakevil/dna/issues/new>.
]=])
end

return {

    --- DNA.triggers['dna.help']() - Handles 'dna.help' event
    -- @param DNA object
    -- @param debugger DnaLogger object
    ['dna.help'] = function (DNA, debugger)
        version(DNA)
        out:write([=[
Usages: dna [OPTIONS] [--] gateway
Serve as a DNSd (proxy) to maintain routes automatically.

Mandatory arguments to long options are mandatory for short options too.

  -d, --debug                   run in debug mode (log completely), conflict
                                with '--quiet' '--silence' and '--verbose'
  -E, --stderr                  log to STDERR
  -G, --google                  aka '-u 8.8.8.8 -u 8.8.4.4', conflict
                                with '--upstream' '--server' and '--opendns'
  -h, --host=HOST               HOST to listen on, default: *
  -l, --log[=FILE]              FILE to log, the STDERR would be used on omitted
  -L, --local                   aka '-h 127.0.0.1'
  -m, --mode=MODE               MODE to communicate remote servers,
                                'tcp' or 'udp', default: tcp
  -O, --opendns                 aka '-u 208.67.222.222 -u 208.67.220.220',
                                conflict with '--upstream' '--server' and
                                '--google'
  -p, --port=PORT               PORT to listen on, default: 53
  -s, --quiet,                  suppress logging unless interrupted
      --silence
  -S, --stdout                  log to STDOUT
  -T, --tcp                     aka '-m tcp', conflict with '--udp'
  -u, --upstream=HOST[:PORT],   HOST as one of remote servers, PORT default: 53,
      --server=HOST[:PORT]      conflict with '--google' and '--opendns'
  -U, --udp                     aka '-m udp', conflict with '--tcp'
  -v, --verbose                 log more details, conflict with '--debug'
                                '--quiet' and '--silence'
  -w, --timeout=SECS,           seconds to timeout the communication with
      --wait=SECS               remote servers, default: 3

  -?, --help                    display this help and exit
  -V, --version                 output version information and exit
]=])
        copyright()
        os.exit()
    end,

    --- DNA.triggers['dna.version']() - Handles 'dna.version' event
    -- @param DNA object
    -- @param debugger DnaLogger object
    ['dna.version'] = function (DNA, debugger)
        version(DNA)
        copyright()
        os.exit()
    end,

    --- DNA.triggers['dna.setup']() - Handles 'dna.setup' event
    -- @param DNA object
    -- @param debugger DnaLogger object
    ['dna.setup'] = function (DNA, debugger)
        version(DNA)
    end,

    --- DNA.triggers['dna.server.setup.fail']() - Handles 'dna.server.setup.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.server.setup.fail'] = function (context, debugger)
        debugger.log(': failed to bind \'' .. context.host .. '.' .. context.port .. '\' for ' .. context.reason, nil, debugger.log.EMERGENCY, 2)
    end,

    --- DNA.triggers['dna.server.setup.done']() - Handles 'dna.server.setup.done' event
    -- @param server DnsServer object
    -- @param debugger DnaLogger object
    ['dna.server.setup.done'] = function (server, debugger)
        out:write(' listening on ', server.host, '.', server.port, "\n")
    end,

    --- DNA.triggers['dna.server.accept']() - Handles 'dna.server.accept' event
    -- @param request Request object
    -- @param debugger DnaLogger object
    ['dna.server.accept'] = function (request, debugger)
        local domain = request.blob:sub(14, -5):gsub('[' .. string.char(3, 6) .. ']', '.')
        debugger.log(request.host .. '.' .. request.port .. ': query \'' .. domain .. '\'', nil, debugger.log.NOTICE)
    end,

    --- DNA.triggers['dna.agent.setup.fail']() - Handles 'dna.agent.setup.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.agent.setup.fail'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': ' .. context.reason, nil, debugger.log.ALERT)
    end,

    --- DNA.triggers['dna.agent.query']() - Handles 'dna.agent.query' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.agent.query'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': #' .. 1 + context.agent.counter .. ' send ' .. #context.query .. ' bytes', nil, debugger.log.INFO)
    end,

    --- DNA.triggers['dna.agent.query.fail']() - Handles 'dna.agent.query.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.agent.query.fail'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': connection ' .. context.reason, nil, debugger.log.ERROR)
    end,

    --- DNA.triggers['dna.agent.query.done']() - Handles 'dna.agent.query.done' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.agent.query.done'] = function (context, debugger)
        debugger.log('@DnaAgent-' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ': #' .. 1 + context.agent.counter .. ' receive ' .. #context.result .. ' bytes', nil, debugger.log.INFO)
    end,

    --- DNA.triggers['dna.server.touch']() - Handles 'dna.server.touch' event
    -- @param response Response object
    -- @param debugger DnaLogger object
    ['dna.server.touch'] = function (response, debugger)
        local match, pattern = '', '\192.\0\1\0\1\0\0..\0\4....' -- 0xC0 .(unknown) 0x000100010000 ..(TTL) 0x0004 ....(IP)
        DNSHosts = {}
        for match in response.blob:gmatch(pattern) do
            DNSHosts[1 + #DNSHosts] = string.format('%d.%d.%d.%d', match:byte(-4, -1))
        end
    end,

    --- DNA.triggers['dna.server.touch.fail']() - Handles 'dna.server.touch.fail' event
    -- @param context Table of event context
    -- @param debugger DnaLogger object
    ['dna.server.touch.fail'] = function (context, debugger)
        debugger.log(context.host .. '.' .. context.port .. ': ' .. context.reason, nil, debugger.log.ERROR)
    end,

    --- DNA.triggers['dna.server.touch.done']() - Handles 'dna.server.touch.done' event
    -- @param response Response object
    -- @param debugger DnaLogger object
    ['dna.server.touch.done'] = function (response, debugger)
        debugger.log(response.host .. '.' .. response.port .. ': got ' .. #DNSHosts .. ' records', nil, debugger.log.NOTICE)
    end,

    --- DNA.triggers['dna.shutdown']() - Handles 'dna.shutdown' event
    -- @param server DnsServer object
    -- @param debugger DnaLogger object
    ['dna.shutdown'] = function (server, debugger)
        server:shutdown()
        out:write(": bye!\n")
    end

}
