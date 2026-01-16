require("base_ins_r")
---@class PlayTrapStateAnimationInstruction: BaseInstruction
_class("PlayTrapStateAnimationInstruction", BaseInstruction)
PlayTrapStateAnimationInstruction = PlayTrapStateAnimationInstruction

function PlayTrapStateAnimationInstruction:Constructor(paramList)
    self._openAnimName = paramList["openAnimName"]
    self._closeAnimName = paramList["closeAnimName"]
    self._hasSummonMonster = tonumber(paramList["hasSummonMonster"]) or 1
end

---@param casterEntity Entity
function PlayTrapStateAnimationInstruction:DoInstruction(TT,casterEntity,phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTrapSummonMonsterResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.TrapSummonMonster)
    if not resultArray or not resultArray[1] then
        return
    end
    ---@type SkillEffectTrapSummonMonsterResult
    local result = resultArray[1]
    if not result:GetTrapOpenStateChange() then
        return
    end
    ---@type Entity
    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end
    ---@type RenderAttributesComponent
    local renderAttrCmpt = e:RenderAttributes()
    if renderAttrCmpt:GetAttribute("OpenState")  and renderAttrCmpt:GetAttribute("OpenState")==1 then
        e:SetAnimatorControllerTriggers({self._openAnimName})
    else
        e:SetAnimatorControllerTriggers({self._closeAnimName})
    end
end