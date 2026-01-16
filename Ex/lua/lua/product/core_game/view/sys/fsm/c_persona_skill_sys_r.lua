--[[------------------------------------------------------------------------------------------
    ClientPersonaSkillSystem_Render：客户端实现P5合击技（后扩展为模块技）状态的表现部分
]] --------------------------------------------------------------------------------------------

require "persona_skill_system"

---@class ClientPersonaSkillSystem_Render:PersonaSkillSystem
_class("ClientPersonaSkillSystem_Render", PersonaSkillSystem)
ClientPersonaSkillSystem_Render = ClientPersonaSkillSystem_Render

function ClientPersonaSkillSystem_Render:_DoRenderPreFeatureSkillStart(TT)
    --启动effect相机
    self._world:MainCamera():EnableEffectCamera(true)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ResetWaitFreeList()
end

function ClientPersonaSkillSystem_Render:_DoRenderNotifyFeatureSkillStart(TT, teamEntity, casterEntity)
end

function ClientPersonaSkillSystem_Render:_DoRenderWaitPlaySkillTaskFinish(TT)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local listWaitTask = playSkillService:GetWaitFreeList()
    self:_WaitTasksEnd(TT, listWaitTask)
end
---@param listTrapTrigger Entity[]
function ClientPersonaSkillSystem_Render:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity)
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = self._world:GetService("PlaySkillInstruction")
    --local listTrapTask = sPlaySkillInstruction:PlayTrapTrigger(TT, casterEntity, listTrapTrigger)
    local listTrapTask = sPlaySkillInstruction:PlayTrapTrigger(TT, teamEntity, listTrapTrigger)
    self:_WaitTasksEnd(TT, listTrapTask)
end
function ClientPersonaSkillSystem_Render:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)
    ---战斗结束
    --格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
    pieceService:RefreshMonsterAreaOutLine(TT)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_ResetGridElement
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    if result then
        local array = result:GetResetGridData()
        playBuffService:PlayBuffView(TT, NTResetGridElement:New(array, casterEntity))
        playBuffService:PlayBuffView(TT, NTResetGridFlushTrap:New())
    end
end

function ClientPersonaSkillSystem_Render:_DoRenderResetPreview(TT, teamEntity, casterEntity)
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = casterEntity:PreviewConvertElement()
    if previewConvertElementCmpt ~= nil then
        previewConvertElementCmpt:SetTempConvertElementDic({})
    else
        Log.notice("Clear Convert Element no cmpt")
    end
end

function ClientPersonaSkillSystem_Render:_DoRenderNotifyFeatureSkillFinish(TT, teamEntity, casterEntity,featureType,skillID)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTFeatureSkillAttackEnd:New(featureType,skillID))
end

function ClientPersonaSkillSystem_Render:_DoRenderShowAfterFeatureSkill(TT, teamEntity, casterEntity)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowPlayerEntity(teamEntity)

    --隐藏effect相机
    self._world:MainCamera():EnableEffectCamera(false)

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    --关闭暗屏
    previewActiveSkillService:StopDarkScreenImmediately()
end

function ClientPersonaSkillSystem_Render:_DoRenderPlayFeatureSkill(isFinalAttack, teamEntity, casterEntity)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2RFeatureAttackResult
    local result = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.FeatureAttack)
    local skillResult = result:GetSkillResult()

    local skillID = result:GetL2RFeatureAttackResult_SkillID()
    --技能演播
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local skinId = 1
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)

    casterEntity:SkillRoutine():ClearSkillRoutine()
    casterEntity:SkillRoutine():SetResultContainer(skillResult)
    ---检查静帧效果，内部会判断是否是玩家施法，这个方法更适合放在玩家阶段去做
    self:_CheckFreezeTime(casterEntity, isFinalAttack)

    local waitTaskID = playSkillService:StartSkillRoutine(casterEntity, skillPhaseArray, skillID)

    return waitTaskID
end

---@param casterEntity Entity 施法者
---@param targetIDArray Array 目标列表
function ClientPersonaSkillSystem_Render:_CheckFreezeTime(casterEntity, isFinalAttack)
    if not isFinalAttack then
        return
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIDArray = scopeResult:GetTargetIDs()
    if table.count(targetIDArray) <= 0 then
        return
    end

    skillEffectResultContainer:SetFinalAttack(true)
end

-- function ClientPersonaSkillSystem_Render:_DoRenderInWave(TT, traps, monsters)
--     ---@type MonsterShowRenderService
--     local sMonsterShowRender = self._world:GetService("MonsterShowRender")
--     sMonsterShowRender:PlaySpawnInWave(TT, traps, monsters)
-- end

function ClientPersonaSkillSystem_Render:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:DoAllMonsterDeadRender(TT)
end

function ClientPersonaSkillSystem_Render:_DoRenderResetPickUp()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:Reset()
end
function ClientPersonaSkillSystem_Render:_DoRenderFeatureSkillEnd(TT,teamEntity, casterEntity)
    if casterEntity then
        casterEntity:RemoveRenderPickUpComponent()
    end
end