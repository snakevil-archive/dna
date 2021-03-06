local out = io.stdout

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

--- ['dna.help']() - Handles 'dna.help' event
-- @param DNA object
-- @param debugger DnaLogger object
['dna.help'] = function (DNA, debugger)
    version(DNA)
    out:write([=[
Usage: dna [OPTIONS] [--] gateway
Serve as a DNSd (proxy) to maintain routes automatically.

Mandatory arguments to long options are mandatory for short options too.

  -c, --cache=SECS              seconds to cache queries, 0 means disable
                                caching, deafult: 600
  -D, --debug                   run in debug mode (log completely), conflict
                                with '--quiet' '--silence' and '--verbose'
  -E, --stderr                  log to STDERR
  -G, --google                  aka '-u 8.8.8.8 -u 8.8.4.4', conflict
                                with '--upstream' '--server' and '--opendns'
  -h, --host=HOST               HOST to listen on, default: *
  -l, --log=FILE                FILE to log
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
  -t, --tunnel                  communicate remote servers through gateway
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

--- ['dna.version']() - Handles 'dna.version' event
-- @param DNA object
-- @param debugger DnaLogger object
['dna.version'] = function (DNA, debugger)
    version(DNA)
    copyright()
    os.exit()
end,


--- ['dna.setup']() - Handles 'dna.setup' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.setup'] = function (context, debugger)
    version(context.DNA)

    local key, value

    local dump = coroutine.wrap(function ()
        local yield = coroutine.yield
        local key, value
        for key, value in pairs(context.config) do
            if 'upstreams' == key then
                for key = 1, #value do
                    yield('upstreams.' .. key, value[key]['host'] .. '.' .. value[key]['port'])
                end
            elseif 'log' == key then
                for key, value in pairs(value) do
                    yield('log.' .. key, value)
                end
            else
                yield(key, value)
            end
        end
    end)

    for key, value in dump do
        debugger.log('@config: ' .. key .. ' = ' .. tostring(value), nil, debugger.log.DEBUG)
    end
end,

--- ['dna.shutdown']() - Handles 'dna.shutdown' event
-- @param server DnaServer object
-- @param debugger DnaLogger object
['dna.shutdown'] = function (server, debugger)
    server:shutdown()
    out:write(": bye!\n")
end,


--- ['dna.server.setup.fail']() - Handles 'dna.server.setup.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.server.setup.fail'] = function (context, debugger)
    debugger.log(': failed to bind \'' .. context.host .. '.' .. context.port .. '\' for ' .. context.reason, nil, debugger.log.EMERGENCY, 2)
end,

--- ['dna.server.setup.done']() - Handles 'dna.server.setup.done' event
-- @param server DnaServer object
-- @param debugger DnaLogger object
['dna.server.setup.done'] = function (server, debugger)
    out:write(' listening on ', server.host, '.', server.port, "\n")
end,

--- ['dna.server.accept']() - Handles 'dna.server.accept' event
-- @param request Request object
-- @param debugger DnaLogger object
['dna.server.accept'] = function (request, debugger)
    debugger.log(request.host .. '.' .. request.port .. ': query \'' .. request.domain .. '\'', nil, debugger.log.NOTICE)
end,

--- ['dna.server.touch.fail']() - Handles 'dna.server.touch.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.server.touch.fail'] = function (context, debugger)
    debugger.log(context.host .. '.' .. context.port .. ': ' .. context.reason, nil, debugger.log.ERROR)
end,

--- ['dna.server.touch.done']() - Handles 'dna.server.touch.done' event
-- @param response Response object
-- @param debugger DnaLogger object
['dna.server.touch.done'] = function (response, debugger)
    debugger.log(response.host .. '.' .. response.port .. ': got ' .. #response.records .. ' records', nil, debugger.log.NOTICE)
end,


--- ['dna.agent.setup']() - Handles 'dna.agent.setup' event
-- @param agent DnaAgent object
-- @param debugger DnaLogger object
['dna.agent.setup'] = function (agent, debugger)
    debugger.log('@agent: prepare ' .. agent.host .. '.' .. agent.port .. '#' .. agent.mode .. '/' .. agent.timeout .. 's', nil, debugger.log.INFO)
end,

--- ['dna.agent.setup.fail']() - Handles 'dna.agent.setup.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.agent.setup.fail'] = function (context, debugger)
    debugger.log('@agent: ' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ' ' .. context.reason, nil, debugger.log.ALERT)
end,

--- ['dna.agent.setup.done']() - Handles 'dna.agent.setup.done' event
-- @param agent DnaAgent object
-- @param debugger DnaLogger object
['dna.agent.setup.done'] = function (agent, debugger)
    local conn = 'connected'
    if 0 < agent.counter then
        conn = 're-' .. conn
    end
    debugger.log('@agent: ' .. agent.host .. '.' .. agent.port .. '#' .. agent.mode .. ' ' .. conn, nil, debugger.log.INFO)
end,

--- ['dna.agent.query']() - Handles 'dna.agent.query' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.agent.query'] = function (context, debugger)
    debugger.log('@agent: ' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ' #' .. 1 + context.agent.counter .. ' send ' .. #context.query .. ' bytes', nil, debugger.log.INFO)
end,

--- ['dna.agent.query.fail']() - Handles 'dna.agent.query.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.agent.query.fail'] = function (context, debugger)
    debugger.log('@agent: ' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ' connection ' .. context.reason, nil, debugger.log.ERROR)
end,

--- ['dna.agent.query.done']() - Handles 'dna.agent.query.done' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.agent.query.done'] = function (context, debugger)
    debugger.log('@agent: ' .. context.agent.host .. '.' .. context.agent.port .. '#' .. context.agent.mode .. ' #' .. 1 + context.agent.counter .. ' receive ' .. #context.result .. ' bytes', nil, debugger.log.INFO)
end,


--- ['dna.cache.setup']() - Handles 'dna.cache.setup' event
-- @param cache DnaCache object
-- @param debugger DnaLogger object
['dna.cache.setup'] = function (cache, debugger)
    debugger.log('@cache: keep ' .. cache.lifetime .. ' seconds', nil, debugger.log.INFO)
end,

--- ['dna.cache.hit']() - Handles 'dna.cache.hit' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.cache.hit'] = function (context, debugger)
    debugger.log('@cache: hit before ' .. os.date('%T', context.expiration), nil, debugger.log.INFO)
end,


--- ['dna.route.setup.fail']() - Handles 'dna.route.setup.fail' event
-- @param route DnaRoute object
-- @param debugger DnaLogger object
['dna.route.setup.fail'] = function (route, debugger)
    local msg = 'shell'
    if not route.gateway then
        msg = 'gateway'
    end
    debugger.log('@route: disable for no ' .. msg, nil, debugger.log.ERROR)
end,

--- ['dna.route.setup.done']() - Handles 'dna.route.setup.done' event
-- @param route DnaRoute object
-- @param debugger DnaLogger object
['dna.route.setup.done'] = function (route, debugger)
    debugger.log('@route: ' .. route.type:upper() .. ' gateway ' .. route.gateway .. ' (every ' .. route.lifetime .. ' seconds)', nil, debugger.log.INFO)
end,

--- ['dna.route.gc']() - Handles 'dna.route.gc' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.gc'] = function (context, debugger)
    if 0 < #context then
        debugger.log('@route: about to clean ' .. #context .. ' out-dated', nil, debugger.log.INFO)
    end
end,

--- ['dna.route.add']() - Handles 'dna.route.add' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.add'] = function (context, debugger)
    debugger.log('@route: pass ' .. context.target .. ' until ' .. os.date('%T', context.expiration), nil, debugger.log.INFO)
    debugger.log('@route: (' .. context.command .. ')', nil, debugger.log.DEBUG)
end,

--- ['dna.route.add.fail']() - Handles 'dna.route.add.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.add.fail'] = function (context, debugger)
    debugger.log('@route: fail to pass ' .. context.target, nil, debugger.log.WARNING)
end,

--- ['dna.route.change']() - Handles 'dna.route.change' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.change'] = function (context, debugger)
    debugger.log('@route: re-pass ' .. context.target .. ' until ' .. os.date('%T', context.expiration), nil, debugger.log.INFO)
end,

--- ['dna.route.delete']() - Handles 'dna.route.delete' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.delete'] = function (context, debugger)
    debugger.log('@route: reject ' .. context.target, nil, debugger.log.INFO)
    debugger.log('@route: (' .. context.command .. ')', nil, debugger.log.DEBUG)
end,

--- ['dna.route.delete.fail']() - Handles 'dna.route.delete.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.delete.fail'] = function (context, debugger)
    debugger.log('@route: fail to reject ' .. context.target, nil, debugger.log.WARNING)
end,

--- ['dna.route.tunnel']() - Handles 'dna.route.tunnel' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.tunnel'] = function (context, debugger)
    debugger.log('@route: tunnel ' .. context.target, nil, debugger.log.INFO)
    debugger.log('@route: (' .. context.command .. ')', nil, debugger.log.DEBUG)
end,

--- ['dna.route.tunnel.fail']() - Handles 'dna.route.tunnel.fail' event
-- @param context Table of event context
-- @param debugger DnaLogger object
['dna.route.tunnel.fail'] = function (context, debugger)
    debugger.log('@route: fail to tunnel ' .. context.target, nil, debugger.log.WARNING)
end,

}
