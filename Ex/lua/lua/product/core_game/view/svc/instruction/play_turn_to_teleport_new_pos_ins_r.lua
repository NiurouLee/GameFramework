require("base_ins_r")
---面向到瞬移结果的新坐标
---@class PlayTurnToTeleportNewPosInstruction: BaseInstruction
_class("PlayTurnToTeleportNewPosInstruction", BaseInstruction)
PlayTurnToTeleportNewPosInstruction = PlayTurnToTeleportNewPosInstruction

function PlayTurnToTeleportNewPosInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
    self._spFix = tonumber(paramList["spFix"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToTeleportNewPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end

    local newPos = teleportEffectResult:GetPosNew()

    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local casterPos = boardServiceRender:GetRealEntityGridPos(casterEntity)
    local dir = newPos - casterPos
    ---祭剑座待机会逆时针歪45度，这里把歪的角度修正回来
    if self._spFix then
        if dir == Vector2(-1,-1) then
            dir = Vector2(-1,0)
        elseif dir == Vector2(-1,1) then
            dir = Vector2(0,1)
        elseif dir == Vector2(1,1) then
            dir = Vector2(1,0)
        elseif dir == Vector2(1,-1) then
            dir = Vector2(0,-1)
        end
    end
    casterEntity:SetDirection(dir)
end
