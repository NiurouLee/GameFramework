require("base_ins_r")
---播放传送旋涡效果指令
---@class PlayDimensionTransportInstruction: BaseInstruction
_class("PlayDimensionTransportInstruction", BaseInstruction)
PlayDimensionTransportInstruction = PlayDimensionTransportInstruction

function PlayDimensionTransportInstruction:Constructor(paramList)
    self._waitTime = tonumber(paramList["waitTime"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDimensionTransportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_DimensionTransport
    local result =
        skillEffectResultContainer:GetEffectResultByPos(
        SkillEffectType.DimensionTransport,
        casterEntity:GetGridPosition()
    )
    if not result then
        return
    end
    local nTargetID = result:GetTargetID()
    if nTargetID <= 0 then
        return
    end
    ---@type Entity
    local targetEntity = world:GetEntityByID(nTargetID)
    if targetEntity:HasTeam() then
        targetEntity = targetEntity:GetTeamLeaderPetEntity() --拿到队长，队伍身上没有SkillRoutine
    end
    -- local skillEffectResultContainer = targetEntity:SkillRoutine():GetResultContainer()
    -- ---@type SkillEffectResult_Teleport
    -- result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
    -- if not result then
    --     return
    -- end
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    --隐藏
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportHide, false, result)
    --延时
    YIELD(TT, self._waitTime)
    --移动
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportMove, false, result)
    --显示
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportShow, false, result)

    local posOld = result:GetPosOld()
    local posNew = result:GetPosNew()
    world:GetService("PlayBuff"):PlayBuffView(TT, NTDimensionTransport:New(targetEntity, posOld, posNew))
end
