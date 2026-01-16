require "play_skill_flight_base_r"

---@class PlaySkillFlightVehiclePhase: PlaySkillFlightBase
_class("PlaySkillFlightVehiclePhase", PlaySkillFlightBase)
PlaySkillFlightVehiclePhase = PlaySkillFlightVehiclePhase

function PlaySkillFlightVehiclePhase:_GetGridList(pet_entity)
    local petSkillRoutine = pet_entity:SkillRoutine():GetResultContainer()
    local scopeResult = petSkillRoutine:GetScopeResult()
    if (scopeResult == nil) then
        return nil
    end
    local chainGrid = scopeResult:GetAttackRange()
    return chainGrid
end
function PlaySkillFlightVehiclePhase:_GetFlyOneGridMS(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetFlyOneGridMS()
end
function PlaySkillFlightVehiclePhase:_GetGridEffectID(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetGridEffectID()
end
function PlaySkillFlightVehiclePhase:_GetHitAnimName(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetHitAnimName()
end
function PlaySkillFlightVehiclePhase:_GetHitEffectID(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetHitEffectID()
end
function PlaySkillFlightVehiclePhase:_GetDisappearEffectID(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetDisappearEffectID()
end
function PlaySkillFlightVehiclePhase:_GetBornEffectID(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetBornEffectID()
end
function PlaySkillFlightVehiclePhase:_GetBornEffectDelay(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetBornEffectDelay()
end
function PlaySkillFlightVehiclePhase:_GetFlyStartMs(phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return waveGridArrayParam:GetFlyStartMs()
end
function PlaySkillFlightVehiclePhase:_Move(go, tran, worldPos, gridWorldpos, disx, flyOneGridMs, phaseParam, atklist)
    tran:DOMove(gridWorldpos, disx * flyOneGridMs / 1000.0, false):SetEase(DG.Tweening.Ease.InOutSine):OnComplete(
        function()
            go:SetActive(false)
        end
    )
end
function PlaySkillFlightVehiclePhase:_GetFlyTime(maxLength, phaseParam)
    ---@type SkillFlightVehcileGridArrayParam
    local waveGridArrayParam = phaseParam
    return maxLength * (waveGridArrayParam:GetFlyOneGridMS()), maxLength * (waveGridArrayParam:GetFlyOneGridMS())
end
