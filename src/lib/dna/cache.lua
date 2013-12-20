local DnaServer
local DnaCacheTable = {}

local DnaCache = {}
DnaCache.__index = DnaCache

setmetatable(DnaCache, {
    __index = require('dna.reporter'),
    --- DnaCache() - Alias of `DnaCache.new()`.
    __call = function (server, ... )
        return server.new(...)
    end
})

--- DnaCache.new() - Creates a cache
-- @param lifetime Lifetime of a piece of cache in seconds
-- @param listener Object to listen events report
-- @return DnaCache object
function DnaCache.new(lifetime, listener)
    lifetime = tonumber(lifetime)
    if 0 > lifetime then
        lifetime = 0
    end
    local self = setmetatable({
        lifetime = lifetime
    }, DnaCache):addListener(listener)
    if 0 < lifetime then
        self:report('dna.cache.setup', self)
    end
    return self
end

--- DnaCache:hit() - Hits a request
-- @param request
-- @return request
function DnaCache:hit(request)
    if 0 < self.lifetime and request.blob then
        DnaServer = request.server
        request.server = self
        local key = request.domain .. request.type
        if not DnaCacheTable[key] then
            self:report('dna.cache.miss', request)
        elseif os.time() > DnaCacheTable[key].expiration then
            self:report('dna.cache.expired', request)
        else
            self:report('dna.cache.hit', DnaCacheTable[key])
            DnaServer:respond{
                host = request.host,
                port = request.port,
                blob = request.blob:sub(1, 2) .. DnaCacheTable[key].blob,
                records = DnaCacheTable[key].records
            }
            return
        end
    end
    return request
end

--- DnaCache:request() - Responds the current request
-- @param response Response object
function DnaCache:respond(response)
    if 0 < self.lifetime and response then
        local key = response.domain .. response.type
        DnaCacheTable[key] = {
            expiration = self.lifetime + os.time(),
            blob = response.blob:sub(3),
            records = response.records
        }
        self:report('dna.cache.update', DnaCacheTable[key])
        return DnaServer:respond(response)
    end
end

return DnaCache
