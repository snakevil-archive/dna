return function (config, ... )
    local DnaConfigGetopt, out = require('dna.config.getopt'), io.stderr
    local options, optype = {
        cache = DnaConfigGetopt.REQUIRED,
        debug = DnaConfigGetopt.ALONE,
        stderr = DnaConfigGetopt.ALONE,
        google = DnaConfigGetopt.ALONE,
        host = DnaConfigGetopt.REQUIRED,
        log = DnaConfigGetopt.REQUIRED,
        ['local'] = DnaConfigGetopt.ALONE,
        mode = DnaConfigGetopt.REQUIRED,
        opendns = DnaConfigGetopt.ALONE,
        port = DnaConfigGetopt.REQUIRED,
        quiet = DnaConfigGetopt.ALONE,
        silence = DnaConfigGetopt.ALONE,
        stdout = DnaConfigGetopt.ALONE,
        tunnel = DnaConfigGetopt.ALONE,
        tcp = DnaConfigGetopt.ALONE,
        upstream = DnaConfigGetopt.REQUIRED,
        server = DnaConfigGetopt.REQUIRED,
        udp = DnaConfigGetopt.ALONE,
        verbose = DnaConfigGetopt.ALONE,
        timeout = DnaConfigGetopt.REQUIRED,
        wait = DnaConfigGetopt.REQUIRED,
        help = DnaConfigGetopt.ALONE,
        version = DnaConfigGetopt.ALONE
    }, 'config'
    local option, value
    for option, value in DnaConfigGetopt(arg, 'c:DEGh:l:Lm:Op:sStTu:Uvw:V', options) do
        if 'c' == option or 'cache' == option then
            config.cache = value
        elseif 'D' == option or 'debug' == option then
            config.log.level = 'debug'
        elseif 'E' == option or 'stderr' == option then
            config.log.path = 'stderr'
        elseif 'G' == option or 'google' == option then
            config.upstreams = {
                {
                    host = '8.8.8.8',
                    port = 53
                },
                {
                    host = '8.8.4.4',
                    port = 53
                }
            }
        elseif 'h' == option or 'host' == option then
            config.host = value
        elseif 'l' == option or 'log' == option then
            config.log.path = value
        elseif 'L' == option or 'local' == option then
            config.host = '127.0.0.1'
        elseif 'm' == option or 'mode' == option then
            config.mode = value
        elseif 'O' == option or 'opendns' == option then
            config.upstreams = {
                {
                    host = '208.67.222.222',
                    port = 53
                },
                {
                    host = '208.67.220.220',
                    port = 53
                }
            }
        elseif 'p' == option or 'port' == option then
            config.port = tonumber(value)
        elseif 's' == option or 'quiet' == option or 'silence' == option then
            config.log.level = 'emergency'
        elseif 'S' == option or 'stdout' == option then
            config.log.path = 'stdout'
        elseif 't' == option or 'tunnel' == option then
            config.tunnel = true
        elseif 'T' == option or 'tcp' == option then
            config.mode = 'tcp'
        elseif 'u' == option or 'upstream' == option or 'server' == option then
            option = {}
            option['host'], option['port'] = value:match('^([%w_%-%.]*):(%d*)$')
            if not option['host'] then
                option['host'] = value
                option['port'] = 53
            else
                option['port'] = tonumber(option['port'])
            end
            config.upstreams[1 + #config.upstreams] = option
        elseif 'U' == option or 'udp' == option then
            config.mode = 'udp'
        elseif 'v' == option or 'verbose' == option then
            config.log.level = 'info'
        elseif 'w' == option or 'timeout' == option or 'wait' == option then
            config.timeout = tonumber(value)
        elseif 'V' == option or 'version' == option then
            optype ='version'
        elseif '?' == option and '?' == value or 'help' == option then
            optype ='help'
        elseif '?' == option then
            out:write(': illegal option -- ' .. value .. "\n")
            return 'opterr'
        elseif ':' == option then
            out:write(': option requires an argument -- ' .. value .. "\n")
            return 'opterr'
        else
            config.gateway = value
        end
    end
    if 'config' ~= optype then
        return optype
    end
    return config
end
