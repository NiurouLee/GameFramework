require("base_ins_r")
---@class PlayAddComboNumInstruction: BaseInstruction
_class("PlayAddComboNumInstruction", BaseInstruction)
PlayAddComboNumInstruction = PlayAddComboNumInstruction

function PlayAddComboNumInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAddComboNumInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local resultAddComboNum = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddComboNum)
    if resultAddComboNum == nil or table.count(resultAddComboNum) == 0 then
        Log.fatal("add combo instruction ,combo result is nil")
        return
    end

    skillEffectResultContainer:SetNormalAttack(true)

    ---@type RenderBattleService
    local renderBattleSvc = world:GetService("RenderBattle")
    local curComboNum = renderBattleSvc:GetComboNum()
    curComboNum = curComboNum + 1
    renderBattleSvc:SetComboNum(curComboNum)
end
