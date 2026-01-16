require "play_skill_phase_base_r"
--@class PlaySkillRoleCGPhase: Object
_class("PlaySkillRoleCGPhase", PlaySkillPhaseBase)
PlaySkillRoleCGPhase = PlaySkillRoleCGPhase

function PlaySkillRoleCGPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseRoleCGParam
    local roleCGParam = phaseParam
    local cgTimeLen = roleCGParam:GetCGTimeLen()
    local cgRes = roleCGParam:GetCGRes()
    local hideRoleTime = roleCGParam:GetHideRoleTime()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BattleRenderConfigComponent
    local battleRenderConfigCmpt = world:BattleRenderConfig()
    local canPlayCG = battleRenderConfigCmpt:GetCanPlaySkillSpineInBattle(cgRes)

    if not canPlayCG then
        return
    end

    if hideRoleTime then
        YIELD(TT, hideRoleTime)
    end
    if hideRoleTime then
        casterEntity:SetViewVisible(false)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowUltraSkillSpine, cgRes)
    YIELD(TT, cgTimeLen)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.StopUltraSkillSpine, cgRes)
    if hideRoleTime then
        casterEntity:SetViewVisible(true)
    end
end
