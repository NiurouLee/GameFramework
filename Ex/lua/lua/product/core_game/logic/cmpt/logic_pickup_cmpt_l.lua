--[[------------------------------------------------------------------------------------------
    LogicPickUpComponent : 点选信息的逻辑组件
]] --------------------------------------------------------------------------------------------

---@class LogicPickUpComponent: Object
_class("LogicPickUpComponent", Object)

function LogicPickUpComponent:Constructor()
    self._pickUpTargetType = SkillPickUpType.None

    ---当前的主动技能ID
    self._activeSkillID = -1
    self._petPstID = -1

    self._lastPickUpGridPos = Vector2(0, 0)
    self._curPickUpGridPos = Vector2(0, 0)
    --保证不超出版边的位置
    self._curPickUpGridPosSafe = nil
    self._entityID = -1
end

function LogicPickUpComponent:SetLogicPickUpTargetType(type)
    self._pickUpTargetType = type
end

function LogicPickUpComponent:GetLogicPickUpTargetType()
    return self._pickUpTargetType
end
function LogicPickUpComponent:GetLogicCurPickUpGridPos()
    return self._curPickUpGridPos
end

function LogicPickUpComponent:GetLogicCurPickUpGridSafePos()
    return self._curPickUpGridPosSafe
end

function LogicPickUpComponent:GetLogicPetPstid()
    return self._petPstID
end

function LogicPickUpComponent:GetEntityID()
    return self._entityID
end

function LogicPickUpComponent:SetEntityID(entityID)
    self._entityID = entityID
end

function LogicPickUpComponent:SetLogicPickUpGridPos(pickUpGridPos)
    self._lastPickUpGridPos = self._curPickUpGridPos
    self._curPickUpGridPos = pickUpGridPos
end

function LogicPickUpComponent:SetLogicPickUpGridSafePos(pickUpGridPos)
    self._curPickUpGridPosSafe = pickUpGridPos
end

function LogicPickUpComponent:GetLogicCurActiveSkillID()
    return self._activeSkillID
end

function LogicPickUpComponent:SetLogicCurActiveSkillInfo(activeSkillID, petPstID)
    self._activeSkillID = activeSkillID
    self._petPstID = petPstID
end

function LogicPickUpComponent:ResetLogicPickUp()
    self._pickUpTargetType = SkillPickUpType.None

    ---当前的主动技能ID
    self._activeSkillID = -1
    self._petPstID = -1

    self._lastPickUpGridPos = Vector2(0, 0)
    self._curPickUpGridPos = Vector2(0, 0)
    --保证不超出版边并且主角可到达的位置
    self._curPickUpGridPosSafe = nil
    self._entityID = -1
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function LogicPickUpComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function LogicPickUpComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return LogicPickUpComponent
function Entity:LogicPickUp()
    return self:GetComponent(self.WEComponentsEnum.LogicPickUp)
end

function Entity:HasLogicPickUp()
    return self:HasComponent(self.WEComponentsEnum.LogicPickUp)
end

function Entity:AddLogicPickUp()
    local index = self.WEComponentsEnum.LogicPickUp
    local component = LogicPickUpComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceLogicPickUp()
    local index = self.WEComponentsEnum.LogicPickUp
    local component = LogicPickUpComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveLogicPickUp()
    if self:HasLogicPickUp() then
        self:RemoveComponent(self.WEComponentsEnum.LogicPickUp)
    end
end
