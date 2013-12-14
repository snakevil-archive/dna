local DnaReporterHq = '-HQ-' .. math.random() .. '-'

local DnaReporter = {}
DnaReporter.__index = DnaReporter

--- DnaReporter:addListener() - Adds a listener to report
-- @param listener DnaListener object
-- @return DnaReporter object
function DnaReporter:addListener(listener)
    if 'table' == type(listener) then
        self[DnaReporterHq] = listener
    end
    return self
end

--- DnaAgent:report() - Reports event
-- @param event Active event name
-- @param context Table of context information
-- @return DnaReporter object
function DnaReporter:report(event, context)
    if self[DnaReporterHq] then
        self[DnaReporterHq]:fire(event, context)
    end
    return self
end

return DnaReporter
