require("base_ins_r")
---@class PlayCasterVisibleInstruction: BaseInstruction
_class("PlayCasterVisibleInstruction", BaseInstruction)
PlayCasterVisibleInstruction = PlayCasterVisibleInstruction

function PlayCasterVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
    self._forcePlayOnSkillHolder = tonumber(paramList.forcePlayOnSkillHolder) == 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
---
function PlayCasterVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local realCaster = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() and (not self._forcePlayOnSkillHolder) then
        realCaster = casterEntity:GetSuperEntity()
    end

    -- 模型显示时血条显示，这是需求
    local isShow = self._visible == 1
    realCaster:SetViewVisible(isShow)

    ---@type HPComponent
    local cHP = realCaster:HP()

    if not cHP then
        return
    end

    local world = realCaster:GetOwnerWorld()

    local eidHPBar = cHP:GetHPSliderEntityID()
    local hpBarEntity = world:GetEntityByID(eidHPBar)

    if not hpBarEntity then
        return
    end

    if realCaster:HasMonsterID() then
        local monsrsvc = world:GetService("MonsterShowRender")
        monsrsvc:ShowMonsterHPBar(TT, realCaster, hpBarEntity, isShow)
    end
end
