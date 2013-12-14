local DnaRouteLifetime, DnaRouteGC, DnaRouteTable = 900, os.time(), {} -- lifetime of dna cache of modern browsers is 10 mins

local DnaRoute = {}
DnaRoute.__index = DnaRoute

setmetatable(DnaRoute, {
    __index = require('dna.reporter'),
    --- DnaRoute() - Alias of `DnaRoute.new()`.
    __call = function (route, ... )
        return route.new(...)
    end
})

--- DnaRoute.new() - Creates a route operator
-- @param gateway Gateway of VPN
-- @param tunnel Table of agents hosts
-- @param listener Object to listen events report
-- @return DnaRoute object
function DnaRoute.new(gateway, tunnel, listener)
    local ostype
    if os.execute() then
        _, _, ostype = os.execute('route > /dev/null 2>&1')
        if 64 == ostype then
            ostype = 'bsd'
        elseif ostype then
            ostype = 'gnu'
        end
    end
    local self = setmetatable({
        lifetime = DnaRouteLifetime,
        gateway = gateway,
        type = ostype
    }, DnaRoute):addListener(listener)
    self:report('dna.route.setup', self)
    if not self.gateway or not self.type then
        self:report('dna.route.setup.fail', self)
    else
        self:report('dna.route.setup.done', self)
        if 'table' == type(tunnel) and #tunnel then
            self:tunnel(tunnel)
        end
    end
    return self
end

--- DnaRoute:fire() - Fires an event
-- @param event Name of the active event
-- @param context Table of context informations
function DnaRoute:fire(event, context)
    if self.gateway and self.type and 'dna.server.touch' == event then
        local index, now, expiration = 0, os.time(), self.lifetime + os.time()
        for index = 1, #context.records do
            if DnaRouteTable[context.records[index]] then
                self:change(context.records[index], expiration)
            else
                self:add(context.records[index], expiration)
            end
        end
        if now + self.lifetime > DnaRouteGC then
            local routes = {}
            for index, expiration in pairs(DnaRouteTable) do
                if now > expiration then
                    routes[1 + #routes] = index
                end
            end
            self:report('dna.route.gc', routes)
            for index = 1, #routes do
                self:delete(routes[index])
            end
        end
    end
    return self:report(event, context)
end

--- DnaRoute:add() - Adds a route rule
-- @param target Rule target
-- @param expiration Time to delete the rule
-- @return DnaRoute object
function DnaRoute:add(target, expiration)
    local context = {
        target = target,
        expiration = expiration,
        command = 'route add -host ' .. target
    }
    if 'gnu' == self.type then
        context.command = context.command .. ' gw'
    end
    context.command = context.command .. ' ' .. self.gateway .. ' > /dev/null 2>&1'
    self:report('dna.route.add', context)
    if not os.execute(context.command) then
        return self:report('dna.route.add.fail', context)
    end
    DnaRouteTable[target] = expiration
    return self:report('dna.route.add.done', context)
end

--- DnaRoute:change() - Delays to delete a route rule
-- @param target Rule target
-- @param expiration Time to delete the rule
-- @return DnaRoute object
function DnaRoute:change(target, expiration)
    local context = {
        target = target,
        expiration = expiration
    }
    self:report('dna.route.change', context)
    DnaRouteTable[target] = expiration
    return self:report('dna.route.change.done', context)
end

--- DnaRoute:delete() - Deletes a route rule
-- @param target Rule target
-- @return DnaRoute object
function DnaRoute:delete(target)
    local context = {
        target = target,
        expiration = expiration,
        command = 'route delete -host ' .. target
    }
    context.command = context.command .. ' > /dev/null 2>&1'
    self:report('dna.route.delete', context)
    if not os.execute(context.command) then
        return self:report('dna.route.delete.fail', context)
    end
    DnaRouteTable[target] = nil
    return self:report('dna.route.delete.done', context)
end

--- DnaRoute:tunnel() - Routes agents
-- @param tunnel Table of agents hosts
function DnaRoute:tunnel(tunnel)
    local context, index
    for index = 1, #tunnel do
        context = {
            target = tunnel[index],
            command = 'route add -host ' .. tunnel[index]
        }
        if 'gnu' == self.type then
            context.command = context.command .. ' gw'
        end
        context.command = context.command .. ' ' .. self.gateway .. ' > /dev/null 2>&1'
        self:report('dna.route.tunnel', context)
        if not os.execute(context.command) then
            self:report('dna.route.tunnel.fail', context)
        else
            self:report('dna.route.tunnel.done', context)
        end
    end
end

return DnaRoute
