--[[------------------------------------------------------------------------------------------
    ChessServiceRender: 战棋模式下的各种表现函数
]] --------------------------------------------------------------------------------------------

_class("ChessServiceRender", BaseService)
---@class ChessServiceRender:BaseService
ChessServiceRender = ChessServiceRender

---结束棋盘上所有单位的预览
function ChessServiceRender:ClearAllChessUnitPreview()
    self:ClearChessMonsterPreview()

    self:ClearChessPetPreview()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    resCmpt:ResetChessPickUp()
    resCmpt:SetChessPetMovePath({})
end

---清理怪物预览
function ChessServiceRender:ClearChessMonsterPreview()
    ---@type PreviewActiveSkillService
    local previewActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillSvc:_RevertAllConvertElement(true)
    previewActiveSkillSvc:ResetPreview()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local effectIDList = resCmpt:GetMonsterChessTargetEffectEntityIDList()

    for i, id in ipairs(effectIDList) do
        ---@type Entity
        local effectEntity = self._world:GetEntityByID(id)
        self._world:DestroyEntity(effectEntity)
    end
    resCmpt:ClearMonsterChessTargetEffectEntityIDList()

    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:HideHideInUIBar()

    --删除Ghost
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyGhost()

    renderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
    ---@type PreviewActiveSkillService
    local previewActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    --previewActiveSkillSvc:AllPieceDoConvert("Normal")
    self._world:GetService("MonsterShowRender"):MonsterGridAnimDown()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:HideSkillTips()

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()

    local GLOBALmonsterGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(GLOBALmonsterGroupEntities) do
        e:ReplaceChessTargetedMark(false)
        ---@type ViewComponent
        local view = e:View()
        ---@type UnityEngine.GameObject
        local go = view:GetGameObject()
        ---@type OutlineComponent
        local outlineCmpt = go:GetComponent(typeof(OutlineComponent))
        if outlineCmpt then
            outlineCmpt.enabled = false
        end
        ---@type MaterialAnimationComponent
        local comp = e:MaterialAnimationComponent()
        comp:StopLayer(MaterialAnimLayer.SkillPreview)
    end
    ---@type Entity[]
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.ChessPet)
    for _, v in ipairs(entityList) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        comp:StopLayer(MaterialAnimLayer.SkillPreview)
        --if v:MaterialAnimationComponent():IsPlayingSelect() or v:MaterialAnimationComponent():IsPlayingAlpha() then
        --    comp:StopLayer(MaterialAnimLayer.SkillPreview)
        --end
    end
end

---清理棋子光灵预览
function ChessServiceRender:ClearChessPetPreview()
    --删除Ghost
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyGhost()

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()

    --删除连线
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:DestroyAllLinkLine()

    --删除棋子产生的所有特效
    self:DestroyPreviewChessPetEffectEntity()

    --选中的棋子
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)

    --删除选中特效
    self:RefreshChessPetSelectStateRender(chessPetEntity, false)

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.HP)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        e:ReplaceChessTargetedMark(false)
    end

    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.FinishTurnOnly)
    self:HideChessPetSkillTips()
end

---删除棋子产生的所有特效
function ChessServiceRender:DestroyPreviewChessPetEffectEntity()
    ---@type EffectService
    local effectSvc = self._world:GetService("Effect")

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PreviewChessPetComponent
    local previewChessPetCmpt = renderBoardEntity:PreviewChessPet()

    local moveRangeEntityIDList = previewChessPetCmpt:GetMoveRangeEffectEntityIDList()
    local attackRangeEntityIDList = previewChessPetCmpt:GetAttackRangeEffectEntityIDList()
    effectSvc:_DestroyEffectArray(moveRangeEntityIDList)
    effectSvc:_DestroyEffectArray(attackRangeEntityIDList)

    previewChessPetCmpt:ClearChessPetPreviewList()
end

---
function ChessServiceRender:RestartChessPetPreviewAttackRange()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    -- local pickUpMonsterEntityID = resCmpt:GetPickUpMonsterEntityID()
    -- if pickUpMonsterEntityID then
    local walkRange = resCmpt:GetChessPetWalkRange()
    local attackRange = resCmpt:GetChessPetAttackRange()
    local isRecover = resCmpt:GetSkillIsRecover()
    self:ShowChessPetPreviewRange(walkRange, attackRange, {}, {}, isRecover)
    -- end
end

---显示棋子的预览范围
---@param walkRange Vector2[] 移动范围列表
---@param attackRange Vector2[] 攻击范围列表
---@param targetIDs number[] 攻击范围选中的单位EntityID
function ChessServiceRender:ShowChessPetPreviewRange(walkRange, attackRange, selectRange, targetIDs, isRecover)
    ---@type EffectService
    local effectSvc = self._world:GetService("Effect")

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PreviewChessPetComponent
    local previewChessPetCmpt = renderBoardEntity:PreviewChessPet()

    --清除预览特效
    self:DestroyPreviewChessPetEffectEntity()

    for k, pos in ipairs(selectRange) do
        ---@type Entity
        local effectEntity = effectSvc:CreateCommonGridEffect(GameResourceConst.ChessPet_AttackTarget_EffectID, pos)
        previewChessPetCmpt:AddAttackRangeEffectEntityID(effectEntity:GetID())
    end

    local targetEffectID = GameResourceConst.ChessPet_AttackRange_EffectID
    if isRecover then
        targetEffectID = GameResourceConst.ChessPet_RecoverRange_EffectID
    end

    for k, pos in ipairs(attackRange) do
        if not table.intable(selectRange, pos) then
            ---@type Entity
            local effectEntity = effectSvc:CreateCommonGridEffect(targetEffectID, pos)
            previewChessPetCmpt:AddAttackRangeEffectEntityID(effectEntity:GetID())
        end
    end

    for k, pos in ipairs(walkRange) do
        if not table.intable(attackRange, pos) and not table.intable(selectRange, pos) then
            ---@type Entity
            local effectEntity = effectSvc:CreateCommonGridEffect(GameResourceConst.ChessPet_MoveRange_EffectID, pos)
            previewChessPetCmpt:AddMoveRangeEffectEntityID(effectEntity:GetID())
        end
    end

    ---不在范围内的都压暗
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()
        if not table.icontains(walkRange, pos) then
            pieceService:SetPieceAnimDown(pos)
        end
    end

    local entitySelectedDic = {}
    for _, eid in ipairs(targetIDs) do
        entitySelectedDic[eid] = true
    end

    ---这里所有单位都需要被更新，否则之前显示过的朋友会无法恢复
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.HP)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            e:ReplaceChessTargetedMark(entitySelectedDic[e:GetID()], isRecover)
        end
    end
end

---获得预览棋子的方向
function ChessServiceRender:GetPreviewChessPetDir()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    local pickUpMonsterEntityID = resCmpt:GetPickUpMonsterEntityID()
    local chessPetEntity = self._world:GetEntityByID(entityID)
    local chessPetDir = chessPetEntity:GetDirection()
    local pickUpPos = resCmpt:GetCurChessPickUpPos()

    local bodyArea = chessPetEntity:BodyArea():GetArea()

    if table.count(bodyArea) == 1 then
        --如果有点选攻击目标 则朝向攻击目标
        local movePath = resCmpt:GetChessPetMovePath()
        if pickUpMonsterEntityID and table.count(movePath) > 0 then
            chessPetDir = pickUpPos - movePath[#movePath]
        elseif table.count(movePath) > 1 then
            chessPetDir = movePath[#movePath] - movePath[#movePath - 1]
        end
    end

    return chessPetDir
end

---在点选的位置显示棋子虚影
function ChessServiceRender:ShowChessPetPreviewGhost(gridPos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)

    ---@type Entity
    local previewGhostEntity = self:_CreateChessPetPreviewGhost(chessPetEntity, gridPos)

    local previewDir = self:GetPreviewChessPetDir()
    local bodyArea = chessPetEntity:BodyArea():GetArea()

    if table.count(bodyArea) == 1 then
        --计算路径
        self:OnCalcMovePath(gridPos)

        --显示路径
        self:OnShowMovePathLineRender()

        previewGhostEntity:SetLocation(gridPos, previewDir)
    else
        local chessPetCenterPos = chessPetEntity:GridLocation():GetGridPos()
        local chessPetOffset = chessPetEntity:GridLocation():GetGridOffset()
        local chessPetCenter = chessPetEntity:GridLocation():Center()

        if chessPetCenterPos == gridPos then
            resCmpt:SetChessPetMovePath({chessPetCenterPos})
            previewGhostEntity:SetLocation(chessPetCenter, previewDir)
        else
            local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}
            local setLocationPos = nil
            local setGridPosition = nil
            for _, dir in ipairs(dirs) do
                local targetPos = chessPetCenterPos + dir
                for i, area in ipairs(bodyArea) do
                    local posWork = targetPos + area
                    if posWork == gridPos then
                        setGridPosition = targetPos
                        setLocationPos = targetPos + chessPetOffset
                        break
                    end
                end
                if setLocationPos then
                    resCmpt:SetChessPetMovePath({targetPos})
                    break
                end
            end
            previewGhostEntity:SetLocation(setLocationPos, previewDir)
            if setGridPosition then
                previewGhostEntity:SetGridPosition(setGridPosition)
            end
        end
    end
end

---创建棋子Ghost
function ChessServiceRender:_CreateChessPetPreviewGhost(chessPetEntity, gridPos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local previewGhostEntityID = resCmpt:GetPickUpPreviewGhostEntityID()
    ---@type Entity
    local previewGhostEntity = self._world:GetEntityByID(previewGhostEntityID)
    --连续点选范围内不重新创建
    if not previewGhostEntity then
        ---@type RenderEntityService
        local renderEntityService = self._world:GetService("RenderEntity")
        previewGhostEntity = renderEntityService:CreateGhost(gridPos, chessPetEntity)
        resCmpt:SetPickUpPreviewGhostEntityID(previewGhostEntity:GetID())
    end

    return previewGhostEntity
end

---选中棋子后点击棋子的攻击范围
function ChessServiceRender:OnPickUpChessPetAttackRange(gridPos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)
    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local chessPetID = chessPetCmpt:GetChessPetID()
    local chessPetPos = chessPetEntity:GridLocation():GetGridPos()
    local walkRange = resCmpt:GetChessPetWalkRange()
    local attackRange = resCmpt:GetChessPetAttackRange()

    --以点选的点为中心，计算技能范围
    local previewSkill = chessPetCmpt:GetPreviewSkillID()
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()
    ---@type SkillConfigData
    local skillConfigData = cfgSvc:GetSkillConfigData(previewSkill, chessPetEntity)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, gridPos, chessPetEntity)
    local scopeList = scopeResult:GetAttackRange()

    local bodyArea = chessPetEntity:BodyArea():GetArea()

    --查看移动范围中有那些位置可以攻击到目标
    local walkCanAttackPosList = {}
    for _, pos in ipairs(scopeList) do
        if table.intable(walkRange, pos) then
            for _, area in ipairs(bodyArea) do
                local centerPos = pos - area
                if table.intable(walkRange, centerPos) and not table.intable(walkCanAttackPosList, centerPos) then
                    local posInBodyAreaCanMove = 0
                    for _, areaNew in ipairs(bodyArea) do
                        local workPos = centerPos + areaNew
                        if table.intable(walkRange, workPos) then
                            posInBodyAreaCanMove = posInBodyAreaCanMove + 1
                        end
                    end

                    if posInBodyAreaCanMove == table.count(bodyArea) then
                        if table.count(bodyArea) == 1 then
                            table.insert(walkCanAttackPosList, centerPos)
                        else
                            --多格怪物，重新计算一下范围
                            ---@type SkillScopeResult
                            local scopeResultTmp =
                                utilScopeSvc:CalcSkillScope(skillConfigData, centerPos, chessPetEntity)
                            local scopeListTmp = scopeResultTmp:GetAttackRange()
                            if table.intable(scopeListTmp, gridPos) then
                                table.insert(walkCanAttackPosList, centerPos)
                            end
                        end
                    end
                end
            end
        end
    end

    local targetMovePos = walkCanAttackPosList[1]
    local lastMovePath = resCmpt:GetChessPetMovePath()

    --点击攻击，没有路径，直接计算最近
    if table.count(lastMovePath) == 0 then
        targetMovePos = self:_OnCompareNearestPos(walkCanAttackPosList, chessPetPos)
    else
        --有路径，需要用攻击范围和路径去计算
        targetMovePos =
            self:_OnCalcWithAttackRangeAndMovePath(targetMovePos, chessPetPos, lastMovePath, walkCanAttackPosList)
    end

    --点选位置显示虚影
    self:ShowChessPetPreviewGhost(targetMovePos)

    --基于移动后的点 计算攻击范围。范围内的显示白色特效，白色优先于红色
    local attackSkill = chessPetCmpt:GetAttackSkillID()
    -- local previewDir = self:GetPreviewChessPetDir()
    local pickUpPos = resCmpt:GetCurChessPickUpPos()
    local previewLogicDir = utilScopeSvc:GetChessEntityGridDirWithPickUpPos(chessPetEntity, pickUpPos, targetMovePos)
    ---@type SkillConfigData
    local attackSkillConfigData = cfgSvc:GetSkillConfigData(attackSkill, chessPetEntity)
    --范围中心是移动路径的终点
    local castPos = targetMovePos
    local curMovePath = resCmpt:GetChessPetMovePath()
    if table.count(curMovePath) > 0 then
        castPos = curMovePath[#curMovePath]
    end
    ---@type SkillScopeResult
    local scopeResultSelect =
        utilScopeSvc:CalcSkillScope(attackSkillConfigData, castPos, chessPetEntity, previewLogicDir)
    local selectRange = scopeResultSelect:GetAttackRange()

    ---@type SkillScopeTargetSelector
    local targetSelector = SkillScopeTargetSelector:New(self._world)
    local tTargetID =
        targetSelector:DoSelectSkillTarget(
        chessPetEntity,
        attackSkillConfigData:GetSkillTargetType(),
        scopeResultSelect,
        attackSkillConfigData:GetID(),
        attackSkillConfigData:GetSkillTargetTypeParam()
    )

    table.removev(tTargetID, entityID)

    local isRecover = false
    local skillEffectArray = skillConfigData:GetSkillEffect()
    for _, skillEffect in ipairs(skillEffectArray) do
        if skillEffect:GetEffectType() == SkillEffectType.AddBlood then
            isRecover = true
            break
        end
    end

    self:ShowChessPetPreviewRange(walkRange, attackRange, selectRange, tTargetID, isRecover)
    self:ShowChessPetSkillTips(attackSkillConfigData)
end

---
---@param skillConfigData SkillConfigData
function ChessServiceRender:ShowChessPetSkillTips(skillConfigData)
    ---@type RenderStateComponent
    local cRenderState = self._world:GetPreviewEntity():RenderState()
    ---@type Entity
    local eSkillTips = self._world:GetEntityByID(cRenderState:GetSkillTipsEntityID())
    if not eSkillTips then
        ---@type RenderEntityService
        local entityRenderSvc = self._world:GetService("RenderEntity")
        eSkillTips = entityRenderSvc:CreateRenderEntity(EntityConfigIDRender.SkillTips)
        cRenderState:SetSkillTipsEntityID(eSkillTips:GetID())
    end

    local name = skillConfigData:GetSkillName()
    local desc = skillConfigData:GetSkillDesc()
    eSkillTips:ReplaceSkillTips(name, desc)
    eSkillTips:SkillTips():SetTriggeredByChessPet(true)
    eSkillTips:SetViewVisible(true)
end

---
function ChessServiceRender:HideChessPetSkillTips()
    ---@type RenderStateComponent
    local cRenderState = self._world:GetPreviewEntity():RenderState()
    ---@type Entity
    local eSkillTips = self._world:GetEntityByID(cRenderState:GetSkillTipsEntityID())
    if not eSkillTips then
        return
    end

    eSkillTips:SetViewVisible(false)
end

---
function ChessServiceRender:_OnCalcWithAttackRangeAndMovePath(
    targetMovePos,
    chessPetPos,
    lastMovePath,
    walkCanAttackPosList)
    --如果点选的点在上次路径内，先检查最后一个点是否能攻击
    local curMovePos = nil
    for _, pos in ipairs(walkCanAttackPosList) do
        if pos == lastMovePath[#lastMovePath] then
            curMovePos = pos
            break
        end
    end

    --上次的移动路径中是否包含
    if not curMovePos then
        -- for _, pos in ipairs(lastMovePath) do
        for i = table.count(lastMovePath), 1, -1 do
            local pos = lastMovePath[i]
            for _, movePos in ipairs(walkCanAttackPosList) do
                if pos == movePos then
                    curMovePos = pos
                    break
                end
            end
            if curMovePos then
                break
            end
        end
    end

    if curMovePos then
        targetMovePos = curMovePos
    else
        targetMovePos = self:_OnCompareNearestPos(walkCanAttackPosList, chessPetPos)
    end
    return targetMovePos
end

function ChessServiceRender:OnCalcMovePath(targetMovePos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)
    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local chessPetID = chessPetCmpt:GetChessPetID()
    local chessPetPos = chessPetEntity:GridLocation():GetGridPos()

    local lastMovePath = resCmpt:GetChessPetMovePath()
    local curMovePath = {}

    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()
    local walkStep = chessPetConfigData:GetChessPetWalkStep(chessPetID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local chessPetList, chessPetPosList = utilScopeSvc:SelectAllChessPet()

    --路径选择
    --路径规则1：如果没有选中点（直接点攻击范围），直接选择最近的路径。
    --路径规则2：有选中点的情况下，如果新选中点当前的路径上，则保留点前的路径。
    --路径规则3：有选中点的情况下，如果新选中点不在当前路径上，需要判断当前路径使用的行动力，路径终点到选中点需要的行动力，剩余行动力是否足够移动。
    --路径规则3.1：如果行动力足够，则保留前路径，从路径终点继续向目标移动。
    --路径规则3.2：如果行动力不够，清空路径，重新计算最短路径。

    --点击攻击，没有路径，直接计算最近
    if table.count(lastMovePath) == 0 then
        table.insert(curMovePath, chessPetPos)
        --原地攻击
        if chessPetPos == targetMovePos then
        else
            local movePath = self:_OnCalcShortestPath(chessPetPos, targetMovePos, chessPetPosList)
            table.appendArray(curMovePath, movePath)
        end
    else
        --有路径，需要用攻击范围和路径去计算
        if table.intable(lastMovePath, targetMovePos) then
            for _, pos in ipairs(lastMovePath) do
                table.insert(curMovePath, pos)
                if pos == targetMovePos then
                    break
                end
            end
        else
            --路径包含脚下 所以要-1
            local hasWalkStep = table.count(lastMovePath) - 1

            local movePath =
                self:_OnCalcShortestPath(lastMovePath[#lastMovePath], targetMovePos, chessPetPosList, lastMovePath)
            local needWalkStep = table.count(movePath)

            if needWalkStep == 0 then
                table.insert(curMovePath, chessPetPos)
                movePath = self:_OnCalcShortestPath(chessPetPos, targetMovePos, chessPetPosList)
                table.appendArray(curMovePath, movePath)
            elseif walkStep - hasWalkStep - needWalkStep >= 0 then
                --剩余行动力支持这次移动
                table.appendArray(curMovePath, lastMovePath)
                table.appendArray(curMovePath, movePath)
            else
                table.insert(curMovePath, chessPetPos)
                movePath = self:_OnCalcShortestPath(chessPetPos, targetMovePos, chessPetPosList)
                table.appendArray(curMovePath, movePath)
            end
        end
    end

    resCmpt:SetChessPetMovePath(curMovePath)
end

--比较出一个距离目标点最近的点
function ChessServiceRender:_OnCompareNearestPos(posList, targetPos)
    local nearestPos = posList[1]
    for _, pos in ipairs(posList) do
        local dis1 = Vector2.Distance(nearestPos, targetPos)
        local dis2 = Vector2.Distance(pos, targetPos)
        if dis2 < dis1 then
            nearestPos = pos
        end
    end
    return nearestPos
end

--计算两点间的最短路径
function ChessServiceRender:_OnCalcShortestPath(posStart, posEnd, chessPetPosList, lastMovePath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local entityID = resCmpt:GetPickUpChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)
    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local chessPetID = chessPetCmpt:GetChessPetID()
    local blockData = chessPetCmpt:GetChessPetBlockData()

    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()
    local walkStep = chessPetConfigData:GetChessPetWalkStep(chessPetID)

    --当前格子的四方向中，距离目标点最近的，没被阻挡的
    local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}

    local movePath = {}

    local walkLastPos = posStart
    for i = 1, walkStep do
        local sortPosList = {}
        for _, dir in ipairs(dirs) do
            local targetPos = walkLastPos + dir

            --如果传了上次的路径，这次选择的点不能在上次的路径里
            if not lastMovePath or (lastMovePath and not table.intable(lastMovePath, targetPos)) then
                local isBlocked = utilDataSvc:IsPosBlock(targetPos, blockData)
                -- local isBlocked = utilDataSvc:IsPosBlockWithEntityRace(targetPos, blockData, chessPetEntity)
                if isBlocked then
                    if table.intable(chessPetPosList, targetPos) then
                        isBlocked = false
                    end
                end
                if isBlocked == false then
                    table.insert(sortPosList, targetPos)
                end
            end
        end

        local curMovePos = self:_OnCompareNearestPos(sortPosList, posEnd)
        table.insert(movePath, curMovePos)

        walkLastPos = movePath[#movePath]
        if walkLastPos == posEnd or walkLastPos == nil then
            break
        end
    end

    return movePath
end

---显示棋子的移动路径
function ChessServiceRender:OnShowMovePathLineRender()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local movePath = resCmpt:GetChessPetMovePath()

    --连线的特效
    local pieceType = 1

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")

    --先清空
    linkageRenderService:DestroyAllLinkLine()

    for i, pos in ipairs(movePath) do
        if i ~= 1 then
            local dir = movePath[i - 1] - movePath[i]
            --新版linerender
            linkageRenderService:CreateLineRender(movePath[i - 1], movePath[i], i, pos, dir, pieceType)
        end
    end
end

---根据棋子的回合结束状态刷新表现
function ChessServiceRender:RefreshChessPetFinishStateRender(entityID, finishTurn)
    if finishTurn then
        self:HdieChessPetCanMoveEffect(entityID)
        ---@type Entity
        local chessPetEntity = self._world:GetEntityByID(entityID)
        ---@type MaterialAnimationComponent
        local matCmpt = chessPetEntity:MaterialAnimationComponent()
        matCmpt:PlayInvalid()
    else
        self:ShowChessPetCanMoveEffect(entityID)
    end
end

---根据棋子的选中状态刷新表现
function ChessServiceRender:RefreshChessPetSelectStateRender(entity, select)
    if not entity then
        return
    end

    ---@type ChessPetRenderComponent
    local chessPetRenderCmpt = entity:ChessPetRender()
    local effectEntityID = chessPetRenderCmpt:GetSelectEffectEntityID()
    local effectEntity = self._world:GetEntityByID(effectEntityID)

    if select == false then
        if effectEntity then
            effectEntity:SetViewVisible(false)
        end
    else
        if not effectEntity then
            local bodyArea = entity:BodyArea():GetArea()
            local effectID = GameResourceConst.ChessPet_CanAction_Selected_SingleGridEffectID
            if table.count(bodyArea) == 4 then
                effectID = GameResourceConst.ChessPet_CanAction_Selected_MultiGridEffectID
            end

            ---@type Entity
            effectEntity = self._world:GetService("Effect"):CreateEffect(effectID, entity)
            chessPetRenderCmpt:SetSelectEffectEntityID(effectEntity:GetID())
        end
        effectEntity:SetViewVisible(true)
    end
end

--region 移动

---@param chessPetEntity Entity 棋子Entity
function ChessServiceRender:DoRenderChessPetPathMove(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChessPathComponent
    local renderChessPathComponent = renderBoardEntity:RenderChessPath()
    local chessPetEntityID = renderChessPathComponent:GetRenderChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)

    local walkResultList = renderChessPathComponent:GetRenderWalkResultList()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local moveSpeed = self:_GetMoveSpeed(chessPetEntity)

    ---走格子
    local hasWalkPoint = false
    if #walkResultList > 0 then
        hasWalkPoint = true
    end

    if hasWalkPoint then
        self:StartMoveAnimation(chessPetEntity, true)
        boardServiceRender:RefreshPiece(chessPetEntity, true, true)
    end

    for _, v in ipairs(walkResultList) do
        local walkRes = v
        local walkPos = walkRes:GetWalkPos()

        ---取当前的渲染坐标
        local curPos = boardServiceRender:GetRealEntityGridPos(chessPetEntity)

        chessPetEntity:AddGridMove(moveSpeed, walkPos, curPos)

        local walkDir = walkPos - curPos
        ---@type BodyAreaComponent
        local bodyAreaCmpt = chessPetEntity:BodyArea()
        local areaCount = bodyAreaCmpt:GetAreaCount()
        ---普攻阶段多格的只有四格，以后如果有别的，再处理
        if areaCount == 4 then
            ---取左下位置坐标
            local leftDownPos = Vector2(curPos.x - 0.5, curPos.y - 0.5)
            walkDir = walkPos - leftDownPos
        end

        chessPetEntity:SetDirection(walkDir)

        while chessPetEntity:HasGridMove() do
            YIELD(TT)
        end

        self:_PlayArrivePos(TT, chessPetEntity, walkRes)
    end

    if hasWalkPoint then
        self:StartMoveAnimation(chessPetEntity, false)
        boardServiceRender:RefreshPiece(chessPetEntity, false, true)
    end

    -- if casterIsDead then
    --     ---@type MonsterShowRenderService
    --     local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    --     sMonsterShowRender:_DoOneMonsterDead(TT, monsterEntity)
    -- end
end

---@param casterEntity Entity
function ChessServiceRender:_GetMoveSpeed(chessPetEntity)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local chessPetID = chessPetCmpt:GetChessPetID()

    local speed = chessPetConfigData:GetChessPetMoveSpeed(chessPetID)
    speed = speed or 1

    return speed
end

---@param targetEntity Entity
function ChessServiceRender:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({Move = isMove})
    end
end

---@param monsterEntity Entity
---@param walkRes MonsterWalkResult
function ChessServiceRender:_PlayArrivePos(TT, monsterEntity, walkRes)
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")
    ---触发机关的表现
    local trapResList = walkRes:GetWalkTrapResultList()
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

        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, monsterEntity)
    end

    local passGrids = walkRes:GetWalkPassedGrid()
end

--endregion 移动

--region 攻击

---攻击表现
function ChessServiceRender:DoRenderChessPetAttack(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChessPathComponent
    local renderChessPathComponent = renderBoardEntity:RenderChessPath()
    local chessPetEntityID = renderChessPathComponent:GetRenderChessPetEntityID()
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local attackSkill = chessPetCmpt:GetAttackSkillID()

    local configSvc = self._world:GetService("Config")
    local skillConfigData = configSvc:GetSkillConfigData(attackSkill, chessPetEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray()

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    -- playSkillService:_SkillRoutineTask(TT, chessPetEntity, skillPhaseArray, attackSkill)

    ---@type L2RActiveAttackResult
    local result = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ActiveAttack)
    local skillResult = result:GetSkillResult()

    chessPetEntity:SkillRoutine():ClearSkillRoutine()
    chessPetEntity:SkillRoutine():SetResultContainer(skillResult)

    --检查静帧

    --攻击前
    local ntChessPetSkillAttackStart = NTChessPetSkillAttackStart:New(chessPetEntity, attackSkill)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntChessPetSkillAttackStart)

    local waitTaskID = playSkillService:StartSkillRoutine(chessPetEntity, skillPhaseArray, attackSkill)

    --攻击后
    local ntChessPetSkillAttackEnd = NTChessPetSkillAttackEnd:New(chessPetEntity, attackSkill)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntChessPetSkillAttackEnd)

    return waitTaskID
end

--endregion 移动

---隐藏棋子身上的可行动特效
function ChessServiceRender:HdieChessPetCanMoveEffect(chessPetEntityID)
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)
    if not chessPetEntity then
        return
    end
    ---@type ChessPetRenderComponent
    local chessPetRenderCmpt = chessPetEntity:ChessPetRender()

    local effectEntityID = chessPetRenderCmpt:GetCanMoveEffectEntityID()
    local effectEntity = self._world:GetEntityByID(effectEntityID)

    if effectEntity then
        effectEntity:SetViewVisible(false)
    end
end

---打开棋子身上的可行动特效
function ChessServiceRender:ShowChessPetCanMoveEffect(chessPetEntityID)
    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)

    ---@type ChessPetComponent
    local chessPetRenderCmpt = chessPetEntity:ChessPetRender()

    local effectEntityID = chessPetRenderCmpt:GetCanMoveEffectEntityID()
    local effectEntity = self._world:GetEntityByID(effectEntityID)

    if not effectEntity then
        local bodyArea = chessPetEntity:BodyArea():GetArea()
        local effectID = GameResourceConst.ChessPet_CanAction_SingleGridEffectID
        if table.count(bodyArea) == 4 then
            effectID = GameResourceConst.ChessPet_CanAction_MultiGridEffectID
        end

        ---@type Entity
        effectEntity = self._world:GetService("Effect"):CreateEffect(effectID, chessPetEntity)
        chessPetRenderCmpt:SetCanMoveEffectEntityID(effectEntity:GetID())
    end
    effectEntity:SetViewVisible(true)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    --新的回合停止“行动结束”的材质动画，需要棋子身上没有跳过行动的buff
    if not utilDataSvc:OnCheckEntityHasBuffFlag(chessPetEntity, BuffFlags.SkipTurn) then
        ---@type MaterialAnimationComponent
        local matCmpt = chessPetEntity:MaterialAnimationComponent()
        --matCmpt:StopMaterialAnim(GameResourceConst.ChessPet_EndTurn_MaterialAnim)---貌似不生效
        matCmpt:StopAll()
    end
end

---隐藏所有棋子的可行动特效
function ChessServiceRender:HdieAllChessPetCanMoveEffect()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPetRender)
    for i, v in ipairs(group:GetEntities()) do
        self:HdieChessPetCanMoveEffect(v:GetID())
        ---@type MaterialAnimationComponent
        local matAnimCmpt = v:MaterialAnimationComponent()
        matAnimCmpt:PlayInvalid()
    end
end

---棋子死亡表现
function ChessServiceRender:DoChessPetListDeadRender(TT, deadEntityIDList)
    local deadTaskArray = {}
    for k, v in ipairs(deadEntityIDList) do
        ---@type Entity
        local deadEntity = self._world:GetEntityByID(v)

        local curDeadTaskID =
            TaskManager:GetInstance():CoreGameStartTask(self._DoOneChessPetDeadRender, self, deadEntity)
        deadTaskArray[#deadTaskArray + 1] = curDeadTaskID
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(deadTaskArray) do
        YIELD(TT)
    end
end

---棋子死亡表现
function ChessServiceRender:DoAllChessPetListDeadRender(TT)
    local monsterDeadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadFlag)
    if not monsterDeadGroup or table.count(monsterDeadGroup) <= 0 then
        return
    end

    local deadTaskArray = {}
    for _, e in ipairs(monsterDeadGroup:GetEntities()) do
        local curDeadTaskID = TaskManager:GetInstance():CoreGameStartTask(self._DoOneChessPetDeadRender, self, e)
        deadTaskArray[#deadTaskArray + 1] = curDeadTaskID
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(deadTaskArray) do
        YIELD(TT)
    end
end

---播放一个棋子的死亡表现
---@param deadEntity Entity
function ChessServiceRender:_DoOneChessPetDeadRender(TT, deadEntity)
    if deadEntity:HasShowDeath() then
        Log.fatal("entity has play dead")
        return
    end
    if deadEntity == nil or deadEntity:HasShowDeath() then ---如果已经处于死亡表现过程
        --Log.notice("MonsterDeath has begin")
        return
    end
    if not deadEntity:HasChessPet() then
        return
    end

    deadEntity:AddShowDeath() ---添加死亡过程标记状态
    deadEntity:AddDeadFlag()

    --血条
    deadEntity:ReplaceRedHPAndWhitHP(0)

    --死亡技能
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    if stateId ~= GameStateID.ChessPetResult then
        local deadSkillTaskID = self:_PlayDeadSkill(TT, deadEntity)
        if deadSkillTaskID then
            while not TaskHelper:GetInstance():IsTaskFinished(deadSkillTaskID) do
                YIELD(TT)
            end
        end
    end

    --删除怪物前，先删掉其身上挂的常驻特效
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    sEffect:DestroyStaticEffect(deadEntity)

    ---死亡动作和,音效,溶解特效
    self:_PlayDeathAnimationAudioEffect(deadEntity)

    YIELD(TT, 1000)

    --脚下格子动画，机关
    self:_PlayBodyAreaPieceTrap(TT, deadEntity)

    --血条
    self:_DestroyHpEntity(TT, deadEntity)

    --死亡触发通知
    ---@type PlayBuffService
    local sPlayBuff = self._world:GetService("PlayBuff")
    sPlayBuff:PlayBuffView(TT, NTChessDead:New(deadEntity))

    YIELD(TT, 2000)

    deadEntity:SetViewVisible(false)

    ---@type EffectService
    local fxsvc = self._world:GetService("Effect")
    --删除创建的特效
    fxsvc:ClearEntityEffect(deadEntity)

    ---@type ShowDeathComponent
    local showDeathCmpt = deadEntity:ShowDeath()
    showDeathCmpt:SetShowDeathEnd(true)
end

--播放死亡技能
function ChessServiceRender:_PlayDeadSkill(TT, deadEntity)
    ---@type ChessPetComponent
    local chessPetCmpt = deadEntity:ChessPet()
    local deadSkillTaskID = 0
    local deathSkillID = chessPetCmpt:GetDieSkillID()
    if deathSkillID and deathSkillID > 0 then --播死亡技
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        deadSkillTaskID = playSkillService:PlaySkillView(deadEntity, deathSkillID)
    end

    return deadSkillTaskID
end

---@param deadEntity Entity
---死亡动作和,音效,溶解特效
function ChessServiceRender:_PlayDeathAnimationAudioEffect(deadEntity)
    local deadTriggerParam = "Death"
    deadEntity:SetAnimatorControllerTriggers({deadTriggerParam})

    local deathAudioID = CriAudioIDConst.SouncCoreGameMonsterDeath
    AudioHelperController.PlayInnerGameSfx(deathAudioID)

    ---@type MaterialAnimationComponent
    local matAnimCmpt = deadEntity:MaterialAnimationComponent()
    if matAnimCmpt then
        matAnimCmpt:StopInvalid()
    end
    deadEntity:NewPlayDeadDark()
end

---脚下格子动画，机关
function ChessServiceRender:_PlayBodyAreaPieceTrap(TT, deadEntity)
    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curPos = boardServiceRender:GetRealEntityGridPos(deadEntity)
    --上面的显示坐标是模型中点有.5  ，要减去逻辑的偏移
    local workPos = curPos - deadEntity:GridLocation():GetGridOffset()
    local bodyArea = deadEntity:BodyArea():GetArea()
    local pieceService = self._world:GetService("Piece")

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(deadEntity)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    for _, p in ipairs(bodyArea) do
        local pos = workPos + p

        local curPieceAnim = pieceService:GetPieceAnimation(pos)
        if curPieceAnim == "Down" then
            pieceService:SetPieceAnimUp(pos) -- 脚底动画
        end

        sTrapRender:ShowHideTrapAtPos(pos, true) --显示机关(绷带剑盾)
    end
end

---清除血条
function ChessServiceRender:_DestroyHpEntity(TT, deadEntity)
    ---@type HPComponent
    local hpCmpt = deadEntity:HP()
    local sliderEntityID = hpCmpt:GetHPSliderEntityID()
    ---@type Entity
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    hpCmpt:WidgetPoolCleanup()
    self._world:DestroyEntity(sliderEntity)
    --清空buff图标
    local uiHpBuffInfoWidget = hpCmpt:GetUIHpBuffInfoWidget()
    if uiHpBuffInfoWidget then
        ---@type UIHPBuffInfo
        local uiHPBuffInfo = uiHpBuffInfoWidget:GetAllSpawnList()[1]
        uiHPBuffInfo:OnOnwerEntityDead()
    end
end

---显示当前已行动的棋子
function ChessServiceRender:ShowCurChessPetEndTurnEffect(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChessPathComponent
    local renderChessPathComponent = renderBoardEntity:RenderChessPath()
    local chessPetEntityID = renderChessPathComponent:GetRenderChessPetEntityID()

    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local finishTurn = chessPetCmpt:IsChessPetFinishTurn()
    if finishTurn then
        ---@type MaterialAnimationComponent
        local matAnimCmpt = chessPetEntity:MaterialAnimationComponent()
        matAnimCmpt:PlayInvalid()
    end
end
