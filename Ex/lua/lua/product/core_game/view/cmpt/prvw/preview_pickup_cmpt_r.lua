--[[------------------------------------------------------------------------------------------
    PreviewPickUpComponent  : 点选型主动技组件 拆分 预览部分
]] --------------------------------------------------------------------------------------------

_class("PreviewPickUpComponent", Object)
---@class PreviewPickUpComponent: Object
PreviewPickUpComponent = PreviewPickUpComponent

function PreviewPickUpComponent:Constructor()
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
function PreviewPickUpComponent:Clear()
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
function PreviewPickUpComponent:SetPreviewContext(id, context)--没有用到
    self._previewContextList[id] = context
end

function PreviewPickUpComponent:GetPreviewContext(id)--没有调用set，所以一定返回nil 待确认
    for _id, context in pairs(self._previewContextList) do
        if _id == id then
            return context
        end
    end
    return nil
end
---@param effectType SkillEffectType
---@param scopeResult Vector2[]
function PreviewPickUpComponent:SetSkillEffectScope(effectType, scopeResult)--没有用到
    self._skillEffectScopeResultList[effectType] = scopeResult
end

---@return Vector2[]
---@param effectType SkillEffectType
function PreviewPickUpComponent:GetSkillEffectScope(effectType)--没有用到
    for _effectType, scopeResult in pairs(self._skillEffectScopeResultList) do
        if _effectType == effectType then
            return scopeResult
        end
    end
    return nil
end
function PreviewPickUpComponent:AddGridPosList(gridList)
    for _, pos in ipairs(gridList) do
        self:AddGridPos(pos)
    end
end

---@param pickUpGridPos Vector2
function PreviewPickUpComponent:AddGridPos(pickUpGridPos)
    table.insert(self._multiPickUpGridPosList, pickUpGridPos)
    self._lastPickUpGridPos = pickUpGridPos
end

---@param pickUpGridPos Vector2
function PreviewPickUpComponent:RemoveGridPos(pickUpGridPos)
    table.removev(self._multiPickUpGridPosList, pickUpGridPos)
    if self._lastPickUpGridPos == pickUpGridPos then
        self._lastPickUpGridPos = self._multiPickUpGridPosList[#self._multiPickUpGridPosList]
    end
end

function PreviewPickUpComponent:ClearGridPos()
    self._multiPickUpGridPosList = {}
    self._lastPickUpGridPos = nil
end
function PreviewPickUpComponent:AddPickExtraParamList(extraParamList)
    if extraParamList then
        for _, param in ipairs(extraParamList) do
            self:AddPickExtraParam(param)
        end
    end
end
function PreviewPickUpComponent:AddPickExtraParam(extraParam)
    table.insert(self._pickUpExtraParamList, extraParam)
end
function PreviewPickUpComponent:RemovePickExtraParam(extraParam)
    table.removev(self._pickUpExtraParamList, extraParam)
end

function PreviewPickUpComponent:ClearPickExtraParam()
    self._pickUpExtraParamList = {}
end
function PreviewPickUpComponent:GetAllPickExtraParam()
    return self._pickUpExtraParamList
end
function PreviewPickUpComponent:HasPickExtraParam(param)
    if table.icontains(self._pickUpExtraParamList, param) then
        return true
    end
    return false
end
function PreviewPickUpComponent:AddDirectionList(directionPickupPos,pickUpDirection,lastPickUpDirection)
    self._directionPickupPos = directionPickupPos
    self._pickUpDirection = pickUpDirection
    self._lastPickUpDirection = lastPickUpDirection
end

function PreviewPickUpComponent:AddDirection(direction, pickUpGridPos)
    table.insert(self._pickUpDirection, direction)
    self._lastPickUpDirection = direction
    self._directionPickupPos[direction] = pickUpGridPos
end

function PreviewPickUpComponent:RemoveDirection(direction)
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

function PreviewPickUpComponent:IsRepeatDirection(direction)
    if table.icontains(self._pickUpDirection, direction) then
        return true
    end
    return false
end

function PreviewPickUpComponent:ClearDirection()
    self._pickUpDirection = {}
	self._lastPickUpDirection = nil
	self._directionPickupPos={}
end

function PreviewPickUpComponent:GetAllDirection()
    return self._pickUpDirection
end

---@return HitBackDirectionType,Vector2
function PreviewPickUpComponent:GetLastPickDirectionAndPickPos()
    return self._lastPickUpDirection,self._directionPickupPos[self._lastPickUpDirection]
end

function PreviewPickUpComponent:GetPickUpDirectionPos()
    return self._directionPickupPos
end

---@return HitBackDirectionType
function PreviewPickUpComponent:GetLastPickUpDirection()
    return self._lastPickUpDirection
end

---@return boolean
function PreviewPickUpComponent:IsRepeatPickUP(pickUpGridPos)
    return table.icontains(self._multiPickUpGridPosList, pickUpGridPos)
end
---@return Vector2
function PreviewPickUpComponent:GetLastPickUpGridPos()
    return self._lastPickUpGridPos
end
---@return Vector2[]
function PreviewPickUpComponent:GetAllValidPickUpGridPos()
    return self._multiPickUpGridPosList
end

---@return number
function PreviewPickUpComponent:GetAllValidPickUpGridPosCount()
    return #self._multiPickUpGridPosList
end

function PreviewPickUpComponent:AddPickUpEffectEntityID(id)
    table.insert(self._pickUpEffectEntityIDs, id)
end

function PreviewPickUpComponent:GetPickUpEffectEntityIDArray()
    return self._pickUpEffectEntityIDs
end

---@return Vector2
function PreviewPickUpComponent:GetFirstValidPickUpGridPos()
    if #self._multiPickUpGridPosList >=1 then
        return self._multiPickUpGridPosList[1]
    else
        Log.fatal("No PickUpGridPos Data")
        return nil
    end
end

function PreviewPickUpComponent:SetReflectDir(dir)
    self._reflectDir = dir 
end

function PreviewPickUpComponent:GetReflectDir()
    return self._reflectDir or ReflectDirectionType.Heng
end

function PreviewPickUpComponent:SetReflectPos(pos)
    self._reflectPos = pos
end

function PreviewPickUpComponent:GetReflectPos()
    return self._reflectPos
end


function PreviewPickUpComponent:GetRotateGhost()
    return self._rotateGhost
end

function PreviewPickUpComponent:SetRotateGhost(ghost)
    self._rotateGhost = ghost
end
--是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function PreviewPickUpComponent:IsIgnorePickCheck()
    return self._ignorePickCheck
end
--设置是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function PreviewPickUpComponent:SetIgnorePickCheck(ignorePickCheck)
    self._ignorePickCheck = ignorePickCheck
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] 
-- function Entity:PreviewPickUpComponent()
--     return self:GetComponent(self.WEComponentsEnum.PreviewPickUp)
-- end

-- function Entity:HasPreviewPickUpComponent()
--     return self:HasComponent(self.WEComponentsEnum.PreviewPickUp)
-- end

-- function Entity:AddPreviewPickUpComponent()
--     local index = self.WEComponentsEnum.PreviewPickUp
--     local component = PreviewPickUpComponent:New()
--     self:AddComponent(index, component)
-- end

-- function Entity:ReplacePreviewPickUpComponent()
--     local index = self.WEComponentsEnum.PreviewPickUp
--     local component = PreviewPickUpComponent:New()
--     self:ReplaceComponent(index, component)
-- end

-- function Entity:RemovePreviewPickUpComponent()
--     if self:HasPreviewPickUpComponent() then
--         self:RemoveComponent(self.WEComponentsEnum.PreviewPickUp)
--     end
-- end

---暂时屏蔽点选拆分
function Entity:PreviewPickUpComponent()
    return self:ActiveSkillPickUpComponent()
end

function Entity:HasPreviewPickUpComponent()
    return self:HasActiveSkillPickUpComponent()
end

function Entity:AddPreviewPickUpComponent()
    self:AddActiveSkillPickUpComponent()
end

function Entity:ReplacePreviewPickUpComponent()
    self:ReplaceActiveSkillPickUpComponent()
end

function Entity:RemovePreviewPickUpComponent()
    self:RemoveActiveSkillPickUpComponent()
end