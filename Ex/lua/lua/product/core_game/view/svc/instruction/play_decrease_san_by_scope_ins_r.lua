---@class PlayDecreaseSanByScopeInstruction:BaseInstruction
_class("PlayDecreaseSanByScopeInstruction", BaseInstruction)
PlayDecreaseSanByScopeInstruction = PlayDecreaseSanByScopeInstruction

function PlayDecreaseSanByScopeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type FeatureServiceRender
    local rsvcFeature = world:GetService("FeatureRender")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_IncreaseSan[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DecreaseSanByScope)
    if not resultArray then
        return
    end
    for _, result in ipairs(resultArray) do
        local old = result:GetOldSanValue()
        local current = result:GetNewSanValue()
        local val = result:GetVal()
        local debtVal = result:GetDebtValue()
        local modifyTimes = result:GetModifyTimes()

        rsvcFeature:NotifySanValueChange(current, old, val * (-1))

        local nt = NTSanValueChange:New(current, old,debtVal,modifyTimes)
        world:GetService("PlayBuff"):PlayBuffView(TT, nt)
    end
end
