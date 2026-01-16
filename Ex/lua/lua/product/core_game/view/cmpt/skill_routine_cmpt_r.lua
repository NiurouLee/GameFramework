--[[------------------------------------------------------------------------------------------
    SkillRoutineComponent : 技能过程组件，存放技能释放过程中需要的数据
]] --------------------------------------------------------------------------------------------

_class("SkillRoutineComponent", Object)
---@class SkillRoutineComponent: Object
SkillRoutineComponent = SkillRoutineComponent

function SkillRoutineComponent:Constructor()
    ---@type SkillEffectResultContainer
    self._effectResultContainer = nil
    self._resultDict = {}
    self._damageDampList = {}
end

function SkillRoutineComponent:GetResultContainer(key)
    if key then
        local v = self._resultDict[key]
        self._resultDict[key] = nil
        return v
    end
    return self._effectResultContainer
end

function SkillRoutineComponent:SetResultContainer(res, key)
    if key then
        self._resultDict[key] = res
    else
        self._effectResultContainer = res
    end
end

function SkillRoutineComponent:ClearSkillRoutine()
    self._effectResultContainer = nil
    self._resultDict = {}
    self._damageDampList = {}
end

function SkillRoutineComponent:GetDamageDampList()
    return self._damageDampList
end

function SkillRoutineComponent:SetDamageDampList(t)
    self._damageDampList = t
end

---@return SkillRoutineComponent
function Entity:SkillRoutine()
    return self:GetComponent(self.WEComponentsEnum.SkillRoutine)
end

function Entity:AddSkillRoutine()
    local index = self.WEComponentsEnum.SkillRoutine
    local component = SkillRoutineComponent:New()
    self:AddComponent(index, component)
end
