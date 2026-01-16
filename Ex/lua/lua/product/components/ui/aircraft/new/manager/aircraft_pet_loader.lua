--[[
    星灵模型异步加载器
]]
---@class AircraftPetLoader:Object
_class("AircraftPetLoader", Object)
AircraftPetLoader = AircraftPetLoader

function AircraftPetLoader:Init(onLoadingCountChanged)
    ---@type AircraftQueue
    self._queue = AircraftQueue:New()
    ---@type table<number,AircraftPet>
    self._pets = {}

    local req = ResourceManager:GetInstance():SyncLoadAsset("AircraftPetSelectAnimRef.prefab", LoadType.GameObject)
    --点击星灵时的描边动画，所有星灵共享同1个clip，显示星灵时传入
    self._clickAnimClip = req.Obj:GetComponent(typeof(UnityEngine.Animation)).clip
    self._clickReq = req

    self._onLoadingCountChanged = onLoadingCountChanged
end

--同步加载星灵
---@param pet AircraftPet
function AircraftPetLoader:SyncLoadePet(pet)
    local req = AircraftPetRequestSync:New(pet:TemplateID(), pet:PstID(), pet:PrefabName(), self._clickAnimClip)
    pet:Show(req)
end

--异步加载星灵
---@param pet AircraftPet
function AircraftPetLoader:AsyncLoadPet(pet)
    local pstID = pet:PstID()
    if self._pets[pstID] then
        return false
    end
    self._queue:Enqueue(AircraftPetRequestAsync:New(pet:TemplateID(), pstID, pet:PrefabName(), self._clickAnimClip))
    self._pets[pstID] = pet
    self:onLoadingChanged()
    return true
end

---@param pet AircraftPet
function AircraftPetLoader:TryDelPet(pet)
    local id = pet:PstID()
    if self._pets[id] then
        ---@type AircraftPetRequestAsync
        local req =
            self._queue:PopFirst(
            function(r)
                ---@type AircraftPetRequestAsync
                local req = r
                return req:ID() == id
            end
        )
        req:Close()
        self._pets[id] = nil
        self:onLoadingChanged()
        return true
    end
    return false
end

function AircraftPetLoader:Dispose()
    self._queue:ForEach(
        function(r)
            ---@type AircraftPetRequestAsync
            local req = r
            req:Close()
        end
    )
    self._queue:Clear()
    self._pets = {}
    self._clickReq:Dispose()
    self._clickReq = nil
    self:onLoadingChanged()
end

function AircraftPetLoader:Update()
    if self._queue:Count() <= 0 then
        return
    end
    ---@type AircraftPetRequestAsync
    local req = self._queue:Peek()
    if req:State() == AircraftPetLoadState.Wait then
        req:Load()
        return
    end
    if req:State() == AircraftPetLoadState.Loading then
        return
    end

    if req:State() == AircraftPetLoadState.Finish then
        ---加载完成
        local id = req:ID()
        local pet = self._pets[id]
        pet:Show(req, self._clickAnimClip)
        self._queue:Dequeue()
        self._pets[id] = nil
        self:onLoadingChanged()
        return
    end

    if req:State() == AircraftPetLoadState.Closed then
        self._queue:Dequeue()
        self._pets[req:ID()] = nil
        self:onLoadingChanged()
        return
    end
end

function AircraftPetLoader:onLoadingChanged()
    if self._onLoadingCountChanged then
        self._onLoadingCountChanged(self._queue:Count())
    end
end

function AircraftPetLoader:LoadingCount()
    return self._queue:Count()
end
