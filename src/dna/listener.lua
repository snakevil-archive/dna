local DnaListenerEvent, DnaListenerTimes = '', 0

local DnaListener = {}
DnaListener.__index = DnaListener

setmetatable(DnaListener, {
    --- DnaListener() - Alias of `DnaListener.new()`.
    __call = function (listener, ... )
        return listener.new(...)
    end
})

--- DnaListener.new() - Creates a listener
-- @param events Table of events and handlers
-- @param debugger DNA object to debug
-- @return DnaListener object
function DnaListener.new(events, debugger)
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
    self = setmetatable(self, DnaListener)
    return self
end

--- DnaListener:fire() - Fires an event
-- @param event Name of the active event
-- @param context Table of context informations
function DnaListener:fire(event, context)
    if self.debugger then
        if DnaListenerEvent == event then
            DnaListenerTimes = 1 + DnaListenerTimes
        else
            DnaListenerEvent = event
            DnaListenerTimes = 1
        end
        if 4 > DnaListenerTimes then
            self.debugger.log('@DnaListener: ' .. event, nil, self.debugger.log.DEBUG)
            if 3 == DnaListenerTimes then
                self.debugger.log('@DnaListener: (ignore duplicates)', nil, self.debugger.log.DEBUG)
            end
        end
    end
    if self.events[event] then
        local i, handler
        for i, handler in ipairs(self.events[event]) do
            handler(context, self.debugger)
        end
    end
    return self
end

return DnaListener
