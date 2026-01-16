--[[------------------------------------------------------------------------------------------
    ActiveSkillPickUpComponent  : 点选型主动技组件
    设计目的：统一现有的点选组件,把数据都统一到一个组件里面,数据统一但是数据内容可以不同宝宝用不同的数据
]] --------------------------------------------------------------------------------------------

_class("ActiveSkillPickUpComponent", Object)
---@class ActiveSkillPickUpComponent: Object
ActiveSkillPickUpComponent = ActiveSkillPickUpComponent

function ActiveSkillPickUpComponent:Constructor()
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
function ActiveSkillPickUpComponent:Clear()
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
function ActiveSkillPickUpComponent:SetPreviewContext(id, context)--没有用到
    self._previewContextList[id] = context
end

function ActiveSkillPickUpComponent:GetPreviewContext(id)--没有调用set，所以一定返回nil 待确认
    for _id, context in pairs(self._previewContextList) do
        if _id == id then
            return context
        end
    end
    return nil
end
---@param effectType SkillEffectType
---@param scopeResult Vector2[]
function ActiveSkillPickUpComponent:SetSkillEffectScope(effectType, scopeResult)--没有用到
    self._skillEffectScopeResultList[effectType] = scopeResult
end

---@return Vector2[]
---@param effectType SkillEffectType
function ActiveSkillPickUpComponent:GetSkillEffectScope(effectType)--没有用到
    for _effectType, scopeResult in pairs(self._skillEffectScopeResultList) do
        if _effectType == effectType then
            return scopeResult
        end
    end
    return nil
end
function ActiveSkillPickUpComponent:AddGridPosList(gridList)
    for _, pos in ipairs(gridList) do
        self:AddGridPos(pos)
    end
end

---@param pickUpGridPos Vector2
function ActiveSkillPickUpComponent:AddGridPos(pickUpGridPos)
    table.insert(self._multiPickUpGridPosList, pickUpGridPos)
    self._lastPickUpGridPos = pickUpGridPos
end

---@param pickUpGridPos Vector2
function ActiveSkillPickUpComponent:RemoveGridPos(pickUpGridPos)
    table.removev(self._multiPickUpGridPosList, pickUpGridPos)
    if self._lastPickUpGridPos == pickUpGridPos then
        self._lastPickUpGridPos = self._multiPickUpGridPosList[#self._multiPickUpGridPosList]
    end
end

function ActiveSkillPickUpComponent:ClearGridPos()
    self._multiPickUpGridPosList = {}
    self._lastPickUpGridPos = nil
end
function ActiveSkillPickUpComponent:AddPickExtraParamList(extraParamList)
    if extraParamList then
        for _, param in ipairs(extraParamList) do
            self:AddPickExtraParam(param)
        end
    end
end
function ActiveSkillPickUpComponent:AddPickExtraParam(extraParam)
    table.insert(self._pickUpExtraParamList, extraParam)
end
function ActiveSkillPickUpComponent:RemovePickExtraParam(extraParam)
    table.removev(self._pickUpExtraParamList, extraParam)
end

function ActiveSkillPickUpComponent:ClearPickExtraParam()
    self._pickUpExtraParamList = {}
end
function ActiveSkillPickUpComponent:GetAllPickExtraParam()
    return self._pickUpExtraParamList
end
function ActiveSkillPickUpComponent:HasPickExtraParam(param)
    if table.icontains(self._pickUpExtraParamList, param) then
        return true
    end
    return false
end
function ActiveSkillPickUpComponent:AddDirectionList(directionPickupPos,pickUpDirection,lastPickUpDirection)
    self._directionPickupPos = directionPickupPos
    self._pickUpDirection = pickUpDirection
    self._lastPickUpDirection = lastPickUpDirection
end

function ActiveSkillPickUpComponent:AddDirection(direction, pickUpGridPos)
    table.insert(self._pickUpDirection, direction)
    self._lastPickUpDirection = direction
    self._directionPickupPos[direction] = pickUpGridPos
end

function ActiveSkillPickUpComponent:RemoveDirection(direction)
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

function ActiveSkillPickUpComponent:IsRepeatDirection(direction)
    if table.icontains(self._pickUpDirection, direction) then
        return true
    end
    return false
end

function ActiveSkillPickUpComponent:ClearDirection()
    self._pickUpDirection = {}
	self._lastPickUpDirection = nil
	self._directionPickupPos={}
end

function ActiveSkillPickUpComponent:GetAllDirection()
    return self._pickUpDirection
end

---@return HitBackDirectionType,Vector2
function ActiveSkillPickUpComponent:GetLastPickDirectionAndPickPos()
    return self._lastPickUpDirection,self._directionPickupPos[self._lastPickUpDirection]
end

function ActiveSkillPickUpComponent:GetPickUpDirectionPos()
    return self._directionPickupPos
end

---@return HitBackDirectionType
function ActiveSkillPickUpComponent:GetLastPickUpDirection()
    return self._lastPickUpDirection
end

---@return boolean
function ActiveSkillPickUpComponent:IsRepeatPickUP(pickUpGridPos)
    return table.icontains(self._multiPickUpGridPosList, pickUpGridPos)
end
---@return Vector2
function ActiveSkillPickUpComponent:GetLastPickUpGridPos()
    return self._lastPickUpGridPos
end
---@return Vector2[]
function ActiveSkillPickUpComponent:GetAllValidPickUpGridPos()
    return self._multiPickUpGridPosList
end

---@return number
function ActiveSkillPickUpComponent:GetAllValidPickUpGridPosCount()
    return #self._multiPickUpGridPosList
end

function ActiveSkillPickUpComponent:AddPickUpEffectEntityID(id)
    table.insert(self._pickUpEffectEntityIDs, id)
end

function ActiveSkillPickUpComponent:GetPickUpEffectEntityIDArray()
    return self._pickUpEffectEntityIDs
end

---@return Vector2
function ActiveSkillPickUpComponent:GetFirstValidPickUpGridPos()
    if #self._multiPickUpGridPosList >=1 then
        return self._multiPickUpGridPosList[1]
    else
        Log.fatal("No PickUpGridPos Data")
        return nil
    end
end

function ActiveSkillPickUpComponent:SetReflectDir(dir)
    self._reflectDir = dir 
end

function ActiveSkillPickUpComponent:GetReflectDir()
    return self._reflectDir or ReflectDirectionType.Heng
end

function ActiveSkillPickUpComponent:SetReflectPos(pos)
    self._reflectPos = pos
end

function ActiveSkillPickUpComponent:GetReflectPos()
    return self._reflectPos
end


function ActiveSkillPickUpComponent:GetRotateGhost()
    return self._rotateGhost
end

function ActiveSkillPickUpComponent:SetRotateGhost(ghost)
    self._rotateGhost = ghost
end
--是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function ActiveSkillPickUpComponent:IsIgnorePickCheck()
    return self._ignorePickCheck
end
--设置是否不检查点选--露比 点选类型，可以不选，点方向时没有同步记录点选位置
function ActiveSkillPickUpComponent:SetIgnorePickCheck(ignorePickCheck)
    self._ignorePickCheck = ignorePickCheck
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] 
function Entity:ActiveSkillPickUpComponent()
    return self:GetComponent(self.WEComponentsEnum.ActiveSkillPickUp)
end

function Entity:HasActiveSkillPickUpComponent()
    return self:HasComponent(self.WEComponentsEnum.ActiveSkillPickUp)
end

function Entity:AddActiveSkillPickUpComponent()
    local index = self.WEComponentsEnum.ActiveSkillPickUp
    local component = ActiveSkillPickUpComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceActiveSkillPickUpComponent()
    local index = self.WEComponentsEnum.ActiveSkillPickUp
    local component = ActiveSkillPickUpComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveActiveSkillPickUpComponent()
    if self:HasActiveSkillPickUpComponent() then
        self:RemoveComponent(self.WEComponentsEnum.ActiveSkillPickUp)
    end
end
