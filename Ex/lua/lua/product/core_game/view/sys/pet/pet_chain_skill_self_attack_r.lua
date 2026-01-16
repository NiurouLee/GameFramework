--[[----------------------------------------------------------
    PetChainSkillSelfAttack 本体连锁技表现播放
]] ------------------------------------------------------------
_class("PetChainSkillSelfAttack", PetChainSkillAttack)
---@class PetChainSkillSelfAttack:PetChainSkillAttack
PetChainSkillSelfAttack = PetChainSkillSelfAttack

---播放本体的连锁技表现
---@param casterEntity Entity 宝宝本体
---@param skillID number 连锁技的技能ID
---@return number taskID 如果启动了连锁技播放，会返回技能播放的协程ID列表
function PetChainSkillSelfAttack:DoPlayPetSelfChainAttack(TT, casterEntity, skillID)
    ---取出本体的连锁技逻辑数据
    ---@type SkillChainAttackData[]
    local chainAttackData = self:_GetChainAttackDataByEntityID(casterEntity:GetID())

    ---本体的连锁技播放次数
    local chainAttackCount = #chainAttackData
    if chainAttackCount <= 0 then
        return
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local skillPhaseArray = self:_GetChainSkillPhaseArray(casterEntity, skillID)

    ---播放前需要清理，不然可能会播的是上一次的数据
    casterEntity:SkillRoutine():ClearSkillRoutine()

    local chainSkillWaitDuration = self:_GetChainSkillWaitDuration(skillID)

    local isLastPlayChainSkill = self:_IsLastPlayChainSkill(casterEntity)

    local playSkillTaskIDList = {}
    for chainIndex = 1, chainAttackCount do
        ---本次连锁技致死的目标 添加DeadFlag标志
        self:_OnResultDeadEntityAddDeadFlag(casterEntity:GetID(), chainIndex)

        ---本体连锁技能的逻辑数据
        ---@type SkillChainAttackData
        local attdata = chainAttackData[chainIndex]
        local results = attdata:GetEffectResultDict()

        ---构造用于表现的技能结果
        ---@type SkillEffectResultContainer
        local resContainer = SkillEffectResultContainer:New()
        resContainer:SetEffectResultDict(results)

        ---@type SkillEffectResult_Teleport
        local skillEffect_Teleport = resContainer:GetEffectResultByArray(SkillEffectType.Teleport)
        if skillEffect_Teleport then
            resContainer:AddEffectResult(skillEffect_Teleport)
        end

        --最后一击判定
        local isFinalAttack = attdata:IsFinalAttack()
        if chainAttackCount == chainIndex and isFinalAttack then
            self:_CheckFinalAttack(resContainer, casterEntity)
        end

        resContainer:SetScopeResult(attdata:GetScopeResult())
        resContainer:SetSkillID(skillID)
        resContainer:SetCurChainSkillIndex(chainIndex)
        casterEntity:SkillRoutine():SetResultContainer(resContainer)

        local dir = self:GetPetForward(casterEntity)
        if dir then
            casterEntity:SetDirection(dir)
        end
        local pstId = casterEntity:PetPstID():GetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.ShowHideChainSkillCG, pstId, true)

        --本体技能
        local nt1 = NTChainSkillAttackStart:New(casterEntity)
        nt1:SetChainSkillIndex(chainIndex)
        playBuffSvc:PlayBuffView(TT, nt1)
        if chainIndex == 2 then
            playBuffSvc:PlayBuffView(TT, NTSecondChainSkillAttackStart:New(casterEntity))
        end

        local taskid = playSkillService:StartSkillRoutine(casterEntity, skillPhaseArray, skillID) --启动连锁技技能播放
        playSkillTaskIDList[#playSkillTaskIDList + 1] = taskid

        if not isLastPlayChainSkill and chainSkillWaitDuration then --如果不是最后一个释放连锁技，且配置了连锁技时长
            if chainSkillWaitDuration > 0 then
                YIELD(TT, chainSkillWaitDuration)
            end
        else
            --如果没有配连锁技表现时长，则等待连锁技表现完全结束
            Log.debug(
                "### [PlayerChainAttackStateSystem_Render]<color=red>not</color> use cfg_chain_skill_duration data.",
                skillID
            )

            while not TaskHelper:GetInstance():IsTaskFinished(taskid) do
                YIELD(TT)
            end
        end

        playBuffSvc:PlayBuffView(TT, NTChainSkillAttack:New(casterEntity))
        local nt2 = NTChainSkillAttackEnd:New(casterEntity)
        nt2:SetChainSkillIndex(chainIndex)
        nt2:SetChainSkillId(skillID)
        playBuffSvc:PlayBuffView(TT, nt2)
        playBuffSvc:PlayBuffView(TT, NTChainSkillDamageEnd:New(casterEntity))

        if chainIndex == chainAttackCount then
            playBuffSvc:PlayBuffView(TT, NTSecondChainSkillAttackEnd:New(casterEntity))
        end

        playBuffSvc:PlayBuffView(TT, NTSingleChainSkillAttackFinish:New(casterEntity, chainIndex)) 

        self:_ShowChainAttackMonsterDead(TT)
    end

    ---本体的连锁技可能没有结束
    while not TaskHelper:GetInstance():IsAllTaskFinished(playSkillTaskIDList) do
        YIELD(TT)
    end
end

---提取本体的连锁技的逻辑结果
---@param casterEntityID number 施法者的EntityID
---@return SkillChainAttackData[] 连锁技数据列表
function PetChainSkillSelfAttack:_GetChainAttackDataByEntityID(casterEntityID)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    ---取出本体的连锁技逻辑数据
    ---@type SkillChainAttackData[]
    local chainAttackData = chainAtkResCmpt:GetPetChainSkillDataList(casterEntityID)

    return chainAttackData
end

---获取连锁技表现播放时长
function PetChainSkillSelfAttack:_GetChainSkillWaitDuration(skillID)
    local cfgv = Cfg.cfg_chain_skill_duration[skillID]
    if cfgv then
        return cfgv.duration
    end
end
