require "play_skill_phase_base_r"

---@class PlaySkillPhase_ShowHideRole: PlaySkillPhaseBase
_class("PlaySkillPhase_ShowHideRole", PlaySkillPhaseBase)
PlaySkillPhase_ShowHideRole = PlaySkillPhase_ShowHideRole

---@param casterEntity Entity
---@param phaseParam SkillPhaseParam_ShowHideRole
function PlaySkillPhase_ShowHideRole:PlayFlight(TT, casterEntity, phaseParam)
    self:_DelayTime(TT, phaseParam:GetBeginDelay())
    local nShowType, showParam = phaseParam:GetShowData()
    if SkillPhaseParam_ShowType.Hide == nShowType then ---隐藏
        casterEntity:View():GetGameObject():SetActive(false)
    elseif SkillPhaseParam_ShowType.Show == nShowType then ---显示
        casterEntity:View():GetGameObject():SetActive(true)
    elseif SkillPhaseParam_ShowType.Replace == nShowType then --替换模型
        local newPrefab = showParam
        casterEntity:ReplaceAsset(NativeUnityPrefabAsset:New(newPrefab, true))
    elseif SkillPhaseParam_ShowType.Fade == nShowType then --渐隐渐显
        local fadeIn = showParam.fadeIn
        local isSelf = showParam.isSelf
        local duration = showParam.duration
        if isSelf then
            casterEntity:NewEnableGhost()
            self:DOFade(casterEntity, fadeIn, duration)
        else
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
            local pos = casterEntity:GridLocation().Position
            ---@type SkillDamageEffectResult
            local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, pos) --此处是为了获取目标实体，真实伤害为0
            local targetEntityID = damageResult:GetTargetID()
            local entity = self._world:GetEntityByID(targetEntityID)
            entity:NewEnableGhost()
            self:DOFade(entity, fadeIn, duration)
        end
    end
    self:_DelayTime(TT, phaseParam:GetEndDelay())
end

---@param fadeIn bool 是否渐显
function PlaySkillPhase_ShowHideRole:DOFade(e, fadeIn, duration)
    duration = duration * 0.001
    if duration <= 0 then
        if fadeIn then
            e:SetTransparentValue(1)
        else
            e:SetTransparentValue(0)
        end
        return
    end
    local tmpDuration = 0
    local factor = 0
    local func = nil
    if fadeIn then
        tmpDuration = 0
        factor = 1
        func = function()
            return tmpDuration <= 1
        end
    else
        tmpDuration = duration
        factor = -1
        func = function()
            return tmpDuration >= 0
        end
    end
    ---@type MathService
    local mathService = self._world:GetService("Math")
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            while func() do
                tmpDuration = tmpDuration + UnityEngine.Time.deltaTime * factor
                local tran = tmpDuration / duration
                tran = mathService:ClampValue(tran, 0, 1)
                e:SetTransparentValue(tran)
                YIELD(TT)
            end
        end,
        self
    )
end
