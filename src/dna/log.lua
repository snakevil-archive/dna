local DnaLogPath, DnaLogLevel = 'stderr', 5

local DnaLog = setmetatable({
    DEBUG = 7,
    INFO = 6,
    NOTICE = 5,
    WARNING = 4,
    ERROR = 3,
    CRITICAL = 2,
    ALERT = 1,
    EMERGENCY = 0
}, {
    --- DnaLog() - Logs messages
    -- @param message What to be logged
    -- @param level Priority of the message
    -- @param inline Whether append a newline automatically
    -- @param level Severity
    -- @param code Exit code on EMERGENCY
    __call = function (log, message, inline, level, code)
        if not level then
            level = DnaLogLevel
        end
        if inline then
            inline = ''
        else
            inline = "\n"
        end
        local out, header
        if 'stderr' == DnaLogPath or 'stdout' == DnaLogPath then
            out = io[DnaLogPath]
        else
            out = io.open(DnaLogPath, 'a+')
        end
        if log.DEBUG == level then
            header = '  [DEBUG] '
        elseif log.INFO == level then
            header = '   [INFO] '
        elseif log.NOTICE == level then
            header = ' [NOTICE] '
        elseif log.WARNING == level then
            header = '[WARNING] '
        elseif log.ERROR == level then
            header = '[ ERROR ] '
        elseif log.CRITICAL == level then
            header = ' [ CRIT ] '
        elseif log.ALERT == level then
            header = '[ ALERT ] '
        elseif log.EMERGENCY == level then
            header = '[ EMERG ] '
            if not code then
                code = 0
            else
                code = math.floor(tonumber(code))
            end
        end
        if level <= DnaLogLevel then
            out:write(header .. message .. inline)
        end
        if log.EMERGENCY == level then
            os.exit(code)
        end
    end
})

return function (path, level)
    if 'string' == type(path) and #path then
        DnaLogPath = path
    end
    if 'string' == type(level) and #level and DnaLog[level:upper()] then
        DnaLogLevel = DnaLog[level:upper()]
    end
    return DnaLog
end
