--[[------------------------------------------------------------------------------------------
    LocationComponent
]] --------------------------------------------------------------------------------------------

_class("LocationComponent", Object)
---@class LocationComponent:Object
---@field Direction Vector3
LocationComponent = LocationComponent
function LocationComponent:Constructor(pos, dir)
    --if (pos and  pos._className ~= "Vector3") or (dir and dir._className ~= "Vector3") then
    --    Log.fatal("Param Invalid ",Log.traceback())
    --end
    self.Position = pos or Vector3(0, 0, 0)
    self.Direction = dir or Vector3(0, 0, 1)
    self.Scale = Vector3(1, 1, 1)

    self.height = 0
    self._modifyLocationCallback = nil
end

---@param pos Vector3
function LocationComponent:SetPosition(pos)
    self.Position = pos
    self:CallBackModify()
end

---@param dir Vecotr3
function LocationComponent:SetDirection(dir)
    self.Direction = dir
    self:CallBackModify()
end

---@return Vector3
function LocationComponent:GetPosition()
    return self.Position:Clone()
end

---@return Vector3
function LocationComponent:GetDirection()
    return self.Direction:Clone()
end

---@return Vector3
function LocationComponent:GetScale()
    return self.Scale:Clone()
end

---@return Vector2
function LocationComponent:GetRenderGridDirection()
    local dir = self:GetDirection()
    return Vector2(math.floor(dir.x), math.floor(dir.z))
end

---@return number
function LocationComponent:Height()
    return self.height
end

function LocationComponent:SetModifyLocationCallback(callback)
    self._modifyLocationCallback = callback
end

function LocationComponent:CallBackModify()
    if self._modifyLocationCallback then
        
        self._modifyLocationCallback(self:GetPosition(), self:GetDirection())
    end
end

function LocationComponent:CallBackModifyLocation(pos, dir, entity)
    self.Position.x = pos.x
    self.Position.z = pos.z
    self.Direction = dir
    self:SyncLocation(entity)
end

---@param entity Entity
function LocationComponent:SyncLocation(entity)
    if self.tranRenderSvc == nil then
        local world = entity:GetOwnerWorld()
        ---@type TransformServiceRenderer
        self.tranRenderSvc = world:GetService("TransformRenderer")
    end
    self.tranRenderSvc:SimpleSyncLocation(entity)
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return LocationComponent
function Entity:Location()
    return self:GetComponent(self.WEComponentsEnum.Location)
end

function Entity:HasLocation()
    return self:HasComponent(self.WEComponentsEnum.Location)
end

---获取真实的渲染坐标
function Entity:GetPosition()
    if self:HasLocation() then
        ---@type LocationComponent
        local cmpt = self:Location()
        return cmpt:GetPosition()
    end
    return nil
end

---获取真实的渲染方向
---@return UnityEngine.Vector3
function Entity:GetDirection()
    if self:HasLocation() then
        ---@type LocationComponent
        local cmpt = self:Location()
        return cmpt:GetDirection()
    end
    return nil
end

---v2的方向
---@return UnityEngine.Vector2
function Entity:GetRenderGridDirection()
    if self:HasLocation() then
        ---@type LocationComponent
        local cmpt = self:Location()
        return cmpt:GetRenderGridDirection()
    end
    return nil
end

---表现使用可以获取实时 怪物或宝宝的坐标
---获取的是通过渲染坐标算出来的基准坐标
---@return Vector2
function Entity:GetRenderGridPosition()
    if self:HasLocation() then
        ---@type BoardServiceRender
        local boardServiceRender = self:GetOwnerWorld():GetService("BoardRender")
        return boardServiceRender:GetEntityRealTimeGridPos(self)
    end
    return nil
end

---@param pos Vector2
---@param dir Vector2
function Entity:SetLocation(pos, dir, forceDirection)
    local logicPos = pos
    local logicDir = dir
    ---不要删除 调试能用
    --Log.fatal("EntityID:",self:GetID(),"SetLocation Pos:", tostring(pos),"dir:", tostring(dir),"Trace:",Log.traceback())
    ---@type BoardServiceRender
    local boardServiceRender = self:GetOwnerWorld():GetService("BoardRender")
    pos = boardServiceRender:GridPosition2LocationPos(pos, self)
    if (not forceDirection) or (dir._className ~= "Vector3") then
        dir = boardServiceRender:GridDir2LocationDir(dir)
    end
    ---@type LocationComponent
    local locationCmp = nil
    local index = self.WEComponentsEnum.Location
    if self:HasLocation() then
        locationCmp = self:Location()
        locationCmp.Position = pos or locationCmp.Position
        locationCmp.Direction = dir or locationCmp.Direction
        locationCmp:CallBackModify()
    else
        locationCmp = LocationComponent:New(pos, dir)
        self:ReplaceComponent(index, locationCmp)
    end
    locationCmp:SyncLocation(self)
end

---@param pos Vector2
function Entity:SetPosition(pos)
    ---@type BoardServiceRender
    local boardServiceRender = self:GetOwnerWorld():GetService("BoardRender")
    ---不要删除 调试能用
    --Log.fatal("EntityID:",self:GetID(),"SetPosition Pos:", tostring(pos),"Trace:",Log.traceback())
    pos = boardServiceRender:GridPosition2LocationPos(pos, self)
    if not pos then
        Log.fatal("SetPosition Invalid ", Log.traceback())
        return
    end
    ---@type LocationComponent
    local locationCmp = nil
    local index = self.WEComponentsEnum.Location
    if self:HasLocation() then
        locationCmp = self:Location()
        locationCmp:SetPosition(pos)
    else
        ---@type LocationComponent
        locationCmp = LocationComponent:New(pos, nil)
        self:ReplaceComponent(index, locationCmp)
    end
    locationCmp:SyncLocation(self)
end

---@param dir Vector2
function Entity:SetDirection(dir)
    --Log.fatal("ID:",self:GetID(),"Dir:", tostring(dir),"Trace:",Log.traceback())
    ---@type BoardServiceRender
    local BoardServiceRender = self:GetOwnerWorld():GetService("BoardRender")
    dir = BoardServiceRender:GridDir2LocationDir(dir)
    if not dir then
        return
    end

    ---@type LocationComponent
    local locationCmp = nil
    local index = self.WEComponentsEnum.Location
    if self:HasLocation() then
        locationCmp = self:Location()
        locationCmp:SetDirection(dir)
        self:ReplaceComponent(index, locationCmp)
    else
        ---@type LocationComponent
        locationCmp = LocationComponent:New(nil, dir)
        self:ReplaceComponent(index, locationCmp)
    end
    locationCmp:SyncLocation(self)
end

---@param scale Vector3
function Entity:SetScale(scale)
    if scale and scale._className ~= "Vector3" then
        Log.fatal("Param Invalid ", Log.traceback())
        return
    end
    ---@type LocationComponent
    local locationCmp = nil
    local index = self.WEComponentsEnum.Location
    if self:HasLocation() then
        locationCmp = self:Location()
        locationCmp.Scale = scale
        self:ReplaceComponent(index, locationCmp)
    else
        ---@type LocationComponent
        locationCmp = LocationComponent:New()
        locationCmp.Scale = scale
        self:ReplaceComponent(index, locationCmp)
    end
    locationCmp:SyncLocation(self)
end

----设置高度后 需要手动调用归零
function Entity:SetLocationHeight(height)
    ---@type LocationComponent
    local locationCmp = nil
    local index = self.WEComponentsEnum.Location
    if self:HasLocation() then
        locationCmp = self:Location()
        locationCmp.height = height
        locationCmp.Position.y = height
        self:ReplaceComponent(index, locationCmp)
    else
        ---@type LocationComponent
        locationCmp = LocationComponent:New(nil, nil)
        locationCmp.height = height
        self:ReplaceComponent(index, locationCmp)
    end
    locationCmp:SyncLocation(self)
end

function Entity:GetDamageCenter()
    local posReturn = nil
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        local posOffSet = cmpt:GetDamageOffset()
        local entityGridPos = self:GetRenderGridPosition()
        if entityGridPos and posOffSet then
            posReturn = entityGridPos + posOffSet
        end
    end
    return posReturn
end
