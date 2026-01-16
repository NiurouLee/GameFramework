--[[------------------------------------------------------------------------------------------
    RenderPickUpComponent  : 点选型主动技组件 拆分 表现部分
]] --------------------------------------------------------------------------------------------

_class("RenderPickUpComponent", Object)
---@class RenderPickUpComponent: Object
RenderPickUpComponent = RenderPickUpComponent

function RenderPickUpComponent:Constructor()
    ---存储指令上下文,key是PreviewConfig中的ID
    ---@type table<number,SkillPreviewContext>
    self._previewContextList = {}
    ---@type Vector2[]
    self._multiPickUpGridPosList = {}
    ---@type Vector2[]
    self._lastPickUpGridPos = nil
    ---@type table<number,Vector2[]>  key是技能效果ID,value是技能效果使用的范围
    self._skillEffectScopeResultList = {}
	---点选的方向数组
	---@type HitBackDirectionType[]
    self._pickUpDirection = {}
	---@type HitBackDirectionType
    self._lastPickUpDirection = nil
    self._pickUpEffectEntityIDs = {}
    self._directionPickupPos = {}
    self._reflectDir=nil
    --点选的额外信息
    self._pickUpExtraParamList = {}
    self._ignorePickCheck = false--（发消息、自动战斗）不检查点选
end
function RenderPickUpComponent:Clear()
    self._previewContextList = {}
    self._lastPickUpGridPos = nil
    self._skillEffectScopeResultList = {}
    self._pickUpDirection = {}
    self._pickUpEffectEntityIDs = {}
    self._directionPickupPos = {}
    self._reflectDir = nil
    self._pickUpExtraParamList = {}
    self._ignorePickCheck = false
end

---@param context SkillPreviewContext
function RenderPickUpComponent:SetPreviewContext(id, context)--没有用到
    self._previewContextList[id] = context
end

function RenderPickUpComponent:GetPreviewContext(id)--没有调用set，所以一定返回nil 待确认
    for _id, context in pairs(self._previewContextList) do
        if _id == id then
            return context
        end
    end
    return nil
end

---@param effectType SkillEffectType
---@param scopeResult Vector2[]
function RenderPickUpComponent:SetSkillEffectScope(effectType, scopeResult)--没有用到
    self._skillEffectScopeResultList[effectType] = scopeResult
end

---@return Vector2[]
---@param effectType SkillEffectType
function RenderPickUpComponent:GetSkillEffectScope(effectType)--没有用到
    for _effectType, scopeResult in pairs(self._skillEffectScopeResultList) do
        if _effectType == effectType then
            return scopeResult
        end
    end
    return nil
end

function RenderPickUpComponent:AddGridPosList(gridList)
    for _, pos in ipairs(gridList) do
        self:AddGridPos(pos)
    end
end

---@param pickUpGridPos Vector2
function RenderPickUpComponent:AddGridPos(pickUpGridPos)
    table.insert(self._multiPickUpGridPosList, pickUpGridPos)
    self._lastPickUpGridPos = pickUpGridPos
end

---@param pickUpGridPos Vector2
function RenderPickUpComponent:RemoveGridPos(pickUpGridPos)
    table.removev(self._multiPickUpGridPosList, pickUpGridPos)
    if self._lastPickUpGridPos == pickUpGridPos then
        self._lastPickUpGridPos = self._multiPickUpGridPosList[#self._multiPickUpGridPosList]
    end
end

function RenderPickUpComponent:ClearGridPos()
    self._multiPickUpGridPosList = {}
    self._lastPickUpGridPos = nil
end
function RenderPickUpComponent:AddPickExtraParamList(extraParamList)
    if extraParamList then
        for _, param in ipairs(extraParamList) do
            self:AddPickExtraParam(param)
        end
    end
end
function RenderPickUpComponent:AddPickExtraParam(extraParam)
    table.insert(self._pickUpExtraParamList, extraParam)
end
function RenderPickUpComponent:RemovePickExtraParam(extraParam)
    table.removev(self._pickUpExtraParamList, extraParam)
end

function RenderPickUpComponent:ClearPickExtraParam()
    self._pickUpExtraParamList = {}
end
function RenderPickUpComponent:GetAllPickExtraParam()
    return self._pickUpExtraParamList
end
function RenderPickUpComponent:HasPickExtraParam(param)
    if table.icontains(self._pickUpExtraParamList, param) then
        return true
    end
    return false
end
function RenderPickUpComponent:AddDirectionList(directionPickupPos,pickUpDirection,lastPickUpDirection)
    self._directionPickupPos = directionPickupPos
    self._pickUpDirection = pickUpDirection
    self._lastPickUpDirection = lastPickUpDirection
end

function RenderPickUpComponent:AddDirection(direction, pickUpGridPos)
    table.insert(self._pickUpDirection, direction)
    self._lastPickUpDirection = direction
    self._directionPickupPos[direction] = pickUpGridPos
end

function RenderPickUpComponent:RemoveDirection(direction)
    table.removev(self._pickUpDirection, direction)
    if self._lastPickUpDirection == direction then
        self._lastPickUpDirection = self._pickUpDirection[#self._pickUpDirection]
    end
    local pos = self._directionPickupPos[direction]
    if pos then
        self:RemoveGridPos(pos)
        self._directionPickupPos[direction] = nil
    end
end

function RenderPickUpComponent:IsRepeatDirection(direction)
    if table.icontains(self._pickUpDirection, direction) then
        return true
    end
    return false
end

function RenderPickUpComponent:ClearDirection()
    self._pickUpDirection = {}
	self._lastPickUpDirection = nil
	self._directionPickupPos={}
end

function RenderPickUpComponent:GetAllDirection()
    return self._pickUpDirection
end

---@return HitBackDirectionType,Vector2
function RenderPickUpComponent:GetLastPickDirectionAndPickPos()
    return self._lastPickUpDirection,self._directionPickupPos[self._lastPickUpDirection]
end

function RenderPickUpComponent:GetPickUpDirectionPos()
    return self._directionPickupPos
end

---@return HitBackDirectionType
function RenderPickUpComponent:GetLastPickUpDirection()
    return self._lastPickUpDirection
end

---@return boolean
function RenderPickUpComponent:IsRepeatPickUP(pickUpGridPos)
    return table.icontains(self._multiPickUpGridPosList, pickUpGridPos)
end
---@return Vector2
function RenderPickUpComponent:GetLastPickUpGridPos()
    return self._lastPickUpGridPos
end
---@return Vector2[]
function RenderPickUpComponent:GetAllValidPickUpGridPos()
    return self._multiPickUpGridPosList
end

---@return number
function RenderPickUpComponent:GetAllValidPickUpGridPosCount()
    return #self._multiPickUpGridPosList
end

function RenderPickUpComponent:AddPickUpEffectEntityID(id)
    table.insert(self._pickUpEffectEntityIDs, id)
end

function RenderPickUpComponent:GetPickUpEffectEntityIDArray()
    return self._pickUpEffectEntityIDs
end

---@return Vector2
function RenderPickUpComponent:GetFirstValidPickUpGridPos()
    if #self._multiPickUpGridPosList >=1 then
        return self._multiPickUpGridPosList[1]
    else
        Log.fatal("No PickUpGridPos Data")
        return nil
    end
end

function RenderPickUpComponent:SetReflectDir(dir)
    self._reflectDir = dir 
end

function RenderPickUpComponent:GetReflectDir()
    return self._reflectDir or ReflectDirectionType.Heng
end

function RenderPickUpComponent:SetReflectPos(pos)
    self._reflectPos = pos
end

function RenderPickUpComponent:GetReflectPos()
    return self._reflectPos
end


function RenderPickUpComponent:GetRotateGhost()
    return self._rotateGhost
end

function RenderPickUpComponent:SetRotateGhost(ghost)
    self._rotateGhost = ghost
end
--是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function RenderPickUpComponent:IsIgnorePickCheck()
    return self._ignorePickCheck
end
--设置是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function RenderPickUpComponent:SetIgnorePickCheck(ignorePickCheck)
    self._ignorePickCheck = ignorePickCheck
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] 
-- function Entity:RenderPickUpComponent()
--     return self:GetComponent(self.WEComponentsEnum.RenderPickUp)
-- end

-- function Entity:HasRenderPickUpComponent()
--     return self:HasComponent(self.WEComponentsEnum.RenderPickUp)
-- end

-- function Entity:AddRenderPickUpComponent()
--     local index = self.WEComponentsEnum.RenderPickUp
--     local component = RenderPickUpComponent:New()
--     self:AddComponent(index, component)
-- end

-- function Entity:ReplaceRenderPickUpComponent()
--     local index = self.WEComponentsEnum.RenderPickUp
--     local component = RenderPickUpComponent:New()
--     self:ReplaceComponent(index, component)
-- end

-- function Entity:RemoveRenderPickUpComponent()
--     if self:HasRenderPickUpComponent() then
--         self:RemoveComponent(self.WEComponentsEnum.RenderPickUp)
--     end
-- end

---暂时屏蔽点选拆分
function Entity:RenderPickUpComponent()
    return self:ActiveSkillPickUpComponent()
end

function Entity:HasRenderPickUpComponent()
    return self:HasActiveSkillPickUpComponent()
end

function Entity:AddRenderPickUpComponent()
    self:AddActiveSkillPickUpComponent()
end

function Entity:ReplaceRenderPickUpComponent()
    self:ReplaceActiveSkillPickUpComponent()
end

function Entity:RemoveRenderPickUpComponent()
    --self:RemoveActiveSkillPickUpComponent()
end