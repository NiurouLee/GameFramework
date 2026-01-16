--[[------------------------------------------------------------------------------------------
    ActiveSkillComponent : 主动技属性组件，驱动主动技的施法，逻辑组件
]] --------------------------------------------------------------------------------------------

_class("ActiveSkillComponent", Object)
---@class ActiveSkillComponent: Object
ActiveSkillComponent = ActiveSkillComponent

function ActiveSkillComponent:Constructor()
    self._activeSkillID = -1
    self._casterPetEntityID = -1
    self._powerfullRoundCount = {} --自动战斗大招积攒回合数
    self._previousReadyRoundCount = {} --技能上回合就绪后，每回合开始计数加1 _powerfullRoundCount 这个首回合先制时不会计数
end

function ActiveSkillComponent:SetActiveSkillID(activeSkillID, casterEntityID)
    self._activeSkillID = activeSkillID
    self._casterPetEntityID = casterEntityID
end

function ActiveSkillComponent:GetActiveSkillID()
    return self._activeSkillID
end

function ActiveSkillComponent:GetActiveSkillCasterEntityID()
    return self._casterPetEntityID
end

function ActiveSkillComponent:AddPowerfullRoundCount(entityId, cnt)
    self._powerfullRoundCount[entityId] = (self._powerfullRoundCount[entityId] or 0) + cnt
end

function ActiveSkillComponent:ClearPowerfullRoundCount(entityId)
    self._powerfullRoundCount[entityId] = 0
end

function ActiveSkillComponent:GetPowerfullRoundCount(entityId)
    return self._powerfullRoundCount[entityId] or 0
end
--与AddPowerfullRoundCount系列的区别是，只有在previousReady下才计数
-- AddPowerfull 在首回合（先制情况下）不计数（不+1），但释放技能后又ready的那回合会+1
function ActiveSkillComponent:AddPreviousReadyRoundCount(entityId, cnt)
    self._previousReadyRoundCount[entityId] = (self._previousReadyRoundCount[entityId] or 0) + cnt
end

function ActiveSkillComponent:ClearPreviousReadyRoundCount(entityId)
    self._previousReadyRoundCount[entityId] = 0
end

function ActiveSkillComponent:GetPreviousReadyRoundCount(entityId)
    return self._previousReadyRoundCount[entityId] or 0
end

function ActiveSkillComponent:ResetActiveSkillCmpt()
    self._activeSkillID = -1
    self._casterPetEntityID = -1
    self._powerfullRoundCount = {}
    self._previousReadyRoundCount = {}
end
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:ActiveSkill()
    return self:GetComponent(self.WEComponentsEnum.ActiveSkill)
end

function Entity:HasActiveSkill()
    return self:HasComponent(self.WEComponentsEnum.ActiveSkill)
end

function Entity:AddActiveSkill()
    local index = self.WEComponentsEnum.ActiveSkill
    local component = ActiveSkillComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceActiveSkill()
    local index = self.WEComponentsEnum.ActiveSkill
    local component = ActiveSkillComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveActiveSkill()
    if self:HasActiveSkill() then
        self:RemoveComponent(self.WEComponentsEnum.ActiveSkill)
    end
end
