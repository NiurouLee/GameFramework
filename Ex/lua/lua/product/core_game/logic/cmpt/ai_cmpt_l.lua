--[[------------------------------------------------------------------------------------------
    AIComponentNew : 怪物AI组件
]] --------------------------------------------------------------------------------------------
_class("AIComponentNew", Object)
---@class AIComponentNew: Object
AIComponentNew = AIComponentNew

AIMoveState = {
    NotMove = 1,
    Moving = 2,
    MoveEnd = 3
}
function AIComponentNew:Constructor()
    ---同一个怪可以有多套AI，以供在不同的阶段执行
    ---目前支持在怪物反制、怪物前置、主回合三个阶段分别配置
    ---然后每个阶段里有多个顺序（order），每个顺序可以有一套AI
    ---此表是key-value结构，其中key是AILogicPeriodType,
    ---value是一个数组，表示多个order的执行，每个元素是一个AI执行体
    --- AILogicPeriodType1 --- [order1] --- [AILogic]
    ---                    --- [order2] --- [AILogic]
    ---                    --- [order3] --- [AILogic]
    --- AILogicPeriodType2 --- [order1] --- [AILogic]
    ---                    --- [order2] --- [AILogic]
    ---                    --- [order3] --- [AILogic]

    ---@type AILogicNode[] 常驻AI逻辑 执行实时技能选择以及其他实时互动效果等逻辑
    self.m_logicList = {}

    ---当前的行为树
    ---@type AILogicNode
    self.m_rootLogic = nil ---根节点

    ---@type AILogicNode
    self.m_logicPreview = nil ---预览使用的根节点
    self.m_nMonsterID = 0
    ---@type int 行动力
    self.m_nMobilityConfig = 0 --配置文件标定的标准行动力
    self.m_nMobilityTotal = 0 --每回合的总行动力，初始化为self.m_nMobilityConfig
    ---@type ArrayList
    self.m_listMoveTarget = ArrayList:New() --移动目标列表
    ---@type Entity 目标Entity 考虑多人模式 需要动态选择目标
    self._targetEntity = nil
    ---@type MainWorld
    self.m_world = nil
    self.m_nStatus = AINewNodeStatus.Ready

    self._runtimeData = {}

    self.canMove = true
    self.canTurn = true
    ---临时存储替换的AI
    ---@type AILogicNode
    self.m_cutLogic = nil

    ---上次移动过的位置
    self.m_lastMovePos = nil

    self._ownerEntity = nil

    ---技能范围  特定技能需要在前一回合 随机出下一回合的技能范围（怪物鸣灼）
    ---在技能预览 或者 逻辑计算范围的时候 如果技skillID取出来的 scopeType = 48 那么技能范围取这里的
    self._skillScopeResult = {}
    ---@type number
    self.m_nCreateRound = 0 ---创建AI的回合数

    self.m_nSelectSkillID = 0

    self._moveState = AIMoveState.NotMove
    self._treeState = 1 --给行为树用的状态标记，默认是1
    ---用于标记当前回合结束的标记
    self._isAIRoundEnd = false

    self._targetTeamEntity = nil

    --AI目标，认为这个是怪物/机关的属性。只在初始化设置一次，变身不替换。
    self._aiTargetType = AITargetType.Normal
    --key的AI一回合运行了第多少次
    ---@type table<number, number>
    self._aiRunCount = {}

    self._treeContext = {}
	
    self._hasAntiSkill = false
end

function AIComponentNew:AddAIRoundRunCount(aiConfigID)
    if not self._aiRunCount[aiConfigID] then
        self._aiRunCount[aiConfigID] = 0
    end
    self._aiRunCount[aiConfigID] = self._aiRunCount[aiConfigID] + 1
end

function AIComponentNew:ClearAIRoundRunCount()
    self._aiRunCount = {}
end

function AIComponentNew:GetAIRoundRunCount(aiConfigID)
    return self._aiRunCount[aiConfigID] or 0
end

function AIComponentNew:GetMoveState()
    return self._moveState
end

function AIComponentNew:SetMoveState(st)
    if self._moveState == st then
        return
    end
    --Log.debug("[AI] AIEntityID=", self._ownerEntity:GetID(), " SetMoveState=", GetEnumKey("AIMoveState", st))

    --Log.fatal("SetMoveState",Log.traceback())
    self._moveState = st
end

function AIComponentNew:GetSelectSkillID()
    return self.m_nSelectSkillID
end

function AIComponentNew:SetSelectSkillID(nSkillID)
    local _id = tonumber(nSkillID)
    if not _id then
        Log.exception(self._className, "Cannot select a non-number skill id: ", nSkillID)
        return
    end

    self.m_nSelectSkillID = nSkillID
end

--------------------------------操作 m_logicList
---剪切特定的AI序列到临时保存位置，
function AIComponentNew:GetCutLogic()
    return self.m_cutLogic
end
---@param nLogicType AILogicPeriodTypee
---@param pLogic AILogicNode
function AIComponentNew:SetCutLogic(pLogic)
    self.m_cutLogic = pLogic
end
function AIComponentNew:ExchangeOnceLogic(nLogicType)
    local pLogicOld = self.m_logicList[nLogicType]
    self.m_logicList[nLogicType] = self.m_cutLogic
    self.m_cutLogic = pLogicOld
    if nLogicType == AILogicPeriodType.Main then
        self:SetPreviewLogic(nLogicType, AILogicOrderType.BaseOrder)
    end
end
--------------------------------
---@param logicType AILogicPeriodType
---@param logic AILogicNode
function AIComponentNew:AddLogic(aiLogicPeriodType, logic, order)
    local periodAIList = self.m_logicList[aiLogicPeriodType]
    if periodAIList == nil then
        self.m_logicList[aiLogicPeriodType] = {}
        periodAIList = self.m_logicList[aiLogicPeriodType]
    end
    local logicOrder = order or AILogicOrderType.BaseOrder
    periodAIList[logicOrder] = logic

    if logic then
        logic:SetActive(false)
        self._treeContext[logic.InstanceID] = {}
    end
end

---提取Entity的某个阶段的所有顺序的执行序列
---@param aiLogicPeriodType AILogicPeriodType 执行阶段
function AIComponentNew:GetAILogicOrders(aiLogicPeriodType)
    local periodAIList = self.m_logicList[aiLogicPeriodType]
    local orderList = {}
    if periodAIList then
        for key, _ in pairs(periodAIList) do
            orderList[#orderList + 1] = key
        end
    end
    return orderList
end

---指定要执行的AI行为树
---@param logicType AILogicPeriodType 执行阶段
---@param order AILogicOrderType 执行顺序
function AIComponentNew:SelectLogic(logicType, order)
    order = order or AILogicOrderType.BaseOrder
    local aiLogic = self:_FindLogic(logicType, order)
    if aiLogic then
        self.m_rootLogic = aiLogic
        self:SetRunningSign(logicType, order)
    end
end

--------------------------------
---查找对应的AI执行序列
---@param nLogicType AILogicPeriodType
---@param nOrder AILogicOrderType
function AIComponentNew:_FindLogic(nLogicType, nOrder)
    local periodLogic = self.m_logicList[nLogicType]
    if not periodLogic then
        return
    end
    local logic = periodLogic[nOrder]
    return logic
end

--设置AI根节点有效
function AIComponentNew:_SetActive(bActive)
    if self.m_rootLogic then
        self.m_rootLogic:SetActive(bActive)
    end
end

--接受状态机的状态变更消息
function AIComponentNew:OnEvent_EnableAiLogic(entityWork, nLogicType, order)
    self:InitAiLogic(AINewNodeStatus.Ready, entityWork, nLogicType, order)
end

function AIComponentNew:OnEvent_DisableAiLogic(entityWork)
    self:_SetActive(false)
    self.m_rootLogic = nil
end

function AIComponentNew:GetRootLogicID()
    local nLogicID = 0
    if self.m_rootLogic then
        nLogicID = self.m_rootLogic:GetAILogicID()
    end
    return nLogicID
end

function AIComponentNew:ResetLogic()
    self.m_nStatus = AINewNodeStatus.Ready
    if self.m_rootLogic then
        self.m_rootLogic:Reset()
    end
end

---@param nStatus AINewNodeStatus
---@param monsterEntity Entity
---@param nLogicType AILogicPeriodType
---@param order AILogicOrderType
function AIComponentNew:InitAiLogic(nStatus, monsterEntity, nLogicType, order)
    self.m_nStatus = nStatus
    self:SelectLogic(nLogicType, order)
    if self.m_rootLogic then
        self.m_rootLogic:Reset()
    end
    if self:IsLogicEnd() then
        self.m_nMobilityTotal = 0
    else
        self.m_nMobilityTotal = monsterEntity:Attributes():GetAIMobility()
    end

    self:OutLog("初始化行动力", " m_nMobilityTotal = ", self.m_nMobilityTotal)
    ---校验总行动力的有效性
    if self.m_nMobilityTotal <= 0 then
        self.m_nStatus = AINewNodeStatus.Success
        return
    end
    self._targetTeamEntity = self.m_world:Player():GetLocalTeamEntity()
    self._targetEntity = self._targetTeamEntity

    --Ai目标
    if self._aiTargetType == AITargetType.Normal then
        --常规Ai，有守护机关打守护机关，没有再打人
        local trapGroup = self.m_world:GetGroup(self.m_world.BW_WEMatchers.Trap)
        for _, e in ipairs(trapGroup:GetEntities()) do
            ---@type TrapComponent
            local trapCmpt = e:Trap()
            local trapType = trapCmpt:GetTrapType()
            if trapType == TrapType.Protected then
                self._targetEntity = e
                break
            end
        end
    elseif self._aiTargetType == AITargetType.Team then
        --无视守护机关直接打人
        self._targetEntity = self._targetTeamEntity
    end

    self:_SetActive(true)

    ---重置上次移动到的目标位置
    self:SetLastMovePos(nil)

    if self.m_world:MatchType() == MatchType.MT_Chess then 
        self:SetMoveState(AIMoveState.MoveEnd)
    else
        if monsterEntity:HasTrap() then
            self:SetMoveState(AIMoveState.MoveEnd)
        else
            self:SetMoveState(AIMoveState.NotMove)
        end
    end
    
    self:SetAITreeState(1)

    ---重置回合状态
    self:SetAIRoundEnd(false)
end

---@param e Entity
function AIComponentNew:CalcBuffedMobility(mobility, e)
    if not e then
        return mobility
    end
    if e:BuffComponent():HasFlag(BuffFlags.Benumb) then
        return 1
    end

    local m = mobility
    --加行动力buff，麻痹buff会将ExAIMobility置为1
    local exMobility = e:Attributes():GetAttribute("ExAIMobility") or 0
    --加速buff
    local accelerateRate = e:BuffComponent():GetBuffValue("AccelerateRate") or 0
    m = math.ceil(self.m_nMobilityConfig * (1 + accelerateRate)) + exMobility
    m = math.max(m, 0)
    return m
end

function AIComponentNew:Update(dt)
    if self:IsLogicEnd() then
        return
    end
    if self.m_rootLogic then
        self.m_nStatus = AINewNodeStatus.Running
        if self.m_rootLogic:IsEnableStart() then
            self.m_world:GetSyncLogger():Trace(
                {
                    key = "AIUpdateBegin",
                    entityID = self._ownerEntity:GetID()
                }
            )
            local aiConfigID = self.m_rootLogic:GetConfigAIID()
            self:AddAIRoundRunCount(aiConfigID)
            self.m_rootLogic:Update(dt)
            self.m_world:GetSyncLogger():Trace(
                {
                    key = "AIUpdateEnd",
                    entityID = self._ownerEntity:GetID()
                }
            )
        end
    end
end

function AIComponentNew:ReSelectWorkSkill()
    if self.m_rootLogic then
        self.m_rootLogic:ReSelectWorkSkill()
    end
end

function AIComponentNew:GetRootLogic()
    return self.m_rootLogic
end
function AIComponentNew:IsLogicEnd()
    if nil == self.m_rootLogic then
        return true
    end
    if self.m_nStatus == AINewNodeStatus.Success or self.m_nStatus == AINewNodeStatus.Failure then
        return true
    end
    return false
end
function AIComponentNew:SetComponentStatus(nStatus)
    self.m_nStatus = nStatus
end

function AIComponentNew:OutLog(stMsg)
    if not self.m_world then
        return
    end

    if not self.m_world:IsDevelopEnv() then
        return
    end

    local nType = 0
    local nID = 0
    if self.m_rootLogic then
        nID = self._entity:GetID()
        local cMonsterID = self._entity:MonsterID()
        if cMonsterID then
            nType = cMonsterID:GetMonsterID()
        end
    end
    local stMonster = ": Monster = [" .. nType .. "." .. nID .. "]"
    local stLogicID = ", AI_Config = " .. self:GetRootLogicID()
    local stMobility = ", nMobility  = " .. self.m_nMobilityTotal
    Log.debug("[AI], " .. stMsg .. stMonster .. stLogicID .. stMobility .. "|")
end

function AIComponentNew:OutErrorLog(stMsg)
    local nType = 0
    local nID = 0
    if self.m_rootLogic then
        nID = self._entity:GetID()
        local cMonsterID = self._entity:MonsterID()
        if cMonsterID then
            nType = cMonsterID:GetMonsterID()
        end
    end
    local stMonster = ": Monster = [" .. nType .. "." .. nID .. "]"
    local stLogicID = ", AI_Config = " .. self:GetRootLogicID()
    local posSelf = self._entity:GridLocation().Position
    local stMonsterPos = ", MonsterPosition = (" .. posSelf.x .. "," .. posSelf.y .. ")"
    Log.error("[AI], " .. stMsg .. stMonster .. stLogicID .. stMonsterPos)
end
--------------------------------操作当前的行动力
function AIComponentNew:CostMobility(n)
    self.m_nMobilityTotal = self.m_nMobilityTotal - n
    return self.m_nMobilityTotal
end

function AIComponentNew:ClearMobilityTotal()
    self.m_nMobilityTotal = 0
end

---返回有效的行动力
function AIComponentNew:GetMobilityValid()
    return self.m_nMobilityTotal
end

function AIComponentNew:GetMobilityConfig()
    local m = self._ownerEntity:Attributes():GetAIMobility()
    return m
end

function AIComponentNew:SetMobilityTotal(mobility)
    self.m_nMobilityTotal = mobility
end

---返回主角跟目标的距离平方和
function AIComponentNew:GetDistance()
    if nil == self.m_rootLogic then
        return 0
    end
    local posSlef = self.m_rootLogic:GetSelfPos()
    local posTarget = self:GetTargetPosCenter()
    local nDistance =
        (posSlef.x - posTarget.x) * (posSlef.x - posTarget.x) + (posSlef.y - posTarget.y) * (posSlef.y - posTarget.y)
    return nDistance
end

function AIComponentNew:GetTargetPosCenter()
    ---@type Entity
    local entityWork = self:GetTargetEntity()
    return entityWork:GridLocation():Center()
end

function AIComponentNew:GetTargetPos()
    ---@type Entity
    local entityWork = self:GetTargetEntity()
    local curPosCenter = self._entity:GridLocation():Center()
    if entityWork then
        -- return entityWork:GetGridPosition()
        --------------------------------
        local targetPos = entityWork:GetGridPosition()
        local gridPos = entityWork:GridLocation():GetGridPos()
        local bodyArea = entityWork:BodyArea():GetArea()
        local lastDistance = 9

        for i, area in ipairs(bodyArea) do
            local posWork = gridPos + area

            local distance = Vector2.Distance(curPosCenter, posWork)
            if distance < lastDistance then
                lastDistance = distance
                targetPos = posWork
            end
        end
        return targetPos
    end
    return nil
end

function AIComponentNew:GetTargetEntity()
    local nTargetID = self:GetRuntimeData("Target")
    if nTargetID then
        local entityTarget = self.m_world:GetEntityByID(nTargetID)
        if entityTarget then
            return entityTarget
        end
    end
    return self._targetEntity
end

function AIComponentNew:GetTargetDefault()
    return self._targetEntity
end

function AIComponentNew:GetTargetTeamEntity()
    return self._targetTeamEntity
end

function AIComponentNew:GetAITargetType()
    return self._aiTargetType
end

--------------------------------    ---技能预览
function AIComponentNew:InitPreviewLogic(logicType)
    local configService = self.m_world:GetService("Config")
    ---@type MonsterConfigData
    local configMonster = configService:GetMonsterConfigData()

    local nPrevOrder = configMonster:GetMonsterPreviewAIOrder(self.m_nMonsterID) or AILogicOrderType.BaseOrder
    ---目前策划确认怪物预览只对执行移动普攻的AI行为进行预览 2019.11.22
    return self:SetPreviewLogic(logicType, nPrevOrder)
end
function AIComponentNew:SetPreviewLogic(logicType, nOrder)
    local periodLogic = self.m_logicList[logicType]
    if not periodLogic then
        self.m_logicPreview = nil
        return
    end
    ---目前策划确认怪物预览只对执行移动普攻的AI行为进行预览 2019.11.22
    local logic = periodLogic[nOrder]
    if nil == logic then
        local listOrder = self:GetAILogicOrders(logicType)
        if #listOrder > 0 then
            logic = periodLogic[listOrder[1]]
        end
    end
    if logic then
        self.m_logicPreview = logic
        self.m_logicPreview:UpdateSkillAction()
    end
end

function AIComponentNew:SetReplacePreviewSkillID(skillID)
    self._replacePreviewSkillID = skillID
end

function AIComponentNew:ResetReplacePreviewSkillID()
    self._replacePreviewSkillID = nil
end

function AIComponentNew:IsReplacePreviewSkill()
    if self._replacePreviewSkillID then
        return true
    else
        return false
    end
end

function AIComponentNew:GetPreviewSkillID()
    if nil == self.m_logicPreview then
        return 0
    end
    if self._replacePreviewSkillID then
        return self._replacePreviewSkillID
    end
    ---@type AILogicNode
    self.m_logicPreview:UpdateSkillAction()
    return self.m_logicPreview:GetActionSkillID(true)
end

function AIComponentNew:SetCurSkillScopeResult(addRoundCount, nSkillID)
    ---@type BattleStatComponent
    local battleStatCmpt = self.m_world:BattleStat()
    local round = battleStatCmpt:GetLevelTotalRoundCount()
    local setRound = round + addRoundCount

    local skillID = nSkillID
    if not skillID then
        skillID = self:GetPreviewSkillID()
    end

    local bodyArea = self._ownerEntity:BodyArea():GetArea()
    local posSelf = self._ownerEntity:GridLocation().Position

    local configService = self.m_world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self.m_world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, posSelf, Vector2(0, 1), bodyArea)

    self._skillScopeResult[setRound] = skillResult
end

function AIComponentNew:GetSkillScopeResult(nextRound)
    ---@type BattleStatComponent
    local battleStatCmpt = self.m_world:BattleStat()
    local round = battleStatCmpt:GetLevelTotalRoundCount()
    if nextRound then
        round = round + 1
    end
    return self._skillScopeResult[round]
end

function AIComponentNew:SetRuntimeData(key, value)
    self._runtimeData[key] = value
end

function AIComponentNew:SetRuntimeDataAll(data)
    if data and type(data) == "table" then
        table.append(self._runtimeData, data)
    end
end

function AIComponentNew:GetRuntimeData(key)
    if not key then
        return self._runtimeData
    end
    return self._runtimeData[key]
end

function AIComponentNew:CanMove()
    return self.canMove
end
function AIComponentNew:CanTurn()
    return self.canTurn
end
function AIComponentNew:SetCanTurn(canTurn)
    self.canTurn = canTurn
end
function AIComponentNew:SetRunningSign(nLogicType, nOrder)
    self.m_nRunningAiType = nLogicType
    self.m_nRunningAiOrder = nOrder
end

function AIComponentNew:GetLastMovePos()
    return self.m_lastMovePos
end

function AIComponentNew:SetLastMovePos(pos)
    self.m_lastMovePos = pos
end
---取消AI逻辑
function AIComponentNew:CancelLogic()
    if self.m_rootLogic then
        self.m_rootLogic:CancelLogic()
    end
    self:SetComponentStatus(AINewNodeStatus.Failure)
end
---初始化创建AI的回合数
function AIComponentNew:InitCreateRound()
    ---创建AI的回合数
    ---@type BattleStatComponent
    local battleStatCmpt = self.m_world:BattleStat()
    self.m_nCreateRound = battleStatCmpt:GetCurWaveTotalRoundCount()
end
function AIComponentNew:GetCreateRound()
    return self.m_nCreateRound
end

---施法状态，目前只有击飞小怪使用
function AIComponentNew:GetAITreeState()
    return self._treeState
end

---设置施法状态，目前只有击飞小怪使用
function AIComponentNew:SetAITreeState(st)
    self._treeState = st
end

function AIComponentNew:SetAIRoundEnd(isEnd)
    self._isAIRoundEnd = isEnd
end

function AIComponentNew:IsAIRoundEnd()
    return self._isAIRoundEnd
end

function AIComponentNew:IsAttachState(curRound)
    if self:GetRuntimeData("AttachMonsterID") then
        return true
    else
        if self:GetRuntimeData("DetachBeginRunRound") then
            if self:GetRuntimeData("DetachBeginRunRound") <= curRound then
                return false
            else
                return true
            end
        else
            return false
        end
    end
end

function AIComponentNew:GetAIMovePath_Test()
    return self._aiMovePathTest
end

function AIComponentNew:SetAIMovePath_Test(path)
    self._aiMovePathTest = path
end

function AIComponentNew:GetAntiSkill()
    return self._hasAntiSkill
end

function AIComponentNew:SetAntiSkill(hasAntiSkill)
    self._hasAntiSkill = hasAntiSkill
end

function AIComponentNew:GetContextByTreeInstanceID(instanceID, key)
    local context = self._treeContext[instanceID]
    if not context then
        return nil
    end

    return context[key]
end

function AIComponentNew:SetContextByTreeInstanceID(instanceID, key, value)
    local context = self._treeContext[instanceID]
    if not context then
        context = {}
        self._treeContext[instanceID] = context
    end

    context[key] = value
end

--------------------------------------------------------------------------------------------

---@return AIComponentNew
function Entity:AI()
    return self:GetComponent(self.WEComponentsEnum.AI)
end

function Entity:HasAI()
    return self:HasComponent(self.WEComponentsEnum.AI)
end

function Entity:HasNewAI()
    return self:HasComponent(self.WEComponentsEnum.AI)
end

--entity创建时初始化参数
function Entity:InitAI(world, nMonsterID, nMobility, aiTargetType)
    local aiComponent = self:AI()
    if aiComponent == nil then
        local index = self.WEComponentsEnum.AI
        aiComponent = AIComponentNew:New()
    end
    aiComponent.m_world = world
    aiComponent.m_nMonsterID = nMonsterID or 0
    aiComponent.m_nMobilityConfig = nMobility or 0
    aiComponent._ownerEntity = self
    if aiTargetType then
        aiComponent._aiTargetType = aiTargetType
    end
    aiComponent:InitCreateRound()
    self:ReplaceComponent(self.WEComponentsEnum.AI, aiComponent)
end

function Entity:AddNewAI(nMonsterID, aiLogicType, listAiID)
    if nil == listAiID or #listAiID <= 0 then
        return
    end
    local aiComponent = self:AI()
    if aiComponent == nil then
        local index = self.WEComponentsEnum.AI
        aiComponent = AIComponentNew:New()
        aiComponent.m_nMonsterID = nMonsterID or 0
        aiComponent._ownerEntity = self
    end
    for i = 1, #listAiID do
        local aiIDAndOrder = listAiID[i]
        local aiGenInfo = AIGenInfo:New(aiComponent.m_world, self, aiIDAndOrder[1], nMonsterID, aiLogicType)
        ---@type AILogicNode
        local aiLogic = CustomLogicFactory.Static_CreateLogic(aiGenInfo)
        if aiIDAndOrder[3] then
            aiLogic._parallelID = aiIDAndOrder[3]
        end
        aiComponent:AddLogic(aiLogicType, aiLogic, aiIDAndOrder[2])
    end
    self:ReplaceComponent(self.WEComponentsEnum.AI, aiComponent)
end

---2020-05-08 韩玉信， 新AI加载机制
function Entity:AddNewAIByConfig(nMonsterID, listConfigAiID, aiOrder)
    if nil == listConfigAiID or #listConfigAiID <= 0 then
        return
    end
    local aiComponent = self:AI()
    if aiComponent == nil then
        local index = self.WEComponentsEnum.AI
        aiComponent = AIComponentNew:New()
        aiComponent.m_nMonsterID = nMonsterID or 0
        aiComponent._ownerEntity = self
    end
    for i = 1, #listConfigAiID do
        local nConfigAiID = listConfigAiID[i]
        local aiGenInfo = AIGenInfoByConfig:New(aiComponent.m_world, self, nConfigAiID)
        local aiLogic = CustomLogicFactory.Static_CreateLogic(aiGenInfo)
        local aiLogicPeriodType = aiGenInfo:GetLogicType()
        aiLogicPeriodType = self._world:ReplaceAILogicPeriodType(aiLogicPeriodType)
        local aiLogicOrder = aiOrder or aiGenInfo:GetLogicOrder()
        aiComponent:AddLogic(aiLogicPeriodType, aiLogic, aiLogicOrder)
        if aiGenInfo:IsPreview() then ---预览会冲掉上一次的残值
            aiComponent:SetPreviewLogic(aiLogicPeriodType, aiLogicOrder)
        end
    end
    self:ReplaceComponent(self.WEComponentsEnum.AI, aiComponent)
end

---替换特定的AI序列， 之前的AI序列会临时保存在AIComponentNew中
function Entity:ReplaceAI(nLogicType, listAiID, orderIndex,enforce)
    ---@type AIComponentNew
    local aiComponent = self:AI()
    if aiComponent == nil then
        return false
    end
    ---如果已经替换，则不再做
    if aiComponent:GetCutLogic() and not enforce then
        return true
    end
    if nil == listAiID or #listAiID <= 0 then
        return false
    end
    local nOrderIndex = orderIndex and orderIndex or AILogicOrderType.BaseOrder

    local pLogicList = {}
    for i = 1, #listAiID do
        local aiGenInfo = AIGenInfo:New(aiComponent.m_world, self, listAiID[i], nil, nLogicType)
        local aiLogic = CustomLogicFactory.Static_CreateLogic(aiGenInfo)
        pLogicList[nOrderIndex] = aiLogic
        nOrderIndex = nOrderIndex + 1
    end
    aiComponent:SetCutLogic(pLogicList)
    aiComponent:ExchangeOnceLogic(nLogicType)
    return true
end
function Entity:ResumeAI(nLogicType)
    ---@type AIComponentNew
    local aiComponent = self:AI()
    if aiComponent == nil then
        return
    end
    aiComponent:ExchangeOnceLogic(nLogicType)
    aiComponent:SetCutLogic(nil)
end

function Entity:ClearAI(nLogicType)
    ---@type AIComponentNew
    local aiComponent = self:AI()
    if aiComponent == nil then
        return
    end
    aiComponent:SetCutLogic(nil)
    aiComponent:ExchangeOnceLogic(nLogicType)

end

---获取entity的占地坐标 --输入的是基准坐标  pos 为空则返回当前占地坐标列表
function Entity:GetCoverAreaList(pos)
    local posList = {}
    if nil == pos then
        pos = self:GridLocation().Position
    end
    if self:HasBodyArea() then
        local area = self:BodyArea():GetArea()
        if #area > 1 then
            for i = 1, #area do
                posList[#posList + 1] = Vector2(pos.x + area[i].x, pos.y + area[i].y)
            end
        else
            posList[#posList + 1] = Vector2(pos.x + area[1].x, pos.y + area[1].y)
        end
    else
        posList[#posList + 1] = pos
    end
    return posList
end

function Entity:SetAICanMoveTurn(monsterID, canMove, canTurn)
    local aiComponent = self:AI()
    if aiComponent == nil then
        return
    end
    aiComponent.canMove = canMove or false
    aiComponent.canTurn = canTurn or false
end

function Entity:InitPreviewLogic(nLogicType)
    local aiComponent = self:AI()
    if aiComponent == nil then
        return
    end
    aiComponent:InitPreviewLogic(nLogicType)
end
