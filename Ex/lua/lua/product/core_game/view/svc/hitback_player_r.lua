--[[--------------------------------------------------------
    技能表现中，所有击退相关的函数
--]] -------------------------------------------------------

require("play_skill_svc_r")

---处理受击及击退表现
---@param attacker Entity
---@param defenter Entity
function PlaySkillService:ProcessHit(attacker, defenter, hitBackData, hitBackSpeed)
    if hitBackData then
        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            self.HitProcessTask,
            self,
            attacker,
            defenter,
            hitBackData,
            hitBackSpeed
        )
        return taskID
    else
        return
    end
end

---@param attacker Entity
---@param defender Entity
---@param result SkillHitBackEffectResult
function PlaySkillService:HitProcessTask(TT, attacker, defender, result, hitBackSpeed)
    local defenderID = defender:GetID()

    ----这里是为了处理队伍跟队长拆分开以后导致的队伍拥有血条，队长拥有模型的问题……
    ---恶心
    local defenderHPMaster = nil
    ---@type Entity
    local defenderEntity = nil
    if defender:Team() then
        defenderHPMaster = defender
        defenderEntity = defender:GetTeamLeaderPetEntity()
    else
        defenderHPMaster = defender
        defenderEntity = defender
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local pieceChangeTable = result:GetGridElementChangeTable()
    ---@type table<number, Entity>
    local emptyGrids = {}
    if pieceChangeTable ~= nil then
        for pos, pieceType in pairs(pieceChangeTable) do
            if not utilDataSvc:IsPosExistNegtiveBlock(pos) then
                emptyGrids[#emptyGrids + 1] = boardServiceRender:CreateEmptyGridEffectEntity(pos)
            end
        end
    end

    local startPos = boardServiceRender:GetRealEntityGridPos(defenderEntity)
    local speed = self._hitBackSpeed
    if hitBackSpeed then
        speed = hitBackSpeed
    end
    if not defenderEntity:HasHitback() then
        defenderEntity:AddHitback(startPos, speed, result:GetPosTarget(), result:GetHitDir())
    end
    while defenderEntity:HasHitback() and not defenderEntity:Hitback():IsHitbackEnd() do
        YIELD(TT)
    end

    --击退触发机关、炸弹
    self:_OnEventHitback_End(TT, defenderEntity, result)

    ---销毁星空格
    for i = 1, #emptyGrids do
        self._world:DestroyEntity(emptyGrids[i])
    end

    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")

    if pieceChangeTable ~= nil then
        for pos, pieceType in pairs(pieceChangeTable) do
            if not utilDataSvc:IsPosExistNegtiveBlock(pos) then
                boardServiceRender:ReCreateGridEntity(pieceType, pos, false)
                svcPlayBuff:_SendNTGridConvertRender(TT, pos, pieceType, SkillEffectType.HitBack)
            end
        end

        local isPlayer = defenderEntity:HasPet()
        if isPlayer == true then
            ---玩家脚下格子变为灰格
            boardServiceRender:ReCreateGridEntity(result:GetColorNew(), defenderEntity:GetRenderGridPosition())
        else
            ---刷怪脚下的格子
            ---@type PieceServiceRender
            local piece_service = self._world:GetService("Piece")
            if piece_service then
                piece_service:RefreshPieceAnim()
            end
        end
    end

    --发送击退结束消息
    self._world:GetService("PlayBuff"):PlayBuffView(
        TT,
        NTHitBackEnd:New(attacker, defender, result:GetStartPos(), result:GetPosTarget())
    )
end

---@param hitbackResult SkillHitBackEffectResult
function PlaySkillService:_OnEventHitback_End(TT, entityWork, hitbackResult)
    entityWork:RemoveHitback()

    local nEntityID = entityWork:GetID()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local posTarget = hitbackResult:GetPosTarget()

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    if entityWork:HasBodyArea() then
        local bodyArea = entityWork:BodyArea():GetArea()
        for _, areaPos in ipairs(bodyArea) do
            trapServiceRender:ShowHideTrapAtPos(areaPos + posTarget, false)
        end
    else
        trapServiceRender:ShowHideTrapAtPos(posTarget, false)
    end

    local pieceService = self._world:GetService("Piece")
    pieceService:RemovePrismAt(hitbackResult:GetGridPos())

    local trapIds = hitbackResult:GetTriggerTrapIds()
    local listTask = {}
    if trapIds then
        local hadTrapGroundId = {}
        local listTrapTrigger = {}
        for i, id in ipairs(trapIds) do
            local e = self._world:GetEntityByID(id)
            if e then
                ---@type TrapRenderComponent
                local trapRender = e:TrapRender()
                local groupID = trapRender:GetGroupID()
                if groupID == 0 or not table.icontains(hadTrapGroundId, groupID) then
                    if not table.icontains(hadTrapGroundId, groupID) then
                        table.insert(hadTrapGroundId, groupID)
                    end

                    listTrapTrigger[#listTrapTrigger + 1] = e
                end
            end
        end
        local nTask =
            GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                trapServiceRender:PlayTrapTriggerSkillTasks(TT, listTrapTrigger, true, entityWork)
            end
        )

        table.insert(listTask, nTask)
    end
    Log.debug(
        "[HitBack] 击退完成，nEntityID =",
        nEntityID,
        "StartPos =",
        GameHelper.MakePosString(hitbackResult:GetStartPos()),
        "TargetPos =",
        GameHelper.MakePosString(hitbackResult:GetPosTarget())
    )
    ---@type RenderEntityService
    local entityRenderService = self._world:GetService("RenderEntity")
    if entityWork:HasMonsterID() then
        entityRenderService:CreateMonsterAreaOutlineEntity(entityWork)
    end

    --炸弹爆炸
    --GameGlobal.TaskManager():CoreGameStartTask(self._DoEvent_HitbackEndOneNew, self, nEntityID, hitbackResult)
    self:_DoEvent_HitbackEndOneNew(TT, nEntityID, hitbackResult)

    while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
        YIELD(TT)
    end
end

function PlaySkillService:_DoEvent_HitbackEndOneNew(TT, entityID, hitbackResult)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    local entity = self._world:GetEntityByID(entityID)
    if entity:HasPetPstID() then
        entityID = entity:Pet():GetOwnerTeamEntity()
    end

    local listTask = {}

    if hitbackResult:GetHitDir() then
        local nTask = GameGlobal.TaskManager():CoreGameStartTask(self._TriggerBomb, self, hitbackResult)
        table.insert(listTask, nTask)
    end

    self:_WaitTaskFinished(TT, listTask)
end

---@param hitbackResult SkillHitBackEffectResult
function PlaySkillService:_TriggerBomb(TT, hitbackResult)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type Entity
    local entityWork = self._world:GetEntityByID(hitbackResult:GetTargetID())
    if nil == entityWork then
        return
    end

    local bombTrapEntityID = hitbackResult:GetBombTrapEntityID()
    if (nil == bombTrapEntityID) then
        return
    end
    local bombTrapEntity = self._world:GetEntityByID(bombTrapEntityID)
    if (nil == bombTrapEntity) then
        return
    end

    local posTarget = hitbackResult:GetPosTarget()
    if entityWork:HasTeam() or entityWork:HasPetPstID() or entityWork:HasMonsterID() then
        local posDir = hitbackResult:GetHitDir()
        if posDir then
            posTarget = posTarget + posDir
        end
    end

    --不再表现这里根据规则计算那个是爆炸，直接从逻辑结果里取
    local listBomb = {bombTrapEntity}

    trapServiceRender:PlayTrapTriggerSkillTasks(TT, listBomb, true, entityWork)

    --击退方向看上去是用来标记数据是否有效的，写法不规范
    hitbackResult:ClearHitDir()
    if table.count(listBomb) > 0 then
        trapServiceRender:ShowHideTrapAtPos(posTarget, true)
        trapServiceRender:DestroyTrapList(TT, listBomb)

        ---@type PlayBuffService
        local playBuffService = self._world:GetService("PlayBuff")
        playBuffService:PlayBuffView(TT, NTTrapAction:New(nil))

        Log.debug("[HitBack] 击退引爆炸弹, ", GameHelper.MakePosString(posTarget))
    end
end

function PlaySkillService:_WaitTaskFinished(TT, listWaitTask)
    if listWaitTask and table.count(listWaitTask) > 0 then
        while not TaskHelper:GetInstance():IsAllTaskFinished(listWaitTask) do
            YIELD(TT)
        end
    end
end
