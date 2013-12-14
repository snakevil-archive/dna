local DnaGetopt = setmetatable({
    ALONE = '',
    OPTIONAL = '?',
    REQUIRED = ':'
}, {
    --- DnaGetopt() - Gets options
    -- @param args Arguments passed in command line
    -- @param shorts String of short options like 'getopt (3)' in ANSI C
    -- @param longs Table of long options
    -- @return Table of recognized result
    __call = function (getopt, args, shorts, longs)
        if 'table' ~= type(args) then
            args = {args}
        end
        if 'string' ~= type(shorts) then
            shorts = tostring(shorts)
        end
        if 'table' ~= type(longs) then
            longs = {}
        end
        local key, value
        for key, value in shorts:gmatch('(%a)(:?)') do
            if ':' == value then
                longs[key] = getopt.REQUIRED
            else
                longs[key] = getopt.ALONE
            end
        end

        return coroutine.wrap(function ()
            local yield, index, jndex = coroutine.yield, 1, 0
            local arg, opt, val
            while index <= #args do
                arg, index = args[index], 1 + index
                if '--' == arg then -- options end
                    break
                elseif '-' ~= arg:sub(1, 1) then -- not options
                    index = index - 1
                    break
                elseif '-' == arg:sub(2, 2) then -- long option
                    opt, val = arg:match('^%-%-([^=]*)=(.*)$')
                    if not opt then
                        opt = arg:sub(3)
                    end
                    if not longs[opt] then -- unknown
                        yield('?', opt)
                    elseif getopt.ALONE == longs[opt] then -- alone
                        yield(opt, true)
                    elseif val then -- (either optional or required) with inline value
                        yield(opt, val)
                    else -- (either optional or required) (without inline value)
                        if index > #args then -- no more arg
                            if getopt.OPTIONAL == longs[opt] then
                                yield(opt, false)
                            else
                                yield(':', opt)
                            end
                        end
                        arg = args[index]
                        if '-' == arg:sub(1, 1) then -- following another option
                            if getopt.OPTIONAL == longs[opt] then
                                yield(opt, false)
                            else
                                yield(':', opt)
                            end
                        else -- following regular arg
                            yield(opt, arg)
                            index = 1 + index
                        end
                    end
                else -- (short option)
                    for jndex = 2, #arg do
                        opt = arg:sub(jndex, jndex)
                        if not longs[opt] then -- unkown
                            yield('?', opt)
                        elseif getopt.ALONE == longs[opt] then -- alone
                            yield(opt, true)
                        elseif getopt.OPTIONAL == longs[opt] then -- optional
                            if jndex ~= #arg then -- with inline value
                                yield(opt, arg:sub(1 + jndex))
                                break
                            elseif index > #args or '-' == args[index]:sub(1, 1) then -- (without inline value) no more arg or following another option
                                yield(opt, false)
                            else -- (without inline value) following regular arg
                                yield(opt, args[index])
                                index = 1 + index
                            end
                        else -- (required)
                            if jndex ~= #arg then -- with inline value
                                yield(opt, arg:sub(1 + jndex))
                                break
                            elseif index > #args or '-' == args[index]:sub(1, 1) then -- (without inline value) no more arg or following another option
                                yield(':', opt)
                            else -- (without inline value) following regular arg
                                yield(opt, args[index])
                                index = 1 + index
                            end
                        end
                    end
                end
            end
            for index = index, #args do
                yield(false, args[index])
            end
        end)
    end
})

return DnaGetopt
