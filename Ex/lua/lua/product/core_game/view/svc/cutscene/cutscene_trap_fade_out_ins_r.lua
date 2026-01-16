require("cutscene_base_ins_r")
---@class CutsceneTrapFadeOutInstruction: CutsceneBaseInstruction
_class("CutsceneTrapFadeOutInstruction", CutsceneBaseInstruction)
CutsceneTrapFadeOutInstruction = CutsceneTrapFadeOutInstruction

function CutsceneTrapFadeOutInstruction:Constructor(paramList)
    self._duration = tonumber(paramList["duration"]) --渐变时长
end

---@param phaseContext CutscenePhaseContext
function CutsceneTrapFadeOutInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()
    --在局内战斗结束的时候 找到所有机关
    local trapGroup = world:GetGroup(world.BW_WEMatchers.Trap)
    --回放是nil
    if trapGroup then
        for i, e in ipairs(trapGroup:GetEntities()) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            if trapRenderCmpt and not trapRenderCmpt:GetHadPlayDestroy() then
                self:DOFade(e, world, self._duration)
            end
        end
    end
end

function CutsceneTrapFadeOutInstruction:DOFade(e, world, duration)
    duration = duration * 0.001
    local fadeComponent = e:View():GetGameObject():GetComponent(typeof(FadeComponent))

    if duration <= 0 then
        -- if fadeIn then
        --     e:SetTransparentValue(1)
        -- else
        -- e:SetTransparentValue(0)
        fadeComponent.Alpha = 0

        -- end
        return
    end
    local tmpDuration = 0
    local factor = 0
    local func = nil
    -- if fadeIn then
    --     tmpDuration = 0
    --     factor = 1
    --     func = function()
    --         return tmpDuration <= 1
    --     end
    -- else
    tmpDuration = duration
    factor = -1
    func = function()
        return tmpDuration >= 0
    end
    -- end

    ---@type MathService
    local mathService = world:GetService("Math")
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            while func() do
                tmpDuration = tmpDuration + UnityEngine.Time.deltaTime * factor
                local tran = tmpDuration / duration
                tran = mathService:ClampValue(tran, 0, 1)
                -- e:SetTransparentValue(tran)

                fadeComponent.Alpha = tran

                YIELD(TT)
            end
        end,
        self
    )
end
