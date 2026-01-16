--[[
    风船家具修改器，存储编辑家具时的临时数据
    家具的操作类型有：移动、旋转、修改所在面、删除、新增
]]
---@class FurnitureModifier:Object
_class("FurnitureModifier", Object)
FurnitureModifier = FurnitureModifier

function FurnitureModifier:Constructor(area, sur, fur, newAdd)
    ---@type AircraftArea
    self._area = area
    ---@type AircraftSurface
    self._surface = sur
    ---@type AircraftFurniture
    self._furniture = fur
    self._furID = self._furniture:InstanceID()
    self._isDirty = false

    --第一次抬起
    self._firstPickup = true
    self._pickUp = false

    self._gridPos = self._furniture:GridPosition()
    self._rotY = self._furniture:GridRotY()

    --是否为删除的家具
    self._deleted = false
    --是否为新增的家具
    self._newAdd = newAdd
    if newAdd then
        self._isDirty = true
    end

    self._worldPosition = self._furniture:WorldPosition()
    self._worldRotation = self._furniture:WorldRotation()

    --原始信息，回滚时用
    self._originGridPos = self._gridPos:Clone()
    self._originRotY = self._rotY
    self._originSurface = sur
    self._originWorldPos = self._worldPosition:Clone()
    self._originWorldRot = self._worldRotation:Clone()
end
--region -------------------------------------------------------------------Get

---@return AircraftFurniture
function FurnitureModifier:Furniture()
    return self._furniture
end

---@return AircraftSurface
function FurnitureModifier:Surface()
    return self._surface
end

---@return AircraftArea
function FurnitureModifier:Area()
    return self._area
end

function FurnitureModifier:ID()
    return self._furID
end

function FurnitureModifier:IsDirty()
    return self._isDirty
end

function FurnitureModifier:WorldPostion()
    return self._worldPosition
end

function FurnitureModifier:WorldRotation()
    return self._worldRotation
end

function FurnitureModifier:GridPosition()
    return self._gridPos
end

function FurnitureModifier:RotY()
    return self._rotY
end

--返回服务器存储数据
function FurnitureModifier:GetSaveData()
    if self._isDirty then
        if self._deleted then
            --返回nil则表明这个家具要删除
            return nil
        end
        local data = MobileFurnitureInfo:New()
        data.asset_id = self._furniture:CfgID() --配置id
        data.area_id = self._area --区域不会变
        data.surface = self._surface:ID()
        --服务器保存整形
        data.pos_x = GridHelper.ToInt(self._gridPos.x)
        data.pos_z = GridHelper.ToInt(self._gridPos.y)
        data.rot = math.floor(self._rotY)
        return data
    else
        --没修改则返回数据
        return self._furniture:GetSvrData()
    end
end

function FurnitureModifier:GetGrids()
    return self._grids
end

--改变的氛围值，只有删除或新增的家具才有
function FurnitureModifier:ChangedAmbient()
    if self._newAdd then
        if self._deleted then
            return 0
        end
        return self._furniture:Ambient()
    end

    if self._deleted then
        return -self._furniture:Ambient()
    end
    return 0
end
--endregion

--region -------------------------------------------------------------------Get

--抬起
function FurnitureModifier:PickUp()
    self._pickUp = true
    --抬起偏移
    self._pickUpOffset = self._furniture._transform.up * GridHelper.PICKUPHEIGHT
    self._furniture:SetPosition(self._worldPosition + self._pickUpOffset)
    --抬起时记录当前信息，放下时如果位置不可用，则回滚到这些信息
    self._validPos = self._gridPos:Clone()
    self._validRotY = self._rotY
    self._validSurface = self._surface
    self._validWorldPos = self._worldPosition:Clone()
    self._validWorldRot = self._worldRotation:Clone()

    if self._firstPickup then
        self._firstPickup = false
        --第1次抬起时计算格子占用情况
        self._grids = GridHelper.FurnitureOccupyGrids(self._furniture, self._gridPos, self._rotY)
    end
    self._furniture:OccupyTiles(false)
    -- self._furniture:ShowAreaAndFootprint(true)
    --抬起默认有效
    -- self._furniture:SetAreaGridValid(true)

    self._isValid = true
end

function FurnitureModifier:SetValidWhenPickup(valid)
    self._isValid = valid
end

--放下
---@param shake boolean 位置不可用时是否抖动
function FurnitureModifier:DropDown(shake)
    self._pickUp = false

    if self._isValid then
        --当前可摆放
        self._furniture:SetPosition(self._worldPosition)
    else
        --当前位置不可用，回滚到抬起时的信息
        self._gridPos = self._validPos
        self._rotY = self._validRotY
        self._surface = self._validSurface
        self._worldPosition = self._validWorldPos
        self._worldRotation = self._validWorldRot

        --当前无效，重新计算一次有效格子
        self._grids = GridHelper.FurnitureOccupyGrids(self._furniture, self._gridPos, self._rotY)

        if shake then
            self._furniture:DoShake(
                function()
                    self._furniture:SetPosition(self._worldPosition)
                    self._furniture:SetRotation(self._worldRotation)
                end
            )
        else
            self._furniture:SetPosition(self._worldPosition)
            self._furniture:SetRotation(self._worldRotation)
        end
    end
    -- self:occupy(self._grids, true)

    local tiles = self._surface:Tiles()
    local layer = self._furniture:Layer()
    local otiles = {}
    for _, pos in ipairs(self._grids) do
        ---@type AircraftTile
        local tile
        if tiles[pos.x] then
            tile = tiles[pos.x][pos.y]
        end
        if tile then
            otiles[#otiles + 1] = tile
        else
            Log.exception("找不到格子：", pos.x, ",", pos.y)
        end
    end

    --放下时占据格子
    self._furniture:SetTiles(otiles)
    self._furniture:OccupyTiles(true)

    -- self._furniture:ShowAreaAndFootprint(false)
end

function FurnitureModifier:ChangePos(gridPos, worldPos, grids, valid)
    self._isDirty = true
    if not self._pickUp then
        Log.exception("没有抬起，不能移动")
    end
    self._gridPos = gridPos
    self._worldPosition = worldPos
    self._grids = grids

    if self._isValid ~= valid then
    -- self._furniture:SetAreaGridValid(valid)
    end
    --当前位置是否有效
    self._isValid = valid
    self._furniture:SetPosition(worldPos + self._pickUpOffset)
end
function FurnitureModifier:ChangeRotY(y, worldRot, grids, valid)
    self._isDirty = true
    if not self._pickUp then
        Log.exception("没有抬起，不能移动")
    end
    self._rotY = y
    self._worldRotation = worldRot
    self._grids = grids
    if self._isValid ~= valid then
    -- self._furniture:SetAreaGridValid(valid)
    end
    self._isValid = valid
    self._furniture:SetRotation(worldRot)
end
function FurnitureModifier:ChangeSurface(sur)
    self._isDirty = true
    if self._surface:ID() == sur:ID() then
        Log.exception("面id未改变")
    end
    self._surface = sur
end

function FurnitureModifier:IsDeleted()
    return self._deleted
end

function FurnitureModifier:Delete()
    if self._deleted then
        return
    end
    self._isDirty = true
    self._deleted = true
    self._furniture:SetActive(false)
    self._furniture:OccupyTiles(false)
end
--回滚所有修改
function FurnitureModifier:Revert()
    if not self._isDirty then
        return
    end

    if self._pickUp then
        self:DropDown(false)
    end

    if self._newAdd then
        self._furniture:Dispose()
        return
    end

    if self._deleted then
        self._furniture:SetActive(true)
        self._deleted = false
        self._furniture:OccupyTiles(true)
    end

    self._worldPosition = self._originWorldPos
    self._worldRotation = self._originWorldRot
    self._rotY = self._originRotY
    self._surface = self._originSurface
    self._gridPos = self._originGridPos

    self._furniture:SetPosition(self._worldPosition)
    self._furniture:SetRotation(self._worldRotation)

    self._isDirty = false
end

function FurnitureModifier:Dispose()
    if self._newAdd then
        self._furniture:Dispose()
    end
end

function FurnitureModifier:IsNewAdd()
    return self._newAdd
end
--endregion
