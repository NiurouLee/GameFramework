require("base_ins_r")

---@class PlayMoveBoardInstruction: BaseInstruction
_class("PlayMoveBoardInstruction", BaseInstruction)
PlayMoveBoardInstruction = PlayMoveBoardInstruction

function PlayMoveBoardInstruction:Constructor(paramList)
    self._sceneRoot1 = paramList["sceneRoot1"]
    self._sceneRoot2 = paramList["sceneRoot2"]
    self._times = tonumber(paramList["times"]) or 1
    self._dirX = tonumber(paramList["dirX"]) or 0
    self._dirY = tonumber(paramList["dirY"]) or 0
    self._dir = Vector2(self._dirX, self._dirY)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMoveBoardInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultMoveBoard[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MoveBoard)
    if resultArray == nil then
        Log.fatal("PlayMoveBoardInstruction, result is nil.")
        return
    end
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type TrapServiceRender
    local trapSvc = world:GetService("TrapRender")
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardComponent = renderBoardEntity:RenderBoard()

    -- local entityResultBase = resultArray[1]:GetMoveEntity()
    -- local pieceResultBase = resultArray[1]:GetMoveBoardPieceResult()

    -- ---@param v SkillEffectResultMoveBoard
    -- for moveIndex, v in ipairs(resultArray) do
    --     if moveIndex > 1 then
    --         --移动一步
    --         local moveEntityResult = v:GetMoveEntity()
    --         local pieceResult = v:GetMoveBoardPieceResult()

    --         --物体
    --         for eid, result in pairs(moveEntityResult) do
    --             -- local eid, oldPos, newPos = table.unpack(r)
    --             local oldPos = result.oldPos
    --             local newPos = result.newPos

    --             local e = world:GetEntityByID(eid)
    --             if e then
    --                 -- local t = {e, oldPos, newPos}
    --                 -- allEntity[#allEntity + 1] = t
    --                 -- arrMovers[#arrMovers + 1] = t
    --                 entityResultBase[eid].newPos = newPos
    --             end
    --         end

    --     -- --格子
    --     -- for i, r in ipairs(pieceResult) do
    --     --     local oldPos, newPos = r[1], r[2]
    --     --     local pieceEntity = pieceService:FindPieceEntity(oldPos)
    --     --     if pieceEntity then
    --     --         local t = {pieceEntity, oldPos, newPos}
    --     --         if moveIndex == 1 then
    --     --             allEntity[#allEntity + 1] = t
    --     --         end
    --     --         arrPiece[#arrPiece + 1] = t
    --     --     end
    --     -- end
    --     end
    -- end

    -- --格子
    -- for i, r in ipairs(pieceResultBase) do
    --     local oldPos, newPos = r[1], r[2]
    --     local targetPos = oldPos + Vector2(self._dir.x * self._times, self._dir.y * self._times)
    --     r[2] = targetPos
    -- end

    local createGridEntityList = {}

    -- local arrPieceLast = {}

    ---@param v SkillEffectResultMoveBoard
    for moveIndex, v in ipairs(resultArray) do
        --实体分类
        local arrPiece = {}
        local arrMonster = {}
        local allEntity = {}
        local arrMovers = {}
        --移动一步
        local entityResult = v:GetMoveBoardEntities()
        local pieceResult = v:GetMoveBoardPieceResult()
        local moveBoardPieceResultCutIn = v:GetMoveBoardPieceResultCutIn()
        local prismResult = v:GetMoveBoardPrisms()
        local convertResult = v:GetConvertColors()
        local trapResult = v:GetTrapSkillResults()
        local trapDestoryList = v:GetTrapDestroyList()

        for i, r in ipairs(pieceResult) do
            local oldPos, newPos = r[1], r[2]
            local pieceEntity = pieceService:FindPieceEntity(oldPos)
            if pieceEntity then
                local t = {pieceEntity, oldPos, newPos}
                allEntity[#allEntity + 1] = t
                arrPiece[#arrPiece + 1] = t
            end
        end
        --划入的
        for i, r in ipairs(moveBoardPieceResultCutIn) do
            local oldPos, newPos, pieceType = r[1], r[2], r[3]
            local newGridEntity = boardServiceRender:CreateGridEntity(pieceType, oldPos)
            if newGridEntity then
                local t = {newGridEntity, oldPos, newPos}
                allEntity[#allEntity + 1] = t
                arrPiece[#arrPiece + 1] = t
                createGridEntityList[#createGridEntityList + 1] = newGridEntity

                playBuffService:_SendNTGridConvertRender(TT, oldPos, pieceType, SkillEffectType.MoveBoard)
            end
        end

        for i, r in ipairs(entityResult) do
            local eid, oldPos, newPos = table.unpack(r)
            local e = world:GetEntityByID(eid)
            if e then
                local t = {e, oldPos, newPos}
                allEntity[#allEntity + 1] = t
                arrMovers[#arrMovers + 1] = t
            end
        end

        -- if moveIndex == 1 then
        --移动实体
        for i, v in ipairs(allEntity) do
            ---@type Entity
            local e = v[1]
            local posTarget = v[3]
            local gridPos = boardServiceRender:GetRealEntityGridPos(e)

            e:RemoveGridMove()
            ---@type GridMoveComponent
            local gridMove = e:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)

            if e:HasTeam() then
                local entityList = e:Team():GetTeamPetEntities()
                for k, entity in pairs(entityList) do
                    entity:RemoveGridMove()
                    ---@type GridMoveComponent
                    local petGridMove = entity:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                end
            elseif e:MonsterID() then
                --删除红线
                renderEntityService:DestroyMonsterAreaOutLineEntity(e)

                --移动前 把压暗的全部抬起
                local pos = e:GridLocation():GetGridOffset()
                local bodyArea = e:BodyArea():GetArea()
                for _, area in ipairs(bodyArea) do
                    local workPos = area + pos
                    local curPieceAnim = pieceService:GetPieceAnimation(workPos)
                    if curPieceAnim == "Down" then
                        pieceService:SetPieceAnimUp(workPos)
                    end
                end
            elseif e:HasTrapID() then
                if e:HasTrapRoundInfoRender() then
                    local eid = e:TrapRoundInfoRender():GetRoundInfoEntityID()
                    if eid then
                        local eff = world:GetEntityByID(eid)
                        eff:RemoveGridMove()
                        eff:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                    end
                end
                local cEffectHolder = e:EffectHolder()
                if cEffectHolder then
                    --处理散布在格子外的待机特效（凛音结界）
                    local effectList = cEffectHolder:GetIdleEffect()
                    if table.count(effectList) > 0 then
                        for i, eff in ipairs(effectList) do
                            local effectEntity = world:GetEntityByID(eff)
                            if effectEntity and effectEntity:HasView() then
                                local curGridPos = boardServiceRender:GetRealEntityGridPos(effectEntity)
                                local newGridPos = curGridPos + Vector2(self._dir.x, self._dir.y)
                                effectEntity:RemoveGridMove()
                                effectEntity:AddGridMove(BattleConst.ConveySpeed, newGridPos, curGridPos)
                            end
                        end
                    end
                end
            end
        end
        -- end

        --需要移动场景
        if self._sceneRoot1 and self._sceneRoot2 and moveIndex == 1 then
            local sceneRoot1 = UnityEngine.GameObject.Find(self._sceneRoot1)
            local sceneRoot2 = UnityEngine.GameObject.Find(self._sceneRoot2)

            local moveTime = 1 / BattleConst.ConveySpeed * self._times
            local sceneRootDistance = math.abs(sceneRoot1.transform.position.z - sceneRoot2.transform.position.z)
            local offsetPos = Vector3(self._dir.x * self._times, 0, self._dir.y * self._times)

            local targetPos1 = sceneRoot1.transform.position + offsetPos
            local dotween1 =
                sceneRoot1.transform:DOMove(targetPos1, moveTime, false):SetEase(DG.Tweening.Ease.Linear):OnComplete(
                function()
                    if sceneRoot1.transform.position.z >= sceneRootDistance then
                        -- sceneRoot1.transform.position = sceneRoot2.transform.position - Vector3(0, 0, sceneRootDistance)
                        sceneRoot1.transform.position =
                            sceneRoot1.transform.position - Vector3(0, 0, sceneRootDistance * 2)
                    end
                end
            )

            local targetPos2 = sceneRoot2.transform.position + offsetPos
            local dotween2 =
                sceneRoot2.transform:DOMove(targetPos2, moveTime, false):SetEase(DG.Tweening.Ease.Linear):OnComplete(
                function()
                    if sceneRoot2.transform.position.z >= sceneRootDistance then
                        -- sceneRoot2.transform.position = sceneRoot1.transform.position - Vector3(0, 0, sceneRootDistance)
                        sceneRoot2.transform.position =
                            sceneRoot2.transform.position - Vector3(0, 0, sceneRootDistance * 2)
                    end
                end
            )
        end

        local gezi_wangge = UnityEngine.GameObject.Find("gezi_wangge")
        if gezi_wangge then
            local wanggePos = gezi_wangge.transform.position
            local dotween =
                gezi_wangge.transform:DOMove(
                wanggePos + Vector3(self._dir.x, 0, self._dir.y),
                1 / BattleConst.ConveySpeed,
                false
            ):SetEase(DG.Tweening.Ease.Linear):OnComplete(
                function()
                    gezi_wangge.transform.position = wanggePos
                end
            )
        end

        while self:IsMoving(allEntity) do
            YIELD(TT)
        end

        --设置场景坐标
        if self._sceneRoot1 then
        end

        -- YIELD(TT, 1 / BattleConst.ConveySpeed * 1000)

        --格子动画播完之后重置位置
        for _, t in ipairs(arrPiece) do
            local e = t[1]
            local oldPos = t[2]
            local newPos = t[3]
            ---@type GridLocationComponent
            local gridLocationCmp = e:GridLocation()
            if gridLocationCmp then
                e:SetGridPosition(oldPos)
                e:SetLocation(oldPos, e:GetGridDirection())
            end
        end

        for _, gridEntity in ipairs(createGridEntityList) do
            world:DestroyEntity(gridEntity)
        end

        --转色
        --转色但是不刷新棱镜
        local notRefreshPrism = true
        for _, v in ipairs(convertResult) do
            local pos = v[1]
            local elementType = v[3]
            playSkillInstructionService:GridConvert(TT, casterEntity, pos, 0, elementType, notRefreshPrism)
        end

        --触发的机关表现
        for _, v in ipairs(trapResult) do
            local eId = v[1]
            local e = world:GetEntityByID(eId)
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = v[2]
            local triggerEid = v[3]
            local triggerEntity = world:GetEntityByID(triggerEid)
            e:SkillRoutine():SetResultContainer(skillEffectResultContainer)
            trapSvc:PlayTrapTriggerSkill(TT, e, false, triggerEntity)
        end

        --死亡的机关表现
        --不播放死亡技能
        local donotPlayDie = true
        for _, entityID in ipairs(trapDestoryList) do
            local entity = world:GetEntityByID(entityID)
            trapSvc:PlayTrapDieSkill(TT, {entity}, donotPlayDie)
        end

        --棱镜
        for _, v in pairs(prismResult) do
            local oldPos = v[1]
            --删除旧棱镜
            pieceService:SetPieceRenderEffect(oldPos, PieceEffectType.Normal)

            local newPos = v[2]
            if newPos then
                --添加新棱镜
                pieceService:SetPieceRenderEffect(newPos, PieceEffectType.Prism)
            end
        end

        --传送移动通知
        for _, v in ipairs(arrMovers) do
            playBuffService:PlayBuffView(TT, NTTransportEachMoveEnd:New(v[1], v[2], v[3]))
        end
        -- YIELD(TT)
    end

    YIELD(TT)

    --移动完后统一设置

    --设置怪物脚底暗色  刷新红线
    pieceService:RefreshPieceAnim()
    pieceService:RefreshMonsterAreaOutLine(TT)
end

function PlayMoveBoardInstruction:IsMoving(es)
    for _, t in ipairs(es) do
        local e = t[1]
        if e:HasGridMove() then
            return true
        end
    end
end
