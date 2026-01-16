--[[------------------------------------------------------------------------------------------
    GridLocationComponent : 二维的逻辑坐标组件 标明Entity所属格子位置及朝向 可以是小数
    pos:二维格子坐标
    dir:朝向
    offset:中心位置偏移(支持多格怪中心不在格子中心上)
]] --------------------------------------------------------------------------------------------

_class("GridLocationComponent", Object)
---@class GridLocationComponent: Object
GridLocationComponent = GridLocationComponent

function GridLocationComponent:Constructor(pos, dir, offset, height, damageOffset)
    ---@type Vector2
    self.Position = self:_InitVectorData(pos) or Vector2(1, 1)
    self.Direction = self:_InitVectorData(dir) or Vector2(0, 0)
    self.Offset = self:_InitVectorData(offset) or Vector2(0, 0)
    self.Height = height or 0
    self.DamageOffset = damageOffset or offset
    ---玩家移动的时候使用用来保证路径上被修改的位置能够生效
    self._moveLastPosition = Vector2(0, 0)
    self._modifyLocationCallback = nil
end

---@param gridLocRes DataGridLocationResult
function GridLocationComponent:InitByGridLocResult(gridLocRes)
    ---@type Vector2
    self.Position = gridLocRes:GetGridLocResultBornPos()
    self.Direction = gridLocRes:GetGridLocResultBornDir()
    self.Offset = gridLocRes:GetGridLocResultBornOffset()
    self.Height = gridLocRes:GetGridLocResultBornHeight()
    self.DamageOffset = gridLocRes:GetGridLocResultDamageOffset()
end

---@return Vector2
function GridLocationComponent:_InitVectorData(data)
    if data then
        return Vector2.New(data.x, data.y)
    end
end

function GridLocationComponent:Destructor()
    self.Position = nil
    self.Direction = nil
    self.Offset = nil
    self.Height = 0
    self.DamageOffset = nil
    self._modifyLocationCallback = nil
end

---@return Vector2
function GridLocationComponent:GetGridPos()
    return self.Position
end

function GridLocationComponent:GetGridDir()
    return Vector2.New(math.floor(self.Direction.x), math.floor(self.Direction.y))
end

function GridLocationComponent:GetRawGridDir()
    return self.Direction:Clone()
end

function GridLocationComponent:GetGridOffset()
    return self.Offset or Vector2.zero
end

---@param pos Vector2
function GridLocationComponent:SetMoveLastPosition(pos)
    self._moveLastPosition = pos
end

---@return Vector2
function GridLocationComponent:GetMoveLastPosition()
    return self._moveLastPosition
end

---@public
---@return Vector2
---返回Entity的中心
function GridLocationComponent:Center()
    local entityPos = self.Position
    local entityOffset = self.Offset or Vector2.zero
    return entityPos + entityOffset
end

---@public
---@return Vector2
---返回Entity的中心 不带偏移
function GridLocationComponent:CenterNoOffset()
    local entityPos = self.Position
    local entityOffset = self.Offset or Vector2.zero
    return entityPos
end

---@public
---@return Vector2
---返回Entity的中心
function GridLocationComponent:DamageCenter()
    local entityPos = self:_InitVectorData(self.Position)
    local entityOffset = self:_InitVectorData(self.DamageOffset) or Vector2.zero
    return entityPos + entityOffset
end

function GridLocationComponent:GetDamageOffset()
    local entityOffset = self:_InitVectorData(self.DamageOffset) or Vector2.zero
    return entityOffset
end

function GridLocationComponent:SetGridPosCmpt(pos)
    --Log.fatal("SetGridPos :", tostring(pos)," entity=",self._entity:GetID())
    self.Position = self:_InitVectorData(pos)
    self:CallBackModify()
end

function GridLocationComponent:GetGridLocHeight()
    return self.Height
end

function GridLocationComponent:SetModifyLocationCallback(callback)
    self._modifyLocationCallback = callback
end

function GridLocationComponent:CallBackModify()
    if self._modifyLocationCallback then
        self._modifyLocationCallback(self:GetGridPos(), self:GetGridDir())
    end
end

function GridLocationComponent:CallBackModifyLocation(pos, dir)
    self.Position.x = pos.x
    self.Position.y = pos.y
    self.Direction = dir
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return GridLocationComponent
function Entity:GridLocation()
    -- if self:HasSuperEntity() then
    --     return self:SuperEntityComponent():GetSuperEntity():GridLocation()
    -- end
    return self:GetComponent(self.WEComponentsEnum.GridLocation)
end

function Entity:HasGridLocation()
    return self:HasComponent(self.WEComponentsEnum.GridLocation)
end

---@param pos Vector2
---@param dir Vector2
function Entity:SetGridLocation(pos, dir)
    if (pos ~= nil) then
        --Log.fatal("SetGridPos :", tostring(pos)," ",Log.traceback())
        if (pos.x == nil or pos.y == nil) then
            Log.error("SetGridLocation error pos param")
            Log.error(pos.x, pos.y)
        end
    else
        --log.error(pos.x, pos.y)
        --Log.error("SetGridLocation error pos = nil param")
    end
    if (dir ~= nil) then
        if (dir.x == nil or dir.y == nil) then
            Log.error("SetGridLocation error dir param")
            Log.error(dir.x, dir.y)
        end
    else
        --log.error(dir.x, dir.y)
        --Log.error("SetGridLocation error dir = nil param")
    end

    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        if pos then
            cmpt:SetGridPosCmpt(pos)
        end
        if dir then
            cmpt.Direction = dir
        end
        cmpt:CallBackModify()
        self:ReplaceComponent(index, cmpt)
    else
        local component = GridLocationComponent:New(pos, dir)
        self:ReplaceComponent(index, component)
    end
end

---部分参数是表现用，但表现不能直接操作逻辑组件
---@param cloneTargetEntity Entity
function Entity:CloneOffsetAndDamageOffset(cloneTargetEntity)
    local cCloneGridLocation = cloneTargetEntity:GridLocation()
    if not cCloneGridLocation then
        return
    end

    local offset = cCloneGridLocation.Offset
    local damageOffset = cCloneGridLocation.DamageOffset

    if offset then
        offset = offset:Clone()
    end
    if damageOffset then
        damageOffset = damageOffset:Clone()
    end

    -- 与SetGridLocationAndOffset实现方式统一的修改
    local cSelfGridLocation = self:GridLocation()
    cSelfGridLocation.Offset = offset
    cSelfGridLocation.DamageOffset = damageOffset
end

function Entity:SetGridLocationAndOffset(pos, dir, offset, damageOffset)
    --Log.fatal("SetGridPos :", tostring(pos)," ",Log.traceback())
    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        cmpt:SetGridPosCmpt(pos)
        cmpt.Direction = dir
        cmpt.Offset = offset
        cmpt.DamageOffset = damageOffset
        cmpt:CallBackModify()
        self:ReplaceComponent(index, cmpt)
    else
        local component = GridLocationComponent:New(pos, dir, offset, damageOffset)
        self:ReplaceComponent(index, component)
    end
end

function Entity:SetGridPosition(pos)
    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        cmpt:SetGridPosCmpt(pos)
        self:ReplaceComponent(index, cmpt)
    else
        self:SetGridLocation(pos, nil)
    end
end

---2019-12-23韩玉信增加API
---@return Vector2
function Entity:GetGridPosition()
    local posReturn = nil
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        posReturn = cmpt:GetGridPos()
    end
    return posReturn
end

---@return Vector2
function Entity:GetGridOffset()
    local offSet = nil
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        offSet = cmpt:GetGridOffset()
    end
    return offSet
end

function Entity:GetGridHeight()
    local height = nil
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        height = cmpt.Height
    end
    return height
end

---@return Vector2
function Entity:GetGridDirection()
    local dirReturn = nil
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        dirReturn = cmpt:GetGridDir()
    end
    return dirReturn
end

function Entity:SetGridDirection(dir)
    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        cmpt.Direction = dir
        cmpt:CallBackModify()
        self:ReplaceComponent(index, cmpt)
    else
        self:SetGridLocation(nil, dir)
    end
end

function Entity:SetGridOffset(offset)
    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        cmpt.Offset = offset
        self:ReplaceComponent(index, cmpt)
    else
        local component = GridLocationComponent:New(nil, nil, offset)
        self:ReplaceComponent(index, component)
    end
end

function Entity:SetGridHeight(height)
    local index = self.WEComponentsEnum.GridLocation
    if self:HasGridLocation() then
        local cmpt = self:GridLocation()
        cmpt.Height = height
        self:ReplaceComponent(index, cmpt)
    else
        local component = GridLocationComponent:New(nil, nil, nil, height)
        self:ReplaceComponent(index, component)
    end
end

---@return boolean
---@param pos Vector2
function Entity:IsOnGridPosition(pos)
    if not self:HasGridLocation() then
        return false
    end

    if self:HasOutsideRegion() then
        return false
    end
    if self:HasOffBoardMonster() then
        return false
    end
    local entityPos = self:GridLocation().Position
    if self:HasBodyArea() then
        local bodyArea = self:BodyArea()._area
        for i = 1, #bodyArea do
            local bodyPos = entityPos + bodyArea[i]
            if bodyPos == pos then
                return true
            end
        end

        ---预览时候的身形(为了解决1格子的怪物，点周围10个格子都可以选中这个怪物的预览)
        local previewArea = self:BodyArea():GetPreviewArea()
        if previewArea and table.count(previewArea) > 0 then
            for i = 1, #previewArea do
                local bodyPos = entityPos + previewArea[i]
                if bodyPos == pos then
                    return true
                end
            end
        end

        return false
    else
        return pos == entityPos
    end
end
