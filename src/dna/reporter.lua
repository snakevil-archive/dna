local DnaReporter = {}
DnaReporter.__index = DnaReporter

setmetatable(DnaReporter, {
    --- DnaReporter() - Alias of `DnaReporter.new()`.
    __call = function (reporter, ... )
        return reporter.new(...)
    end
})

--- DnaReporter.new() - Creates a reporter
-- @param events Table of events and handlers
-- @param debugger DNA object to debug
-- @return DnaReporter object
function DnaReporter.new(events, debugger)
    local self = {
        events = {},
        debugger = debugger
    }
    if 'table' == type(events) then
        local event, handler
        for event, handler in pairs(events) do
            if 'function' == type(handler) then
                self.events[event] = {
                    handler
                }
            end
        end
    end
    self = setmetatable(self, DnaReporter)
    return self
end

local rname, rcounter = '', 0
--- DnaReporter:fire() - Fires an event
-- @param event Name of the active event
-- @param context Table of context informations
function DnaReporter:fire(event, context)
    if self.debugger then
        if rname == event then
            rcounter = 1 + rcounter
        else
            rname = event
            rcounter = 1
        end
        if 4 > rcounter then
            self.debugger.log('@DnaReporter: ' .. event, nil, self.debugger.log.debug)
            if 3 == rcounter then
                self.debugger.log('@DnaReporter: (ignore duplicates)', nil, self.debugger.log.debug)
            end
        end
    end
    if self.events[event] then
        local i, handler
        for i, handler in ipairs(self.events[event]) do
            handler(context)
        end
    end
    return self
end

return DnaReporter
