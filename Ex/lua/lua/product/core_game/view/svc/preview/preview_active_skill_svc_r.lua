--[[------------------------------------------------------------------------------------------
    PreviewActiveSkillService 临时提供的一个预览Service ，后续可能会改掉
]] --------------------------------------------------------------------------------------------

_class("PreviewActiveSkillService", BaseService)
---@class PreviewActiveSkillService:BaseService
PreviewActiveSkillService = PreviewActiveSkillService

function PreviewActiveSkillService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

function PreviewActiveSkillService:Initialize()
    ---@type PieceServiceRender
    self._pieceService = self._world:GetService("Piece")
    self._pieceAnimFunc = {}
    self._pieceAnimFunc["Silver"] = self._pieceService.SetPieceAnimSliver
    self._pieceAnimFunc["Black"] = self._pieceService.SetPieceAnimBlack
    self._pieceAnimFunc["Gray"] = self._pieceService.SetPieceAnimGray
    self._pieceAnimFunc["Normal"] = self._pieceService.SetPieceAnimNormal
    self._pieceAnimFunc["Dark"] = self._pieceService.SetPieceAnimDark
    self._pieceAnimFunc["Add"] = self._pieceService.SetPieceAnimAdd
    self._pieceAnimFunc["Reflash"] = self._pieceService.SetPieceAnimReflash
    self._pieceAnimFunc["Invalid"] = self._pieceService.SetPieceAnimInvalid
end

function PreviewActiveSkillService:Dispose()
end

---终止所有主动技预览效果时的接口
---@param isSwitch boolean 是否切换主动技
function PreviewActiveSkillService:StopAllPreviewActiveSkillEffect(isSwitch, isCast)
    ---恢复所有转色的临时效果，转回原来的颜色
    self:_RevertAllConvertElement(true)
    ---恢复所有连线预览转色的临时效果，转回原来的颜色
    self:_RevertAllLinkLineConvertElement()
    self:RevertAllTransportGrid()
    ---重置预览索引，这个索引是为了让协程只做自己的事情
    self:ResetPreview()

    ---将所有黑色格子，还原成原来的颜色
    self:_RevertBright()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PetHidePreviewArrow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.Normal)
    ---@type GameStateID
    local curState = self:_GetCurState()

    ---切换主动技预览时，不需要切换主状态机状态
    if isCast ~= true and isSwitch ~= true and curState == GameStateID.PreviewActiveSkill then
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewActiveSkillFinish, 1)
        --self:_SendFSMFinishCommand(GameEventType.PreviewActiveSkillFinish, 1)
    end

    --取消波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    if self._world:MatchType() == MatchType.MT_BlackFist then
        flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.Pet):GetEntities()
    end
    for _, v in ipairs(flashEnemyEntities) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        if not comp then--查冒烟报错
            Log.error("StopAllPreviewActiveSkillEffect, flashEmemy no materialAnimationCmpt,entityID: ",v:GetID())
            if v:HasMonsterID() then
                local monsterID = v:MonsterID():GetMonsterID()
                Log.error("StopAllPreviewActiveSkillEffect, flashEmemy no materialAnimationCmpt,entityID: ",v:GetID(), " monsterID:",monsterID)
            end
            if v:HasTrapID() then
                local trapID = v:TrapID():GetTrapID()
                Log.error("StopAllPreviewActiveSkillEffect, flashEmemy no materialAnimationCmpt,entityID: ",v:GetID(), " trapID:",trapID)
            end
        else
            comp:StopLayer(MaterialAnimLayer.SkillPreview)
        end
        
        --if v:MaterialAnimationComponent():IsPlayingSelect() or v:MaterialAnimationComponent():IsPlayingAlpha() then
        --    comp:StopLayer(MaterialAnimLayer.SkillPreview)
        --end
    end

    --锁格子效果重置
    self:ResetLockGrids()
end

function PreviewActiveSkillService:_RevertAllLinkLineConvertElement()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return false
    end

    ---@type PreviewLinkLineService
    local linkLineService = self._world:GetService("PreviewLinkLine")
    --还原连线路径的格子颜色
    if #chainPath > 0 then
        linkLineService:CancelAllLinkPosPieceType(chainPath)
    end
end

function PreviewActiveSkillService:ResetLockGrids()
    --锁格子特效变化
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for i, e in ipairs(group:GetEntities()) do
        if not e:HasDeadFlag() and e:TrapRender():GetTrapRender_IsLockedGrid() then
            if e:View() then
                local go = e:View():GetGameObject()
                local u3dAnimCmpt = go:GetComponent(typeof(UnityEngine.Animation))
                if e:TrapID():GetTrapID() == BattleConst.LockGridTrapID then
                    u3dAnimCmpt:Play("eff_2000521_lock_reset01")
                else
                    u3dAnimCmpt:Play("eff_2000521_lock_reset")
                end
            end
        end
    end
end

function PreviewActiveSkillService:_GetCurState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    return utilDataSvc:GetCurMainStateID()
end

---立即结束暗屏效果
function PreviewActiveSkillService:StopDarkScreenImmediately()
    ---关闭相机暗屏机制
    self._world:MainCamera():EnableDarkCamera(false)

    ---将hud bg设置为0
    self._world:MainCamera():SetHudBgAlpha(0)
end

---TODO 改成用逻辑数据直接刷颜色
---转色预览效果，对应的星灵身上会有预览转色组件
---恢复每个人身上的转色临时效果，就是取出每个星灵身上的转色组件
---转换回原来的颜色
function PreviewActiveSkillService:_RevertAllConvertElement(isConvertToNormal)
    ---@type BoardServiceRender
    local boardService = self._world:GetService("BoardRender")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local convertElementGroup = self._world:GetGroup(self._world.BW_WEMatchers.PreviewConvertElement)
    local env = self._world:GetPreviewEntity():PreviewEnv()
    for _, actorEntity in ipairs(convertElementGroup:GetEntities()) do
        ---@type PreviewConvertElementComponent
        local previewConvertElementCmpt = actorEntity:PreviewConvertElement()
        if previewConvertElementCmpt then
            local tempConvertElementDic = previewConvertElementCmpt:GetTempConvertElementDic()
            for gridPos, originalElementType in pairs(tempConvertElementDic) do
                ---@type Entity
                local pieceEntity = renderBoardCmpt:GetGridRenderEntity(gridPos)
                local nowElementType = pieceEntity:Piece():GetPieceType()
                env:SetPieceType(gridPos,originalElementType)
                if nowElementType ~= originalElementType then
                    boardService:ReCreateGridEntity(originalElementType, gridPos, false)
                else
                    if isConvertToNormal then
                        pieceService:SetPieceEntityAnimNormal(pieceEntity)
                    else
                        pieceService:SetPieceEntityDark(pieceEntity)
                    end
                end
            end
            previewConvertElementCmpt:ClearTempConvertElement()
        end
    end

    self:ResetLockGrids()
end



function PreviewActiveSkillService:ResetPreview()
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity ~= nil then
        ---@type RenderStateComponent
        local renderState = previewEntity:RenderState()
        renderState:ResetPreviewRoutine()
    end
end

function PreviewActiveSkillService:GetPreviewIndex()
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity ~= nil then
        ---@type RenderStateComponent
        local renderState = previewEntity:RenderState()
        return renderState:GetPreviewRoutineIndex()
    end

    return 0
end

----------------新预览代码 上面的后面大部分会干掉-----
---设置格子压暗
function PreviewActiveSkillService:SetGridMask()
    self:AllPieceDoConvert("Dark")
end

----取消所有格子动画,恢复到最初始状态
function PreviewActiveSkillService:_RevertBright()
    self:AllPieceDoConvert("Normal")
end

---@param scopeParam SkillPreviewScopeParam
function PreviewActiveSkillService:PreviewScopeSenityCheck(scopeParam)
    local scopeType = scopeParam:GetScopeType()
    if (scopeType == SkillScopeType.EmptyRandGrid or
            scopeType == SkillScopeType.RandomRectAndCount or
            scopeType == SkillScopeType.RandomGrids or
            scopeType == SkillScopeType.RandomGridsAndTypeSize or
            scopeType == SkillScopeType.MultiRandomRange or
            scopeType == SkillScopeType.RandomPosEmptyOrTrap or
            scopeType == SkillScopeType.RandomGridsByPieceType)
    then
        return false, string.format("cannot preview randomized scope: %s", tostring(scopeType))
    end

    return true
end

---计算技能预览的范围
---@param scopeParam SkillPreviewScopeParam
---@return SkillScopeResult
function PreviewActiveSkillService:CalcScopeResult(scopeParam, casterEntity)
    local isSenitySafe, errorMsg = self:PreviewScopeSenityCheck(scopeParam)
    if not isSenitySafe then
        Log.exception(self._className, errorMsg)
        return
    end

    local casterPos = casterEntity:GridLocation():CenterNoOffset()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSKillPreviewScopeResult(scopeParam, casterPos, casterEntity)
    ---暂时只取有效范围
    return scopeResult
end

function PreviewActiveSkillService:AllPieceDoConvert(type)
    ---@type  PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieceTable = env:GetAllPieceType()
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    for x, columnDic in pairs(pieceTable) do
        for y, curGridType in pairs(columnDic) do
            local curGridPos = Vector2(x, y)
            local func = self._pieceAnimFunc[type]
            if func then
                func(self._pieceService, curGridPos, curGridType)

                --处理十字棱镜特效
                trapServiceRender:OnPlayPreviewPrismEffectTrapAnim(curGridPos, curGridType, type)
            end
        end
    end
end

function PreviewActiveSkillService:DoAnim(brightGridList, brightType)
    local brightFunc = self._pieceAnimFunc[brightType]
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    for _, pos in pairs(brightGridList) do
        if brightFunc then
            brightFunc(self._pieceService, pos)

            --处理十字棱镜特效
            trapServiceRender:OnPlayPreviewPrismEffectTrapAnim(pos, nil, brightType)
        end
    end
end
---只是播动画
function PreviewActiveSkillService:DoConvert(brightGridList, brightType, otherGirdType)
    ---@type  PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieceTable = env:GetAllPieceType()
    local brightFunc = self._pieceAnimFunc[brightType]
    local otherFunc = self._pieceAnimFunc[otherGirdType]
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    if otherFunc then
        for x, columnDic in pairs(pieceTable) do
            for y, curGridType in pairs(columnDic) do
                local curGridPos = Vector2(x, y)
                local isBright = table.Vector2Include(brightGridList, curGridPos)
                if isBright then
                    if brightFunc then
                        brightFunc(self._pieceService, curGridPos)
                    end
                else
                    if otherFunc then
                        otherFunc(self._pieceService, curGridPos)
                    end
                end

                --处理十字棱镜特效
                local pieceAnim = isBright and brightType or otherGirdType
                trapServiceRender:OnPlayPreviewPrismEffectTrapAnim(curGridPos, curGridType, pieceAnim)
            end
        end
    else
        self:DoAnim(brightGridList, brightType)
    end
end

---@return SkillPreviewContext
---@param skillPreviewConfigData SkillPreviewConfigData
---@param scopePosList Vector2[] 一个外部范围 如果有值就使用这个范围不需要自己重新计算
function PreviewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, casterEntity, pickUpPos, scopePosList)
    ---@type SkillPreviewContext
    local previewContext = SkillPreviewContext:New(self._world, casterEntity)
    previewContext:SetConfigData(skillPreviewConfigData)
    ---@type SkillPreviewScopeParam
    local scopeParam = skillPreviewConfigData:GetPreviewScopeParam()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult
    if scopePosList then
        previewContext:SetScopeResult(scopePosList)
        scopeResult = SkillScopeResult:New(SkillScopeType.CenterPos, scopePosList[1], scopePosList, scopePosList)
    else
        scopeResult = previewActiveSkillService:CalcScopeResult(scopeParam, casterEntity)
        previewContext:SetScopeResult(scopeResult:GetAttackRange())
        local scopeResultCenterPos = scopeResult:GetCenterPos()
        if scopeResultCenterPos then
            previewContext:SetScopeCenterPos(scopeResultCenterPos)
        end
    end

    previewContext:SetPickUpPos(pickUpPos)
    local targetIDList = utilScopeSvc:SelectSkillTarget(
        casterEntity, scopeParam:GetScopeTargetType(), scopeResult,nil,scopeParam:GetScopeTargetTypeParam())
    for i = 1, #targetIDList do
        local e = self._world:GetEntityByID(targetIDList[i])
        if e:HasTeam() then
            e = e:GetTeamLeaderPetEntity()
            targetIDList[i] = e:GetID()
        end
    end
    previewContext:SetTargetEntityIDList(targetIDList)

    local effectList = skillPreviewConfigData:GetPreviewEffectList()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService = self._world:GetService("PreviewCalcEffect")

    for _, v in pairs(effectList) do
        ---@type SkillEffectParamBase
        local effectParam = previewEffectCalcService:CreateSkillEffectParam(v.effectType, v)
        previewContext:SetEffectParam(v.effectType, effectParam)
    end

    previewContext:SetEffectList(skillPreviewConfigData:GetPreviewEffectList())
    previewContext:SetPreviewIndex(self:GetPreviewIndex())
    return previewContext
end

---@param previewContext SkillPreviewContext
function PreviewActiveSkillService:DoPreviewInstruction(TT, instructionSet, casterEntity, previewContext)
    local insIndex = 1
    local insSetCount = table.count(instructionSet)
    while insIndex > 0 and insIndex <= insSetCount do
        ---@type BaseInstruction
        local instruction = instructionSet[insIndex]

        --Log.fatal("instruction start:",instruction._className)
        local needBreak = instruction:DoInstruction(TT, casterEntity, previewContext)
        if needBreak then
            break
        else
            insIndex = insIndex + 1
        end
    end
end


---对目标格子执行转色
---@param targetElementType ElementType
function PreviewActiveSkillService:DoConvertElement(
    TT,
    targetGridPosArray,
    targetElementType,
    actorEntity,
    blockedPieces)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = actorEntity:PreviewConvertElement()
    ---TODO 把这个组件干掉
    if not previewConvertElementCmpt then
        actorEntity:AddPreviewConvertElement()
        previewConvertElementCmpt = actorEntity:PreviewConvertElement()
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    local needRecreateList = {}
    for _, gridPos in ipairs(targetGridPosArray) do
        local originalElementType = utilData:FindPieceElement(gridPos)
        previewConvertElementCmpt:AddTempConvertElement(gridPos, originalElementType)
        --if targetElementType ~= originalElementType then
        --    table.insert(needRecreateList,gridPos)
        --end

        local entity = self:_ReplaceGridRes(targetElementType, gridPos)
        table.insert(needRecreateList, { entity = entity, pos = gridPos })
    end
    local oldPreviewIndex = self:GetPreviewIndex()
    -- 等待一帧是为了让转色Color的Ani加载完成，避免卡莲转色Ani播放不完整
    YIELD(TT)
    local newPreviewIndex = self:GetPreviewIndex()
    if oldPreviewIndex ~= newPreviewIndex then
        -- 由于已经切换预览，需要回滚上面的操作
        for _, v in ipairs(needRecreateList) do
            self._world:DestroyEntity(v.entity)
        end

        Log.fatal("preview active skill failed ")
        return
    end
    for i, v in ipairs(needRecreateList) do
        local sourceEntity = pieceService:FindPieceEntity(v.pos)
        self._world:DestroyEntity(sourceEntity)
        v.entity:SetLocationHeight(0)
        renderBoardCmpt:SetGridRenderEntityData(v.pos, v.entity)
        pieceService:SetPieceAnimColor(v.pos)
		
        --处理十字棱镜特效
        trapServiceRender:OnClosePreviewPrismEffectTrap(v.pos)
    end

    --锁格子动画
    if blockedPieces then
        for _, gridPos in ipairs(blockedPieces) do
            local es = env:GetEntitiesAtPos(
                gridPos,
                function(e)
                    return e:TrapRender() and e:TrapRender():GetTrapRender_IsLockedGrid()
                end
            )
            local lockGridTrap = es[1]
            if lockGridTrap then
                local go = lockGridTrap:View():GetGameObject()
                local u3dAnimCmpt = go:GetComponent(typeof(UnityEngine.Animation))
                if lockGridTrap:TrapID():GetTrapID() == BattleConst.LockGridTrapID then
                    u3dAnimCmpt:Play("eff_2000521_lock_red01")
                else
                    u3dAnimCmpt:Play("eff_2000521_lock_red")
                end
            end
        end
    end
end

----@param elementType PieceType
----@param gridPos Vector2
function PreviewActiveSkillService:_ReplaceGridRes(elementType, gridPos,anim)
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local gridEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.Grid)
    local gridPrefabPath = boardServiceR:_GetGridPrefabPath(elementType)
    gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath, true))
    gridEntity:ReplacePiece(elementType)
    gridEntity:SetGridPosition(gridPos)
    gridEntity:SetLocation(gridPos)
    --gridEntity:SetLocationHeight((BattleConst.CacheHeight))
    if not anim then
        pieceSvc:SetPieceEntityDark(gridEntity)
    else
        pieceSvc:_PlayGridAnimation(gridEntity,anim)
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    gridEntity:AddReplaceMaterialComponent(gridMatPath)

    Log.debug("_ReplaceGridRes gridPos=", Vector2.Pos2Index(gridPos), " pieceType=", elementType)

    return gridEntity
end

function PreviewActiveSkillService:_CreatePickUpArrow(pos, dir, forceShow, centerPos)
    local arrowPos = pos + centerPos

    if not forceShow then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        if not utilDataSvc:IsValidPiecePos(arrowPos) then
            return
        end
    end

    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    ---@type Entity
    local arrowEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.PickUpArrow)
    arrowEntity:SetLocation(arrowPos, dir)
    return arrowEntity
end
---@param type ShowArrowType
function PreviewActiveSkillService:ShowPickUpArrowByType(type,forceShow, centerPos)
    local dirIndex
    if type == ShowArrowType.LeftAndRight then
        dirIndex={3,7}
    elseif type == ShowArrowType.UpAndDown then
        dirIndex={1,5}
    elseif type == ShowArrowType.Four then
        dirIndex={ 1, 3, 5, 7 }
    end
    self:ShowPickUpArrow(dirIndex, forceShow, centerPos)
end

function PreviewActiveSkillService:ShowDynamicPickUpArrow(dirIndexs, forceShow, centerPos)
    self:ShowPickUpArrow(dirIndexs, forceShow, centerPos)
end

function PreviewActiveSkillService:ShowFourPickUpArrow(forceShow, centerPos)
    self:ShowPickUpArrow({ 1, 3, 5, 7 }, forceShow, centerPos)
end

function PreviewActiveSkillService:ShowEightPickUpArrow(forceShow, centerPos)
    self:ShowPickUpArrow({ 1, 2, 3, 4, 5, 6, 7, 8 }, forceShow, centerPos)
end

PreviewActiveSkillService.__DirectionalVector = {
    [1] = Vector2.up,
    [2] = Vector2.New(1, 1),
    [3] = Vector2.right,
    [4] = Vector2.New(1, -1),
    [5] = Vector2.down,
    [6] = Vector2.New(-1, -1),
    [7] = Vector2.left,
    [8] = Vector2.New(-1, 1)
}

function PreviewActiveSkillService:ShowPickUpArrow(tDirectionIndex, forceShow, centerPos)
    for _, dirIndex in ipairs(tDirectionIndex) do
        local v2 = PreviewActiveSkillService.__DirectionalVector[dirIndex]
        --Log.error(self._className, tostring(v2), tostring(v2), tostring(forceShow))
        self:_CreatePickUpArrow(v2, v2, forceShow, centerPos)
    end
end

function PreviewActiveSkillService:DestroyPickUpArrow()
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        self._world:DestroyEntity(e)
    end
end

function PreviewActiveSkillService:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
    if self:_GetCurState() == GameStateID.PreviewActiveSkill then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.PickUPInvalidGridCancelActiveSkill)
        GameGlobal.TaskManager():CoreGameStartTask(self.CancelActiveSkillCast, self, activeSkillID, petPstID, true)
    end
end

function PreviewActiveSkillService:CancelActiveSkillCast(TT, activeSkillID, petPstID, nocmd)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local nTaskID = self:PlaySkillView_Preview(self._world, activeSkillID, petPstID, false)

    self:_StopPreviewActiveSkill(false, false, activeSkillID, petPstID)

    --清除预览主动技阶段的连线
    self:ClearPreviewLinkLine(activeSkillID, petPstID)

    while not playSkillService:IsTaskFinished(nTaskID) do
        YIELD(TT)
    end

    --终止预览时，格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
    ---@type Entity
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    playSkillService:ShowPlayerEntity(teamEntity)

    if not nocmd then
        self:_ClearAllPickUpComponent(petPstID)
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 1)
    end
end

function PreviewActiveSkillService:ClearPreviewLinkLine(activeSkillID, petPstID)
    if not activeSkillID or not petPstID then
        return
    end
    
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityId)

    ---@type SkillConfigData
    local skillCfgData = self._configService:GetSkillConfigData(activeSkillID, petEntity)
    if not skillCfgData then
        return
    end

    ---@type SkillPickUpType
    local pickUpType = skillCfgData:GetSkillPickType()
    if pickUpType == SkillPickUpType.LinkLine then
        self._world:EventDispatcher():Dispatch(GameEventType.CancelChainPath)

        ---@type InputComponent
        local inputCmpt = self._world:Input()
        inputCmpt:SetPreviewActiveSkill(false)
    end
end

function PreviewActiveSkillService:_ClearAllPickUpComponent(petPstID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local casterPetEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    if casterPetEntityID < 0 then
        Log.fatal("caster entity id invalid")
        return
    end

    local petEntity = self._world:GetEntityByID(casterPetEntityID)
    petEntity:RemovePreviewPickUpComponent()
end

function PreviewActiveSkillService:_StopPreviewActiveSkill(isSwitch, bShowPlayerEntity, activeSkillID, petPstID)
    if isSwitch ~= true then
        self:StopDarkScreenImmediately()
    end

    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    GameGlobal.TaskManager():CoreGameStartTask(self.DoCancelPreviewInstruction, self, activeSkillID, petPstID)
    -- if isSwitch ~= true then
    if bShowPlayerEntity then
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        ---@type Entity
        local teamEntity = self._world:Player():GetPreviewTeamEntity()
        playSkillService:ShowPlayerEntity(teamEntity)
    end

    self:_DestroyPickUpArrow()

    --取消波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    if self._world:MatchType() == MatchType.MT_BlackFist then
        flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.Pet):GetEntities()
    end
    for _, v in ipairs(flashEnemyEntities) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        if comp then 
            comp:StopLayer(MaterialAnimLayer.SkillPreview)
        end
    end

    self:ResetPreview()
    self:_ClearPreviewActiveSkill(isSwitch)
end

function PreviewActiveSkillService:_DestroyPickUpArrow()
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        self._world:DestroyEntity(e)
    end
end

---@param isSwitch bool 是否切换主动技
function PreviewActiveSkillService:_ClearPreviewActiveSkill(isSwitch, isCast)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.PreviewActiveSkill)
    local targetEntity = nil
    for _, entity in ipairs(group:GetEntities()) do
        targetEntity = entity
        entity:RemovePreviewActiveSkill()
        --Log.fatal("_ClearPreviewActiveSkill",UnityEngine.Time.frameCount)
    end
    self:StopAllPreviewActiveSkillEffect(isSwitch, isCast)

    ---清理点选信息
    ---@type PickUpComponent
    local worldPickUpCmpt = self._world:PickUp()
    worldPickUpCmpt:ResetPickUpData()
end

function PreviewActiveSkillService:DoCancelPreviewInstruction(TT, activeSkillID, petPstID)
    if not activeSkillID or not petPstID then
        return
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityId)
    if not petEntity then
        ---施法者并非光灵时
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        local entityID = pickUpTargetCmpt:GetEntityID()
        petEntity = self._world:GetEntityByID(entityID)
    end    
    
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID, petEntity)
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for _, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in pairs(instructionParam._previewList) do
                local instructionSet = skillPreviewConfigData:GetCancelPreviewInstructionSet()
                if instructionSet then
                    local previewContext = previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData,
                        petEntity)
                    local taskID = GameGlobal.TaskManager():CoreGameStartTask(
                        previewActiveSkillService.DoPreviewInstruction,
                        previewActiveSkillService,
                        instructionSet,
                        petEntity,
                        previewContext
                    )
                    table.insert(taskIDList, taskID)
                end
            end
        end
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

----END------------

----怪物和机关部分----
---@param skillConfigData SkillConfigData
function PreviewActiveSkillService:_ShowSkillTips(skillConfigData)
    local skillName = skillConfigData:GetSkillName()
    local skillDesc = skillConfigData:GetSkillDesc()

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type RenderStateComponent
    local renderStatCmpt = previewEntity:RenderState()

    local skillTipsEntityID = renderStatCmpt:GetSkillTipsEntityID()
    local skillTipsEntity = nil
    if skillTipsEntityID == -1 then
        --如果还没有，就创建出来

        ---@type RenderEntityService
        local sEntity = self._world:GetService("RenderEntity")
        skillTipsEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.SkillTips)
        skillTipsEntity:SetOwnerWorld(self._world)

        skillTipsEntityID = skillTipsEntity:GetID()
        renderStatCmpt:SetSkillTipsEntityID(skillTipsEntityID)
    else
        skillTipsEntity = self._world:GetEntityByID(skillTipsEntityID)
    end
    skillTipsEntity:SetViewVisible(true)
    Log.debug("Preview SetViewVisible True EntityID:", skillTipsEntityID)
    ---@type SkillTipsComponent
    local skillTips = skillTipsEntity:SkillTips()
    ---通知view更新
    skillTipsEntity:ReplaceSkillTips(skillName, skillDesc)
    Log.debug("[Preview] 预览怪物技能： 技能标签<" .. skillConfigData:GetSkillName() .. ">")
end

function PreviewActiveSkillService:HideSkillTips()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type RenderStateComponent
    local renderStatCmpt = previewEntity:RenderState()

    local skillTipsEntityID = renderStatCmpt:GetSkillTipsEntityID()
    if skillTipsEntityID ~= -1 then
        local skillTipsEntity = self._world:GetEntityByID(skillTipsEntityID)
        skillTipsEntity:SetViewVisible(false)
        --Log.debug("Preview SetViewVisible False EntityID:",skillTipsEntityID)
    end
end

function PreviewActiveSkillService:_ShowDescTips(trapName, trapDesc)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type RenderStateComponent
    local renderStatCmpt = previewEntity:RenderState()

    local skillTipsEntityID = renderStatCmpt:GetSkillTipsEntityID()
    local skillTipsEntity = nil
    if skillTipsEntityID == -1 then
        --如果还没有，就创建出来
        ---@type RenderEntityService
        local sEntity = self._world:GetService("RenderEntity")
        skillTipsEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.SkillTips)
        skillTipsEntity:SetOwnerWorld(self._world)

        skillTipsEntityID = skillTipsEntity:GetID()
        renderStatCmpt:SetSkillTipsEntityID(skillTipsEntityID)
    else
        skillTipsEntity = self._world:GetEntityByID(skillTipsEntityID)
    end
    skillTipsEntity:SetViewVisible(true)
    Log.debug("Preview SetViewVisible True EntityID:", skillTipsEntityID)

    ---通知view更新
    skillTipsEntity:ReplaceSkillTips(trapName, trapDesc)
    ---@type SkillTipsComponent
    local skillTips = skillTipsEntity:SkillTips()
    skillTips:SetTrapDesc(true)
end

--region Logic
---拿到可以连锁的宝宝
function PreviewActiveSkillService:GetChianAttackPetIds()
    local pets = {}
    local skillIds = {}
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()
    local chainPath = renderBoardEntity:RenderChainPath():GetRenderChainPath()
    --容错，可能不是连线到任意门，如主动技位移
    if not chainPath then
        return pets, skillIds
    end
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---这个就是连线数
    local chainCount, superGridNum = utilCalcSvc:GetChainDamageRateAtIndex(chainPath, #chainPath)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if petRoundTeam and table.count(petRoundTeam) > 0 then
        for _, eId in ipairs(petRoundTeam) do
            local e = self._world:GetEntityByID(eId)
            local chainCountFix = e:RenderAttributes():GetAttribute("ChainSkillReleaseFix") or 0
            local chainCountMul = e:RenderAttributes():GetAttribute("ChainSkillReleaseMul") or 0
            local chainExtraFix = utilData:GetEntityBuffValue(e, "ChangeExtraChainSkillReleaseFixForSkill")
            local finalChainCount = math.ceil((chainCount + chainCountFix) * (1 + chainCountMul))
            local chainSkillID = e:SkillInfo():GetChainSkillConfigID(finalChainCount, chainExtraFix)
            if chainSkillID and chainSkillID > 0 then
                table.insert(pets, eId)
                table.insert(skillIds, chainSkillID)
            end
        end
    end
    return pets, skillIds
end

--endregion

---激活相机暗屏机制
function PreviewActiveSkillService:StartPreviewFocusEffect()
    local cMainCamera = self._world:MainCamera()
    cMainCamera:EnableDarkCamera(true)
    local targetAlpha = BattleConst.ActiveSkillDarkAlpha
    cMainCamera:SetHudBgAlpha(targetAlpha)
end

---停止预览连锁技
function PreviewActiveSkillService:StopPreviewChainSkill(TT)
    ---@type PreviewActiveSkillService
    local sPreviewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type PlaySkillService
    local sPlaySkill = self._world:GetService("PlaySkill")
    sPreviewActiveSkill:StopDarkScreenImmediately()
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    ---@type Entity
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    sPlaySkill:ShowPlayerEntity(teamEntity)
    --取消波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    for _, v in ipairs(flashEnemyEntities) do
        local cMaterialAnimationComponent = v:MaterialAnimationComponent()
        if cMaterialAnimationComponent then 
            cMaterialAnimationComponent:StopLayer(MaterialAnimLayer.SkillPreview)
        end
    end
    ---拾取结束
    local casterEntity = teamEntity:GetTeamLeaderPetEntity()
    local skillPreviewParamInstruction = SkillPreviewParamInstruction:New({})
    local instructionSet = skillPreviewParamInstruction:_ParseInstructionSet(BattleConst.DimensionPreviewInstructionSetIdFinish)
    if instructionSet then
        local previewContext = SkillPreviewContext:New(self._world, casterEntity)
        sPreviewActiveSkill:DoPreviewInstruction(TT, instructionSet, casterEntity, previewContext)
    end
    sPreviewActiveSkill:ResetPreview()

    self._world:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyPreview, {
        shutdown = true
    })
end

function PreviewActiveSkillService:ClearChainPreviewData()
    --重置ReplacePreviewChainSkill组件
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewChainSkill()
end

---@param previewPickUpComponent PreviewPickUpComponent
function PreviewActiveSkillService:UpdateUI(pickUpNum, mustPickUpNum, previewPickUpComponent)
    local leftPickUpNumber = pickUpNum - previewPickUpComponent:GetAllValidPickUpGridPosCount()
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
    if leftPickUpNumber < 0 then
        Log.fatal("leftPickUpNumber <=0 number:", leftPickUpNumber)
        leftPickUpNumber = 0
    end
    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, leftPickUpNumber)
    ---配置了必须点数量的要点够数量才能释放主动技
    if mustPickUpNum then
        ---没有配置的 只要点了就能放
        if pickUpCount == mustPickUpNum then
            self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
            return
        end
    elseif pickUpCount ~= 0 then
        self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
        return
    end
    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)

    --if leftPickUpNumber ~= pickUpNum then
    --    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
    --else
    --    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)
    --end
end

---@param pickUpGirdPos Vector2
function PreviewActiveSkillService:_DoPickUpInstruction(TT, type, skillConfigData, casterEntity, pickUpGirdPos)
    ---@type number[]
    local taskIDList = {}
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for i, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in ipairs(instructionParam._previewList) do
                local instructionSet = self:_GetInstructSet(type, skillPreviewConfigData)
                if instructionSet then
                    ---@type SkillPreviewContext
                    local previewContext = self:_GetPreviewContext(
                        type,
                        skillPreviewConfigData,
                        casterEntity,
                        skillPreviewConfigData:GetID(),
                        pickUpGirdPos
                    )
                    local taskID = GameGlobal.TaskManager():CoreGameStartTask(
                        previewActiveSkillService.DoPreviewInstruction,
                        previewActiveSkillService,
                        instructionSet,
                        casterEntity,
                        previewContext
                    )
                    table.insert(taskIDList, taskID)
                end
            end
        end
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function PreviewActiveSkillService:_GetPreviewContext(type, skillPreviewConfigData, casterEntity, id, pickUpGridPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local context = previewPickUpComponent:GetPreviewContext(id)
    if not context then
        if type == PickUpInstructionType.Invalid then
            context = self:CreatePreviewContext(skillPreviewConfigData, casterEntity, pickUpGridPos, { pickUpGridPos })
        else
            context = self:CreatePreviewContext(skillPreviewConfigData, casterEntity, pickUpGridPos)
        end
    end
    return context
end

---@param skillPreviewConfigData SkillPreviewConfigData
function PreviewActiveSkillService:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end

    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end

    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

---@param petPstId number 宠物PstID
---@param playOrCancel bool 播放还是取消
---播放主动技预览动作
function PreviewActiveSkillService:PlaySkillView_Preview(world, nSkillID, petPstId, bStart)
    bStart = bStart or false
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstId)
    ---@type Entity
    local petEntity = world:GetEntityByID(petEntityId)
    ---@type TaskManager
    local taskManager = GameGlobal.TaskManager()
    local nTaskID = taskManager:CoreGameStartTask(self._PlayActiveSkillPreviewAction, self, world, nSkillID, petEntity,
        bStart)
    return nTaskID
end

---@param entityCaster Entity
function PreviewActiveSkillService:_PlayActiveSkillPreviewAction(TT, world, nSkillID, entityCaster, bStart)
    if nil == entityCaster then
        return
    end

    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(nSkillID, entityCaster)
    local previewParam = skillConfigData:GetSkillPreviewParam()
    local paramType = 0
    if previewParam and type(previewParam) == "table" then
        paramType = previewParam.type or 0
    end

    if 1 == paramType then
        local nWorkViewID = 0
        if bStart then
            nWorkViewID = previewParam[1]
        else
            nWorkViewID = previewParam[2]
        end
        --技能演播
        local skillPhaseArray = skillConfigData:ParseViewID(nWorkViewID)
        if table.count(skillPhaseArray) > 0 then
            local waitTaskID = self:StartSkillRoutine(entityCaster, skillPhaseArray, nSkillID)
            while not self:IsTaskFinished(waitTaskID) do
                YIELD(TT)
            end
        end
    else
        local animTrigger
        if bStart then
            animTrigger = "AtkUltPreview"
        else
            animTrigger = "AtkUltPreviewCancel"
        end
        self:PlayCasterPreviewAnim(entityCaster, bStart, animTrigger)
    end
end

function PreviewActiveSkillService:ResetCasterPreviewAnimTrigger(casterEntity, isPreview)
    ---@type UnityEngine.GameObject
    local csGo = casterEntity:View().ViewWrapper.GameObject
    local csTransformRoot = csGo.transform:Find("Root")
    if not csTransformRoot then
        return
    end
    
    ---@type UnityEngine.Animator
    local csAnimator = csTransformRoot:GetComponent("Animator")
    if not csAnimator then
        return
    end

    local resetTrigger
    if isPreview then
        resetTrigger = "AtkUltPreviewCancel"
    else
        resetTrigger = "AtkUltPreview"
    end
    csAnimator:ResetTrigger(resetTrigger)
end

function PreviewActiveSkillService:PlayCasterPreviewAnim(casterEntity,bStart,animTrigger)
    casterEntity:SetAnimatorControllerTriggers({ animTrigger })
    --[[
        1.在设置预览动作之前，可能因为其他输入的原因(双主动技光灵，频繁点击技能图标，切换技能预览）
        这个角色会被重复设置"AtkUltPreviewCancel" trigger
        但此时角色可能处于idle状态
        这种情况下，预览设置后，会从AtkUltPreview重新进入idle状态
        因此在这里加入下面的代码，当预览取消时，一并重置"AtkUltPreviewCancel"

        2.在取消预览动作之前，可能因为其他输入的原因(频繁点击头像或其他原因)
        这个角色会被重复设置"AtkUltPreview" trigger
        但此时角色可能处于预览静止状态（默认状态机为"atkult_preview_idle"状态）
        这种情况下，预览取消后，会从idle重新进入AtkUltPreview状态
        因此在这里加入下面的代码，当预览取消时，一并重置"AtkUltPreview"
    ]]
    self:ResetCasterPreviewAnimTrigger(casterEntity, bStart)
end

---@param entityCaster Entity
function PreviewActiveSkillService:StartSkillRoutine(entityCaster, skillPhaseArray, nSkillID)
    return self._world:GetService("PlaySkill"):StartSkillRoutine(entityCaster, skillPhaseArray, nSkillID)
end

function PreviewActiveSkillService:IsTaskFinished(waitTaskID)
    return self._world:GetService("PlaySkill"):IsTaskFinished(waitTaskID)
end

function PreviewActiveSkillService:CommonSkillPreview(TT, casterEntity, skillID, previewSetID)
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, casterEntity)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")

    local skillPreviewParamInstruction = SkillPreviewParamInstruction:New({})
    local instructionSetID = previewSetID
    if not instructionSetID then
        Log.exception("SkillID:", skillID, "PreviewType :", previewSetID, "Invalid ")
        return
    end
    local instructionSet   = skillPreviewParamInstruction:_ParseInstructionSet(instructionSetID)
    ----@type SkillPreviewContext
    local previewContext   = SkillPreviewContext:New(self._world, casterEntity)
    local skillEffectArray = skillConfigData:GetSkillSourceEffectTable() -- svcCfgDeco:GetLatestEffectParamArray(casterEntity:GetID(), activeSkillID)
    previewContext:SetEffectList(skillEffectArray) --设置效果列表，即为技能表的效果列表

    ---技能范围
    local targetType = skillConfigData:GetSkillTargetType()
    local targetTypeParam = skillConfigData:GetSkillTargetTypeParam()
    local scopeParam =
    SkillPreviewScopeParam:New(
        {
            TargetType = targetType,
            ScopeType = skillConfigData:GetSkillScopeType(),
            ScopeCenterType = skillConfigData:GetSkillScopeCenterType(),
            TargetTypeParam = targetTypeParam
        }
    )
    scopeParam:SetScopeParamData(skillConfigData:GetSkillScopeParam())
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcScopeResult(scopeParam, casterEntity)
    previewContext:SetScopeResult(scopeResult:GetAttackRange())
    previewContext:SetScopeType(scopeResult:GetScopeType())
    previewContext:SetScopeCenterPos(scopeResult:GetCenterPos())
    ---目标
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, scopeResult, skillID, targetTypeParam)
    previewContext:SetTargetEntityIDList(targetIDList)
    local previewIndex = self:GetPreviewIndex()
    previewContext:SetPreviewIndex(previewIndex)
    if instructionSet then
        local taskID = GameGlobal.TaskManager():CoreGameStartTask(
            previewActiveSkillService.DoPreviewInstruction,
            previewActiveSkillService,
            instructionSet,
            casterEntity,
            previewContext
        )
        table.insert(taskIDList, taskID)
    end


    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        local curPreviewIndex = self:GetPreviewIndex()
        if curPreviewIndex ~= previewIndex then

        end
        YIELD(TT)
    end
end

---@param result SkillEffectResultTransportByRange
---@param casterEntity Entity
function PreviewActiveSkillService:PlayTransportPreview(TT,casterEntity,result)
    if not casterEntity:HasPreviewConvertElement() then
        casterEntity:AddPreviewConvertElement()
    end
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = casterEntity:PreviewConvertElement()
    ---@type TransportByRangePieceData[]
    local pieceDataList = result:GetPieceDataList()
    ---@type PieceServiceRender
    local pieceSvc= self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    for _, data in ipairs(pieceDataList) do
        local sourcePieceEntity = pieceSvc:FindPieceEntity(data:GetPiecePos())
        sourcePieceEntity:SetLocationHeight(1000)
        pieceSvc:_PlayGridAnimation(sourcePieceEntity,"Normal")
        ---pieceSvc:_PlayGridAnimation(sourcePieceEntity,"Dark")
        ---@type Entity
        local entity = self:_ReplaceGridRes(data:GetPieceType(),data:GetPiecePos(),"Normal")
        entity:SetLocationHeight(0)
        pieceSvc:_PlayGridAnimationNoEffect(entity,"Normal")
        if not  utilDataSvc:IsValidPiecePos(data:GetNextPos()) then
            pieceSvc:SetPieceShowRange(entity,data:GetPiecePos())
        end
        local dis = Vector2.Distance(data:GetNextPos(), data:GetPiecePos())
        entity:AddGridMove(BattleConst.PreviewConveySpeed*dis, data:GetNextPos(), data:GetPiecePos())
        previewConvertElementCmpt:AddPreviewTransportEntity(entity,sourcePieceEntity)
        trapServiceRender:OnClosePreviewPrismEffectTrap(data:GetPiecePos())
    end
    local targetID,targetPos,targetNextPos = result:GetTargetData()
    if targetID then
        local targetEntity= self._world:GetEntityByID(targetID)
        ---@type RenderEntityService
        local entitySvc = self._world:GetService("RenderEntity")
        local ghostEntity = entitySvc:CreateGhost(targetPos, targetEntity)
        ghostEntity:AddGridMove(BattleConst.PreviewConveySpeed,targetNextPos, targetPos)
    end
end

function PreviewActiveSkillService:RevertAllTransportGrid()
    ---@type BoardServiceRender
    local boardService = self._world:GetService("BoardRender")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local convertElementGroup = self._world:GetGroup(self._world.BW_WEMatchers.PreviewConvertElement)
    for _, actorEntity in ipairs(convertElementGroup:GetEntities()) do
        ---@type PreviewConvertElementComponent
        local previewConvertElementCmpt = actorEntity:PreviewConvertElement()
        if previewConvertElementCmpt then
            local transportEntityList,sourceEntityList = previewConvertElementCmpt:GetPreviewTransportEntityList()
            for i, entityID in ipairs(transportEntityList) do
                local entity = self._world:GetEntityByID(entityID)
                pieceService:_PlayGridAnimation(entity,"Dark")
                pieceService:RevertPieceShowRange(entity)
                self._world:DestroyEntity(entity)
            end
            for i, entityID in ipairs(sourceEntityList) do
                ---@type Entity
                local entity = self._world:GetEntityByID(entityID)
                if  entity then
                    entity:SetLocationHeight(0)
                    pieceService:_PlayGridAnimation(entity,"Dark")
                end
            end
            previewConvertElementCmpt:ClearPreviewTransportEntity()
            --actorEntity:RemovePreviewConvertElement()
        end
    end
end

---对目标格子执行转色
---@param targetElementType ElementType
---@param dataArray PickUpGridTogetherData
function PreviewActiveSkillService:PlayPickUpGridTogether(
        TT,
        dataArray,
        actorEntity,
        blockedPieces)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = actorEntity:PreviewConvertElement()
    if not previewConvertElementCmpt then
        actorEntity:AddPreviewConvertElement()
        previewConvertElementCmpt = actorEntity:PreviewConvertElement()
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    local needRecreateList = {}
    ---@param data PickUpGridTogetherData
    for _, data in ipairs(dataArray) do
        local gridPos = data:GetGridPos()
        local originalElementType = utilData:FindPieceElement(gridPos)
        if originalElementType ~= PieceType.None then
            previewConvertElementCmpt:AddTempConvertElement(gridPos, originalElementType)
            local entity = self:_ReplaceGridRes(data:GetGridType(), gridPos)
            table.insert(needRecreateList, { entity = entity, pos = gridPos })
        end
    end
    local oldPreviewIndex = self:GetPreviewIndex()
    -- 等待一帧是为了让转色Color的Ani加载完成，避免卡莲转色Ani播放不完整
    YIELD(TT)
    local newPreviewIndex = self:GetPreviewIndex()
    if oldPreviewIndex ~= newPreviewIndex then
        -- 由于已经切换预览，需要回滚上面的操作
        for _, v in ipairs(needRecreateList) do
            self._world:DestroyEntity(v.entity)
        end

        Log.fatal("preview active skill failed ")
        return
    end
    for i, v in ipairs(needRecreateList) do
        local sourceEntity = pieceService:FindPieceEntity(v.pos)
        self._world:DestroyEntity(sourceEntity)
        v.entity:SetLocationHeight(0)
        renderBoardCmpt:SetGridRenderEntityData(v.pos, v.entity)
        pieceService:SetPieceAnimColor(v.pos)

        --处理十字棱镜特效
        trapServiceRender:OnClosePreviewPrismEffectTrap(v.pos)
    end

    --锁格子动画
    if blockedPieces then
        for _, gridPos in ipairs(blockedPieces) do
            local es = env:GetEntitiesAtPos(
                    gridPos,
                    function(e)
                        return e:TrapRender() and e:TrapRender():GetTrapRender_IsLockedGrid()
                    end
            )
            local lockGridTrap = es[1]
            if lockGridTrap then
                local go = lockGridTrap:View():GetGameObject()
                local u3dAnimCmpt = go:GetComponent(typeof(UnityEngine.Animation))
                if lockGridTrap:TrapID():GetTrapID() == BattleConst.LockGridTrapID then
                    u3dAnimCmpt:Play("eff_2000521_lock_red01")
                else
                    u3dAnimCmpt:Play("eff_2000521_lock_red")
                end
            end
        end
    end
end