--[[----------------------------------------------------------
    PetChainSkillAgentAttack 代理对象的连锁技表现播放
]] ------------------------------------------------------------
require("pet_chain_skill_attack_r")

_class("PetChainSkillAgentAttack", PetChainSkillAttack)
---@class PetChainSkillAgentAttack:PetChainSkillAttack
PetChainSkillAgentAttack = PetChainSkillAgentAttack

---播放代理的连锁技表现
---@param casterEntity Entity 宝宝本体
---@param skillID number 连锁技的技能ID
---@return number taskID 如果启动了连锁技播放，会返回技能播放的协程ID列表
function PetChainSkillAgentAttack:DoPlayPetAgentChainAttack(TT, casterEntity, skillID)
    --代理连锁
    ---@type BuffViewComponent
    local buffViewCmpt = casterEntity:BuffView()
    local agentChainEntityID = buffViewCmpt:GetBuffValue("AgentChainEntityID")
    ---@type Entity
    local agentChainEntity = self._world:GetEntityByID(agentChainEntityID)
    if not agentChainEntity then
        return
    end

    agentChainEntity:SkillRoutine():ClearSkillRoutine()

    local agentDataList = self:_GetAgentChainAttackDataByEntityID(casterEntity:GetID())

    local chainAttackCount = #agentDataList
    if chainAttackCount <= 0 then
        return
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    for chainIndex = 1, chainAttackCount do
        ---本次连锁技致死的目标 添加DeadFlag标志
        self:_OnResultDeadEntityAddDeadFlag(casterEntity:GetID(), chainIndex)

        local agentData = agentDataList[chainIndex]
        local agentPos = agentChainEntity:GridLocation():GetGridPos()
        local agentDir = casterEntity:GridLocation():GetGridDir()
        agentChainEntity:SetLocation(agentPos, agentDir)

        local results = agentData:GetEffectResultDict()

        ---@type SkillEffectResultContainer
        local resContainer = SkillEffectResultContainer:New()
        resContainer:SetEffectResultDict(results)
        resContainer:SetScopeResult(agentData:GetScopeResult())

        --最后一击判定
        local isFinalAttack = agentData:IsFinalAttack()
        if chainAttackCount == chainIndex and isFinalAttack then
            self:_CheckFinalAttack(resContainer, casterEntity)
        end
        agentChainEntity:SkillRoutine():SetResultContainer(resContainer)

        local skillPhaseArray = self:_GetChainSkillPhaseArray(agentChainEntity, agentData:GetSkillID())

        local taskid = playSkillService:StartSkillRoutine(agentChainEntity, skillPhaseArray, agentData:GetSkillID())

        while not TaskHelper:GetInstance():IsTaskFinished(taskid, true) do
            YIELD(TT)
        end
        playBuffSvc:PlayBuffView(TT, NTSingleChainSkillAttackFinish:New(casterEntity, chainIndex))
        self:_ShowChainAttackMonsterDead(TT)
    end
end

---提取代理对象的连锁技的逻辑结果
---@param casterEntityID number 施法者的EntityID
---@return SkillChainAttackData[] 连锁技数据列表
function PetChainSkillAgentAttack:_GetAgentChainAttackDataByEntityID(casterEntityID)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    ---@type SkillChainAttackData[]
    local chainAttackData = chainAtkResCmpt:GetPetAgentChainSkillDataList(casterEntityID)

    return chainAttackData
end
