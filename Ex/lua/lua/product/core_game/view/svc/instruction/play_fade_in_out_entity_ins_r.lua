require("base_ins_r")
---渐显渐隐实体
---@class PlayFadeInOutEntityInstruction: BaseInstruction
_class("PlayFadeInOutEntityInstruction", BaseInstruction)
PlayFadeInOutEntityInstruction = PlayFadeInOutEntityInstruction

function PlayFadeInOutEntityInstruction:Constructor(paramList)
    self._fadeIn = paramList["fadeIn"] == "true" --是否渐显
    self._target = paramList["target"] --目标
    self._duration = tonumber(paramList["duration"]) --渐变时长
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayFadeInOutEntityInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    if self._target == "self" then
        casterEntity:NewEnableGhost()
        self:DOFade(casterEntity, world)
    elseif self._target == "player" then
	    ---@type Entity
        local teamEntity = world:Player():GetCurrentTeamEntity()
	    local ePlayer= teamEntity:GetTeamLeaderPetEntity()
        ePlayer:NewEnableGhost()
        self:DOFade(ePlayer, world)
    end
end

---@param fadeIn bool 是否渐显
function PlayFadeInOutEntityInstruction:DOFade(e, world)
    local fadeIn = self._fadeIn
    self._duration = self._duration * 0.001
    if self._duration <= 0 then
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
        tmpDuration = self._duration
        factor = -1
        func = function()
            return tmpDuration >= 0
        end
    end
    ---@type MathService
    local mathService = world:GetService("Math")
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            while func() do
                tmpDuration = tmpDuration + UnityEngine.Time.deltaTime * factor
                local tran = tmpDuration / self._duration
                tran = mathService:ClampValue(tran, 0, 1)
                e:SetTransparentValue(tran)
                YIELD(TT)
            end
        end,
        self
    )
end
