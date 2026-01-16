--[[
    多个加血加过合并飘字。默认目标是同一个
]]
require("base_ins_r")
---@class PlayAddHpTextMergeInstruction: BaseInstruction
_class("PlayAddHpTextMergeInstruction", BaseInstruction)
PlayAddHpTextMergeInstruction = PlayAddHpTextMergeInstruction

function PlayAddHpTextMergeInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAddHpTextMergeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local addHpResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBlood)

    if not addHpResultArray then
        return
    end

    ---@type SkillEffectResult_AddBlood
    local addHpResult = addHpResultArray[1]
    local targetID = addHpResult:GetTargetID()
    local targetEntity = world:GetEntityByID(targetID)
    local skillID = skillEffectResultContainer:GetSkillID()
    local gridPos = addHpResult:GetGridPos()
    if not targetEntity then
        Log.error("[PlayInstruction_AddHpText] 没有找到目标， nSkillID = ", skillID, ", TargetID = ", targetID)
    end

    -- local addHpDamageInfo = addHpResult:GetDamageInfo()
    local damageShowType = playDamageService:SingleOrGrid(skillID)

    --合并后的值
    local addValue = 0
    local mazeDamageList = {}
    for i = 1, #addHpResultArray do
        ---@type SkillEffectResult_AddBlood
        local result = addHpResultArray[i]
        addValue = addValue + result:GetAddValue()

        ---@type DamageInfo
        local damageInfo = result:GetDamageInfo()
        if damageInfo:GetMazeDamageList() then
            for entityID, damageValue in pairs(damageInfo:GetMazeDamageList()) do
                if not mazeDamageList[entityID] then
                    mazeDamageList[entityID] = 0
                end
                mazeDamageList[entityID] = mazeDamageList[entityID] + damageValue
            end
        end
    end

    ---@type DamageInfo
    local mergeDamageInfo = DamageInfo:New(addValue, DamageType.Recover)
    mergeDamageInfo:SetMazeDamageList(mazeDamageList)
    mergeDamageInfo:SetShowType(damageShowType)
    mergeDamageInfo:SetChangeHP(addValue)
    mergeDamageInfo:SetRenderGridPos(gridPos)
    playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, mergeDamageInfo)
end
