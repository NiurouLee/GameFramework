require("base_ins_r")
---播放传送旋涡效果指令
---@class PlayEddyTransportInstruction: BaseInstruction
_class("PlayEddyTransportInstruction", BaseInstruction)
PlayEddyTransportInstruction = PlayEddyTransportInstruction

function PlayEddyTransportInstruction:Constructor(paramList)
    self._waitTime = tonumber(paramList["waitTime"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEddyTransportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local posCaster = casterEntity:GetGridPosition()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_EddyTransport
    local skillEffectResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.EddyTransport, posCaster)
    if nil == skillEffectResult then
        return
    end
    local nTargetID = skillEffectResult:GetTargetID()
    if nTargetID <= 0 then
        return
    end
    local world = casterEntity:GetOwnerWorld()
    --传送目标
    ---@type Entity
    local targetEntity = world:GetEntityByID(nTargetID)
    if targetEntity:HasTeam() then
        targetEntity = targetEntity:GetTeamLeaderPetEntity()
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = targetEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
    if not teleportEffectResult then
        return
    end
    --隐藏
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportHide, true, teleportEffectResult)
    --延时
    YIELD(TT, self._waitTime)
    --移动
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportMove, true, teleportEffectResult)
    --显示
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportShow, true, teleportEffectResult)
end
