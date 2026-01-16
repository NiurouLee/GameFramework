--[[------------------------------------------------------------------------------------------
    NormalSkillCalculator :普攻计算器
    根据选择的目标计算普通攻击伤害
    局内普攻的核心对象之一
]] --------------------------------------------------------------------------------------------

---@class NormalSkillCalculator: Object
_class("NormalSkillCalculator", Object)
NormalSkillCalculator = NormalSkillCalculator

---@param world MainWorld
function NormalSkillCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")

    ---@type SkillEffectCalcService
    self._skillEffectCalcService = self._world:GetService("SkillEffectCalc")

    ---@type TrapServiceLogic
    self._trapServiceLogic = self._world:GetService("TrapLogic")

    ---@type BattleService
    self._battleService = self._world:GetService("Battle")

    ---@type TriggerService
    self._triggerService = self._world:GetService("Trigger")

    ---@type SkillScopeTargetSelector
    self._skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()

    ---@type table<number, number>
    self._frameTimeMultipleDic = {}

    self._deadChainIndx = 10000 --玩家死亡的格子索引

    ---发给表现层的数据
    self._playNormalSkillSequence = {} ---普攻执行流
    self._pathTriggerTrapsDic = {} ---路径上每个点触发的机关
    self._pathNormalSkillWaitTimeDic = {} ---路径上每个点普攻需要等待的时间
    self._pathMoveStartWaitTime = 0 ---连线的开始等待时间
    ---
end

---为出战队伍里的每一个队员计算普攻伤害
---@param teamEntity Entity
function NormalSkillCalculator:DoCalculateNormalSkill(teamEntity)
    --- 0 初始化计算数据
    self:_OnInitializeData(teamEntity)

    --- buff 通知攻击开始前
    self:_NotifyNormalAttackStart()

    --- 1 统计每个AttackGridData的时间
    self:_OnGetTimeAttackListDic(teamEntity)

    --- 2 按时序计算全部AttackGridData的伤害并应用结果
    self:_OnCalcAndApply(teamEntity)

    --- 3 在全部攻击以后 检查机关的触发
    self:_OnCheckTriggerTrapAfterAttackAll(teamEntity)

    --- 4 还原队长坐标为连线初始点
    local pos = teamEntity:GridLocation():GetMoveLastPosition()
    teamEntity:SetGridPosition(pos)

    --- buff 通知攻击结束
    self:_NotifyNormalAttackEnd()

    ---死亡目标挂上DeadMark
    self:_SetNormalAttackDead()
end

function NormalSkillCalculator:_OnInitializeData(teamEntity)
    --取出连线数据

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()

    ---@type Vector2[]
    self._chainPathData = logicChainPathCmpt:GetLogicChainPath()
    ---@type PieceType
    self._chainPathElementType = logicChainPathCmpt:GetLogicPieceType()

    ---@type LogicRoundTeamComponent
    local LogicRoundTeam = teamEntity:LogicRoundTeam()
    self._petRoundTeam = LogicRoundTeam:GetPetRoundTeam()

    ---统计每个trap触发的时间
    ---@type SortedDictionary<number, number> key 时间  value trap index
    self._timeTrapDic = SortedDictionary:New()
    self._triggerService:Notify(NTTeamNormalAttackStart:New(self._chainPathElementType, self._chainPathData))
    ---路线途径的会触发的陷阱列表
    self._indexTrapDic = self:_GetIndexTrapDic(teamEntity)

    local pathSuperGridCount = self:_GetPathSuperGridCount()
    pathSuperGridCount = self:_ModifyPathSuperGridCount(pathSuperGridCount,teamEntity)
    logicChainPathCmpt:SetPathSuperGridCount(pathSuperGridCount)

    local pathPoorGridCount = self:_GetPathPoorGridCount()
    logicChainPathCmpt:SetPathPoorGridCount(pathPoorGridCount)

    ---触发陷阱顺序
    self._triggerTrapIndex = 1

    ---@type SortedDictionary<number, table<number, NormalAttackData>> key 时间  value 伤害list(在同一个时间可能有多个伤害)
    self._timeAttackListDic = SortedDictionary:New()

    --重置统一帧倍数时长表
    self._frameTimeMultipleDic = {}

    self._stopChainIndex = nil

    self._stopPos = nil
end

function NormalSkillCalculator:_NotifyNormalAttackStart()
    for petIndex = 1, #self._petRoundTeam do
        local petEntityID = self._petRoundTeam[petIndex]
        local petEntity = self._world:GetEntityByID(petEntityID)

        self._triggerService:Notify(NTNormalAttackStart:New(petEntity, self._chainPathElementType, self._chainPathData))
    end
end

function NormalSkillCalculator:_NotifyNormalAttackEnd()
    for petIndex = 1, #self._petRoundTeam do
        local petEntityID = self._petRoundTeam[petIndex]
        local petEntity = self._world:GetEntityByID(petEntityID)

        self._triggerService:Notify(NTNormalAttackEnd:New(petEntity))
    end
end

---移动一个格子需要的时间  计算是否斜着走
function NormalSkillCalculator:_GetOneGridMoveTime(pathPosition, chainIndex)
    local oneGridMoveTime = 0
    if self:_IsPosInCrossLine(pathPosition, self._chainPathData[chainIndex - 1]) then
        oneGridMoveTime = self:_MakeTimeFrameTimeMultiple(BattleConst.OneGridMoveTime)
    else
        oneGridMoveTime = self:_MakeTimeFrameTimeMultiple(BattleConst.OneGridObliqueMoveTime)
    end
    return oneGridMoveTime
end

---统计每个AttackGridData的时间
function NormalSkillCalculator:_OnGetTimeAttackListDic(teamEntity)
    ---@type number 计算过程中的当前时间
    local currentTime = 0

    ---辅助数据 统计每个宝宝到达和离开每个连线格子的时间
    ---@type table<number, table<number, table<number, number>>> key1 petIndex  key2 chainIndex  key3 1:到达时间 2:离开时间  value 时间  (第一个宝宝到达第一个格子时间为零)
    local petGridTimeDic = {}

    local petsAttactList = self:_OnGetPathAttackList(teamEntity, self._chainPathData)
    self._pathMoveStartWaitTime = self:_OnGetPathMoveStartWaitTime(petsAttactList)

    --统计全部AttackGridData的时序并保存结果
    for petIndex = 1, #self._petRoundTeam do
        local petEntityID = self._petRoundTeam[petIndex]
        local petEntity = self._world:GetEntityByID(petEntityID)
        local petAttackDataCmpt = petEntity:SkillPetAttackData()
        ---@type SkillPathNormalAttackData
        local normalAttackData = petAttackDataCmpt:GetNormalAttackData()

        petGridTimeDic[petIndex] = {}

        for chainIndex, pathPosition in ipairs(self._chainPathData) do
            petGridTimeDic[petIndex][chainIndex] = {}

            -- 计算星灵在格子上的攻击结束时间，划水普攻，从移动开始计算爆点
            currentTime = self:_OnCalcAttackFinishTimeBeforeMove(currentTime, petIndex, chainIndex, pathPosition)

            --1 计算星灵在格子上的移动结束时间
            currentTime, petGridTimeDic =
                self:_OnCalcMoveFinishTime(currentTime, petIndex, chainIndex, pathPosition, petGridTimeDic)

            ---@type SkillPathPointNormalAttackData
            local pathPointAttackData = normalAttackData:GetPathPointAttackData(pathPosition)

            --2 计算星灵在格子上的攻击结束时间
            if pathPointAttackData ~= nil then
                currentTime = self:_OnCalcAttackFinishTime(currentTime, petIndex, chainIndex, pathPosition)
            end

            petGridTimeDic[petIndex][chainIndex][2] = currentTime + BattleConst.FrameTime

            --最后一个pet离开起点
            if chainIndex <= #self._chainPathData and chainIndex == 2 and petIndex == #self._petRoundTeam then
                self._world:GetService("Trigger"):Notify(NTPlayerFirstMoveEnd:New(petEntity, self._chainPathData[1]))
            end
        end
    end
end

---计算星灵在格子上的移动开始时间
function NormalSkillCalculator:_OnCalcMoveFinishTime(currentTime, petIndex, chainIndex, pathPosition, petGridTimeDic)
    local petEntityID = self._petRoundTeam[petIndex]
    local petEntity = self._world:GetEntityByID(petEntityID)

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    --上一个星灵 在下一个格子的攻击时间
    local prePetAttackTime = 0
    if petIndex > 1 then
        prePetAttackTime = self:_GetNormalAttackTime(petIndex - 1, pathPosition)
    end
    --星灵 在下一个格子的攻击时间
    local curPetAttackTime = self:_GetNormalAttackTime(petIndex, pathPosition)

    local waitAttactTime = prePetAttackTime - curPetAttackTime
    if waitAttactTime < 0 then
        waitAttactTime = 0
    end

    if not self._pathNormalSkillWaitTimeDic[petIndex] then
        self._pathNormalSkillWaitTimeDic[petIndex] = {}
    end
    self._pathNormalSkillWaitTimeDic[petIndex][chainIndex] = waitAttactTime

    if petIndex == 1 and chainIndex == 1 then
        --出发点不会有陷阱
        petGridTimeDic[petIndex][chainIndex][1] = 0
        currentTime = 0
    elseif petIndex == 1 then
        --Log.fatal("[normal attack time] pet:"..petIndex.." arrive pos:"..tostring(pathPosition).." time:"..currentTime)
        --到达第chainIndex个格子的时间
        local oneGridMoveTime = self:_GetOneGridMoveTime(pathPosition, chainIndex)
        local t = currentTime + BattleConst.FrameTime + oneGridMoveTime
        petGridTimeDic[petIndex][chainIndex][1] = t

        currentTime = petGridTimeDic[petIndex][chainIndex][1]

        local attackList = {}
        if self._timeAttackListDic:ContainsKey(t) then
            attackList = self._timeAttackListDic:Find(t)
        else
            self._timeAttackListDic:Insert(t, attackList)
        end

        table.insert(attackList, ChainMoveData:New(petEntityID, pathPosition, chainIndex))

        --计算陷阱触发效果及导致的停顿
        if self._indexTrapDic[chainIndex] then
            self._timeTrapDic:Insert(currentTime, chainIndex)
            local trapDelay = self:_GetTrapDelay(self._indexTrapDic[chainIndex])
            currentTime = petGridTimeDic[petIndex][chainIndex][1] + self:_MakeTimeFrameTimeMultiple(trapDelay)
        end
    elseif chainIndex == 1 then
        --Log.fatal("[normal attack time] pet:"..petIndex.." arrive pos:"..tostring(pathPosition).." time:"..currentTime)

        petGridTimeDic[petIndex][chainIndex][1] =
            petGridTimeDic[petIndex - 1][chainIndex][1] + self:_MakeTimeFrameTimeMultiple(self._pathMoveStartWaitTime) +
            waitAttactTime

        currentTime = petGridTimeDic[petIndex][chainIndex][1]

        local attackList = {}
        if self._timeAttackListDic:ContainsKey(currentTime) then
            attackList = self._timeAttackListDic:Find(currentTime)
        else
            self._timeAttackListDic:Insert(currentTime, attackList)
        end

        table.insert(attackList, ChainMoveData:New(petEntityID, pathPosition, chainIndex))
    else
        --Log.fatal("[normal attack time] pet:"..petIndex.." arrive pos:"..tostring(pathPosit.ion).." time:"..currentTime)

        --计算第petIndex宝宝到达第chainIndex格子时间
        local oneGridMoveTime = self:_GetOneGridMoveTime(pathPosition, chainIndex)

        --上一个星灵在目标格子的最后时间
        local prePetFinishActionTime = petGridTimeDic[petIndex - 1][chainIndex][2]

        --计算等待时间
        --如果不是队长 and 当前时间 <= 上一个星灵在这个点的攻击时间
        if chainIndex ~= #self._chainPathData and currentTime <= prePetFinishActionTime then
            local nextChainIndex = chainIndex + 1
            local nextPathPosition = self._chainPathData[nextChainIndex]
            -- --计算第petIndex宝宝到达第chainIndex格子时间
            -- local prePetLeaveMoveTime = self:_GetOneGridMoveTime(nextPathPosition, nextChainIndex)
            local prePetLeaveMoveTime = 0

            currentTime = prePetFinishActionTime + prePetLeaveMoveTime + BattleConst.FrameTime
        end

        petGridTimeDic[petIndex][chainIndex][1] = currentTime + oneGridMoveTime + waitAttactTime

        currentTime = petGridTimeDic[petIndex][chainIndex][1]

        local attackList = {}
        if self._timeAttackListDic:ContainsKey(currentTime) then
            attackList = self._timeAttackListDic:Find(currentTime)
        else
            self._timeAttackListDic:Insert(currentTime, attackList)
        end

        table.insert(attackList, ChainMoveData:New(petEntityID, pathPosition, chainIndex))
    end

    return currentTime, petGridTimeDic
end

---计算星灵在格子上的攻击结束时间
function NormalSkillCalculator:_OnCalcAttackFinishTime(currentTime, petIndex, chainIndex, pathPosition)
    local petEntityID = self._petRoundTeam[petIndex]
    local petEntity = self._world:GetEntityByID(petEntityID)

    --检查这个出战星灵是否有禁止普攻技能的buff
    ---@type BuffComponent
    local buffComp = petEntity:BuffComponent()
    local forbidPetNormalSkill = buffComp:GetBuffValue("ForbidPetNormalSkill")
    if forbidPetNormalSkill then
        return currentTime
    end

    --划水普攻，攻击爆点从开始移动的时候开始计算
    local normalSkillBeforeMove = buffComp:GetBuffValue("NormalSkillBeforeMove")
    if normalSkillBeforeMove then
        return currentTime
    end

    local petAttackDataCmpt = petEntity:SkillPetAttackData()
    ---@type SkillPathNormalAttackData
    local normalAttackData = petAttackDataCmpt:GetNormalAttackData()

    -- ---提取技能配置数据
    -- ---@type SkillInfoComponent
    -- local skillInfoCmpt = petEntity:SkillInfo()
    -- local normalSkillID = skillInfoCmpt:GetNormalSkillID()

    ---@type SkillPathPointNormalAttackData
    local pathPointAttackData = normalAttackData:GetPathPointAttackData(pathPosition)

    local attackGridDic = pathPointAttackData:GetAttackGridDic()

    ---排序后的格子队列
    local orderGridArray = pathPointAttackData:GetPetOrderGridArray(petEntity, pathPosition)
    local gridCount = #orderGridArray
    if (petEntity:BuffComponent():GetBuffValue("ForcePetNormalAttackAfterMove")) then
        if chainIndex ~= 1 then
            orderGridArray = {pathPosition}
            gridCount = 1
        else
            orderGridArray = {}
            gridCount = 0
        end
    end
    -- if gridCount > 0 then
    --     currentTime = currentTime + BattleConst.FrameTime
    -- end

    --Log.fatal("[normal attack time] pet:"..petIndex.." before attack time:"..currentTime)
    for i, beAttackPos in ipairs(orderGridArray) do
        ---@type AttackGridData
        local attackGridData = self:_FindAttackGridData(attackGridDic, beAttackPos)
        local isLastAttackPos = i == gridCount

        --[[
            路万博(@PLM) 12-6 10:49:32
            歌尔蒂的需求是穿怪时全队不普攻，维克的需求是每个格子必定普攻

            路万博(@PLM) 12-6 10:49:43
            你们俩商量下这俩人用一起了怎么办@All

            ...

            孙艺文 12-6 11:17:05
            是这样，这俩同场上概率不高，怎么方便处理怎么来吧

            孙艺文 12-6 11:17:11
            不报错就行
        ]]
        if attackGridData then
            local normalSkillID = attackGridData:GetAttackGridSkillId()

            currentTime = currentTime + BattleConst.FrameTime
            local normalAttackData =
            NormalAttackData:New(
                    attackGridData,
                    petEntityID,
                    normalSkillID,
                    beAttackPos,
                    chainIndex,
                    pathPosition,
                    isLastAttackPos
            )

            --Log.fatal("[normal attack time] pet:"..petIndex.." before attack anim time:"..currentTime)

            local hitTime, length = self:_GetNormalAttackHitTimeAndLength(normalSkillID, isLastAttackPos, petEntity)
            local attackTime = currentTime + self:_MakeTimeFrameTimeMultiple(hitTime)
            currentTime = currentTime + self:_MakeTimeFrameTimeMultiple(length)

            --Log.fatal("[normal attack time] pet:"..petIndex.." hit time:"..hitTime.." length time:"..length.." time stamp:"..currentTime)
            self._world:GetSyncLogger():Trace(
                    {
                        key = "NormalAttackGridDataTime",
                        entityID = petEntityID,
                        attackTime = attackTime,
                        chainIndex = chainIndex,
                        beAttackPos = tostring(beAttackPos),
                        attackPos = tostring(pathPosition)
                    }
            )

            --将attack time作为key 插入到伤害排序列表中
            local attackList = {}
            if self._timeAttackListDic:ContainsKey(attackTime) then
                attackList = self._timeAttackListDic:Find(attackTime)
            else
                self._timeAttackListDic:Insert(attackTime, attackList)
            end
            attackList[#attackList + 1] = normalAttackData

            --Log.fatal("[normal attack time Attack] pet "..petIndex.." target id:"..attackGridData:GetTargetID().."  path pos "..tostring(pathPosition).."  attack pos "..tostring(beAttackPos).."  time "..attackTime)
            --[[普攻时序log
                            GameGlobal.TaskManager():CoreGameStartTask(function(TT)
                                YIELD(TT, attackTime * 1000)
                                Log.fatal("Normal Attack: pet "..petIndex.."  path pos "..tostring(pathPosition).."  attack pos "..tostring(beAttackPos).."  time "..attackTime)
                            end)
                            --]]
        end
    end

    return currentTime
end

---计算星灵在格子上的攻击结束时间，划水普攻，从移动开始计算爆点
function NormalSkillCalculator:_OnCalcAttackFinishTimeBeforeMove(currentTime, petIndex, chainIndex, pathPosition)
    local petEntityID = self._petRoundTeam[petIndex]
    local petEntity = self._world:GetEntityByID(petEntityID)

    ---@type BuffComponent
    local buffComp = petEntity:BuffComponent()
    --划水普攻，攻击爆点从开始移动的时候开始计算
    local normalSkillBeforeMove = buffComp:GetBuffValue("NormalSkillBeforeMove")
    if not normalSkillBeforeMove then
        return currentTime
    end

    local petAttackDataCmpt = petEntity:SkillPetAttackData()
    ---@type SkillPathNormalAttackData
    local normalAttackData = petAttackDataCmpt:GetNormalAttackData()

    ---@type SkillPathPointNormalAttackData
    local pathPointAttackData = normalAttackData:GetPathPointAttackData(pathPosition)

    local attackGridDic = pathPointAttackData:GetAttackGridDic()

    ---排序后的格子队列
    local orderGridArray = pathPointAttackData:GetPetOrderGridArray(petEntity, pathPosition)
    local gridCount = #orderGridArray
    if (petEntity:BuffComponent():GetBuffValue("ForcePetNormalAttackAfterMove")) then
        if chainIndex ~= 1 then
            orderGridArray = {pathPosition}
            gridCount = 1
        else
            orderGridArray = {}
            gridCount = 0
        end
    end

    for i, beAttackPos in ipairs(orderGridArray) do
        ---@type AttackGridData
        local attackGridData = self:_FindAttackGridData(attackGridDic, beAttackPos)
        local isLastAttackPos = i == gridCount

        --[[
            路万博(@PLM) 12-6 10:49:32
            歌尔蒂的需求是穿怪时全队不普攻，维克的需求是每个格子必定普攻

            路万博(@PLM) 12-6 10:49:43
            你们俩商量下这俩人用一起了怎么办@All

            ...

            孙艺文 12-6 11:17:05
            是这样，这俩同场上概率不高，怎么方便处理怎么来吧

            孙艺文 12-6 11:17:11
            不报错就行
        ]]
        if attackGridData then
            local normalSkillID = attackGridData:GetAttackGridSkillId()

            -- currentTime = currentTime + BattleConst.FrameTime
            local normalAttackData =
            NormalAttackData:New(
                    attackGridData,
                    petEntityID,
                    normalSkillID,
                    beAttackPos,
                    chainIndex,
                    pathPosition,
                    isLastAttackPos
            )

            local hitTime, length = self:_GetNormalAttackHitTimeAndLength(normalSkillID, isLastAttackPos, petEntity)
            local attackTime = currentTime + self:_MakeTimeFrameTimeMultiple(hitTime)
            -- currentTime = currentTime + self:_MakeTimeFrameTimeMultiple(length)

            self._world:GetSyncLogger():Trace(
                    {
                        key = "NormalAttackGridDataTime",
                        entityID = petEntityID,
                        attackTime = attackTime,
                        chainIndex = chainIndex,
                        beAttackPos = tostring(beAttackPos),
                        attackPos = tostring(pathPosition)
                    }
            )

            --将attack time作为key 插入到伤害排序列表中
            local attackList = {}
            if self._timeAttackListDic:ContainsKey(attackTime) then
                attackList = self._timeAttackListDic:Find(attackTime)
            else
                self._timeAttackListDic:Insert(attackTime, attackList)
            end
            attackList[#attackList + 1] = normalAttackData
        end
    end

    return currentTime
end

function NormalSkillCalculator:_OnCalcAndApply(teamEntity)
    ---储存每个技能的顺序
    self._playNormalSkillSequence = {}
    self._pathTriggerTrapsDic = {}

    local normalSkillIndex = 1
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()

    local teamEntityLeader = teamEntity:GetTeamLeaderPetEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPath = logicChainPathCmpt:GetLogicChainPath()

    --需要发从起点出发的每个光灵的移动通知
    for petIndex = 1, #self._petRoundTeam do
        local petEntityID = self._petRoundTeam[petIndex]
        local petEntity = self._world:GetEntityByID(petEntityID)
        local ntPetChainMoveBegin = NTPetChainMoveBegin:New(petEntity, chainPath[1], 0, nil, 1)
        triggerSvc:Notify(ntPetChainMoveBegin)
    end

    --按时序计算全部AttackGridData的伤害并应用结果
    for i = 1, self._timeAttackListDic:Size() do
        --1 在每次攻击以前 检查机关的触发
        self:_OnCheckTriggerTrapBeforeAttack(teamEntity, i)

        --2 计算攻击数据
        local attackList = self._timeAttackListDic:GetAt(i)
        for k = 1, #attackList do
            local data = attackList[k]
            if data._className == "NormalAttackData" then
                ---@type NormalAttackData
                local normalAttackData = attackList[k]
                ---@type AttackGridData
                local attackGridData = normalAttackData:GetAttackGridData()
                local petEntityID = normalAttackData:GetPetEntityID()
                local casterEntity = self._world:GetEntityByID(petEntityID)
                --2.0  初始技能 初始技能目标 用于区分首要攻击目标和溅射攻击目标
                local originaBeAttackPos = normalAttackData:GetBeAttackPos()
                local originalSkillID = attackGridData:GetAttackGridSkillId()
                local originalAttackPosList = attackGridData:GetAttackPosList()
                local originalTargetIdList = attackGridData:GetTargetIdList()

                local newAttackSkillId = originalSkillID
                local directReplace = 0 --直接替换普攻，而不是计算普攻扩展，默认0计算扩展

                local attackPos = normalAttackData:GetPathPosition()
                self._world:GetService("Trigger"):Notify(
                    NTNormalAttackChangeBefore:New(casterEntity, attackPos, originaBeAttackPos)
                )

                --2.1  重新计算attackGridData buff修改技能ID 重新计算范围 目标
                attackGridData, newAttackSkillId, directReplace = self:_CalcNormalSkillExtraScope(normalAttackData)
                ---存在可能导致后续不攻击的行为 要判断一下
                if self:CanAttackByPos(attackPos) then
                    --2.2  计算伤害
                    self:_CalcNormalSkillEffect(
                        teamEntity,
                        normalAttackData,
                        attackGridData,
                        originalSkillID,
                        originaBeAttackPos,
                        directReplace,
                        false
                    )

                    --2.3  存储修改后的 NormalAttackData  表现要取
                    self:_SaveAttackGridData(normalAttackData, attackGridData)

                    --将普攻的逻辑顺序保存给表现，表现做普攻爆点等待
                    self:_OnSavePlayNormalSkillSequence(
                        casterEntity,
                        normalSkillIndex,
                        originalSkillID,
                        newAttackSkillId,
                        normalAttackData,
                        originaBeAttackPos,
                        attackGridData
                    )

                    --如果有普攻双击的buff，再次计算一个普攻
                    if self:_OnCheckNormalAttackDouble(casterEntity,normalAttackData) then
                        self:_ForNormalAttackDouble(
                            teamEntity,
                            casterEntity,
                            normalAttackData,
                            originalAttackPosList,
                            originalTargetIdList,
                            originaBeAttackPos,
                            originalSkillID
                        )
                    end
                end
            elseif data._className == "ChainMoveData" then
                ---@type ChainMoveData
                local chainMoveData = data
                local v2Pos = chainMoveData:GetPos()
                if self:CanMoveToPos(v2Pos) then
                    -- local posOld = teamEntity:GetGridPosition()

                    local petEntityID = chainMoveData:GetPetEntityID()
                    local petEntity = self._world:GetEntityByID(petEntityID)
                    local pieceType = utilData:FindPieceElement(v2Pos)
                    local chainIndex = chainMoveData:GetChainIndex()
                    local ntPlayerEachMoveStart = NTPlayerEachMoveStart:New(petEntity, v2Pos, pieceType, chainIndex)
                    triggerSvc:Notify(ntPlayerEachMoveStart)

                    local pieceEffectType = PieceEffectType.Normal
                    local traps = self._pathTriggerTrapsDic[chainIndex]
                    if traps then
                        for _, e in ipairs(traps) do
                            if e:Trap():IsPrismGrid() then
                                pieceEffectType = PieceEffectType.Prism
                                break
                            end
                        end
                    end
                    --修改Pet的位置，解决普攻完成后计算距离Pet最远怪已Pet最后终点格子为基准格子的问题
                    petEntity:SetGridPosition(v2Pos)

                    local chainIndexOld = math.max(1, chainIndex - 1)
                    local posOld = chainPath[chainIndexOld]

                    local ntPlayerEachMoveEnd = NTPlayerEachMoveEnd:New(petEntity, v2Pos, pieceType, posOld, chainIndex)
                    ntPlayerEachMoveEnd:SetPieceEffectType(pieceEffectType)
                    triggerSvc:Notify(ntPlayerEachMoveEnd)

                    if petEntityID == teamEntityLeader:GetID() then
                        -- 本次移动的出发位置，通知用
                        local v2TeamMoveBeginPos = teamEntity:GetGridPosition()
                        ---解决行走在任意一个格子上，伤害飘字都在最后终点格子上的问题
                        teamEntity:SetGridPosition(v2Pos)

                        local ntTeamLeaderEachMoveStart = NTTeamLeaderEachMoveStart:New(petEntity, v2Pos, pieceType, posOld)
                        triggerSvc:Notify(ntTeamLeaderEachMoveStart)

                        local ntTeamEachMoveStart = NTTeamEachMoveStart:New(teamEntity, v2Pos, pieceType, posOld)
                        triggerSvc:Notify(ntTeamEachMoveStart)

                        local ntTeamLeaderEachMoveEnd = NTTeamLeaderEachMoveEnd:New(petEntity, v2Pos, pieceType, posOld)
                        ntTeamLeaderEachMoveEnd:SetPieceEffectType(pieceEffectType)
                        triggerSvc:Notify(ntTeamLeaderEachMoveEnd)

                        local ntTeamEachMoveEnd = NTTeamEachMoveEnd:New(teamEntity, v2Pos, pieceType, posOld)
                        ntTeamEachMoveEnd:SetPieceEffectType(pieceEffectType)
                        triggerSvc:Notify(ntTeamEachMoveEnd)
                    end
                end
            end
        end
    end
end

---计算因为buff修改技能范围
---@param normalAttackData NormalAttackData
function NormalSkillCalculator:_CalcNormalSkillExtraScope(normalAttackData)
    ---@type AttackGridData
    local attackGridData = normalAttackData:GetAttackGridData()
    local petEntityID = normalAttackData:GetPetEntityID()
    local petEntity = self._world:GetEntityByID(petEntityID)
    local normalSkillID = attackGridData:GetAttackGridSkillId()
    local beAttackPos = normalAttackData:GetBeAttackPos()
    local chainIndex = normalAttackData:GetChainIndex()
    local pathPosition = normalAttackData:GetPathPosition()

    --检查是否有更改普攻技能的buff
    ---@type BuffComponent
    local buffComp = petEntity:BuffComponent()
    local newAttackSkillId = buffComp:GetBuffValue("ChangeNormalSkillID") or normalSkillID --新普攻ID，取不到就用原来的
    --可以通过其他条件增加次数
    local newAttackSkillCount = buffComp:GetBuffValue("ChangeNormalSkillCount") or 0
    local normalSkillDirectReplace = buffComp:GetBuffValue("NormalSkillDirectReplace")
    local newNormalSkillExcludeOriPos = buffComp:GetBuffValue("ChangeNormalSkillExcludeOriPos") or 0 --扩展普攻范围是否去掉原攻击位置
    local useAttackPosAsCenter = buffComp:GetBuffValue("ChangeNormalSkillUseAttackPosAsCenter") or 0 --扩展普攻的范围中心点使用光灵攻击位置（而不是被击位置）
    local normalAttackRemoveSameTarget = buffComp:GetBuffValue("NormalAttackRemoveSameTarget") or 0 --相同的目标只攻击一次
    local normalAttackCrossTwoCount = buffComp:GetBuffValue("NormalAttackCrossTwoCount") or 0 --十字两格的普攻

    if newAttackSkillId and newAttackSkillCount > 0 then
        buffComp:SetBuffValue("ChangeNormalSkillCount", newAttackSkillCount - 1)

        --计算目标列表
        local targetIds = {}
        local gridPosArr = {}

        if normalSkillDirectReplace == 1 then
            --只替换技能ID，技能目标不变
            attackGridData:SetAttackGridSkillID(newAttackSkillId)
        else
            --常规，以被击点为中心进行计算范围
            local centerPos = beAttackPos
            if useAttackPosAsCenter == 1 then
                centerPos = pathPosition
            end

            --重新计算攻击目标
            ---@type SkillConfigData 普通攻击的技能数据
            local skillConfigData = self._configService:GetSkillConfigData(newAttackSkillId)
            local skillTargetType = skillConfigData:GetSkillTargetType()
            local casterDir = beAttackPos - pathPosition

            ---@type UtilScopeCalcServiceShare
            local utilScopeSvc = self._world:GetService("UtilScopeCalc")
            ---@type SkillScopeResult
            local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, centerPos, petEntity, casterDir)
            local skill_range_grid_list = scopeResult:GetAttackRange()

            if newNormalSkillExcludeOriPos == 1 then
                table.removev(skill_range_grid_list, beAttackPos)
            end
            if normalAttackCrossTwoCount > 0 then
                local tmpRange = {}
                for _, gridPos in ipairs(skill_range_grid_list) do
                    local distance = Vector2.Distance(gridPos, beAttackPos)
                    if distance == 1 then
                        table.insert(tmpRange, gridPos)
                    end
                end
                skill_range_grid_list = tmpRange
            end
            skill_range_grid_list[#skill_range_grid_list + 1] = beAttackPos

            local targetEntities = nil
            if self._world:MatchType() == MatchType.MT_BlackFist then
                targetEntities = {self._world:Player():GetCurrentEnemyTeamEntity()}
            else
                local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
                targetEntities = monster_group:GetEntities()
            end

            for _, e in ipairs(targetEntities) do
                --需要判断是否可以选择为目标
                if self._skillScopeTargetSelector:SelectConditionFilter(e, true) then
                    local monster_grid_pos = e:GetGridPosition()
                    local monster_body_area_cmpt = e:BodyArea()
                    local monster_body_area = monster_body_area_cmpt:GetArea()

                    local targetBodyPosInSkillRangePosList = {}
                    for i, bodyArea in ipairs(monster_body_area) do
                        local curMonsterBodyPos = monster_grid_pos + bodyArea
                        if table.icontains(skill_range_grid_list, curMonsterBodyPos) then
                            table.insert(targetBodyPosInSkillRangePosList, curMonsterBodyPos)
                        end
                    end

                    if table.count(targetBodyPosInSkillRangePosList) > 0 then
                        if normalAttackRemoveSameTarget == 1 then
                            --如果是普攻去掉相同目标的，添加一个距离施法者最近的一个坐标就可以返回了
                            table.sort(
                                targetBodyPosInSkillRangePosList,
                                function(a, b)
                                    local disA = Vector2.Distance(pathPosition, a)
                                    local disB = Vector2.Distance(pathPosition, b)
                                    return disA < disB
                                end
                            )
                            table.insert(targetIds, e:GetID())
                            table.insert(gridPosArr, targetBodyPosInSkillRangePosList[1])
                        else
                            --常规普攻
                            for i, pos in ipairs(targetBodyPosInSkillRangePosList) do
                                table.insert(targetIds, e:GetID())
                                table.insert(gridPosArr, pos)
                            end
                        end
                    end
                end
            end
            --默认先取传进来的
            local NewAttackGridData = attackGridData
            --normalSkillID ==newAttackSkillId如果当前的普攻已经是新替换的了（普攻双击的第二次计算的时候）就不再新替换了
            if normalSkillID ~= newAttackSkillId then
                NewAttackGridData = AttackGridData:New(nil, nil, nil, newAttackSkillId)
            end

            --需要清掉再添加新的，解决上面那种没有AttackGridData:New的情况下，保留上次数据的情况
            NewAttackGridData:ClearTargetIdList()
            for i = 1, #targetIds do
                NewAttackGridData:AddTargetId(targetIds[i])
            end
            NewAttackGridData:ClearAttackPosList()
            for i = 1, #gridPosArr do
                NewAttackGridData:AddAttackPos(gridPosArr[i])
            end
            attackGridData = NewAttackGridData
            normalAttackData:SetAttackGridData(NewAttackGridData)
        end

        --计算完成后，传出去新的普攻ID
        normalSkillID = newAttackSkillId
    end

    return attackGridData, normalSkillID, normalSkillDirectReplace
end

---计算普攻技能效果
function NormalSkillCalculator:_CalcNormalSkillEffect(
    teamEntity,
    normalAttackData,
    attackGridData,
    originalSkillID,
    originaBeAttackPos,
    directReplace,
    isNormalAttackDouble)
    local endChainIndx = self:_CalcEndIndex() --玩家提前结束的格子索引

    local petEntityID = normalAttackData:GetPetEntityID()
    local petEntity = self._world:GetEntityByID(petEntityID)
    local normalSkillID = attackGridData:GetAttackGridSkillId()
    local chainIndex = normalAttackData:GetChainIndex()
    local beAttackEntityIdList = attackGridData:GetTargetIdList()
    local gridPosArr = attackGridData:GetAttackPosList()

    ---@type BuffComponent
    local buffComp = petEntity:BuffComponent()
    local normalAttackOneDamageOneCombo = buffComp:GetBuffValue("NormalAttackOneDamageOneCombo") --一个伤害一个combo

    --在死亡格子之前的格子都可以正常结算
    if chainIndex < self._deadChainIndx and chainIndex < endChainIndx then
        -- 设置连锁倍率参数，伤害计算需要这个参数
        -- 原先逻辑中chainIndex就是连锁倍率参数，但这样不能满足需求
        -- chainIndex现在回归了【格子在连锁路径中的索引】这一语义
        ---@type SkillPetAttackDataComponent
        local petAtkComponent = petEntity:SkillPetAttackData()
        ---@type UtilCalcServiceShare
        local utilCalcSvc = self._world:GetService("UtilCalc")

        ---@type LogicChainPathComponent
        local logicChainPathCmpt = teamEntity:LogicChainPath()
        local chainRate = logicChainPathCmpt:GetChainRateAtIndex(chainIndex)
        petAtkComponent:SetCurrentChainDamageRate(chainRate)
        local superGridNum = logicChainPathCmpt:GetSuperGridCountAtPathIndex(chainIndex)
        petAtkComponent:SetCurrentSuperGridNum(superGridNum)
        local poorGridNum = logicChainPathCmpt:GetPoorGridCountAtPathIndex(chainIndex)
        petAtkComponent:SetCurrentPoorGridNum(poorGridNum)
        local chainPathPoint = self._chainPathData[chainIndex]

        self._world:GetService("Trigger"):Notify(NTNormalAttackCalcStart:New(petEntity, attackGridData))
        local firstDefender, firstDefenderPos, firstDamagePos
        for i = 1, #beAttackEntityIdList do
            local beAttackEntityID = beAttackEntityIdList[i]
            local defenderEntity = self._world:GetEntityByID(beAttackEntityID)
            local pos = defenderEntity:GridLocation().Position
            if not firstDefender then
                firstDefender = defenderEntity
                firstDefenderPos = pos
            end
            local gridPos = pos
            if gridPosArr and gridPosArr[i] then
                gridPos = gridPosArr[i]
            end
            if not firstDamagePos then
                firstDamagePos = gridPos
            end
            --初始攻击点使用初始技能计算伤害  额外范围使用替换的技能计算伤害  and 不是直接替换普攻的技能，默认directReplace=0计算扩展
            local skillID = normalSkillID
            if gridPos == originaBeAttackPos and directReplace == 0 then
                skillID = originalSkillID
            end

            local calcParam =
                SkillEffectCalcParam:New(
                petEntityID,
                {beAttackEntityID},
                nil, -- .skillEffectParam后面会赋值
                skillID,
                nil, -- skillRange原先也没有
                chainPathPoint,
                gridPos
            )

            calcParam:SetDamageGridPos(gridPos)

            self:_OnApplyEachSkillEffect(petEntity, attackGridData, calcParam, isNormalAttackDouble)

            --如果是一个伤害一个combo and 不是最后一个伤害
            if normalAttackOneDamageOneCombo == 1 and i ~= #beAttackEntityIdList then
                self:_AddCombo(teamEntity)

                --
                local skillAddComboResult = SkillAddComboNumEffectResult:New()
                attackGridData:AddEffectResult(skillAddComboResult)
            end
        end

        --普攻如果是治疗就不增加combo(诺维亚)
        local hasDamageEffect = false
        ---@type ConfigDecorationService
        local svcCfgDeco = self._world:GetService("ConfigDecoration")
        local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(petEntity:GetID(), normalSkillID)
        for _, v in ipairs(skillEffectArray) do
            ---@type SkillEffectParamBase
            local skillEffectParam = v
            ---@type SkillEffectType
            local skillEffectType = skillEffectParam:GetEffectType()
            if skillEffectType == SkillEffectType.Damage then
                hasDamageEffect = true
                break
            end
        end

        --本次普攻有伤害效果 再添加combo
        if hasDamageEffect then
            self:_AddCombo(teamEntity)
        end

        --通知一次 计算普通结束
        local nt = NTNormalAttackCalcEnd:New(petEntity, firstDefender, chainPathPoint, firstDamagePos)
        nt:SetSkillID(normalSkillID)
        nt:SetSkillType(SkillType.Normal)
        self._world:GetService("Trigger"):Notify(nt)

        --与NTNormalAttackCalcEnd区别是被击位置使用originaBeAttackPos
        local nt1 = NTNormalAttackCalcEndUseOriPos:New(petEntity, firstDefender, chainPathPoint, originaBeAttackPos)
        nt1:SetSkillID(normalSkillID)
        nt1:SetSkillType(SkillType.Normal)
        self._world:GetService("Trigger"):Notify(nt1)
    end
end

function NormalSkillCalculator:_AddCombo(teamEntity)
    local battleSvc = self._world:GetService("Battle")
    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local curComboNum = battleSvc:GetLogicComboNum()
    curComboNum = curComboNum + 1
    battleSvc:SetLogicComboNum(curComboNum)
    --combo数就是普攻数
    battleStatComponent:SetOneChainMaxNormalAttack(teamEntity, curComboNum)
end

---@param t SkillEffectCalcParam
function NormalSkillCalculator:_OnApplyEachSkillEffect(petEntity, attackGridData, t, isNormalAttackDouble)
    local logger = self._world:GetMatchLogger()
    logger:BeginSkill(t.casterEntityID, t.attackPos, t.skillID, t.skillRange)
    --buff通知
    self:_NotifyNormalSkillBegin(t)

    --存储一个伤害结果，用于普攻表现。在加血普攻修改技能目标前
    ---@type SkillDamageEffectResult
    local saveSkillDamageEffectResult = self:_SaveDamageResultBeforeAddBlood(t)

    local totalDamage = 0
    local damageType
    local skillEffectResultArray = self._skillEffectCalcService:CalcSkillEffect_All(t)
    for effectResultIndex = 1, #skillEffectResultArray do
        local skillResultData = skillEffectResultArray[effectResultIndex]
        local skillEffectType = skillResultData:GetEffectType()

        attackGridData:AddEffectResult(skillResultData)

        if skillEffectType == SkillEffectType.Damage then
            ---@type SkillDamageEffectResult
            local skillDamageEffectResult = skillResultData
            ---@type DamageInfo
            local damageInfo = skillDamageEffectResult:GetDamageInfo(1)
            local targetID = skillDamageEffectResult:GetTargetID()
            local castDamage = skillDamageEffectResult:GetTotalDamage()
            if isNormalAttackDouble then
                skillDamageEffectResult:SetNormalAttackDouble(true)
            end
            damageType = damageInfo:GetDamageType()
            attackGridData:AddDamageValue(targetID, castDamage)
            totalDamage = totalDamage + castDamage
        elseif skillEffectType == SkillEffectType.AddBlood then
            --这里是为了最后一个有伤害的普攻静帧表现用的，治疗普攻可以不静帧。这里可以不处理往普攻数据里添加伤害（attackGridData:AddDamageValue）

            --如果是加血的普攻，是没有伤害结果的
            --但是为了在普攻表现的时候，有朝向，可以发送普攻的表现通知，可以匹配被击者。需要添加一个假的伤害结果
            damageType = DamageType.Invalid
            attackGridData:AddEffectResult(saveSkillDamageEffectResult)

            --普攻的伤害在计算的时候就应用了，这里需要添加治疗效果的应用
            ---@type SkillEffectResult_AddBlood
            local addBloodResult = skillResultData
            local targetID = addBloodResult:GetTargetID()
            local healValue = addBloodResult:GetAddValue()
            ---@type DamageInfo
            local addHpDamageInfo = DamageInfo:New(healValue, DamageType.Recover)
            ---@type CalcDamageService
            local calcDamageSvc = self._world:GetService("CalcDamage")
            calcDamageSvc:AddTargetHP(targetID, addHpDamageInfo)
            addBloodResult:SetDamageInfo(addHpDamageInfo)
            attackGridData:AddEffectResult(addBloodResult)
        elseif skillEffectType == SkillEffectType.WeikeNotify then
            local executor = SkillEffectLogicExecutor:New(self._world)
            executor:_ApplyWeikeNotify(petEntity, {}, {skillResultData})
            attackGridData:AddEffectResult(skillResultData)
        end
    end
    --buff通知
    self:_NotifyNormalSkillEnd(t, damageType, totalDamage, saveSkillDamageEffectResult)

    logger:EndSkill(t.casterEntityID)
    ---普攻数据埋点
    self._world:GetDataLogger():AddDataLog("OnNormalSkillEnd", petEntity, t.skillID, totalDamage)
end

---@param t SkillEffectCalcParam
function NormalSkillCalculator:_SaveDamageResultBeforeAddBlood(t)
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(0, DamageType.Invalid)
    ---@type SkillDamageEffectResult
    local skillDamageEffectResult = SkillDamageEffectResult:New(t.gridPos, t.targetEntityIDs[1], 0, {damageInfo})
    return skillDamageEffectResult
end

---存储一个伤害结果，用于普攻表现。在加血普攻修改技能目标前
---@param t SkillEffectCalcParam
function NormalSkillCalculator:_NotifyNormalSkillBegin(t)
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local attacker = self._world:GetEntityByID(t.casterEntityID)
    local defender = self._world:GetEntityByID(t.targetEntityIDs[1])
    local nt = NTNormalEachAttackStart:New(attacker, defender, t.attackPos, t.gridPos)
    nt:SetSkillID(t.skillID)
    nt:SetSkillType(SkillType.Normal)
    triggerSvc:Notify(nt)
end

---@param t SkillEffectCalcParam
---@param damageResult SkillDamageEffectResult
function NormalSkillCalculator:_NotifyNormalSkillEnd(t, damageType, damageValue, damageResult)
    --不能使用attackGridData，因为会包含这个点上的所有格子的结果
    --不能使用SkillEffectCalcParam，因为如果是加血普攻，技能范围和目标会被改
    --只能使用在计算以前存的SkillDamageEffectResult
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local attacker = self._world:GetEntityByID(t.casterEntityID)
    local defender = self._world:GetEntityByID(damageResult:GetTargetID())

    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local heroLastAttackMonster = {defender:GetID(), damageResult:GetGridPos()}
    battleStatComponent:SetHeroLastAttackMonster(heroLastAttackMonster)

    local nt = NTNormalEachAttackEnd:New(attacker, defender, t.attackPos, damageResult:GetGridPos())
    nt:SetSkillID(t.skillID)
    nt:SetSkillType(SkillType.Normal)

    nt:SetDamageValue(damageValue)
    nt:SetDamageType(damageType)

    triggerSvc:Notify(nt)
end

---存储修改后的 NormalAttackData
---@param normalAttackData NormalAttackData
---@param attackGridData AttackGridData
function NormalSkillCalculator:_SaveAttackGridData(normalAttackData, attackGridData)
    local petEntityID = normalAttackData:GetPetEntityID()
    local petEntity = self._world:GetEntityByID(petEntityID)
    local chainIndex = normalAttackData:GetChainIndex()
    local beAttackPos = normalAttackData:GetBeAttackPos()

    ---@type SkillPetAttackDataComponent
    local skillPetAttackDataComponent = petEntity:SkillPetAttackData()
    ---@type SkillPathNormalAttackData
    local normalAtkData = skillPetAttackDataComponent:GetNormalAttackData()
    local pos = self._chainPathData[chainIndex]
    ---@type SkillPathPointNormalAttackData
    local pathPointNormalAttackData = normalAtkData:GetPathPointAttackData(pos)
    local attackGridDic = pathPointNormalAttackData:GetAttackGridDic()
    for k, v in pairs(attackGridDic) do
        if k.x == beAttackPos.x and k.y == beAttackPos.y then
            attackGridDic[k] = attackGridData
            break
        end
    end
end

---获得普攻被击动画的时长
function NormalSkillCalculator:_GetNormalAttackHitTimeAndLength(skillID, isLastAttackPos, casterEntity)
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
    end
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)
    ---服务端还不能正常解析view，所以这里打个补丁
    if skillPhaseArray == nil or #skillPhaseArray == 0 then
        if self._skillViewParser == nil then
            self._skillViewParser = SkillViewParamParser:New()
        end

        local skillConfig = BattleSkillCfg(skillID)
        local skillViewID = skillConfig.ViewID
        if skillConfig.SpecialView then
            local skinSkillViewID = skillConfig.SpecialView[skinId]
            if skinSkillViewID then
                skillViewID = skinSkillViewID
            end
        end
        skillPhaseArray = self._skillViewParser:ParseSkillView(skillViewID)
    end

    if #skillPhaseArray < 1 then
        Log.fatal("_GetNormalAttackHitTimeAndLength, skill phase array size < 1, skillID:" .. skillID)
        return 0, 0
    end

    local phaseData
    for i = 1, #skillPhaseArray do
        local tmpPhaseData = skillPhaseArray[i]
        local posdirParam = tmpPhaseData:GetPosDirParam()
        local phaseParam = tmpPhaseData:GetPhaseParam()
        local phaseType = phaseParam:GetPhaseType()
        if
            phaseType == SkillViewPhaseType.AttackAnimation or phaseType == SkillViewPhaseType.NormalAttackForAddBlood or
                phaseType == SkillViewPhaseType.NormalAttackOnlyAnimation or
                phaseType == SkillViewPhaseType.NormalAttackWithMove
         then
            phaseData = tmpPhaseData
            break
        end
    end

    if not phaseData then
        Log.fatal(
            "_GetNormalAttackHitTimeAndLength, phaseType ~= SkillViewPhaseType.AttackAnimation, skillID:" .. skillID
        )
        return 0, 0
    end

    ---可能是 SkillPhaseAttackAnimationParam 也可能是   SkillPhaseNormalAttackForAddBloodParam
    local phaseParam = phaseData:GetPhaseParam()
    return phaseParam:GetHitPointDelay(isLastAttackPos) / 1000, phaseParam:GetCastTotalTime(isLastAttackPos) / 1000
end

function NormalSkillCalculator:_MakeTimeFrameTimeMultiple(time)
    if not self._frameTimeMultipleDic[time] then
        self._frameTimeMultipleDic[time] = math.ceil(time / BattleConst.FrameTime) * BattleConst.FrameTime
    end

    return self._frameTimeMultipleDic[time]
end

---@param pos1 Vector2
---@param pos2 Vector2
function NormalSkillCalculator:_IsPosInCrossLine(pos1, pos2)
    return pos1.x - pos2.x == 0 or pos1.y - pos2.y == 0
end

function NormalSkillCalculator:_FindAttackGridData(attackGridDic, beAttackPos)
    for k, v in pairs(attackGridDic) do
        if k == beAttackPos then
            return v
        end
    end

    return nil
end

---这里返回机关表现导致的玩家停顿时间，目前包括地刺在内，都不导致玩家chainmove过程中停顿
function NormalSkillCalculator:_GetTrapDelay(trapEntityList)
    return 0
end

---计算机关效果及延时
---@param trap table<int, Entity> key是机关的Level
---@return number 导致的停顿时间
function NormalSkillCalculator:_CalcTrapTrigger(trapEntityList, targetID)
    local maxLevel = -1
    local minLevel = 100000
    for key, _ in pairs(trapEntityList) do
        if key then
            if key > maxLevel then
                maxLevel = key
            end
            if key < minLevel then
                minLevel = key
            end
        end
    end
    local triggerTraps = {}
    --按机关的层数触发，高层先触发
    for i = maxLevel, minLevel, -1 do
        local trap = trapEntityList[i]
        if trap then
            local eTarget = self._world:GetEntityByID(targetID)
            local taps = self._trapServiceLogic:CalcTrapTriggerSkill(trap, eTarget)
            table.appendArray(triggerTraps, taps)
        end
    end
    return triggerTraps
end

---统计路过的机关
---@param chainPathData table<number, Vector2>
---@return table<number, table<int, Entity>> chain index - { trigger level index - trap entity value}
function NormalSkillCalculator:_GetIndexTrapDic(teamEntity)
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local res = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        if trapServiceLogic:CanSelectByRaceType(e, teamEntity) and trapCmpt:GetTriggerSkillID() then
            local pos = e:GridLocation().Position
            ---2020-07-23韩玉信发现pos类型有时候被修改为了非Vector2类型
            for i = 1, #self._chainPathData do
                if pos == self._chainPathData[i] then
                    if not res[i] then
                        res[i] = {}
                    end
                    res[i][trapCmpt:GetTrapLevel()] = e
                end
            end
        end
    end
    return res
end

function NormalSkillCalculator:_GetPathSuperGridCount()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local mapSuperGridTrapEntities = {}
    local GLOBALtrapGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(GLOBALtrapGroupEntities) do
        ---@type TrapComponent
        local cTrap = e:Trap()
        if cTrap:IsSuperGrid() and not e:HasDeadMark() then
            local posIndex = e:GetGridPosition():Pos2Index()
            mapSuperGridTrapEntities[posIndex] = e
        end
    end

    local t = {}

    local count = 0
    for i = 1, #self._chainPathData do
        local posIndex = self._chainPathData[i]:Pos2Index()
        if mapSuperGridTrapEntities[posIndex] then
            count = count + 1
        end
        t[i] = count
    end

    return t
end
--
function NormalSkillCalculator:_ModifyPathSuperGridCount(pathSuperGridCount,teamEntity)
    --光灵 米洛斯 主动技吸收强化格子后，将数量记录到队伍的buffvalue，增加到
    ---@type BuffComponent
    local buffComp = teamEntity:BuffComponent()
    local addCountVal = buffComp:GetBuffValue("PetAbsorbSuperGridCount")
    if addCountVal then
        local addCount = tonumber(addCountVal)
        if addCount > 0 then
            for index,count in ipairs(pathSuperGridCount) do
                pathSuperGridCount[index] = count + addCount
            end
        end
    end
    return pathSuperGridCount
end
function NormalSkillCalculator:_GetPathPoorGridCount()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local poorGridEntityByPosIndex = {}
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(globalTrapEntities) do
        ---@type TrapComponent
        local cTrap = e:Trap()
        if cTrap:IsPoorGrid() and not e:HasDeadMark() then
            local posIndex = e:GetGridPosition():Pos2Index()
            poorGridEntityByPosIndex[posIndex] = e
        end
    end

    local t = {}

    local count = 0
    for i = 1, #self._chainPathData do
        local posIndex = self._chainPathData[i]:Pos2Index()
        if poorGridEntityByPosIndex[posIndex] then
            count = count + 1
        end
        t[i] = count
    end

    return t
end

---计算提前终止普攻计算的chainPath索引（出口位置不普攻）
function NormalSkillCalculator:_CalcEndIndex()
    if self._chainPathData then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local lastIdx = table.count(self._chainPathData)
        local lastPos = self._chainPathData[lastIdx]
        if utilDataSvc:IsPosExit(lastPos) then
            return lastIdx
        end
    end
    return 99999
end

---在每次攻击以前 检查机关的触发
function NormalSkillCalculator:_OnCheckTriggerTrapBeforeAttack(teamEntity, index)
    local attackTime = self._timeAttackListDic:GetKeyAt(index)

    while self._timeTrapDic:Size() >= self._triggerTrapIndex and
        self._timeTrapDic:GetKeyAt(self._triggerTrapIndex) <= attackTime do
        local jump = self:_OnCheckTriggerTrap(teamEntity)
        if jump then
            break
        end
    end
end

---在全部攻击以后 检查机关的触发
---@param teamEntity Entity
function NormalSkillCalculator:_OnCheckTriggerTrapAfterAttackAll(teamEntity)
    while self._timeTrapDic:Size() >= self._triggerTrapIndex and not teamEntity:HasTeamDeadMark() do
        local jump = self:_OnCheckTriggerTrap(teamEntity)
        if jump then
            break
        end
    end
end

function NormalSkillCalculator:_OnCheckTriggerTrap(teamEntity)
    local chainIndex = self._timeTrapDic:GetAt(self._triggerTrapIndex)
    ---中了停止类的buff以后后续连线内容不再计算
    if self._stopChainIndex and chainIndex >= self._stopChainIndex then
        return true
    end
    if chainIndex >= self._deadChainIndx then
        return true
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if utilData:PlayerIsDead(teamEntity) then
        --玩家死于某一个机关，记录机关位置，之后的机关不再计算
        self._deadChainIndx = chainIndex
        --给玩家挂上DeadFlag，标记玩家在逻辑上死亡
        if teamEntity:HasTeamDeadMark() then
            Log.fatal("Player already dead")
        else
            teamEntity:AddTeamDeadMark(self._chainPathData[chainIndex])
            Log.info("Trap cause player dead at", self._chainPathData[chainIndex])
        end
        return true
    end

    local position = self._chainPathData[chainIndex]
    teamEntity:SetGridPosition(position)
    --playerEntity:GridLocation().Position = self._chainPathData[chainIndex]
    local triggerTraps = self:_CalcTrapTrigger(self._indexTrapDic[chainIndex], teamEntity:GetID())

    self._pathTriggerTrapsDic[chainIndex] = triggerTraps

    if teamEntity:BuffComponent():HasFlag(BuffFlags.Benumb) and not self._stopChainIndex then
        self._stopChainIndex = chainIndex
        self:RebuildChainPath(teamEntity)
    end
    self._triggerTrapIndex = self._triggerTrapIndex + 1

    return false
end

function NormalSkillCalculator:_SetNormalAttackDead()
    --检查所有怪的死亡状态
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        sMonsterShowLogic:AddMonsterDeadMark(e)
    end
end

--获得星灵在这个连线位置攻击的次数
function NormalSkillCalculator:_GetNormalAttackTime(petIndex, pathPosition)
    local attackCount = self:_GetNormalAttackCount(petIndex, pathPosition)

    local attackTime = 0

    if attackCount > 0 then
        attackTime = attackTime + 0.5 + (BattleConst.FrameTime * 3)

        if attackCount > 1 then
            local addTime = 0.333 + (BattleConst.FrameTime * 3)
            attackTime = attackTime + (attackCount - 1) * addTime
        end
    end

    return attackTime
end

--获得星灵在这个连线位置攻击的次数
function NormalSkillCalculator:_GetNormalAttackCount(petIndex, pathPosition)
    local petEntityID = self._petRoundTeam[petIndex]
    local petEntity = self._world:GetEntityByID(petEntityID)

    local attackCount = 0

    local petAttackDataCmpt = petEntity:SkillPetAttackData()
    ---@type SkillPathNormalAttackData
    local normalAttackData = petAttackDataCmpt:GetNormalAttackData()
    ---@type SkillPathPointNormalAttackData
    local pathPointAttackData = normalAttackData:GetPathPointAttackData(pathPosition)
    if pathPointAttackData ~= nil then
        local orderGridArray = pathPointAttackData:GetPetOrderGridArray(petEntity, pathPosition)
        if (petEntity:BuffComponent():GetBuffValue("ForcePetNormalAttackAfterMove")) then
            local chainPath = petEntity:Pet():GetOwnerTeamEntity():LogicChainPath():GetLogicChainPath()
            local beginGrid = chainPath[1]
            if beginGrid ~= pathPosition then
                orderGridArray = {}
            else
                orderGridArray = {pathPosition}
            end
        end

        attackCount = attackCount + #orderGridArray
    end

    return attackCount
end

---检查 连线中普攻的数量
---没有普攻  或者  所有星灵攻击次数一样
function NormalSkillCalculator:_OnGetPathAttackList(teamEntity, chain_path)
    local petsAttactList = {}

    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petRoundTeam = logicTeamCmpt:GetPetRoundTeam()

    for i, petEntityID in ipairs(petRoundTeam) do
        local petEntity = self._world:GetEntityByID(petEntityID)

        local attackCount = 0

        for chainIndex, pathPosition in ipairs(chain_path) do
            local petAttackDataCmpt = petEntity:SkillPetAttackData()
            ---@type SkillPathNormalAttackData
            local normalAttackData = petAttackDataCmpt:GetNormalAttackData()

            ---@type SkillPathPointNormalAttackData
            local pathPointAttackData = normalAttackData:GetPathPointAttackData(pathPosition)
            if pathPointAttackData ~= nil then
                ---判断在一个位置能攻击的格子坐标列表
                local orderGridArray = pathPointAttackData:GetPetOrderGridArray(petEntity, pathPosition)
                if (petEntity:BuffComponent():GetBuffValue("ForcePetNormalAttackAfterMove")) then
                    if chainIndex ~= 1 then
                        orderGridArray = {pathPosition}
                    else
                        orderGridArray = {}
                    end
                end

                attackCount = attackCount + #orderGridArray
            end
        end

        --星灵在连线中攻击的次数
        if attackCount > 0 then
            table.insert(petsAttactList, attackCount)
        end
    end

    return petsAttactList
end

---连线中 需要等待的时间
---检查 连线中普攻的数量
---没有普攻  或者  所有星灵攻击次数一样
function NormalSkillCalculator:_OnGetPathMoveStartWaitTime(petsAttactList)
    -- local pathAttacKCount = 0
    local moveWaitTime = 0

    --t1
    if #petsAttactList == 0 then
        --没有攻击次数   0.33333
        moveWaitTime = 10 * BattleConst.FrameTime
    else
        -- end
        --有攻击次数
        local hasEightDirectionAttack = false
        local petAttackCount = 0
        for i, attackCount in ipairs(petsAttactList) do
            if i ~= 1 and petAttackCount ~= attackCount then
                hasEightDirectionAttack = true
                break
            end
            petAttackCount = attackCount
        end

        --没有八方向的普攻
        -- if not hasEightDirectionAttack then
        moveWaitTime = (petAttackCount - 1) * 0.333 + 0.5
        if moveWaitTime > 1 then
            moveWaitTime = 1
        end
    end

    return moveWaitTime
end

function NormalSkillCalculator:GetPlayNormalSkillSequence()
    return self._playNormalSkillSequence
end

function NormalSkillCalculator:GetTriggerTraps()
    return self._pathTriggerTrapsDic
end

function NormalSkillCalculator:GetPathNormalSkillWaitTimes()
    return self._pathNormalSkillWaitTimeDic
end

function NormalSkillCalculator:GetPathMoveStartWaitTime()
    return self._pathMoveStartWaitTime
end

function NormalSkillCalculator:CanAttackByPos(attackPos)
    if self._stopChainIndex then
        for i, v in ipairs(self._chainPathData) do
            if v.x == attackPos.x and v.y == attackPos.y and i ~= self._stopChainIndex then
                return true
            end
        end
        return false
    else
        return true
    end
end

function NormalSkillCalculator:CanMoveToPos(movePos)
    if self._stopChainIndex then
        for i, v in ipairs(self._chainPathData) do
            if v.x == movePos.x and v.y == movePos.y and i <= self._stopChainIndex then
                return true
            end
        end
        return false
    else
        return true
    end
end

function NormalSkillCalculator:RebuildChainPath(teamEntity)
    self._chainPathData = table.sub(self._chainPathData, 1, self._stopChainIndex)

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local logicPath = logicChainPathCmpt:GetLogicChainPath()
    local cutChainPath = {}
    for index, pos in ipairs(logicPath) do
        if index > self._stopChainIndex then
            cutChainPath[index] = pos
        end
    end
    logicPath = table.sub(logicPath, 1, self._stopChainIndex)
    logicChainPathCmpt:SetLogicChainPath(logicPath, logicChainPathCmpt:GetLogicPieceType())
    logicChainPathCmpt:SetCutChainPath(cutChainPath)
    self._skillLogicService:UpdateTeamGridLocationByChainPath(teamEntity, logicPath)
end

---将普攻的逻辑顺序保存给表现，表现做普攻爆点等待
function NormalSkillCalculator:_OnSavePlayNormalSkillSequence(
    casterEntity,
    normalSkillIndex,
    originalSkillID,
    newAttackSkillId,
    normalAttackData,
    originaBeAttackPos,
    attackGridData)
    --  将普攻逻辑顺序存起来 表现的时候要按照逻辑顺序播放
    local hitTime, length =
        self:_GetNormalAttackHitTimeAndLength(originalSkillID, normalAttackData:GetisLastAttackPos(), casterEntity)

    local playNormalSkill = {}
    playNormalSkill.order = normalSkillIndex
    playNormalSkill.skillID = newAttackSkillId
    playNormalSkill.attackPos = normalAttackData:GetPathPosition()
    playNormalSkill.beAttackPos = originaBeAttackPos

    playNormalSkill.attackGridData = attackGridData
    playNormalSkill.hitPointDelay = hitTime * 1000
    playNormalSkill.playStartTime = 0
    table.insert(self._playNormalSkillSequence, playNormalSkill)
    normalSkillIndex = normalSkillIndex + 1
end

---判断是否有普攻双击的buff
function NormalSkillCalculator:_OnCheckNormalAttackDouble(casterEntity,normalAttackData)
    ---@type BuffComponent
    local buffComponent = casterEntity:BuffComponent()
    local normalAttackDoubleCountKey = "NormalAttackDoubleCount"
    local normalAttackDoubleCount = buffComponent:GetBuffValue(normalAttackDoubleCountKey)
    if normalAttackDoubleCount and normalAttackDoubleCount > 0 then
        local newCount = normalAttackDoubleCount - 1
        buffComponent:SetBuffValue(normalAttackDoubleCountKey, newCount)
        return true
    end
    --房间词条“狙手的普攻概率双击,每连线一格获得3%概率”
    local normalAttackDoubleBaseRateKey = "NormalAttackDoubleBaseRate"
    local normalAttackDoubleEachMoveIncreaseRateKey = "NormalAttackDoubleEachMoveIncreaseRate"
    local normalAttackDoubleBaseRate = buffComponent:GetBuffValue(normalAttackDoubleBaseRateKey)
    local normalAttackDoubleEachMoveIncreaseRate = buffComponent:GetBuffValue(normalAttackDoubleEachMoveIncreaseRateKey)
    local chainIndex = normalAttackData:GetChainIndex()
    if normalAttackDoubleBaseRate then
        local doubleRate = normalAttackDoubleBaseRate
        if normalAttackDoubleEachMoveIncreaseRate and (normalAttackDoubleEachMoveIncreaseRate ~= 0) then
            doubleRate = doubleRate + (chainIndex - 1) * normalAttackDoubleEachMoveIncreaseRate
        end
        if doubleRate > 1 then
            doubleRate = 1
        end
        if doubleRate > 0 then--0.5是50%
            local checkParam = doubleRate * 1000 --*1000为了提高一个精度
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            local nRandNum = randomSvc:LogicRand(1, 1000)
            if nRandNum <= checkParam then
                return true
            end
        end
    end
    return false
end

---如果有普攻双击的buff，再次计算一个普攻
function NormalSkillCalculator:_ForNormalAttackDouble(
    teamEntity,
    casterEntity,
    normalAttackData,
    originalAttackPosList,
    originalTargetIdList,
    originaBeAttackPos,
    originalSkillID)
    --这种做法 如果2个普攻ID不一样，会让第二个是一个新的，表现那边默认取不到
    -- ---@type NormalAttackData
    -- normalAttackData = attackList[k]

    --第二次计算是否修改普攻前，把前面用到的AttackGridData里的普攻ID还原成初始ID
    local attackGridData = normalAttackData:GetAttackGridData()
    --樱龙使需要设置这个把第二次普攻设置回去，但是加血普攻设置了这个第二下就变成了伤害普攻
    -- attackGridData:SetAttackGridSkillID(originalSkillID)
    attackGridData:SetAttackPosList(originalAttackPosList)
    attackGridData:SetTargetIdList(originalTargetIdList)

    --普攻双击，第二次计算范围，通知也要有两次
    local attackPos = normalAttackData:GetPathPosition()
    self._world:GetService("Trigger"):Notify(
        NTNormalAttackChangeBefore:New(casterEntity, attackPos, originaBeAttackPos)
    )

    local newAttackSkillId = originalSkillID
    local directReplace = 0 --直接替换普攻，而不是计算普攻扩展，默认0计算扩展
    --重新计算attackGridData buff修改技能ID 重新计算范围 目标
    attackGridData, newAttackSkillId, directReplace = self:_CalcNormalSkillExtraScope(normalAttackData)

    local isNormalAttackDouble = true

    --计算伤害
    self:_CalcNormalSkillEffect(
        teamEntity,
        normalAttackData,
        attackGridData,
        originalSkillID,
        originaBeAttackPos,
        directReplace,
        isNormalAttackDouble
    )
end
