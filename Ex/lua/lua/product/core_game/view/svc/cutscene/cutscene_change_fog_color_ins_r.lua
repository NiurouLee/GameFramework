require("cutscene_base_ins_r")
---@class CutsceneChangeFogColorInstruction: CutsceneBaseInstruction
_class("CutsceneChangeFogColorInstruction", CutsceneBaseInstruction)
CutsceneChangeFogColorInstruction = CutsceneChangeFogColorInstruction

function CutsceneChangeFogColorInstruction:Constructor(paramList)
    self._duration = tonumber(paramList["duration"]) --渐变时长
    self._colorR = tonumber(paramList["colorR"]) or 255
    self._colorG = tonumber(paramList["colorG"]) or 255
    self._colorB = tonumber(paramList["colorB"]) or 255
    self._colorA = tonumber(paramList["colorA"]) or 255
end

---@param phaseContext CutscenePhaseContext
function CutsceneChangeFogColorInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()

    local goRenderSetting = UnityEngine.GameObject.Find("[H3DRenderSetting]")
    local csRenderSetting = goRenderSetting:GetComponent("H3DRenderSetting")

    --初始颜色
    local flogColor = csRenderSetting.FlogColor

    --目标颜色
    local targetColor = Color(self._colorR / 255, self._colorG / 255, self._colorB / 255, self._colorA / 255)

    --当前运行时间
    local runTime = 0
    self._duration = self._duration / 1000

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            while runTime <= self._duration do
                runTime = runTime + UnityEngine.Time.deltaTime
                local timePercent = runTime / self._duration
                local colorR = Mathf.Clamp(timePercent, flogColor.r, targetColor.r)
                local colorG = Mathf.Clamp(timePercent, flogColor.g, targetColor.g)
                local colorB = Mathf.Clamp(timePercent, flogColor.b, targetColor.b)
                local colorA = Mathf.Clamp(timePercent, flogColor.a, targetColor.a)

                local newColor = Color(colorR, colorG, colorB, colorA)
                -- UnityEngine.Shader.SetGlobalColor("h3d_FogHighColor", newColor)
                csRenderSetting.FlogColor = newColor

                YIELD(TT)
            end
        end
        -- self
    )
end
