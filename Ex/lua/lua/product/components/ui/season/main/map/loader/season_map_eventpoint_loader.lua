---@class SeasonMapEventPointLoader:Object
_class("SeasonMapEventPointLoader", Object)
SeasonMapEventPointLoader = SeasonMapEventPointLoader

---@param loadType SeasonEventPointLoadType
function SeasonMapEventPointLoader:Constructor(loadType)
    ---@type SeasonQueue
    self._queue = SeasonQueue:New()
    ---@type table<number, SeasonMapEventPoint>
    self._eventpoints = {}
    ---@type SeasonEventPointLoadType
    self._loadMode = loadType
end

---@param eventpoint SeasonMapEventPoint
function SeasonMapEventPointLoader:LoadResource(eventpoint)
    local id = eventpoint:GetID()
    if self._eventpoints[id] then
        return
    end
    if self._loadMode == SeasonEventPointLoadType.Sync then
        self._queue:Enqueue(SeasonMapEventPointRequestSync:New(id, eventpoint:GetResName()))
    elseif self._loadMode == SeasonEventPointLoadType.Async then
        self._queue:Enqueue(SeasonMapEventPointRequestAsync:New(id, eventpoint:GetResName()))
    end
    self._eventpoints[id] = eventpoint
end

---@param eventpoint SeasonMapEventPoint
function SeasonMapEventPointLoader:InterruptAsyncLoad(eventpoint)
    self._queue:ForEach(
        function (r)
            ---@type SeasonMapEventPointRequestAsync
            local req = r
            if req:ID() == eventpoint:GetID() then
                if req:State() == SeasonEventPointLoadState.Wait then
                    req:Close()
                elseif req:State() == SeasonEventPointLoadState.Loading then
                    req:Dispose()
                end
            end
        end
    )
end

function SeasonMapEventPointLoader:Dispose()
    self._queue:ForEach(
        function(r)
            ---@type SeasonMapEventPointRequestAsync
            local req = r
            req:Close()
        end
    )
    self._queue:Clear()
    table.clear(self._eventpoints)
end

function SeasonMapEventPointLoader:Update()
    if self._queue:Count() <= 0 then
        return
    end
    if self._loadMode == SeasonEventPointLoadType.Sync then
        self._queue:ForEach(
            function(req)
                ---@type SeasonMapEventPointRequestSync
                local request = req
                request:Load()
                local id = request:ID()
                local eventpoint = self._eventpoints[id]
                eventpoint:OnShow(request)
            end
        )
        self._queue:Clear()
    elseif self._loadMode == SeasonEventPointLoadType.Async then
        self:_LoadPer()
    end
end

function SeasonMapEventPointLoader:_LoadPer()
    ---@type SeasonMapEventPointRequestAsync
    local req = self._queue:Peek()
    if req:State() == SeasonEventPointLoadState.Wait then
        req:Load()
        return
    end
    if req:State() == SeasonEventPointLoadState.Loading then
        return
    end
    if req:State() == SeasonEventPointLoadState.Finish then
        local id = req:ID()
        local eventpoint = self._eventpoints[id]
        eventpoint:OnShow(req)
        self._queue:Dequeue()
        self._eventpoints[id] = nil
        return
    end
    if req:State() == SeasonEventPointLoadState.Closed then
        self._queue:Dequeue()
        self._eventpoints[req:ID()] = nil
        return
    end
end