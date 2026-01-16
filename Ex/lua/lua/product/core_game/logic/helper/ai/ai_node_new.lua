--[[--------------------
    AINewNode AI逻辑节点基类
--]] --------------------
require "custom_node"
require "ai_sort_by_distance"

_class("AINewNode", CustomNode)
---@class AINewNode:CustomNode
AINewNode = AINewNode

function AINewNode:Constructor()
    self.m_stActionLogType = nil
    ---@type AINewNodeStatus
    self.Status = AINewNodeStatus.Ready
    ---@type Entity
    self.m_entityOwn = nil --AI所属的实体
    self:Activate(true)
    ---@type AILogicNode 及其派生类
    self.m_logicOwn = nil --两种意思：节点为叶子则是AI所属的Logic节点；如果为AILogicNode节点，则是父节点
    self.m_configData = nil --根据AI种类的不同，这个结构体也是不一样的
    self.m_logicData = nil
    ---@type MainWorld
    self._world = nil
    self._genInfo = nil
    ---@type number
    self._treeID = nil  ---在一个行为树中本节点独一无二的ID
end

function AINewNode:Reset()
    self.Status = AINewNodeStatus.Ready
    self.m_logicData = nil
end

function AINewNode:SetLogicData(logicData)
    self.m_logicData = logicData
end
function AINewNode:SetConfigData(configData)
    self.m_configData = configData
end
function AINewNode:GetConfigData()
    return self.m_configData
end

function AINewNode:SetTreeID(treeID)
    self._treeID = treeID
end

function AINewNode:GetTreeID()
    return self._treeID
end

---@param cfg table
---@param context CustomNodeContext
function AINewNode:InitializeNode(cfg, context, logicOwn, configData)
    AINewNode.super.InitializeNode(self, cfg, context)
    ---@type AIGenInfoBase
    local genInfo = context.GenInfo
    self.m_entityOwn = genInfo.OwnerEntity
    ---如果我是個Action 那麽這個是AILogicNode，每個AI都有一個根节点
    self.m_logicOwn = logicOwn
    self.m_configData = configData
    self.CustomLogicID = cfg.ID
    self.CustomLogicType = cfg.Type
    ---@type MainWorld
    self._world = genInfo.m_world
    ---@type AIGenInfoBase
    self._genInfo = genInfo
    self.m_stActionLogType = "[" .. cfg.Type .. "]"
    if not self.CustomLogicID and not  self.m_logicOwn then
        if EDITOR then
            Log.exception("No AIConfigData Trace:",Log.traceback())
        end
    end
end
---获得AI配置ID
function AINewNode:GetConfigAIID()
    ---这里只有根节点有这个参数下面的action都没有这玩意（服，nb）
    if self.CustomLogicID then
        return self.CustomLogicID
    elseif self.m_logicOwn then
        return self.m_logicOwn.CustomLogicID
    else
        Log.fatal("No AIConfigIDData")
    end
end

function AINewNode:GetParallelID()
    if self.CustomLogicID then
        return self._parallelID
    elseif self.m_logicOwn then
        return self.m_logicOwn._parallelID
    else
        Log.fatal("No AIConfigIDData")
    end
end
---获得AI宿主的ID
function AINewNode:GetMyOwnEntityID()
    return self.m_entityOwn:GetID()
end

---@return Entity
function AINewNode:GetMyOwnEntity()
    return self.m_entityOwn
end

function AINewNode:SetInitialize(world, entityOwn)
    self._world = world
    self.m_entityOwn = entityOwn
end

function AINewNode:SetSkillList(newSkillList)
    self._genInfo:SetSkillList(newSkillList)
end

function AINewNode:Update()
    if self:IsActive() then
        self._world:GetSyncLogger():Trace(
            {key = "AINodeUpdate", AINode = self._className, status = GetEnumKey("AINewNodeStatus", self.Status)}
        )
        if self.Status == AINewNodeStatus.Ready then
            self:OnBegin()
            self.Status = AINewNodeStatus.Running
        end
        self.Status = self:OnUpdate()
        self:PrintLog("AINodeStatus=", self.Status)
        if self.Status ~= AINewNodeStatus.Running then
            self:OnEnd()
        end
    end
    return self.Status
end

function AINewNode:OnBegin()
end
---@return AINewNodeStatus 每次Update返回状态
function AINewNode:OnUpdate()
    return AINewNodeStatus.Success
end
function AINewNode:OnEnd()
end
---判断是否处于工作状态
function AINewNode:IsEnableStart()
    if self.Status == AINewNodeStatus.Ready or self.Status == AINewNodeStatus.Running then
        return true
    end
    return false
end
function AINewNode:IsRunning()
    if self.Status == AINewNodeStatus.Running then
        return true
    end
    return false
end
function AINewNode:IsReady()
    if self.Status == AINewNodeStatus.Ready then
        return true
    end
    return false
end
function AINewNode:IsSuccess()
    if self.Status == AINewNodeStatus.Success then
        return true
    end
    return false
end
function AINewNode:GetStatues()
    return self.Status
end

function AINewNode:GetActionSkillIDEx(preview)
    if preview then
        return self:GetActionSkillID()
    end

    if self.m_entityOwn:BuffComponent():HasFlag(BuffFlags.Benumb) then
        local skillID = self:GetNormalSkillID() or 0
        self:PrintLog("自行为树选取技能<麻痹Buff不放技能>，技能ID = ", skillID)
        return skillID
    end
    return self:GetActionSkillID()
end

function AINewNode:GetActionSkillID(nIndex)
    return self:GetLogicData(nIndex or 1)
end
function AINewNode:GetAILogicID()
    local nLogicID = self.CustomLogicID or self.m_logicOwn.CustomLogicID or 0
    return nLogicID
end
---@param switchType AINewNodeStatus
function AINewNode:GetStrSwitchType(switchType)
    if switchType == AINewNodeStatus.Ready then
        return "Ready"
    elseif switchType == AINewNodeStatus.Running then
        return "Running"
    elseif switchType == AINewNodeStatus.Success then
        return "Success",1
    elseif switchType == AINewNodeStatus.Failure then
        return "Failure",2
    elseif switchType > AINewNodeStatus.Other then
        return "Other :"..switchType,switchType
    else
        Log.fatal("Invalid SwitchType :",switchType,"Trace:",Log.traceback())
    end
end

function AINewNode:AddDebugStream(monsterID,entityID,round,runCount,aiConfigID,aiTreeID,slotID)
    if not self._aiDebugModule  then
        ---@type  AIDebugModule
        self._aiDebugModule = GameGlobal.GetModule(AIDebugModule)
    end
    if not self._aiLogger then
        ---@type AILogger
        self._aiLogger =  self._world:GetAILogger()
    end

    if EDITOR then
        self._aiDebugModule:AddAIDebugStreamInfo(monsterID,entityID,round,runCount,aiConfigID,aiTreeID,slotID)
    end

    self._aiLogger:AddAIStreamLog(monsterID,entityID,round,runCount,aiConfigID,aiTreeID,slotID)
end

function AINewNode:AddDebugInfo(monsterID,entityID,round,runCount,aiConfigID,aiTreeID,info)
    if not self._aiDebugModule  then
        ---@type  AIDebugModule
        self._aiDebugModule = GameGlobal.GetModule(AIDebugModule)
    end
    if not self._aiLogger then
        ---@type AILogger
        self._aiLogger =  self._world:GetAILogger()
    end
    if EDITOR then
        self._aiDebugModule:AddAIDebugRunInfo(monsterID, entityID, round, runCount, aiConfigID, aiTreeID, info)
    end
    self._aiLogger:AddAIDebugInfoLog(monsterID,entityID,round,runCount,aiConfigID,aiTreeID,info)
end


---@param curAction AINewNode
---@param nextAction AINewNode
function AINewNode:PrintActionSwitchLog(curAction,curTreeID, nextAction,nextTreeID,switchType,nextIsEnd)
    if EDITOR then
        if not self:GetMyOwnEntity():HasMonsterID() then
            return
        end
        if not self._aiDebugModule then
            ---@type  AIDebugModule
            self._aiDebugModule = GameGlobal.GetModule(AIDebugModule)
            ---@type AILogger
            self._aiLogger =  self._world:GetAILogger()
        end
        --local curTreeID = curAction:GetTreeID()
        local entityID = curAction:GetMyOwnEntityID()
        local aiConfigID = curAction:GetConfigAIID()
        local curActionType = curAction:GetStrActionType()
        local nextActionInfo = ""
        local switchType,slotID = self:GetStrSwitchType(switchType)
        ---@type AIComponentNew
        local aiComponent = self:GetMyOwnEntity():AI()
        local runCount = aiComponent:GetAIRoundRunCount(self:GetConfigAIID())
        local round = self._world:BattleStat():GetLevelTotalRoundCount()
        local monsterID = 0
        if self:GetMyOwnEntity():HasMonsterID() then
            monsterID = self:GetMyOwnEntity():MonsterID():GetMonsterID()
        elseif self:GetMyOwnEntity():HasTrapID() then
            monsterID = self:GetMyOwnEntity():TrapID():GetTrapID()
        end
        local entityID = self:GetMyOwnEntity():GetID()
        self:AddDebugStream(monsterID,entityID,round,runCount,aiConfigID,curTreeID,slotID)
        if nextAction then
            --local nextTreeID = nextAction:GetTreeID()
            local nextActionType= nextAction:GetStrActionType()
            nextActionInfo = " NextActionTreeID:"..nextTreeID.." NexActionType:"..nextActionType
            ---self:AddDebugStream(monsterID,entityID,round,runCount,aiConfigID,nextTreeID,nil)
        end
        ---@type AIComponentNew
        local aiComponent = self:GetMyOwnEntity():AI()
        local runCount = aiComponent:GetAIRoundRunCount(self:GetConfigAIID())
        Log.debug("[AI] SwitchNode AIConfigID:",aiConfigID," RunCount:",runCount," CurTreeID:",curTreeID," CurActionType:",curActionType," SwitchType:",switchType,nextActionInfo)
    end
end
---@return string
function AINewNode:GetStrActionType()
    return self.m_stActionLogType
end

function AINewNode:PrintDebugLog(...)
    if self._world and self._world:IsDevelopEnv() and EDITOR then
        local aiComponent = self:GetMyOwnEntity():AI()
        local runCount = aiComponent:GetAIRoundRunCount(self:GetConfigAIID())
        local round = self._world:BattleStat():GetLevelTotalRoundCount()
        local monsterID = 0
        if self:GetMyOwnEntity():HasMonsterID() then
            monsterID = self:GetMyOwnEntity():MonsterID():GetMonsterID()
        elseif self:GetMyOwnEntity():HasTrapID() then
            monsterID = self:GetMyOwnEntity():TrapID():GetTrapID()
        end
        local entityID = self:GetMyOwnEntity():GetID()
        local aiConfigID = self:GetConfigAIID()
        local treeID = self:GetTreeID()
        local info = string.args2str({...}, ' ')
        self:AddDebugInfo(monsterID,entityID,round,runCount,aiConfigID,treeID,info)
    end
end

function AINewNode:PrintLog(...)
    if self._world and self._world:IsDevelopEnv() then
        ---@type AIComponentNew
        local aiComponent = self:GetMyOwnEntity():AI()
        local roundCount = aiComponent:GetAIRoundRunCount(self:GetConfigAIID())
        Log.debug("[AI] AIConfigID:",self:GetConfigAIID()," RunCount:",roundCount," TreeID:",self:GetTreeID()," EntityID=", self.m_entityOwn:GetID()," Action=", self.m_stActionLogType, " ", ...)
    end
end

function AINewNode:PrintLog2(...)
    Log.debug("[AI] AIConfigID:",self:GetConfigAIID()," TreeID:",self:GetTreeID()," EntityID=", self.m_entityOwn:GetID(), " Action=", self.m_stActionLogType, " ", ...)
end

---@param posWork Vector2
function AINewNode:_MakePosString(posWork)
    return GameHelper.MakePosString(posWork)
end

function AINewNode:GetSelfPos()
    local entityOwn = self.m_entityOwn
    if nil == entityOwn then
        return nil
    end
    return entityOwn:GetGridPosition()
end
---@return boolean 判断给定的Entity是否死亡
---@param entityWork Entity
function AINewNode.IsEntityDead(entityWork)
    if entityWork and entityWork:HasDeadMark() then
        return true
    end
    return false
end
--------------------------------操作行为树子节点执行流程
---@return AILogicNode 及其派生类
function AINewNode:GetLogicNodeRoot() --返回AI根节点
    if nil == self.m_entityOwn then
        return nil
    end
    local aiComponent = self.m_entityOwn:AI()
    if nil == aiComponent then
        return nil
    end
    return aiComponent:GetRootLogic()
end
---@param logicData self.m_logicData 或者 self.m_configData
function AINewNode:_GetLogicData(logicData, nIndex)
    if type(logicData) == "number" then
        return logicData
    elseif type(logicData) == "nil" then
        return nil
    elseif type(logicData) == "table" then
        return logicData[nIndex]
    elseif type(logicData) == "function" then
        return logicData(nIndex)
    end
    return logicData
end
function AINewNode:GetLogicData(nIndex)
    if nIndex and type(nIndex) == "string" then
        return self:_GetLogicData(self.m_configData, nIndex)
    end
    nIndex = nIndex or 0
    if nil == self.m_logicData or nIndex < 0 then
        return self:_GetLogicData(self.m_configData, -nIndex)
    end
    return self:_GetLogicData(self.m_logicData, nIndex)
end
---@type AIComponentNew
function AINewNode:GetAiComponent()
    return self.m_entityOwn:AI()
end

function AINewNode:GetRuntimeData(key)
    local aiComponent = self:GetAiComponent()
    if nil == aiComponent then
        return nil
    end
    return aiComponent:GetRuntimeData(key)
end

function AINewNode:SetRuntimeData(key, value)
    if self:GetAiComponent() then
        self.m_entityOwn:AI():SetRuntimeData(key, value)
    else
        self:PrintLog("在还没有AI Component时 设置了runtimeData!")
    end
end
---从配置文件读取技能
function AINewNode:_GetConfigSkillList(monsterID)
    local listSkill = nil
    if monsterID > 0 then
        local configService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfig = configService:GetMonsterConfigData()
        listSkill = monsterConfig:GetMonsterSkillIDs(monsterID)
    end
    return listSkill
end
function AINewNode:GetConfigSkillList()
    local skills = self._genInfo:GetSkillList()
    if nil == skills or #skills <= 0 then
        local nConfigType = self._genInfo:GetGenInfoType()
        if EnumAIGenInfo.Monster == nConfigType then
            local cMonsterID = self.m_entityOwn:MonsterID()
            if cMonsterID then
                skills = self:_GetConfigSkillList(cMonsterID:GetMonsterID())
            end
        else
            skills = self._genInfo:GetSkillList()
        end
    end
    return skills
end
function AINewNode:GetConfigSkillID(nIndexX, nIndexY)
    local vecSkillList = self:GetConfigSkillList()
    return vecSkillList[nIndexX][nIndexY]
end

--普攻
function AINewNode:GetNormalSkillID()
    local configService = self._world:GetService("Config")
    local vecSkillList = self:GetConfigSkillList()
    for i, vec in ipairs(vecSkillList) do
        if type(vec) == "table" then
            for j, skillID in ipairs(vec) do
                local cfg = configService:GetSkillConfigData(skillID)
                local skillType = cfg:GetSkillType()
                if skillType == SkillType.Normal then
                    return skillID
                end
            end
        else ---两种形式的SkillList格式，cfg_monster_class内的是二维数组，cfg_ai里是一维数组
            local skillID = vec
            local cfg = configService:GetSkillConfigData(skillID)
            local skillType = cfg:GetSkillType()
            if skillType == SkillType.Normal then
                return skillID
            end
        end
    end
end
function AINewNode:GetGameRountNow()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    local round = battleStatCmpt:GetCurWaveTotalRoundCount()
    return round
end
--------------------------------存放一些可以复用的逻辑给派生类使用
---判断entity是否可以走到pos位置
---@return boolean
---@param pos Vector2
function AINewNode:IsPosAccessible(pos)
    if false == self.m_entityOwn:HasBodyArea() then
        return true
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local monsterIDCmpt = self.m_entityOwn:MonsterID()
    local nMonsterBlockData = monsterIDCmpt:GetMonsterBlockData() --陆行/飞行
    local coverList = self:GetCoverAreaList(pos)
    local coverListSelf = self:GetCoverAreaList(self.m_entityOwn:GetGridPosition())
    for i = 1, #coverList do
        local posWork = coverList[i]
        if not table.icontains(coverListSelf, posWork) then ---确保不被自己堵上
            if boardServiceLogic:IsPosBlock(posWork, nMonsterBlockData) then
                return false
            end
        end
    end
    return true
end
---@param planPosList SortedArray   候选位置列表内部元素是 ---@type AiSortByDistance
---@param defPos Vector2    找不到的情况下，返回的默认值：一般是entity的当前位置
function AINewNode:FindPosValid(planPosList, defPos)
    if nil == planPosList or planPosList:Size() <= 0 then
        return defPos
    end
    local posSelf = defPos
    local posReturn = posSelf
    local nPosCount = planPosList:Size()
    for i = 1, nPosCount do
        ---@type AiSortByDistance
        local posWork = planPosList:GetAt(i)
        local bAccessible = self:IsPosAccessible(posWork.data)
        if true == bAccessible then
            posReturn = posWork.data
            break
        -- else
        --     if posWork.data == posSelf then     --遇到自己也是地图障碍物
        --         posReturn = posWork.data;
        --         break;
        --     end
        end
    end
    return posReturn
end
function AINewNode:FindPosValidAndConnected(planPosList, posTarget, posDefault)
    if nil == planPosList then
        return posDefault
    end
    local posReturn = posDefault
    local nPosCount = planPosList:Size()
    for i = 1, nPosCount do
        ---@type AiSortByDistance
        local posWork = planPosList:GetAt(i)
        local bAccessible = self:IsPosAccessible(posWork.data)
        if true == bAccessible then
            if self:IsPosConnected(posTarget, posWork.data) then
                posReturn = posWork.data
                break
            end
        end
    end
    return posReturn
end
---获取entity的占地坐标
function AINewNode:GetCoverAreaList(pos)
    local posList = {}
    if self.m_entityOwn then
        posList = self.m_entityOwn:GetCoverAreaList(pos)
    end
    return posList
end
---判断起始位置到目标位置中间是否（直线）有障碍物（其他怪和静态障碍物）
---@param posStart Vector2
---@param posEnd Vector2
function AINewNode:IsHaveObstacle(posStart, posEnd)
    local direct = posEnd - posStart
    local nMax = math.max(math.abs(direct.x), math.abs(direct.y))
    if 0 == nMax then
        return false
    end
    direct.x = direct.x / nMax
    direct.y = direct.y / nMax
    local posWork = posStart + direct
    local posLogic = Vector2.New(math.floor(posWork.x), math.floor(posWork.y))
    while posLogic ~= posEnd do
        if false == self:IsPosAccessible(posLogic) then
            return true
        end
        posWork = posWork + direct
        posLogic.x = math.floor(posWork.x)
        posLogic.y = math.floor(posWork.y)
    end
    return false
end
function AINewNode:IsPosConnected(posStart, posEnd)
    local bHaveObstacle = self:IsHaveObstacle(posStart, posEnd)
    return false == bHaveObstacle
end

---计算移动范围：所有怪物的移动轨迹都是十字（ 从centerPos 出发nWalkStep步以内 ）
---@return ComputeWalkPos[]
function AINewNode:ComputeWalkRange(centerPos, nWalkStep, bFilter)
    bFilter = bFilter or false
    ---@type Callback
    local cbFilter = nil
    if bFilter then
        cbFilter = Callback:New(1, self.IsPosAccessible, self)
    end
    return ComputeScopeRange.ComputeRange_WalkMathPos(centerPos, 1, nWalkStep, cbFilter)
end
---@param casterEntity Entity
function AINewNode:IsTargetInRange(casterEntity,targetType,targetTypeParam,scopeCenterType,scopeType,scopeParam)
    local dir = casterEntity:GridLocation().Direction
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterPos = casterEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()
    local centerPos,bodyArea = skillCalc._gridFilter:CalcCenterPosAndBodyArea(scopeCenterType, casterPos, casterBodyArea, scopeParam)
    ---@type SkillScopeResult
    local result = skillCalc:ComputeScopeRange(
            scopeType,
            scopeParam,
            centerPos,
            bodyArea,
            dir,
            targetType,
            casterPos,
            casterEntity
    )
    ---先选技能目标
    local targetEntityIDArray = utilScopeSvc:SelectSkillTarget(self.m_entityOwn, targetType, result, nil,targetTypeParam)
    return #targetEntityIDArray > 0
end

--------------------------------
---加了参数不敢改太多就把自己调用的改了
---@return SkillScopeResult
function AINewNode:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList,entityCaster)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalculater = utilScopeSvc:GetSkillScopeCalc()
    dir = dir or Vector2(0, 1) --不传方向默认朝上
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, centerPos, dir, bodyAreaList,entityCaster)
    return skillResult
end
---通过判断技能目标数量判断是否在技能范围内
function AINewNode:IsSkillTargetInSkillRange(nSkillID)
    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return false
    end
    local selfPos = entityCaster:GetGridPosition()
    local dir = entityCaster:GridLocation().Direction
    local selfBodyArea = entityCaster:BodyArea():GetArea()
    local targetIDList = self:GetSkillTargetList(nSkillID, selfPos, dir, selfBodyArea,entityCaster)
    return #targetIDList > 0
end

---@return number[]
function AINewNode:GetSkillTargetList(skillID, centerPos, dir, bodyAreaList,entityCaster)
    ---@type SkillScopeResult
    local skillResult = self:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList,entityCaster)
    if not skillResult then
        return {}
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local targetType = skillConfigData:GetSkillTargetType()
    ---先选技能目标
    local targetEntityIDArray = utilScopeSvc:SelectSkillTarget(self.m_entityOwn, targetType, skillResult, skillID)
    return targetEntityIDArray
end

---@return table<int,Vector2>
---计算技能的相对范围
function AINewNode:CalculateSkillRange(skillID, centerPos, dir, bodyAreaList)
    ---@type SkillScopeResult
    local skillResult = self:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList)

    if not skillResult then
        return {}
    end

    ---数据去重
    local skillRange = skillResult:GetAttackRange()
    local listReturn = {}
    for i = 1, #skillRange do
        local posWork = skillRange[i]
        if false == table.icontains(listReturn, posWork) then
            table.insert(listReturn, posWork)
        end
    end
    return listReturn
end

---@param entityCaster Entity
---@param entityTarget Entity
---@param nSkillID number
function AINewNode:IsEntityInSkillRange(nSkillID, entityTarget)
    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return false
    end
    local selfPos = entityCaster:GetGridPosition()
    local dir = entityCaster:GridLocation().Direction
    local selfBodyArea = entityCaster:BodyArea():GetArea()
    local skillRangeData = self:CalculateSkillRange(nSkillID, selfPos, dir, selfBodyArea)
    if not entityTarget or #skillRangeData == 0 then
        self:PrintLog("skillID = ", nSkillID, ", 技能范围为空<不能攻击>")
        return false
    end
    local bSuccess = self:_IsTargetInSkillRange(entityTarget, skillRangeData)
    if true == bSuccess then
        self:PrintLog("skillID = ", nSkillID, ", 技能范围内<可以攻击>")
        return true
    else
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(nSkillID)
        if SkillTargetType.Monster == skillConfigData:GetSkillTargetType() then
            self:PrintLog("skillID = ", nSkillID, ", 同组范围<可以攻击>")
            return true
        end
        self:PrintLog("skillID = ", nSkillID, ", 技能范围外<不能攻击>")
        return false
    end
    self:PrintLog("skillID = ", nSkillID, ", 技能范围外<不能攻击>")
    return false
end

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
function AINewNode.InsertSortedArray(sortedArray, centerPos, workPos, nIndex)
    ---@type AiSortByDistance
    local posData = AiSortByDistance:New(centerPos, workPos, nIndex)
    sortedArray:Insert(posData)
end

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
---@param curPos Vector2
---@param nIndex number
function AINewNode.InsertSortedArrayDisAndDir(sortedArray, centerPos, workPos, curPos, nIndex)
    ---@type AiSortByDistanceAndDir
    local posData = AiSortByDistanceAndDir:New(centerPos, workPos, curPos, nIndex)
    sortedArray:Insert(posData)
end

---判断三点是否一线：方向是A=>B=>C
function AINewNode:_IsOneLine(posA, posB, posC, bCheckPath)
    local bOneLine = GameHelper.IsPointOneLine(posA, posB, posC)
    return bOneLine
end
function AINewNode.CheckHitBlockPath(world, posStart, posEnd)
    local bBlockPath = false
    ---@type UtilDataServiceShare
    local utilSvc = world:GetService("UtilData")
    ---@type BoardServiceLogic
    local boardServiceLogic = world:GetService("BoardLogic")

    local posDir = GameHelper.ComputeLogicDir(posEnd - posStart)
    local posWork = posStart + posDir
    while posWork ~= posEnd do
        local listEntityBomb = utilSvc:GetTrapsAtPos(posWork)
        if table.count(listEntityBomb) > 0 then
            if boardServiceLogic:IsPosBlock(posWork, BlockFlag.HitBack) then--炸弹用，没有处理飞行怪的击退
                bBlockPath = true
                break
            end
        end

        posWork = posWork + posDir
    end
    return bBlockPath
end
function AINewNode:_IsCanHitBombToPlayer(posMonster, posBomb, posPlayer, bCheckPath)
    local bOneLine = GameHelper.IsPointOneLine(posMonster, posBomb, posPlayer)
    if nil == bCheckPath then
        return bOneLine
    end
    if bOneLine then
        bOneLine = not AINewNode.CheckHitBlockPath(self._world, posBomb, posPlayer)
    end
    return bOneLine
end
----------------------------------------------------------------
function AINewNode:_IsAllAIMoveDone()
    local aiSchSvc = self._world:GetService("AIScheduler")
    ---@type SortedArray
    local aiList = aiSchSvc:GetAIList()
    self:PrintLog("_IsAllAIMoveDone() aiList count=", aiList:Size())
    ---@param e Entity
    for i = 1, aiList:Size() do
        local e = aiList:GetAt(i)
        self:PrintLog("_IsAllAIMoveDone() aiList[", i, "]=", e:GetID())
        ---@type AIComponentNew
        local aiCmpt = e:AI()
        local hasDeadMark = e:HasDeadMark()
        if not hasDeadMark and aiCmpt then
            local st = aiCmpt:GetMoveState()
            local entityID = e:GetID()
            if st ~= AIMoveState.MoveEnd then
                self:PrintLog(
                    "[AI] IsAllAIMoveDone() false entityID=",
                    entityID,
                    " moveState=",
                    GetEnumKey("AIMoveState", st)
                )
                return false
            end
        end
    end
    return true
end
---获取节点配置的技能ID，支持固定技能ID和按照位置取技能ID
function AINewNode:GetLogicSkillID()
    local skillIndexX, skillIndexY = self:GetLogicData(-1), self:GetLogicData(-2)
    if skillIndexY then
        local nSkillID = self:GetConfigSkillID(skillIndexX, skillIndexY)
        return nSkillID
    else
        return skillIndexX
    end
end