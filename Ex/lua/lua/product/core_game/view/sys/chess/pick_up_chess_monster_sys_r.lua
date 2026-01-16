--[[----------------------------------------------------------
    ChessPickUpMonsterSystem_Render：战棋点选到敌方怪物单位
]] ------------------------------------------------------------
---@class PickUpChessMonsterSystem_Render:ReactiveSystem
_class("PickUpChessMonsterSystem_Render", ReactiveSystem)
PickUpChessMonsterSystem_Render = PickUpChessMonsterSystem_Render

---@param world World
function PickUpChessMonsterSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function PickUpChessMonsterSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpChessResult)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PickUpChessMonsterSystem_Render:Filter(entity)
    ---@type PickUpChessResultComponent
    local resCmpt = entity:PickUpChessResult()
    ---@type ChessPickUpTargetType
    local resType = resCmpt:GetChessPickUpResultType()
    if resType == ChessPickUpTargetType.Monster then
        return true
    end
    return false
end

---重载ReactiveSystem的函数
function PickUpChessMonsterSystem_Render:ExecuteEntities(entities)
    self:InitServices()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local pickUpPos = resCmpt:GetCurChessPickUpPos()

    ---当前的行走范围
    local attackRange = resCmpt:GetChessPetAttackRange()
    local isRecover = resCmpt:GetSkillIsRecover()

    ---当前点选的光灵怪的ID
    local entityID = resCmpt:GetPickUpMonsterEntityID()
    if not entityID then
        Log.exception("点战棋的敌方单位，没有目标ID")
        return
    end

    local changed = resCmpt:IsChessPickUpTargetChanged()
    if not changed then
        ---结束敌方怪物的预览
        --self:_FinishMonsterPreview()
        return
    end

    ---@type GameStateID
    local stateId = self._utilDataSvc:GetCurMainStateID()
    if stateId == GameStateID.PreviewChessPet then
        self:_HandleInPreviewChessPetState(attackRange, pickUpPos, isRecover)
    elseif stateId == GameStateID.PickUpChessPet then
        self:_HandleInPickUpChessPetState(attackRange, pickUpPos, isRecover)
    else
        ---清理棋子光灵预览
        self._chessSvcRender:ClearChessPetPreview()
        ---清理敌方单位预览
        self._chessSvcRender:ClearChessMonsterPreview()

        ---显示敌方单位的预览
        self:ShowChessMonsterPreview(entityID)
    end
end

---当先点了我方单位，然后再点敌方单位
---@param attackRange Vector2[] 攻击范围
---@param pickUpPos Vector2 点选位置
function PickUpChessMonsterSystem_Render:_HandleInPreviewChessPetState(attackRange, pickUpPos, isRecover)
    ---这里先使用移动范围判断，应该使用攻击范围
    local inAttackRange = self:_CheckPickWalkRange(attackRange, pickUpPos)
    if inAttackRange then
        ---在攻击范围内，显示效果
        Log.notice("在攻击范围内，显示效果")
        --显示棋子虚影
        self._chessSvcRender:OnPickUpChessPetAttackRange(pickUpPos)
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 1)
        if isRecover then
            self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Recover)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Attack)
        end
    else
        ---清理棋子光灵预览
        self._chessSvcRender:ClearChessPetPreview()

        ---@type PreviewMonsterTrapService
        local prvwSvc = self._world:GetService("PreviewMonsterTrap")
        prvwSvc:HideHideInUIBar()

        ---重置棋子的点选ID
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpChessResultComponent
        local pickUpResCmpt = renderBoardEntity:PickUpChessResult()
        pickUpResCmpt:SetPickUpChessPetEntityID(nil)
        ---这个时候也不需要怪物的预览ID了
        pickUpResCmpt:SetPickUpMonsterEntityID(nil)

        self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 3)
    end
end

---在我方单位的点选预览时，点选了敌方单位
---@param attackRange Vector2[] 攻击范围
---@param pickUpPos Vector2 点选位置
function PickUpChessMonsterSystem_Render:_HandleInPickUpChessPetState(attackRange, pickUpPos, isRecover)
    ---这里先使用移动范围判断，应该使用攻击范围
    local inAttackRange = self:_CheckPickWalkRange(attackRange, pickUpPos)
    if inAttackRange then
        ---在攻击范围内，切换目标显示效果
        Log.fatal("在攻击范围内，显示效果")
        --显示棋子虚影
        self._chessSvcRender:OnPickUpChessPetAttackRange(pickUpPos)
        if isRecover then
            self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Recover)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Attack)
        end
    else
        ---清理棋子光灵预览
        self._chessSvcRender:ClearChessPetPreview()
		
        ---@type PreviewMonsterTrapService
        local prvwSvc = self._world:GetService("PreviewMonsterTrap")
        prvwSvc:HideHideInUIBar()

        ---重置棋子的点选ID
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpChessResultComponent
        local pickUpResCmpt = renderBoardEntity:PickUpChessResult()
        pickUpResCmpt:SetPickUpChessPetEntityID(nil)
        ---这个时候也不需要怪物的预览ID了
        pickUpResCmpt:SetPickUpMonsterEntityID(nil)

        ---从点选切到waitinput
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish, 5)
    end
end

function PickUpChessMonsterSystem_Render:InitServices()
    if not self._utilDataSvc then
        ---@type UtilDataServiceShare
        self._utilDataSvc = self._world:GetService("UtilData")
    end
    if not self._configService then
        ---@type ConfigService
        self._configService = self._world:GetService("Config")
    end
    if not self._chessSvcRender then
        ---@type ChessServiceRender
        self._chessSvcRender = self._world:GetService("ChessRender")
    end

    if not self._utilCalcSvc then
        ---@type UtilCalcServiceShare
        self._utilCalcSvc = self._world:GetService("UtilCalc")
    end
    if not self._utilScopeCalc then
        ---@type UtilScopeCalcServiceShare
        self._utilScopeCalc = self._world:GetService("UtilScopeCalc")
    end
end

---显示怪物预览
function PickUpChessMonsterSystem_Render:ShowChessMonsterPreview(entityID)
    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:ShowInUIBar(entityID)

    -----@type Entity
    local previewEntity = self._world:GetEntityByID(entityID)
    local element = previewEntity:Element():GetPrimaryType()
    ---500084
    local monsterSkillID = self._utilDataSvc:GetAIPreviewSkillID(previewEntity)
    if monsterSkillID == 0 then
        return
    end

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = self._configService:GetSkillConfigData(monsterSkillID, previewEntity)
    local previewType = skillConfigData:GetSkillPreviewType()
    if previewType == SkillPreviewType.N15MonsterChessSp then
        self:_PreviewSkillType28(previewEntity, monsterSkillID, skillConfigData, element)
    elseif previewType == SkillPreviewType.N15MonsterInstruction then
        self:_PreviewSkillType29(previewEntity, monsterSkillID, skillConfigData, element)
    elseif previewType == SkillPreviewType.Tips then
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    end
end

---@param entity Entity
---@param skillConfigData SkillConfigData
---针对预览类型29，敌方棋子指令化配置
function PickUpChessMonsterSystem_Render:_PreviewSkillType29(entity,skillID,skillConfigData,element)
    self:_ShowChessMonsterTips(skillID)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    local previewType = skillConfigData:GetSkillPreviewType()
    local previewParam =skillConfigData:GetSkillPreviewParam()
    local setID = previewParam[1]
    local taskID =  GameGlobal.TaskManager():CoreGameStartTask(previewActiveSkillService.CommonSkillPreview, previewActiveSkillService, entity, skillID,setID)
end

---@param entity Entity
---@param skillConfigData SkillConfigData
------针对预览类型28,敌方棋子普攻
function PickUpChessMonsterSystem_Render:_PreviewSkillType28(entity,skillID,skillConfigData,element)
    local previewEntity = entity
    local previewCasterPos = previewEntity:GetGridPosition()
    local previewCasterDir = previewEntity:GetGridDirection()
    local targetEntityIDList = self._utilScopeCalc:GetSortChessPetByMonsterPos(previewCasterPos)
    local targetID = targetEntityIDList[1]
    local moveFinalPos = previewCasterPos
    local hasMove = false
    if self._utilCalcSvc:CheckChessMonsterCanMove(previewEntity, element) and self:_IsNoMoveCanAttack(entity,skillID,skillConfigData) then
        local movePath = self._utilCalcSvc:GetMonster2TargetNearestPathByElement(previewEntity, targetID, element)
        if #movePath >0 then
            moveFinalPos = movePath[#movePath]
            hasMove = true
        end
    end
    ---@type SkillScopeResult
    local rangResult =self._utilScopeCalc:CalcSkillScope(skillConfigData, moveFinalPos, previewEntity, previewCasterDir)
    ---@type Vector2[]
    local attackRange = rangResult:GetAttackRange()
	
    for i, targetEntityID in ipairs(targetEntityIDList) do
        -----@type Entity
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        local targetPos = targetEntity:GetGridPosition()
        if table.intable(attackRange, targetPos) then
            targetID = targetEntityID
            break
        end
    end

    self:_ShowChessMonsterTips(skillID)
    ---显示格子动画
    ---@type RenderEntityService
    local renderEntitySvc = self._world:GetService("RenderEntity")
    ---renderEntitySvc:CreatePreviewAreaOutlineEntity(attackRange, EntityConfigIDRender.MoveRange)

    if hasMove then
        ---攻击者虚影
        local ghostEntity = renderEntitySvc:CreateGhost(moveFinalPos, previewEntity)
    end
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()

    ----@type EffectService
    local effectSrv = self._world:GetService("Effect")
    ----@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    local effectEntityList ={}
    local entity = self._world:GetEntityByID(targetID)
    if entity then
        -----@type Entity
        local effectEntity = effectSrv:CreateEffect(BattleConst.ChainSkillSnipeEffectID, entity, true)
        renderBattleService:PlaySnipeEffectAnimation(effectEntity, element)
        resCmpt:AddMonsterChessTargetEffectEntity(effectEntity:GetID())
        table.insert(effectEntityList, effectEntity)
    end
    entity:NewEnableFlashAlpha()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    GameGlobal.TaskManager():CoreGameStartTask(self._ShowTargetSnipeEffect,self, previewActiveSkillService:GetPreviewIndex(),effectEntityList,element)
    self:_HandleNotInChessMonsterAttackRange({})
end

---控制怪物棋子普攻的狙击特效效果
function PickUpChessMonsterSystem_Render:_ShowTargetSnipeEffect(TT,previewIndex,effectList,element)
    ----@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    while true do
        YIELD(TT,1000)

        local newPreviewIndex = previewActiveSkillService:GetPreviewIndex()
        if newPreviewIndex ~= previewIndex then
            return
        end

        for i, effectEntity in ipairs(effectList) do
            renderBattleService:PlaySnipeEffectAnimation(effectEntity,element)            
        end
    end
end

---显示tips
function PickUpChessMonsterSystem_Render:_ShowChessMonsterTips(monsterSkillID)
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = self._configService:GetSkillConfigData(monsterSkillID)

    ---显示Tips
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:_ShowSkillTips(skillConfigData)
end

---压暗不在攻击范围内的格子
function PickUpChessMonsterSystem_Render:_HandleNotInChessMonsterAttackRange(attackRange)
    ---不在范围内的都压暗
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()
        if not table.icontains(attackRange, pos) then
            pieceService:SetPieceAnimDown(pos)
        end
    end
end

function PickUpChessMonsterSystem_Render:_CheckPickWalkRange(walkRange, gridPos)
    for k, pos in ipairs(walkRange) do
        -- ---@type ComputeWalkPos
        -- local walkInfo = v
        -- local pos = walkInfo:GetPos()
        if pos == gridPos then
            return true
        end
    end

    return false
end

function PickUpChessMonsterSystem_Render:_FinishMonsterPreview()
    ---@type PreviewActiveSkillService
    local previewActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillSvc:_RevertAllConvertElement(true)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearChessMonsterPreview()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    resCmpt:ResetChessPickUp()



    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    if stateId ~= GameStateID.WaitInput then
        ---这个地方只处理waitinput状态下的终止
        Log.exception("only handle waitinput")
    end
end


function PickUpChessMonsterSystem_Render:_IsNoMoveCanAttack(entity,skillID,skillConfigData)
    local previewEntity = entity
    local previewCasterPos = previewEntity:GetGridPosition()
    local previewCasterDir = previewEntity:GetGridDirection()
    ---@type SkillScopeResult
    local rangResult =self._utilScopeCalc:CalcSkillScope(skillConfigData, previewCasterPos, previewEntity, previewCasterDir)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local targetType = SkillTargetType.ChessPet
    ---先选技能目标
    local targetEntityIDArray = utilScopeSvc:SelectSkillTarget(entity, targetType, rangResult, skillID)
    return #targetEntityIDArray==0
end