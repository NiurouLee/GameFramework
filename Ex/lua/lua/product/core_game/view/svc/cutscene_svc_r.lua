--[[------------------------------------------------------------------------------------------
    CutsceneServiceRender: 3D剧情服务
]] --------------------------------------------------------------------------------------------

_class("CutsceneServiceRender", BaseService)
---@class CutsceneServiceRender:BaseService
CutsceneServiceRender = CutsceneServiceRender

function CutsceneServiceRender:Constructor(world)
    self._originalSkyBoxColor = nil
end

function CutsceneServiceRender:SetOriginalSkyBoxColor(color)
    self._originalSkyBoxColor = color
end
function CutsceneServiceRender:GetOriginalSkyBoxColor()
    return self._originalSkyBoxColor
end

function CutsceneServiceRender:ResetSkyBoxColor()
    if self._originalSkyBoxColor then
        UnityEngine.RenderSettings.skybox:SetColor("_Tint", self._originalSkyBoxColor)
    end
end

---播放实时剧情
function CutsceneServiceRender:PlayRealTimeCutscene(TT, type)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type LevelConfigData
    local levelConfigData = cfgService:GetLevelConfigData()
    ---@type table<number,LevelCutsceneParam>
    local cutsceneParam = levelConfigData:GetLevelCutsceneParam()

    for k, v in pairs(cutsceneParam) do
        if v:GetType() == type then
            ---取出对应的ID后，解析出剧情的资源，并启动播放
            ---@type CutsceneDirector
            local cutsceneDirector = CutsceneDirector:New(self._world)
            cutsceneDirector:DoPlayCutscenePhase(TT, v:GetID())
            Log.debug("Play Cutscene ID ", v:GetID(), "Type:", type)
        end
    end
end

---回放剧情
function CutsceneServiceRender:ReviewCutscene(TT, levelID)
    local levelRawData = Cfg.cfg_level[levelID]
    if not levelRawData or not levelRawData.Cutscene then
        return
    end

    local cutsceneID = -1
    for _, cutsceneRawData in pairs(levelRawData.Cutscene) do
        cutsceneID = cutsceneRawData.CutsceneID
    end

    ---@type CutsceneDirector
    local cutsceneDirector = CutsceneDirector:New(self._world)
    cutsceneDirector:DoPlayCutscenePhase(TT, cutsceneID)
end

function CutsceneServiceRender:GetCutsceneRenderGridPosition(entity)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local targetGridPos
    -- if not needOffSet then
    local monster_body_area_cmpt = entity:BodyArea()
    local monster_body_area = {}
    if monster_body_area_cmpt then
        monster_body_area = monster_body_area_cmpt:GetArea()
    end

    ---多格怪
    if #monster_body_area > 1 then
        local renderPosition = entity:Location().Position
        targetGridPos = boardServiceRender:BoardRenderPos2FloatGridPos_New(renderPosition)
        -- local offset = entity:GridLocation().Offset
        local offset = Vector2(0, 0)
        if #monster_body_area == 4 then
            offset = Vector2(0.5, 0.5)
        elseif #monster_body_area == 9 then
            offset = Vector2(1, 1)
        end

        targetGridPos = targetGridPos - offset
        targetGridPos = Vector2(math.floor(targetGridPos.x), math.floor(targetGridPos.y))
    else
        local renderPosition = entity:Location().Position
        targetGridPos = boardServiceRender:BoardRenderPos2GridPos(renderPosition)
    end
    -- else
    --     local renderPosition = entity:Location().Position
    --     targetGridPos = self:BoardRenderPos2FloatGridPos_New(renderPosition)
    -- end
    return targetGridPos
end

function CutsceneServiceRender:PlayCutsceneCreateMonster(TT, monsterID, monsterClassID, name, pos, dir, turnToPlayer)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local cutsceneMonsterEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.CutsceneMonster)

    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterResPath
    local areaArray
    if monsterClassID then
        local monsterClassConfigData = Cfg.cfg_monster_class[monsterClassID]
        monsterResPath = monsterClassConfigData.ResPath
        areaArray = monsterConfigData:ExplainMonsterArea(monsterClassConfigData.Area)
    end
    if monsterID then
        monsterResPath = monsterConfigData:GetMonsterResPath(monsterID)
        areaArray = monsterConfigData:GetMonsterArea(monsterID)
    end

    cutsceneMonsterEntity:ReplaceAsset(NativeUnityPrefabAsset:New(monsterResPath, true))
    cutsceneMonsterEntity:ReplaceBodyArea(areaArray) --重置格子占位

    --如果目标坐标上有队长，或其他被随机到该位置的怪物，则随机一个坐标
    --在剧情中阻挡的坐标集合，已经创建的怪物和队长
    local blocks = self:_GetCutsceneBlockPos()

    local playerEntity = self._world:Player():GetLocalTeamEntity()
    local playerPos = self:GetCutsceneRenderGridPosition(playerEntity)

    --优先从棋盘内选点召唤，以玩家周围算方形环范围
    local listReturn = self:_CalcScopeSquareRing(playerPos, {Vector2(0, 0)}, 9, 2)

    --需要计算出可以召唤出怪物的坐标
    local gridPos = self:_GetCutsceneCreateMonsterPos(pos, areaArray, blocks, listReturn)

    --表现偏移
    local monster_body_area_cmpt = cutsceneMonsterEntity:BodyArea()
    local monster_body_area = {}
    if monster_body_area_cmpt then
        monster_body_area = monster_body_area_cmpt:GetArea()
    end
    local offset = Vector2(0, 0)
    if #monster_body_area == 4 then
        offset = Vector2(0.5, 0.5)
    elseif #monster_body_area == 9 then
        offset = Vector2(1, 1)
    end
    gridPos = gridPos + offset

    --默认朝向队长的位置
    if turnToPlayer == 1 then
        dir = playerPos - gridPos
    end
    cutsceneMonsterEntity:SetLocation(gridPos, dir)

    cutsceneMonsterEntity:AddCutsceneMonster()
    ---@type CutsceneMonsterComponent
    local cutsceneMonsterComponent = cutsceneMonsterEntity:CutsceneMonster()
    cutsceneMonsterComponent:SetCutsceneMonsterName(name)
end

--获得剧情中的阻挡坐标
function CutsceneServiceRender:_GetCutsceneBlockPos()
    local blocks = {}

    --格式是 {[1],[2]}
    local gapTiles = BattleConst.GapTiles
    --改成V2
    local gapTilesPosList = {}
    for i, p in ipairs(gapTiles) do
        local gridPos = Vector2(p[1], p[2])
        table.insert(blocks, gridPos)
    end

    for _, entity in ipairs(self:GetCutsceneMonsterGroupEntity()) do
        local bodyArea = entity:BodyArea():GetArea()
        local gridPos = self:GetCutsceneRenderGridPosition(entity)
        for _, area in ipairs(bodyArea) do
            local bodyPos = area + gridPos
            table.insert(blocks, bodyPos)
        end
    end
    local playerEntity = self._world:Player():GetLocalTeamEntity()
    local playerPos = self:GetCutsceneRenderGridPosition(playerEntity)
    table.insert(blocks, playerPos)

    return blocks
end

function CutsceneServiceRender:GetCutsceneMonsterGroupEntity()
    local entityList = {}
    local group = self._world:GetGroup(self._world.BW_WEMatchers.CutsceneMonster)
    for _, entity in ipairs(group:GetEntities()) do
        ---@type CutsceneMonsterComponent
        local cutsceneMonsterComponent = entity:CutsceneMonster()
        if not cutsceneMonsterComponent:GetHadPlayDead() then
            table.insert(entityList, entity)
        end
    end
    return entityList
end

---计算一个可以召唤怪物的坐标，如果目标坐标被阻挡，则优先在棋盘内随机一个
---@param pos Vector2 怪物召唤的坐标
---@param bodyArea Vector2[] 怪物身形
---@param blocks Vector2[] 棋盘上阻挡召唤的坐标数组
---@param attackRange Vector2[] 棋盘上可以召唤的范围
function CutsceneServiceRender:_GetCutsceneCreateMonsterPos(pos, bodyArea, blocks, attackRange)
    local canCutsceneCreate = true

    for _, area in ipairs(bodyArea) do
        local bodyPos = Vector2(area.x + pos.x, area.y + pos.y)
        if table.icontains(blocks, bodyPos) then
            canCutsceneCreate = false
        end
    end

    if canCutsceneCreate then
        return pos
    else
        table.insert(blocks, pos)
        table.removev(attackRange, pos)
        local randomIndex = Mathf.Random(1, table.count(attackRange))
        local posRandom = attackRange[randomIndex]

        local posNew = self:_GetCutsceneCreateMonsterPos(posRandom, bodyArea, blocks, attackRange)
        return posNew
    end
end

---剧情怪物死亡表现
function CutsceneServiceRender:PlayCutsceneMonsterDead(TT, monsterEntity, monsterDeadType)
    ---@type CutsceneMonsterComponent
    local cutsceneMonsterComponent = monsterEntity:CutsceneMonster()
    cutsceneMonsterComponent:SetHadPlayDead(true)

    --默认死亡动画名字
    local deadTriggerParam = "Death"
    monsterEntity:SetAnimatorControllerTriggers({deadTriggerParam})

    if monsterDeadType and monsterDeadType ~= DeathShowType.None then
        local deathEffectID = nil
        if monsterDeadType == DeathShowType.DissolveLight then
            monsterEntity:NewPlayDeadLight()
            deathEffectID = BattleConst.MonsterDeadEffectLight
        elseif monsterDeadType == DeathShowType.DissolveDark then
            monsterEntity:NewPlayDeadDark()
            deathEffectID = BattleConst.MonsterDeadEffectDark
        else
            deathEffectID = monsterDeadType
        end

        if deathEffectID then
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            if type(deathEffectID) == "number" then
                deathEffectID = {deathEffectID}
            end
            for i, effID in ipairs(deathEffectID) do
                local effectEntity = effectService:CreateEffect(effID, monsterEntity)
            end
        end
    end
end

--region 范围计算

function CutsceneServiceRender:_CalcScopeSquareRing(casterPos, bodyArea, ringCount, ringCountRemove)
    local listTotalData = ComputeScopeRange.ComputeRange_SquareRing(casterPos, #bodyArea, ringCount)

    local listTotalDataRemove = {}
    if ringCountRemove and ringCountRemove > 0 then
        listTotalDataRemove = ComputeScopeRange.ComputeRange_SquareRing(casterPos, #bodyArea, ringCountRemove)
    end

    local listAttackData = {}
    for key, value in ipairs(listTotalData) do
        local isValidGrid = self:isValidGrid(value)
        if isValidGrid and not table.intable(listTotalDataRemove, value) then
            listAttackData[#listAttackData + 1] = value
        end
    end

    return listAttackData
end

--region 范围计算

--region 移动

---剧情怪物向人移动
function CutsceneServiceRender:PlayCutsceneMonsterMoveToPlayer(TT, monsterName, moveGridCount, moveSpeed)
    local waitTaskList = {}

    local moveMonsterEntityList = {}
    --找出所有需要移动的剧情怪物
    for _, entity in ipairs(self:GetCutsceneMonsterGroupEntity()) do
        ---@type CutsceneMonsterComponent
        local cutsceneMonsterComponent = entity:CutsceneMonster()
        if cutsceneMonsterComponent:GetCutsceneMonsterName() == monsterName then
            table.insert(moveMonsterEntityList, entity)
        end
    end

    --排序，距离玩家近的先移动

    --每走一步算一次
    for i = 1, moveGridCount do
        --计算移动
        for _, entity in ipairs(moveMonsterEntityList) do
            self.m_entityOwn = entity

            ---计算可移动到的目标点
            local posWalk = self:_CalcMovePos(entity)

            ---存在可移动的点
            if posWalk ~= nil then
                local posSelf = self:GetCutsceneRenderGridPosition(entity)

                ---@type CutsceneMonsterComponent
                local cutsceneMonsterComponent = entity:CutsceneMonster()
                ---保存上一次移动点
                cutsceneMonsterComponent:SetLastMovePos(posSelf)

                local taskID =
                    GameGlobal.TaskManager():CoreGameStartTask(self._DoWalk, self, entity, {posWalk}, moveSpeed)
                if taskID > 0 then
                    waitTaskList[#waitTaskList + 1] = taskID
                end
            end
        end

        ---等待所有流程结束
        if #waitTaskList > 0 then
            while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskList) do
                YIELD(TT)
            end
        end
    end
end

---播放怪物行走
---@param monsterEntity Entity 怪物Entity
function CutsceneServiceRender:_DoWalk(TT, monsterEntity, walkResultList, moveSpeed)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---走格子
    local hasWalkPoint = false
    if #walkResultList > 0 then
        hasWalkPoint = true
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, true)
    end

    for _, resultPos in ipairs(walkResultList) do
        ---取当前的渲染坐标
        local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)

        ---resultPos是坐标中心  还不是移动表现的坐标
        local walkPos = resultPos
        ---@type BodyAreaComponent
        local bodyAreaCmpt = monsterEntity:BodyArea()
        local areaCount = bodyAreaCmpt:GetAreaCount()
        if areaCount == 4 then
            walkPos = Vector2(walkPos.x + 0.5, walkPos.y + 0.5)

        -- ---取左下位置坐标
        -- local leftDownPos = Vector2(curPos.x - 0.5, curPos.y - 0.5)
        -- walkDir = walkPos - leftDownPos
        end
        local walkDir = walkPos - curPos

        monsterEntity:AddGridMove(moveSpeed, walkPos, curPos)
        monsterEntity:SetDirection(walkDir)

        Log.debug("[PlayAI]Entity:", monsterEntity:GetID(), ",CurPos:", curPos, " WalkTo,", walkPos)
        while monsterEntity:HasGridMove() do
            YIELD(TT)
        end
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, false)
    end
end

---@param targetEntity Entity
function CutsceneServiceRender:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({Move = isMove})
    end
end

---计算本次要移动到的目标位置
---@param entityWork Entity
function CutsceneServiceRender:_CalcMovePos(entityWork)
    local posSelf = self:GetCutsceneRenderGridPosition(entityWork)

    ---找到距离自己最远的移动目标格子
    local posTarget = self:FindNewTargetPos(entityWork)
    ---已经到目标点了
    if posSelf == posTarget then
        return nil
    end

    local nWalkTotal = 1
    local posWalkList = self:ComputeWalkRange(posSelf, nWalkTotal, true)
    local posWalk = self:FindNewWalkPos(posWalkList, posTarget, posSelf)
    ---最近可移动点是自己的位置，不需要移动
    if posWalk and posWalk == posSelf then
        -- self:PrintLog("不需要移动 ", self:_MakePosString(posSelf), ">===>", self:_MakePosString(posWalk))
        return nil
    end

    return posWalk
end

function CutsceneServiceRender:FindNewTargetPos(entityWork)
    local selfPos = self:GetCutsceneRenderGridPosition(entityWork)
    local selfBodyArea = entityWork:BodyArea():GetArea()

    local playerEntity = self._world:Player():GetLocalTeamEntity()
    local playerPos = self:GetCutsceneRenderGridPosition(playerEntity)

    --在目标的周围查找
    local workCenter = playerPos
    --多格怪要求把目标坐标移动到多格的左下角：posCenter被作为右上角坐标计算
    -- if 4 == #selfBodyArea then
    --     workCenter = workCenter + Vector2(-1, -1)
    -- elseif 9 == #selfBodyArea then
    --     workCenter = workCenter + Vector2(-2, -2)
    -- end

    -- ---数据去重
    -- local skillRange = scopeResult:GetAttackRange()
    -- local listReturn = {}
    -- for i = 1, #skillRange do
    --     local posWork = skillRange[i]
    --     if false == table.icontains(listReturn, posWork) then
    --         table.insert(listReturn, posWork)
    --     end
    -- end

    local listReturn = self:_CalcScopeSquareRing(workCenter, {Vector2(0, 0)}, 1, 0)

    self.m_nextPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_nextPosList:AllowDuplicate()
    self.m_nextPosList:Clear()

    for i = 1, #listReturn do
        local posWork = listReturn[i]
        if self:IsPosAccessible(posWork) then
            AINewNode.InsertSortedArray(self.m_nextPosList, selfPos, posWork, i)
        end
    end

    --范围中最近
    local posReturn = self:FindPosValid(self.m_nextPosList, playerPos)

    return posReturn
end

---@param planPosList SortedArray   候选位置列表内部元素是 ---@type AiSortByDistance
---@param defPos Vector2    找不到的情况下，返回的默认值：一般是entity的当前位置
function CutsceneServiceRender:FindPosValid(planPosList, defPos)
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

---计算移动范围：所有怪物的移动轨迹都是十字（ 从centerPos 出发nWalkStep步以内 ）
---@return ComputeWalkPos[]
function CutsceneServiceRender:ComputeWalkRange(centerPos, nWalkStep, bFilter)
    bFilter = bFilter or false
    ---@type Callback
    local cbFilter = nil
    if bFilter then
        cbFilter = Callback:New(1, self.IsPosAccessible, self)
    end
    return ComputeScopeRange.ComputeRange_WalkMathPos(centerPos, 1, nWalkStep, cbFilter)
end

---判断entity是否可以走到pos位置
---@return boolean
---@param pos Vector2
function CutsceneServiceRender:IsPosAccessible(pos)
    local coverList = self:GetCoverAreaList(pos)

    local wordPos = self:GetCutsceneRenderGridPosition(self.m_entityOwn)

    local coverListSelf = self:GetCoverAreaList(wordPos)
    local blocks = self:_GetCutsceneBlockPos()
    for i = 1, #coverList do
        local posWork = coverList[i]
        if not table.icontains(coverListSelf, posWork) then ---确保不被自己堵上
            if table.icontains(blocks, posWork) then
                return false
            end
        end
    end
    return true
end

---获取entity的占地坐标
function CutsceneServiceRender:GetCoverAreaList(pos)
    local posList = {}
    if self.m_entityOwn then
        posList = self.m_entityOwn:GetCoverAreaList(pos)
    end
    return posList
end

---查找战术行动坐标：返回距离战略目标最近的点，找不到会返回自己的位置（不移动）
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
function CutsceneServiceRender:FindNewWalkPos(walkRange, posCenter, posDef)
    return self:FindPosByNearCenter(walkRange, posCenter, posDef, 1)
end

---查找距离圆心最近的位置
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
---@param posDef Vector2 默认的返回值
function CutsceneServiceRender:FindPosByNearCenter(listPlanPos, posCenter, posDef, nCheckStep)
    if nil == listPlanPos or table.count(listPlanPos) <= 0 then
        return posDef
    end
    local listWalk = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    listWalk:AllowDuplicate()

    ---@type CutsceneMonsterComponent
    local cutsceneMonsterComponent = self.m_entityOwn:CutsceneMonster()
    local lastMovePos = cutsceneMonsterComponent:GetLastMovePos()

    for i = 1, #listPlanPos do
        ---@type ComputeWalkPos
        local posData = listPlanPos[i]
        local posWalk = posData:GetPos()
        if posWalk ~= posDef and (nil == nCheckStep or nCheckStep == posData:GetStep()) then
            if posWalk ~= lastMovePos then
                AINewNode.InsertSortedArray(listWalk, posCenter, posWalk, i)
            else
                --Log.fatal("this pos is last move pos:",posWalk)
            end
        end
    end
    return self:FindPosValid(listWalk, posDef)
end

--endregion 移动

function CutsceneServiceRender:PlayCutsceneHitbackPlayer(TT, dis, dir, speed)
    local playerEntity = self._world:Player():GetLocalTeamEntity()
    local playerPos = self:GetCutsceneRenderGridPosition(playerEntity)

    --在剧情中阻挡的坐标集合，已经创建的怪物和队长
    local blocks = self:_GetCutsceneBlockPos()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    --格式是 {[1],[2]}
    local gapTiles = BattleConst.GapTiles
    --改成V2
    local gapTilesPosList = {}
    for i, p in ipairs(gapTiles) do
        local gridPos = Vector2(p[1], p[2])
        table.insert(gapTilesPosList, gridPos)
    end

    local targetPos = playerPos
    for i = 1, dis do
        local hitBackPos = playerPos + Vector2(dir.x * i, dir.y * i)

        --击退坐标被阻挡  或者超出棋盘
        if
            table.icontains(blocks, hitBackPos) or not self:isValidGrid(hitBackPos) or
                table.icontains(gapTilesPosList, hitBackPos)
         then
            break
        end

        targetPos = hitBackPos
    end

    playerEntity:AddHitback(playerPos, speed, targetPos, dir)

    while playerEntity:HasHitback() and not playerEntity:Hitback():IsHitbackEnd() do
        YIELD(TT)
    end
end

function CutsceneServiceRender:isValidGrid(pos)
    local isValid = pos.x >= 1 and pos.y >= 1 and pos.x <= BattleConst.DefaultMaxX and pos.y <= BattleConst.DefaultMaxY
    return isValid
end
