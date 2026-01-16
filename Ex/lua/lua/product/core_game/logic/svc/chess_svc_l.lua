--[[------------------------------------------------------------------------------------------
    ChessServiceLogic : 战棋逻辑服务
]] --------------------------------------------------------------------------------------------

_class("ChessServiceLogic", BaseService)
---@class ChessServiceLogic: BaseService
ChessServiceLogic = ChessServiceLogic

---棋子按照路径移动。移动/移动攻击
function ChessServiceLogic:DoChessPetPathMove()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicChessPathComponent
    local logicChessPathComponent = boardEntity:LogicChessPath()
    local chessPath = logicChessPathComponent:GetLogicChessPath()
    local entityID = logicChessPathComponent:GetLogicChessPetEntityID()
    local chessPetEntity = self._world:GetEntityByID(entityID)
    if not chessPetEntity then
        return
    end

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local monsterWalkResultList = {}

    for _, pos in ipairs(chessPath) do
        --逃脱
        if chessPetEntity:HasMonsterEscape() then
            break
        end

        ---@type MonsterWalkResult
        local walkRes = MonsterWalkResult:New()

        --移动前buff

        local lastPos = chessPetEntity:GetGridPosition()
        --更新阻挡
        boardServiceLogic:UpdateEntityBlockFlag(chessPetEntity, lastPos, pos)
        --设置坐标
        chessPetEntity:SetGridPosition(pos)

        walkRes:SetWalkPos(pos)

        --移动后buff

        --触发机关
        self:_OnChessPetMoveArrivePos(chessPetEntity, walkRes)

        table.insert(monsterWalkResultList, walkRes)
    end

    logicChessPathComponent:SetLogicWalkResultList(monsterWalkResultList)

    return entityID
end

---@param walkRes MonsterWalkResult
function ChessServiceLogic:_OnChessPetMoveArrivePos(chessPetEntity, walkRes)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(chessPetEntity, TrapTriggerOrigin.Move)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)

        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    --本次移动经过的格子
    local passGrids = {}
    local isDuplicate = function(pos)
        for _, value in ipairs(passGrids) do
            if value.x == pos.x and value.y == pos.y then
                return true
            end
        end
        return false
    end
    local bodyArea = chessPetEntity:BodyArea():GetArea()
    local dir = chessPetEntity:GridLocation():GetGridDir()
    local curPos = chessPetEntity:GetGridPosition()
    for _, value in ipairs(bodyArea) do
        local pos = curPos + value - dir
        if not isDuplicate(pos) then
            passGrids[#passGrids + 1] = pos
        end
    end
    walkRes:SetWalkPassedGrid(passGrids)
end

---
function ChessServiceLogic:DoChessPetAttack()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicChessPathComponent
    local logicChessPathComponent = boardEntity:LogicChessPath()
    local chessPath = logicChessPathComponent:GetLogicChessPath()
    local entityID = logicChessPathComponent:GetLogicChessPetEntityID()
    local chessPetEntity = self._world:GetEntityByID(entityID)
    if not chessPetEntity then
        return
    end

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local attackSkill = chessPetCmpt:GetAttackSkillID()

    --攻击前
    local ntChessPetSkillAttackStart = NTChessPetSkillAttackStart:New(chessPetEntity, attackSkill)
    self._world:GetService("Trigger"):Notify(ntChessPetSkillAttackStart)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    skillLogicSvc:CalcSkillEffect(chessPetEntity, attackSkill)

    --攻击后
    local ntChessPetSkillAttackEnd = NTChessPetSkillAttackEnd:New(chessPetEntity, attackSkill)
    self._world:GetService("Trigger"):Notify(ntChessPetSkillAttackEnd)
end

---结束棋子回合
function ChessServiceLogic:FinishChessPetTurn(finishAll, targetEntityID)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    local chessPetEntities = group:GetEntities()
    for i, v in ipairs(chessPetEntities) do
        ---@type ChessPetComponent
        local chessPetCmpt = v:ChessPet()
        if finishAll then
            chessPetCmpt:SetChessPetFinishTurn(true)
        elseif targetEntityID == v:GetID() then
            chessPetCmpt:SetChessPetFinishTurn(true)
        end
    end
end

---查询是否所有棋子回合结束
function ChessServiceLogic:IsAllChessPetTurnFinish()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)

    for i, entity in ipairs(group:GetEntities()) do
        if self:_OnCheckChessCanAction(entity) then
            return false
        end
    end

    return true
end

---@param entity Entity
---检查能否移动
function ChessServiceLogic:_OnCheckChessCanAction(entity)
    if entity:HasDeadMark() then
        return false
    end

    --棋子行动完
    ---@type ChessPetComponent
    local chessPetCmpt = entity:ChessPet()
    if chessPetCmpt:IsChessPetFinishTurn() then
        return false
    end

    --逃脱
    if entity:HasMonsterEscape() then
        return false
    end

    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    local isSkipTurn = buffCmpt:HasFlag(BuffFlags.SkipTurn)
    if isSkipTurn then
        return false
    end

    return true
end

---检查并执行棋子的逻辑死亡
function ChessServiceLogic:DoChessPetListDeadLogic(deadEntityIDList)
    for _, v in ipairs(deadEntityIDList) do
        local e = self._world:GetEntityByID(v)
        ---先添加逻辑死亡标记
        self:AddChessPetDeadMark(e)
        ---此函数内部会判断是否重复执行过Dead
        self:_DoOneChessLogicDead(e)
    end
end

---处理单个棋子的死亡
---@param chessPetEntity Entity
function ChessServiceLogic:_DoOneChessLogicDead(chessPetEntity)
    if not chessPetEntity:HasDeadMark() then
        return
    end

    ---@type DeadMarkComponent
    local deadMarkCmpt = chessPetEntity:DeadMark()
    if deadMarkCmpt:HasDoLogicDead() then
        ---走到这里，说明重复执行了死亡逻辑
        --Log.warn("monster has do logic dead ", Log.traceback())
        return
    end

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    if not chessPetCmpt then
        return
    end

    deadMarkCmpt:SetDoLogicDead(true)

    --死亡技能
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    if stateId ~= GameStateID.ChessPetResult then
        self:_CalcChessPetDeathSkill(chessPetEntity)
    end

    --清除阻挡
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    sBoard:RemoveEntityBlockFlag(chessPetEntity, chessPetEntity:GridLocation().Position)

    --buff
    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    sTrigger:Notify(NTChessDead:New(chessPetEntity)) --死亡触发通知

    --设置逻辑坐标
    chessPetEntity:SetGridPosition(Vector2(BattleConst.CacheHeight, BattleConst.CacheHeight))
end

---获取血量为0，并且没有执行死亡逻辑的棋子列表
function ChessServiceLogic:GetDeadChessPetList()
    local deadChessPetEntityIDList = {}
    local chessPetGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(chessPetGroup:GetEntities()) do
        ---@type AttributesComponent
        local attrCmpt = e:Attributes()
        local curHp = attrCmpt:GetCurrentHP()
        if curHp <= 0 and not e:HasDeadMark() then
            deadChessPetEntityIDList[#deadChessPetEntityIDList + 1] = e:GetID()
        end
    end

    return deadChessPetEntityIDList
end

---
function ChessServiceLogic:GetHasDeadMarkChessPetList()
    local deadChessPetEntityIDList = {}
    local chessPetGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(chessPetGroup:GetEntities()) do
        ---@type AttributesComponent
        local attrCmpt = e:Attributes()
        local curHp = attrCmpt:GetCurrentHP()
        if e:HasDeadMark() then
            deadChessPetEntityIDList[#deadChessPetEntityIDList + 1] = e:GetID()
        end
    end

    return deadChessPetEntityIDList
end

---尝试给目标加上逻辑死亡标记
---@param e Entity
function ChessServiceLogic:AddChessPetDeadMark(e)
    if not e:HasChessPet() then
        return
    end

    ---血量大于0，说明还没死
    local cAttributes = e:Attributes()
    local curHp = cAttributes:GetCurrentHP()
    if curHp > 0 then
        return
    end

    ---如果已经挂上过逻辑死亡标记，不用再挂了
    if e:HasDeadMark() then
        return
    end

    e:AddDeadMark()
    return e:DeadMark()
end

---@param monsterEntity Entity
---计算死亡技效果
function ChessServiceLogic:_CalcChessPetDeathSkill(chessPetEntity)
    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local deathSkillID = chessPetCmpt:GetDieSkillID()
    if deathSkillID and deathSkillID > 0 then
        ---@type SkillLogicService
        local skillLogicService = self._world:GetService("SkillLogic")
        skillLogicService:CalcSkillEffect(chessPetEntity, deathSkillID)
        skillLogicService:UpdateRenderSkillRoutine(chessPetEntity)
    end
end
