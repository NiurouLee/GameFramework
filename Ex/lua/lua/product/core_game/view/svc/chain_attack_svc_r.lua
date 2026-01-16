require("base_service")

_class("ChainAttackServiceRender", BaseService)
---@class ChainAttackServiceRender:BaseService
ChainAttackServiceRender = ChainAttackServiceRender

function ChainAttackServiceRender:Constructor(world)
    self.world = world
end

---@param teamEntity Entity
function ChainAttackServiceRender:_DoRenderShowChainAttack(TT, teamEntity)
    local ntChainStart = NTChainSkillTurnStart:New(teamEntity)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntChainStart)
    --NTChainSkillTurnStart 在被麻痹等情况下不会再逻辑上发送，新增NTChainSkillTurnStartBeSkipped
    --逻辑发送这个通知是有条件的，这里其实没有判断，但道理上应该问题不大？
    local ntChainSkip = NTChainSkillTurnStartSkipped:New(teamEntity)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntChainSkip)

    --在连锁技释放以前，将星灵头像移动回去
    for i, pet in ipairs(teamEntity:Team():GetTeamPetEntities()) do
        self._world:EventDispatcher():Dispatch(GameEventType.InOutQueue, pet:PetPstID():GetPstID(), false)
    end

    --队长
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()

    if teamEntity:HasChainSkillSequence() then
        teamEntity:RemoveChainSkillSequence()
    end

    --检查队长的连锁技能不能放
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkRes = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)
    local playerHasChainAttack = chainAtkRes:GetPetHasCastChainSkill(teamLeaderEntity:GetID())
    renderBoardEntity:ReplaceRenderRoundTeam(chainAtkRes:GetChainTeamResult())

    ---@type RenderChainPathComponent
    local rchainpath = renderBoardEntity:RenderChainPath()

    local piece_type = rchainpath:GetRenderPieceType()
    teamEntity:AddChainSkillSequence()

    ---@type ChainSkillSequenceComponent
    local chain_skill_sequence_cmpt = teamEntity:ChainSkillSequence()
    local chain_skill_sequence_table = chain_skill_sequence_cmpt.ChainSkillSeqTable
    self:_CalcChainSkillCount(teamEntity, piece_type, chain_skill_sequence_table)

    --检查是否需要挂，给谁挂，最后一击的标记
    -- self:_CheckFinalAttack()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local chainSkillCnt = #chain_skill_sequence_table
    if #chain_skill_sequence_table > 0 then
        local firstPetID = chain_skill_sequence_table[1]
        self:_HideOtherPetsExcept(firstPetID)

        if self:_HasSuperChainSkill() == false and playerHasChainAttack then
            YIELD(TT, 200)
        end

        --找第一个可以转入连锁技攻击的宝宝
        local petEntityID = self:_GetFirstChainSkillActorID(chain_skill_sequence_table)
        local petEntity = self._world:GetEntityByID(petEntityID)
        petEntity:AddChainSkillFlag()

        ---开始连锁技前压暗
        pieceService:SetAllPieceDark()

        ---通知星灵进入连锁技攻击状态
        GameGlobal.EventDispatcher():Dispatch(GameEventType.IdleEnd, 2, petEntityID)

        while #chain_skill_sequence_table > 0 do
            YIELD(TT, 100)
        end
    end

    ---传送门进入的连锁攻击阶段，当没有连锁技触发时，也需要恢复格子动画，所以提到外面来 MSG66114
    ---全部连锁技结束后还原
    pieceService:RefreshPieceAnim()

    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTChainSkillTurnEnd:New(chainSkillCnt))
end

---@param teamEntity Entity
function ChainAttackServiceRender:_CalcChainSkillCount(teamEntity, pieceType, chainSkillSequenceTable)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local rchainpath = renderBoardEntity:RenderChainPath()
    local renderChainPathCmpt = self._world:GetRenderBoardEntity():RenderChainPath()
    local chainRate = renderChainPathCmpt:GetRenderPathChainRateAtIndex(#rchainpath:GetRenderChainPath())

    local petRoundTeam = self:_GetChainPetRoundTeam()
    for petIndex = 1, #petRoundTeam do
        local petEntityID = petRoundTeam[petIndex]

        local petHasAttack = chainAtkResCmpt:GetPetHasCastChainSkill(petEntityID)
        if petHasAttack and not table.icontains(chainSkillSequenceTable, petEntityID) then
            chainSkillSequenceTable[#chainSkillSequenceTable + 1] = petEntityID

            local petEntity = self._world:GetEntityByID(petEntityID)
            petEntity:ReplaceChainSkill(chainRate)
        end
    end
end

function ChainAttackServiceRender:_HideOtherPetsExcept(entityID)
    local petRoundTeam = self:_GetChainPetRoundTeam()
    for petIndex = 1, #petRoundTeam do
        local petEntityID = petRoundTeam[petIndex]
        local petEntity = self._world:GetEntityByID(petEntityID)
        if petEntity:HasViewExtension() then
            petEntity:SetViewVisible(entityID == petEntityID)
        end
    end
end

function ChainAttackServiceRender:_GetFirstChainSkillActorID(chain_skill_sequence_table)
    local pet_entity_id = chain_skill_sequence_table[1]
    if not pet_entity_id then
        pet_entity_id = -1
    end
    return pet_entity_id
end

function ChainAttackServiceRender:_HasSuperChainSkill()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()

    local petRoundTeam = self:_GetChainPetRoundTeam()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    for i, v in ipairs(petRoundTeam) do
        local petEntity = self._world:GetEntityByID(v)
        ---@type ChainSkillComponent
        local chainSkillCmpt = petEntity:ChainSkill()
        local hasDamage = chainAtkResCmpt:ChainAttackResultHasDamage(v)
        if hasDamage == true and chainSkillCmpt ~= nil then
            local realChainNum = chainSkillCmpt:GetChainNum()
            if realChainNum >= superChainCount then
                return true
            end
        end
    end

    return false
end

function ChainAttackServiceRender:_StopFocusEffect(TT)
    self._world:MainCamera():EnableDarkCamera(false)
    local toNormalTime = BattleConst.ChainSkillToNormalTime
    local targetAlpha = 0
    local originalAlpha = BattleConst.ChainSkillDarkAlpha

    ---关闭相机暗屏机制
    self._world:MainCamera():EnableDarkCamera(false)

    local lastTime = 0
    ---@type TimeService
    local timeService = self._world:GetService("Time")
    local curTime = timeService:GetCurrentTimeMs()
    local startTime = curTime
    local timeLen = curTime - startTime
    while timeLen < toNormalTime do
        local deltaTime = timeService:GetDeltaTimeMs()
        timeLen = timeLen + deltaTime

        local percent = timeLen / toNormalTime
        local imgAlpha = originalAlpha - percent * originalAlpha

        self._world:MainCamera():SetHudBgAlpha(imgAlpha)

        self._world:EventDispatcher():Dispatch(GameEventType.SetHeadMaskAlpha, imgAlpha)
        YIELD(TT)
    end
end

function ChainAttackServiceRender:_DoRenderShowSuperChainSkill(TT, teamEntity)
    local isSuperChainSkill = self:_HasSuperChainSkill()
    local focusEffectTaskID = -1
    if isSuperChainSkill == true then
        ---启动暗屏并显示UI
        focusEffectTaskID = GameGlobal.TaskManager():CoreGameStartTask(self._StartFocusEffect, self)
        ---@type RenderEntityService
        local renderEntitySvc = self._world:GetService("RenderEntity")
        local pos = renderEntitySvc:GetScreenHeadPos(teamEntity)

        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideSuperChain, true, pos)
        YIELD(TT, 1000)
        ---关闭UI
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideSuperChain, false)
    end

    if focusEffectTaskID > 0 then
        while not TaskHelper:GetInstance():IsTaskFinished(focusEffectTaskID) do
            YIELD(TT)
        end
    end
end

function ChainAttackServiceRender:_StartFocusEffect(TT)
    local toDarkTime = BattleConst.ChainSkillToDarkTime
    local targetAlpha = BattleConst.ChainSkillDarkAlpha

    ---激活相机暗屏机制
    self._world:MainCamera():EnableDarkCamera(true)

    local lastTime = 0

    ---@type TimeService
    local timeService = self._world:GetService("Time")
    local curTime = timeService:GetCurrentTimeMs()
    local startTime = curTime
    local timeLen = curTime - startTime
    while timeLen < toDarkTime do
        local deltaTime = timeService:GetDeltaTimeMs()
        timeLen = timeLen + deltaTime

        local percent = timeLen / toDarkTime
        local imgAlpha = percent * targetAlpha

        self._world:MainCamera():SetHudBgAlpha(imgAlpha)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SetHeadMaskAlpha, imgAlpha)
        YIELD(TT)
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:SetAllPieceDark()
end

function ChainAttackServiceRender:_GetChainPetRoundTeam()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()
    return petRoundTeam
end
