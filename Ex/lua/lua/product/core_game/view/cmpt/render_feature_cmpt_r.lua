--[[
    RenderFeatureComponent : 用于表现的feature组件
]]

---@class RenderFeatureComponent: Object
_class( "RenderFeatureComponent", Object )
RenderFeatureComponent = RenderFeatureComponent

---
function RenderFeatureComponent:Constructor()

end
---San每回合降低
function RenderFeatureComponent:SetCurRoundDecreaseSanValue(round,modifyValue,curVal,oldVal,debtVal,modifyTimes)
    if not self._decreaseSan then
        self._decreaseSan = {}
    end
    self._decreaseSan[round] = {modify = modifyValue,cur = curVal,old = oldVal,debt = debtVal,_modifyTimes = modifyTimes}
end
---San每回合降低
function RenderFeatureComponent:GetCurRoundDecreaseSanValue(round)
    if self._decreaseSan then
        return self._decreaseSan[round]
    end
end
---昼夜 回合数变化
function RenderFeatureComponent:SetCurRoundDayNightRouncChangeValue(round,curState,oldState,restRound)
    if not self._roundChangeDayNight then
        self._roundChangeDayNight = {}
    end
    self._roundChangeDayNight[round] = {_curState = curState,_oldState = oldState,_restRound = restRound}
end
---昼夜 回合数变化
function RenderFeatureComponent:GetCurRoundDayNightRouncChangeValue(round)
    if self._roundChangeDayNight then
        return self._roundChangeDayNight[round]
    end
end
---
---@param owner Entity
function RenderFeatureComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
---
function RenderFeatureComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end



--[[
    Entity Extensions
]]
---@return RenderFeatureComponent
function Entity:RenderFeature()
    return self:GetComponent(self.WEComponentsEnum.RenderFeature)
end

---
function Entity:HasRenderFeature()
    return self:HasComponent(self.WEComponentsEnum.RenderFeature)
end

---
function Entity:AddRenderFeature()
    local index = self.WEComponentsEnum.RenderFeature;
    local component = RenderFeatureComponent:New()
    self:AddComponent(index, component)
end

---
function Entity:ReplaceRenderFeature()
    local index = self.WEComponentsEnum.RenderFeature;
    local component = RenderFeatureComponent:New()
    self:ReplaceComponent(index, component)
end

---
function Entity:RemoveRenderFeature()
    if self:HasRenderFeature() then
        self:RemoveComponent(self.WEComponentsEnum.RenderFeature)
    end
end