--[[------------------
    技能指令表现的公共服务对象
--]] ------------------

_class("PlaySkillInstructionService", Object)
---@class PlaySkillInstructionService:Object
PlaySkillInstructionService = PlaySkillInstructionService

function PlaySkillInstructionService:Constructor(world)
    ---@type MainWorld
    self._world = world
    --region 召唤表现执行函数
    self.m_listSummonFunction = {}
    self.m_listSummonFunction[SkillEffectEnum_SummonType.Monster] = self._SummonShow_Monster
    self.m_listSummonFunction[SkillEffectEnum_SummonType.Trap] = self._SummonShow_Trap
    --endregion
end

-- ================================= 瞬移相关方法 ======================================

--- @class RoleShowType
local RoleShowType = {
    TeleportHide = 3, ---瞬移:消失
    TeleportMove = 5, ---瞬移:选定位置
    TeleportShow = 6, ---瞬移:显示
    BuffNotify = 9, ---瞬移:通知BUFF
    Teleport2Sky = 10, ---表现上天
    TeleportHide2Sky = 11, ---瞬移:消失上天，不隐藏模型
    TeleportMoveNoTurn = 12, ---瞬移：显示，不设置方向
    TeleportHideTrap = 13 ---瞬移，隐藏顺以后位置上的机关
}
_enum("RoleShowType", RoleShowType)

---@param targetEntity Entity
---@param teleportEffectResult SkillEffectResult_Teleport
function PlaySkillInstructionService:Teleport(TT, targetEntity, showType, onlySelf, teleportEffectResult)
    if targetEntity:HasTeam() then
        targetEntity = targetEntity:GetTeamLeaderPetEntity()
    end
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    if RoleShowType.TeleportHide == showType then --瞬移:消失
        local oldPos = teleportEffectResult:GetPosOld()
        local oldColor = teleportEffectResult:GetColorOld()
        self:_RoleShow(targetEntity, false, false)
        ---脚下格子
        self:_RebuildGrid(TT, targetEntity, oldColor, 1, oldPos, SkillEffectType.Teleport)
        trapServiceRender:ShowHideTrapAtPos(oldPos, true)
    elseif RoleShowType.TeleportHide2Sky == showType then --瞬移:消失上天，不隐藏模型
        local oldPos = teleportEffectResult:GetPosOld()
        local oldColor = teleportEffectResult:GetColorOld()
        self:_RoleShow(targetEntity, false, false, true)
        ---脚下格子
        self:_RebuildGrid(TT, targetEntity, oldColor, 1, oldPos, SkillEffectType.Teleport)
        trapServiceRender:ShowHideTrapAtPos(oldPos, true)
    elseif RoleShowType.TeleportMove == showType then --瞬移:选定位置
        self:_TeleportTargetPos(TT, targetEntity, teleportEffectResult, onlySelf)
    elseif RoleShowType.TeleportMoveNoTurn == showType then --瞬移:选定位置,不旋转方向
        self:_TeleportTargetPos(TT, targetEntity, teleportEffectResult, onlySelf, true)
    elseif RoleShowType.Teleport2Sky == showType then --瞬移:表现上天
        self:_TeleportTarget2Sky(TT, targetEntity, teleportEffectResult, onlySelf)
        local oldPos = teleportEffectResult:GetPosOld()
        trapServiceRender:ShowHideTrapAtPos(oldPos, true)
    elseif RoleShowType.TeleportShow == showType then ---瞬移:显示
        local newColor = teleportEffectResult:GetColorNew()
        local newPos = teleportEffectResult:GetPosNew()
        self:_RebuildGrid(TT, targetEntity, newColor, 0, newPos, SkillEffectType.Teleport)
        self:_RoleShow(targetEntity, true, true)
        trapServiceRender:ShowHideTrapAtPos(newPos, false)
        ---怪物的瞬移立即播放触发的机关效果
        if targetEntity:HasMonsterID() then
            local trapIDList = teleportEffectResult:GetTriggerTrapIDList()
            local trapEntityList = {}
            for _, v in ipairs(trapIDList) do
                local trapEntity = self._world:GetEntityByID(v)
                trapEntityList[#trapEntityList + 1] = trapEntity
            end
            self:PlayTrapTrigger(TT, targetEntity, trapEntityList)
        end
        if targetEntity:HasPetPstID() or targetEntity:HasTeam() then
            ---@type PieceServiceRender
            local pieceService = self._world:GetService("Piece")
            pieceService:RemovePrismAt(newPos)
        end
    elseif RoleShowType.BuffNotify == showType then --瞬移:通知BUFF
        local oldPos = teleportEffectResult:GetPosOld()
        local newPos = teleportEffectResult:GetPosNew()
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTTeleport:New(targetEntity, oldPos, newPos))
    elseif RoleShowType.TeleportHideTrap == showType then
        local trapID = teleportEffectResult:GetNeedDelTrapEntityID()
        if trapID ~= 0 then
            local trap = self._world:GetEntityByID(trapID)
            if trap then
                trapServiceRender:PlayTrapDieSkill(TT, {trap}, 1)
            end
        end
    end
end

---@param entityWork Entity
function PlaySkillInstructionService:_RoleShow(entityWork, bShowRole, bShowBloodSlider, noActiveModel)
    if not noActiveModel then
        entityWork:SetViewVisible(bShowRole)
    else
        entityWork:SetLocationHeight(1000)
    end
    local slider_entity_id = 0
    if entityWork:HasPetPstID() then
        ---@type Entity
        local captainEntity = entityWork:Pet():GetOwnerTeamEntity()
        slider_entity_id = captainEntity:HP():GetHPSliderEntityID()
    else
        slider_entity_id = entityWork:HP():GetHPSliderEntityID()
    end
    local slider_entity = self._world:GetEntityByID(slider_entity_id)
    if slider_entity then
        slider_entity:SetViewVisible(bShowBloodSlider)
    end
end

function PlaySkillInstructionService:_SendNTGridConvertRender(TT, pos, pieceType, effectType)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    return playBuffSvc:_SendNTGridConvertRender(TT, pos, pieceType, effectType)
end

---@param entityWork Entity
function PlaySkillInstructionService:_RebuildGrid(TT, entityWork, color, bLight, rebuildPos, effectType)
    local targetPos = entityWork:GetGridPosition()
    if entityWork:HasPetPstID() then ---宝宝
        ---@type BoardServiceRender
        local boardService = self._world:GetService("BoardRender")
        boardService:ReCreateGridEntity(color, rebuildPos)
        if bLight and bLight > 0 then
            self:_SendNTGridConvertRender(TT, rebuildPos, color, effectType)
        end
    else ---小怪
        ---@type PieceServiceRender
        local pieceService = self._world:GetService("Piece")
        ---@type RenderEntityService
        local renderEntityService = self._world:GetService("RenderEntity")
        if bLight and bLight > 0 then
            renderEntityService:DestroyMonsterAreaOutLineEntity(entityWork)
        else
            renderEntityService:DestroyMonsterAreaOutLineEntity(entityWork)
            renderEntityService:CreateMonsterAreaOutlineEntity(entityWork)
        end

        local utilDataService = self._world:GetService("UtilData")
        local bodyArea = entityWork:BodyArea():GetArea()
        for i = 1, #bodyArea do
            local posWork = targetPos + bodyArea[i]
            if utilDataService:IsValidPiecePos(posWork) then
                if bLight and bLight > 0 then
                    pieceService:SetPieceAnimUp(posWork)
                else
                    pieceService:SetPieceAnimDown(posWork)
                end
            end
        end
    end
end
---真正计算瞬移目标的功能函数
---@param entityWork Entity
---@param skillResult SkillEffectResult_Teleport
function PlaySkillInstructionService:_TeleportTargetPos(TT, entityWork, skillResult, onlySelf, noTurn)
    if nil == entityWork then
        return
    end
    local posNew = skillResult:GetPosNew()
    if nil == posNew then
        return
    end
    ---瞬移的执行部分
    local dirNew = skillResult:GetDirNew()
    local casterDir = nil
    if dirNew then
        casterDir = dirNew
    else
        casterDir = entityWork:GridLocation().Direction
    end
    ---转换坐标前，设置Blocked数据
    local posOld = skillResult:GetPosOld()
    local bOnlyWorkEntity = false
    if entityWork:HasPetPstID() then ---宝宝： 默认整队都要移动
        ---@type Entity
        local teamEntity = entityWork:Pet():GetOwnerTeamEntity()

        local isPetActiveSkill = skillResult:GetTeleportResult_IsPetActiveSkill()
        if isPetActiveSkill then ---主动技瞬移要求带着队伍
            bOnlyWorkEntity = false
        else
            bOnlyWorkEntity = onlySelf or false
        end
        entityWork:SetLocation(posNew, casterDir)
        teamEntity:SetLocation(posNew, casterDir)

        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        boardServiceRender:ReCreateGridEntity(PieceType.None, posNew)
    else
        bOnlyWorkEntity = true
        if noTurn then
            entityWork:SetPosition(posNew + entityWork:GetGridOffset())
        else
            entityWork:SetLocation(posNew + entityWork:GetGridOffset(), casterDir)
        end
    end

    --entityWork:SetGridLocation(posNew, casterDir)
    if not bOnlyWorkEntity then ---要求移动整队
        ---@type Entity
        local teamEntity = entityWork:Pet():GetOwnerTeamEntity()
        ---@param petEntity Entity
        for i, petEntity in ipairs(teamEntity:Team():GetTeamPetEntities()) do
            petEntity:SetLocation(posNew, casterDir)
        end
    end
end

function PlaySkillInstructionService:_TeleportTarget2Sky(TT, entityWork, skillResult, onlySelf)
    if nil == entityWork then
        return
    end

    if entityWork:HasMonsterID() then
        local oldPos = skillResult:GetPosOld()
        ---@type PieceServiceRender
        local pieceService = self._world:GetService("Piece")
        local entityRenderService = self._world:GetService("RenderEntity")
        entityRenderService:DestroyMonsterAreaOutLineEntity(entityWork)
        local bodyArea = entityWork:BodyArea():GetArea()
        for i = 1, #bodyArea do
            local posWork = oldPos + bodyArea[i]
            pieceService:SetPieceAnimUp(posWork)
        end
        local newPos = skillResult:GetPosNew()
        entityWork:SetPosition(newPos)
    end

    --entityWork:SetLocationHeight(1000)
end

---瞬移结束后，播放触发的机关技能
---@param entityWork Entity
---@param listTrapTrigger Entity[]
function PlaySkillInstructionService:PlayTrapTrigger(TT, entityWork, listTrapTrigger)
    if not listTrapTrigger or table.count(listTrapTrigger) <= 0 then
        return
    end
    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    --客户端需要播表现之后销毁
    local listTaskReturn = {}
    --逻辑算了机关组   所以PlayTrapTriggerSkill 第二个参数 传false 只播放自己就可以了
    for _, e in ipairs(listTrapTrigger) do
        local listTaskID = sTrapRender:PlayTrapTriggerSkill(TT, e, false, entityWork)
        table.appendArray(listTaskReturn, listTaskID)
    end
    return listTaskReturn
end

-- ====================================================================================

-- ==================================== 转色相关方法 ===================================

function PlaySkillInstructionService:GridConvert(TT, entityCaster, gridPos, dataSource, dataUser, notRefreshPrism)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = entityCaster:SkillRoutine():GetResultContainer()

    local nNewGridType = nil --- PieceType.Any
    local flushTraps = {} --需要洗掉的机关
    if 0 == dataSource then ---使用自定义的数据来源
        nNewGridType = dataUser or PieceType.None
    elseif SkillEffectType.ResetGridElement == dataSource then
        ---@type SkillEffectResult_ResetGridElement
        local skillResultArray = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
        if skillResultArray then
            nNewGridType = skillResultArray:FindGridDataNew(gridPos)
            flushTraps = skillResultArray:GetFlushTrapsAt(gridPos)
        end
    elseif SkillEffectType.ConvertGridElement == dataSource then
        ---@type SkillConvertGridElementEffectResult
        local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
        if convertResult then
            nNewGridType = convertResult:GetTargetElementType()
        end
    elseif SkillEffectType.ManualConvert == dataSource then
        ---@type SkillManualConvertGridElementEffectResult
        local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ManualConvert)
        if convertResult then
            nNewGridType = convertResult:GetTargetElementType()
        end
    end

    --执行转色
    if nNewGridType and nNewGridType >= PieceType.None and nNewGridType <= PieceType.Any then
        ---@type BoardServiceRender
        local boardService = self._world:GetService("BoardRender")
        ---@type PlayBuffService
        local svcPlayBuff = self._world:GetService("PlayBuff")
        --旧格子颜色
        ---@type PieceServiceRender
        local pieceSvc = self._world:GetService("Piece")
        local nOldGridType = PieceType.None
        local gridEntity = pieceSvc:FindPieceEntity(gridPos)
        ---@type PieceComponent
        local pieceCmpt = gridEntity:Piece()
        nOldGridType = pieceCmpt:GetPieceType()

        ---@type Entity
        local newGridEntity =
            boardService:ReCreateGridEntity(nNewGridType, gridPos, false, false, false, notRefreshPrism)
        --破坏格子后 不会创建新格子
        if newGridEntity then
            pieceSvc:SetPieceEntityAnimNormal(newGridEntity)
        end

        local tConvertInfo = {}
        local convertInfo = NTGridConvert_ConvertInfo:New(gridPos, nOldGridType, nNewGridType)
        table.insert(tConvertInfo, convertInfo)
        local notify = NTGridConvert:New(entityCaster, tConvertInfo)
        notify:SetConvertEffectType(dataSource)
        notify.__attackPosMatchRequired = true
        svcPlayBuff:PlayBuffView(TT, notify)
    end

    --洗机关，直接删除
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    for _, trap in ipairs(flushTraps) do
        trapServiceRender:DestroyTrap(TT, trap)
    end
end

-- ====================================================================================

--region SummonEverything相关
---@param resultSummon SkillEffectResult_SummonEverything
function PlaySkillInstructionService:ShowSummonAction(TT, world, resultSummon)
    if nil == resultSummon then
        return
    end
    local nSummonType = resultSummon:GetSummonType()
    local pFunction = self.m_listSummonFunction[nSummonType]
    if nil == pFunction then
        return
    end
    local nSummonID = resultSummon:GetSummonID()
    if nil == nSummonID then
        return
    end
    local posSummon = resultSummon:GetSummonPos()
    local posCenter = resultSummon:GetPosCenter()
    pFunction(self, TT, world, resultSummon, posCenter, posSummon, nSummonID)
end
---@param resultSummon SkillEffectResult_SummonEverything
---@param posCenter Vector2 圆心坐标，施法者位置
---@param posSummon Vector2 可以召唤的位置
---@param nSummonID number 召唤怪物类型ID
---@return Entity
function PlaySkillInstructionService:_SummonShow_Monster(TT, world, resultSummon, posCenter, posSummon, nSummonID)
    if nil == posSummon then
        return nil
    end
    local summonMonsterData = resultSummon:GetMonsterData()
    local summonTransformData = resultSummon:GetSummonTransformData()

    ---@type Entity
    local eMonsters = {}
    local eHPs = {}
    local monsterIds = {}
    local entityWork = world:GetEntityByID(summonMonsterData.m_entityWorkID)
    table.insert(eMonsters, entityWork)
    table.insert(eHPs, summonMonsterData.m_entityHp)
    table.insert(monsterIds, summonMonsterData.m_nMonsterID)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = world:GetService("MonsterShowRender")
    local taskID =
        TaskManager:GetInstance():CoreGameStartTask(
        sMonsterShowRender.ShowSummonMonster,
        sMonsterShowRender,
        entityWork,
        summonTransformData
    )

    while not HelperProxy:GetInstance():IsTaskFinished(taskID) do
        YIELD(TT)
    end

    return eMonsters
end
---@param resultSummon SkillEffectResult_SummonEverything
---@param world MainWorld
function PlaySkillInstructionService:_SummonShow_Trap(TT, world, resultSummon, posCenter, posSummon, nSummonID)
    if nil == posSummon then
        return nil
    end
    local summonMonsterData = resultSummon:GetTrapData()
    local trapEntity = world:GetEntityByID(summonMonsterData.m_entityWorkID)
    trapEntity:SetPosition(posSummon)

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
end
--endregion

function PlaySkillInstructionService:PlayAttackAudio(waitTime,casterEntity,audioID)
    local taskID = TaskManager:GetInstance():CoreGameStartTask(self._PlayAttackAudio,self,waitTime,casterEntity,audioID)
    return taskID
end
function PlaySkillInstructionService:_PlayAttackAudio(TT,waitTime,casterEntity,audioID)
    if waitTime and waitTime > 0 then
        YIELD(TT,waitTime)
    end
    if audioID then
        local playingID = AudioHelperController.PlayInnerGameSfx(audioID)
        ---@type EffectHolderComponent
        local effectCpmt = casterEntity:EffectHolder()
        if not effectCpmt then
            casterEntity:AddEffectHolder()
            effectCpmt = casterEntity:EffectHolder()
        end
        effectCpmt:AttachAudioID(audioID,playingID)
    end
end

---@param entity Entity
function PlaySkillInstructionService:PlayEntityMove(TT,entity,oldPos,newPos,speed)
    ---取当前的渲染坐标
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    self:StartMoveAnimation(entity, true)
    if entity:HasMonsterID() then
        boardServiceRender:RefreshPiece(entity, true, true)
    end
    local curPos = boardServiceRender:GetRealEntityGridPos(entity)

    entity:AddGridMove(speed, newPos, curPos)
    local walkDir = newPos - curPos

    entity:SetDirection(walkDir)

    --boardServiceRender:ReCreateGridEntity(newGridType,walkPos,false,false,true)

    while entity:HasGridMove() do
        YIELD(TT)
    end
    self:StartMoveAnimation(entity, false)
    if entity:HasMonsterID() then
        boardServiceRender:RefreshPiece(entity, false, true)
    end
end

---@param casterEntity Entity
function PlaySkillInstructionService:GetMoveSpeed(casterEntity)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type MonsterConfigData 怪物配置数据
    local configData = cfgSvc:GetMonsterConfigData()

    ---@type MonsterIDComponent
    local monsterIDCmpt = casterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    local speed = configData:GetMonsterSpeed(monsterID)
    speed = speed or 1

    return speed
end

---@param targetEntity Entity
function PlaySkillInstructionService:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({Move = isMove})
    end
end


---@param monsterEntity Entity
---@param trapResList WalkTriggerTrapResult[]
function PlaySkillInstructionService:PlayArrivePosTriggerTrap(TT, monsterEntity,pos, trapResList)
    ---触发机关的表现
    for _, v in ipairs(trapResList) do
        ---@type WalkTriggerTrapResult
        local walkTrapRes = v
        local trapEntityID = walkTrapRes:GetTrapEntityID()
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        ---@type AISkillResult
        local trapSkillRes = walkTrapRes:GetTrapResult()
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = trapSkillRes:GetResultContainer()
        trapEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)

        Log.debug(
                "[AIMove] PlayArrivePos() monster=",
                monsterEntity:GetID(),
                " pos=",
                pos,
                " play trapid=",
                trapEntity:GetID(),
                " defender=",
                skillEffectResultContainer:GetScopeResult():GetTargetIDs()[1]
        )

        ---@type TrapServiceRender
        local trapSvc = self._world:GetService("TrapRender")
        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, monsterEntity)
    end
end