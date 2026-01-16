--[[------------------
    监听事件服务，处理所有从UI过来的事件
--]]
------------------
_class("EventListenerServiceRender", BaseService)
---@class EventListenerServiceRender:BaseService
EventListenerServiceRender = EventListenerServiceRender

function EventListenerServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    self._preClickSkillID = -1
    self._currentSkillID = -1
    self._autoBinder = AutoEventBinder:New(self._world:EventDispatcher())

    --对局加载事件，自UICommonLoading迁移
    self._autoBinder:BindEvent(GameEventType.MatchStart, self, self._OnMatchStart)

    --注册事件
    Log.notice("EventListenerServiceRender start")
    self._autoBinder:BindEvent(GameEventType.ClickPetHead, self, self._OnClickPetHead)
    self._autoBinder:BindEvent(GameEventType.ClickTrapHead, self, self._OnClickTrapHead)
    self._autoBinder:BindEvent(GameEventType.ClickPersonaSkill, self, self._OnClickPersonaSkill)
    self._autoBinder:BindEvent(GameEventType.StopPreviewActiveSkill, self, self._StopPreviewActiveSkill)
    self._autoBinder:BindEvent(GameEventType.CasterPreviewAnimatorExitPreview, self,
        self._CasterPreviewAnimatorExitPreview)
    self._autoBinder:BindEvent(GameEventType.StopPreviewFeatureSkill, self, self._StopPreviewFeatureSkill)
    self._autoBinder:BindEvent(GameEventType.CastActiveSkill, self, self.OnCastActiveSkill)
    self._autoBinder:BindEvent(GameEventType.CastActiveSkillNoPet, self, self.OnCastActiveSkillNoPet)
    self._autoBinder:BindEvent(GameEventType.CastPersonaSkill, self, self.OnCastPersonaSkill)
    self._autoBinder:BindEvent(GameEventType.ActiveSkillPickUp, self, self.OnActiveSkillPickUp)
    self._autoBinder:BindEvent(GameEventType.CancelActiveSkillCast, self, self.OnCancelActiveSkillCast)
    self._autoBinder:BindEvent(GameEventType.CastPickUpSkill, self, self.OnCastPickUpSkill)
    --连锁预览
    self._autoBinder:BindEvent(GameEventType.CancelChainSkillCast, self, self.OnCancelChainSkillCast)
    self._autoBinder:BindEvent(GameEventType.CastPickUpChainSkill, self, self.OnCastPickUpChainSkill)

    self._autoBinder:BindEvent(GameEventType.CancelReborn, self, self.OnCancelReborn)
    ---点击头像的时候，会立即触发一次这个事件，然后在预览系统中检测skill id是否和当前的一致，如果一致才会继续显示
    self._autoBinder:BindEvent(GameEventType.PreClickPetHead, self, self.OnPreClickHead)
    ---自动战斗的UI消息
    self._autoBinder:BindEvent(GameEventType.AutoFight, self, self._AutoFight)
    --开启倍速的ui消息
    self._autoBinder:BindEvent(GameEventType.DoubleSpeed, self, self._DoubleSpeed)
    self._autoBinder:BindEvent(GameEventType.ChangeTeamLeader, self, self._ChangeTeamLeader)
    self._autoBinder:BindEvent(GameEventType.UIChangeTeamLeader, self, self._OnUIChangeTeamLeader)
    self._autoBinder:BindEvent(GameEventType.DumpSyncLog, self, self._DumpSyncLog)
    --self._autoBinder:BindEvent(GameEventType.AppHome, self, self._DumpSyncLog)

    self._autoBinder:BindEvent(GameEventType.SpecialMissionQuitGame, self, self.OnSpecialMissionQuitGame)

    --怪物预览
    self._autoBinder:BindEvent(GameEventType.ClickUI2ClosePreviewMonster, self, self.OnClickUI2ClosePreviewMonster)
    self._autoBinder:BindEvent(GameEventType.OnUIGMCheatCommand, self, self.OnUIGMCheatCommand)

    --局内错误上报
    self._autoBinder:BindEvent(GameEventType.ClientExceptionReport, self, self.OnClientExceptionReport)

    --局内技能-选择光灵出战位置
    self._autoBinder:BindEvent(
        GameEventType.BattleUISelectTargetTeamPosition,
        self,
        self.OnBattleUISelectTargetTeamPosition
    )
    self._autoBinder:BindEvent(
        GameEventType.ClearSelectedTeamOrderPosition,
        self,
        self.OnClearSelectedTeamOrderPosition
    )

    self._autoBinder:BindEvent(GameEventType.ChessUIInputMoveAction, self, self.OnChessUIInputMoveAction)
    self._autoBinder:BindEvent(GameEventType.ChessUIInputAttackAction, self, self.OnChessUIInputAttackAction)
    self._autoBinder:BindEvent(GameEventType.ChessUIInputSkipAction, self, self.OnChessUIInputSkipAction)
    self._autoBinder:BindEvent(GameEventType.ChessUIInputFinishTurnAction, self, self.OnChessUIInputFinishTurnAction)
    self._autoBinder:BindEvent(GameEventType.GuideChessClick, self, self.OnGuideChessClick)

    self._autoBinder:BindEvent(GameEventType.UIMiniMazeChooseWaveAward, self, self.OnUIMiniMazeChooseWaveAward)
    self._autoBinder:BindEvent(GameEventType.GuideMonsterClick, self, self.OnGuideMonsterClick)

    self._autoBinder:BindEvent(GameEventType.ScanFeatureSaveInfo, self, self.OnScanFeatureSaveInfo)

    self._autoBinder:BindEvent(GameEventType.MirageUIClearPickUp, self, self.OnMirageUIClearPickUp)
    self._autoBinder:BindEvent(GameEventType.MirageUIConfirmPickUp, self, self.OnMirageUIConfirmPickUp)
    self._autoBinder:BindEvent(GameEventType.MirageUICountDownOver, self, self.OnMirageUICountDownOver)
    self._autoBinder:BindEvent(GameEventType.MirageUIRefreshStep, self, self.OnMirageUIRefreshStep)

    self._autoBinder:BindEvent(GameEventType.UIBattleSwitchPetEquipRefine, self, self.OnSwitchPetEquipRefine)
    self._autoBinder:BindEvent(GameEventType.UIBlackChange, self, self.OnResolutionChanged) --折叠屏手机分辨率改变

    self._autoBinder:BindEvent(GameEventType.PopStarPickUp, self, self.OnPopStarPickUp)

    ---@type FightResultEventListenerRender
    self._fightResultEventListener = FightResultEventListenerRender:New(self._world, self._autoBinder)
end

function EventListenerServiceRender:Dispose()
    self._autoBinder:UnBindAllEvents()
end

function EventListenerServiceRender:_OnMatchStart()
    ---@type BattleRenderConfigComponent
    local battleRenderConfigCmpt = self._world:BattleRenderConfig()
    battleRenderConfigCmpt:SetIsMatchStart(true)
end

---星灵主动技预览
function EventListenerServiceRender:_OnClickPetHead(castSkillPetPstID, energyReady, curSkillID)
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    if castSkillPetPstID ~= 0 then
        --哪个星灵触发预览，就给哪个星灵身上挂预览组件
        ---@type Entity
        local e = self._world:Player():GetPetEntityByPetPstID(castSkillPetPstID)
        ---@type SkillInfoComponent
        local skillInfoComponent = e:SkillInfo()
        local skillID = skillInfoComponent:GetActiveSkillID()
        ---@type HPComponent
        local hp = e:HP()
        hp:SetHPPosDirty(true, false)
        --检查是否存在子技能列表
        if curSkillID then
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(skillID, e)
            local subSkillList = skillConfigData:GetSubSkillIDList()
            if #subSkillList > 0 and table.icontains(subSkillList, curSkillID) then
                skillID = curSkillID
            else
                --附加主动技
                local extraSkillList = skillInfoComponent:GetExtraActiveSkillIDList()
                if extraSkillList and table.icontains(extraSkillList, curSkillID) then
                    skillID = curSkillID
                else
                    local variantActiveSkillInfo = skillInfoComponent:GetVariantActiveSkillInfo()
                    if variantActiveSkillInfo then
                        local variantList = variantActiveSkillInfo[skillID]
                        if variantList and table.icontains(variantList, curSkillID) then
                            skillID = curSkillID
                        end
                    end
                end
            end
        end
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, castSkillPetPstID)
        e:ReplacePreviewActiveSkill(skillID, castSkillPetPstID)
        if self._world:MatchType() == MatchType.MT_PopStar then
            ---消灭星星显示施法者
            ---@type PopStarServiceRender
            local popStarRSvc = self._world:GetService("PopStarRender")
            popStarRSvc:PopStarShowCasterEntity(castSkillPetPstID)
        elseif not table.icontains(BattleConst.NoShowCasterEntityOnPreview, skillID) then
            playSkillService:ShowCasterEntity(e:GetID())
        end
        self:_PreviewSkill(skillID, castSkillPetPstID)
    end
end

---机关主动技预览
function EventListenerServiceRender:_OnClickTrapHead(skillID, trapEntityID, energyReady)
    if self._preClickSkillID ~= skillID then
        Log.fatal("click head skill not match", self._preClickSkillID, skillID)
        return
    end

    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    local trap = self._world:GetEntityByID(trapEntityID)
    if not trap then
        return
    end

    --删除点选组件
    trap:RemovePreviewPickUpComponent()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, -1)
    pickUpTargetCmpt:SetEntityID(trap:GetID())
    trap:ReplacePreviewActiveSkill(skillID, trapEntityID)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowCasterEntity(trap:GetID())

    ---@type PickUpComponent
    local pickUpCmpt = self._world:PickUp()
    pickUpCmpt:SetCurActiveSkillInfo(skillID, -1)
    pickUpCmpt:SetEntityID(trap:GetID())

    self:_PreviewSkill(skillID, trapEntityID)
end

---P5合击技预览
function EventListenerServiceRender:_OnClickPersonaSkill(featureType, skillID)
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    ---消灭星星隐藏之前因点击光灵头像而显示出来的光灵
    if self._world:MatchType() == MatchType.MT_PopStar then
        ---@type PopStarServiceRender
        local popStarRSvc = self._world:GetService("PopStarRender")
        popStarRSvc:PopStarShowCasterEntity(-1)
    end

    local skillHolder = FeatureServiceHelper.GetFeatureSkillHolderEntity(featureType)
    local e = skillHolder
    if not e then
        return
    end

    --删除点选组件
    e:RemovePreviewPickUpComponent()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, -1)
    pickUpTargetCmpt:SetEntityID(e:GetID())
    e:ReplacePreviewActiveSkill(skillID)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type Entity
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    playSkillService:ShowPlayerEntity(teamEntity)

    ---消灭星星特殊处理
    if self._world:MatchType() ~= MatchType.MT_PopStar then
        local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
        local teamLeaderEntity = self._world:GetEntityByID(teamLeaderEntityID)
        if teamLeaderEntity:HasView() then
            teamLeaderEntity:SetViewVisible(false)
            teamLeaderEntity:SetViewVisible(true)
            --清理一下队长动作状态
            --casterEntity:SetAnimatorControllerTriggers({"AtkUltPreviewCancel"})
        end
    end
    ---@type PickUpComponent
    local pickUpCmpt = self._world:PickUp()
    pickUpCmpt:SetCurActiveSkillInfo(skillID, -1)
    pickUpCmpt:SetEntityID(e:GetID())

    local castSkillPetPstID = 0
    self:_PreviewSkill(skillID, castSkillPetPstID)
end

function EventListenerServiceRender:_PreviewSkill(skillID, castSkillPetPstID)
    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
    --只要启动了预览，暗屏效果一直都在
    sPreviewSkill:StartPreviewFocusEffect()        
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(skillID, castSkillPetPstID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    local curState = self:_GetCurState()

    if pickUpType == SkillPickUpType.None then
        ---直接发动类的技能，点击头像进入预览状态
        if curState == GameStateID.WaitInput then
            --普通状态，进入预览状态
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 3)
        elseif curState == GameStateID.PickUpActiveSkillTarget then
            --从选格子状态进入预览状态
            self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 3)
        elseif curState == GameStateID.PreviewActiveSkill then
            --预览状态中，什么都不做
        else
            Log.fatal("preview skill state error:", curState)
        end
    else
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        ---选格子类的技能，点击头像直接进入PickUpTarget状态
        if curState == GameStateID.WaitInput then
            sPreviewSkill:PlaySkillView_Preview(self._world, skillID, castSkillPetPstID, true)
            --普通状态，进入选格子状态
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 3)
        elseif curState == GameStateID.PickUpActiveSkillTarget then
            sPreviewSkill:PlaySkillView_Preview(self._world, skillID, castSkillPetPstID, true)
            --从选格子状态进入预览状态
            self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 3)
        elseif curState == GameStateID.PreviewActiveSkill then
            --预览状态中，切换到选格子状态
            sPreviewSkill:PlaySkillView_Preview(self._world, skillID, castSkillPetPstID, true)
        else
            Log.fatal("preview pick up skill state error:", curState)
        end
    end
end

function EventListenerServiceRender:_GetCurState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    return utilDataSvc:GetCurMainStateID()
end

function EventListenerServiceRender:_CasterPreviewAnimatorExitPreview(petPstID, activeSkillID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    if not petEntityID then
        return
    end
    local petEntity = self._world:GetEntityByID(petEntityID)
    if not petEntity then
        return
    end

    if not activeSkillID then
        return
    end

    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID, petEntity)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    if pickUpType == SkillPickUpType.None then
        ---此种类型的拾取是不会触发播放预览主动技动作的，所以直接返回
        return
    end

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:PlayCasterPreviewAnim(petEntity, false, "AtkUltPreviewCancel")
end

function EventListenerServiceRender:_StopPreviewActiveSkill(isSwitch, bShowPlayerEntity, activeSkillID, petPstID)
    ---@type Entity
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")

    if isSwitch ~= true then
        previewActiveSkillService:StopDarkScreenImmediately()
    end

    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()
    GameGlobal.TaskManager():CoreGameStartTask(self.DoCancelPreviewInstruction, self, activeSkillID, petPstID)
    -- if isSwitch ~= true then
    if bShowPlayerEntity then
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        playSkillService:ShowPlayerEntity(teamEntity)
    end

    previewActiveSkillService:_DestroyPickUpArrow()

    --取消波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    for _, v in ipairs(flashEnemyEntities) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        if comp then
            comp:StopLayer(MaterialAnimLayer.SkillPreview)
        end
    end

    previewActiveSkillService:ResetPreview()

    previewActiveSkillService:_ClearPreviewActiveSkill(isSwitch)

    previewActiveSkillService:ClearPreviewLinkLine(activeSkillID, petPstID)

    --终止预览时，格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
end

function EventListenerServiceRender:_StopPreviewFeatureSkill(isSwitch, bShowPlayerEntity, featureSkillID, featureType)
    ---@type Entity
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")

    if isSwitch ~= true then
        previewActiveSkillService:StopDarkScreenImmediately()
    end

    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()
    GameGlobal.TaskManager():CoreGameStartTask(self.DoFeatureCancelPreviewInstruction, self, featureSkillID, featureType)
    -- if isSwitch ~= true then
    if bShowPlayerEntity then
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        playSkillService:ShowPlayerEntity(teamEntity)
    end

    previewActiveSkillService:_DestroyPickUpArrow()

    --取消波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    for _, v in ipairs(flashEnemyEntities) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        if comp then
            comp:StopLayer(MaterialAnimLayer.SkillPreview)
        end
    end

    previewActiveSkillService:ResetPreview()

    previewActiveSkillService:_ClearPreviewActiveSkill(isSwitch)

    --终止预览时，格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
end

function EventListenerServiceRender:CastPickUpActiveSkill(TT, activeSkillID, petPstID, entityID)
    ---@type ConfigService
    local configService = self._configService

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local casterPetEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    local petEntity = self._world:GetEntityByID(casterPetEntityID)

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    previewActiveSkillService:_DestroyPickUpArrow()

    --清理暗色格子
    previewActiveSkillService:_RevertBright()

    --取消怪物波点
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
    for _, v in ipairs(flashEnemyEntities) do
        ---@type MaterialAnimationComponent
        local comp = v:MaterialAnimationComponent()
        if comp then
            comp:StopLayer(MaterialAnimLayer.SkillPreview)
        end
    end

    --主动技开始后，需要重置预览索引
    previewActiveSkillService:ResetPreview()

    previewActiveSkillService:_ClearPreviewActiveSkill(false, true)

    --找到对应Pet的entity id
    if skillConfigData:GetSkillType() == SkillType.Active then
        if casterPetEntityID < 0 then
            Log.fatal("caster entity id invalid")
            return
        end

        ---打印施法宝宝的信息
        self:_LogPetCasterInfo(casterPetEntityID, activeSkillID)
        skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity) --这里重取一遍是因为光灵的技能数据可能会被换掉
        ---@type SkillPickUpType
        local pickUpType = skillConfigData:GetSkillPickType()
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = petEntity:PreviewPickUpComponent()
        local canSendBefore, errorTypeBefore = self:_CheckCanSendActivePickSkillCmd(previewPickUpComponent, petEntity,
            activeSkillID)

        if canSendBefore then
            self:DoActiveSkillInstruction(TT, activeSkillID, petPstID)
            local canSend, errorType = self:_CheckCanSendActivePickSkillCmd(previewPickUpComponent, petEntity,
                activeSkillID)

            self._world:GetService("Piece"):RefreshPieceAnim()
            if canSend then
                self:SendCastPickUpActiveSkillCommand(activeSkillID, petPstID, previewPickUpComponent)
                if pickUpType == SkillPickUpType.LinkLine then
                    ---@type InputComponent
                    local inputCmpt = self._world:Input()
                    inputCmpt:SetPreviewActiveSkill(false)
                end
            else
                local errorStep = ActivePickSkillCheckErrorStep.SendBeforeAfterDoIns
                self:_OnCastActivePickSkillFail(errorStep, errorType, activeSkillID, petPstID, previewPickUpComponent)
            end
        else
            local errorStep = ActivePickSkillCheckErrorStep.SendBeforeDoIns
            self:_OnCastActivePickSkillFail(errorStep, errorTypeBefore, activeSkillID, petPstID, previewPickUpComponent)
        end
    elseif skillConfigData:GetSkillType() == SkillType.TrapSkill then
        self:DoActiveSkillInstruction(TT, activeSkillID, petPstID, entityID)
        local casterEntity = self._world:GetEntityByID(entityID)
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        self._world:GetService("Piece"):RefreshPieceAnim()
        self:SendCastPickUpActiveSkillCommand(activeSkillID, 0, previewPickUpComponent, entityID)
    elseif skillConfigData:GetSkillType() == SkillType.FeatureSkill then
        self:DoActiveSkillInstruction(TT, activeSkillID, petPstID, entityID)
        local casterEntity = self._world:GetEntityByID(entityID)
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        self._world:GetService("Piece"):RefreshPieceAnim()
        self:SendCastPickUpActiveSkillCommand(activeSkillID, 0, previewPickUpComponent, entityID)
    end
end

function EventListenerServiceRender:OnCastActiveSkill(activeSkillID, petPstID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local casterPetEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    if casterPetEntityID < 0 then
        Log.fatal("caster entity id invalid")
        return
    end
    local e = self._world:GetEntityByID(casterPetEntityID)

    ---@type ConfigService
    local configService = self._configService

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)

    ---@type SkillScopeType
    local pickUpType = skillConfigData:GetSkillPickType()

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    if not table.icontains(BattleConst.NoShowCasterEntityOnPreview, activeSkillID) then
        playSkillService:ShowCasterEntity(casterPetEntityID)
    end

    ---星灵在释放主动技能的时候 需要清除普攻连线激活的副属性。主动技只有主属性伤害
    local petEntity = self._world:GetEntityByID(casterPetEntityID)
    petEntity:RemovePreviewPickUpComponent()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    if pickUpType == SkillPickUpType.None then
        ---打印施法宝宝的信息
        self:_LogPetCasterInfo(casterPetEntityID, activeSkillID)

        --清理暗色格子
        previewActiveSkillService:_RevertBright()

        --主动技开始后，需要重置预览索引
        previewActiveSkillService:ResetPreview()

        previewActiveSkillService:_ClearPreviewActiveSkill(false, true)

        self._world:GetService("Piece"):RefreshPieceAnim()

        self:SendCastActiveSkillCommand(activeSkillID, petPstID)

        GameGlobal.TaskManager():CoreGameStartTask(self.DoActiveSkillInstruction, self, activeSkillID, petPstID)
    else
        local monsterEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
        for _, v in ipairs(monsterEntities) do
            if v:BuffView() and not v:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation) then
                v:NewEnableTransparent()
            end
        end
        ---转入技能输入状态
        ---如果已经可以发动技能，并且技能范围类型是玩家自己选的，就可以转到主动技拾取阶段了
        ---@type PickUpComponent
        local pickUpCmpt = self._world:PickUp()
        pickUpCmpt:SetCurActiveSkillInfo(activeSkillID, petPstID)

        Log.notice("cast pick up active skill", activeSkillID)
    end
end

function EventListenerServiceRender:OnCastActiveSkillNoPet(activeSkillID, trapEntityID)
    local trap = self._world:GetEntityByID(trapEntityID)
    local entityPos = trap:GridLocation():CenterNoOffset()

    ---@type ConfigService
    local configService = self._configService

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)

    ---@type SkillScopeType
    local pickUpType = skillConfigData:GetSkillPickType()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    if pickUpType == SkillPickUpType.None then
        --清理暗色格子
        previewActiveSkillService:_RevertBright()

        --主动技开始后，需要重置预览索引
        previewActiveSkillService:ResetPreview()

        previewActiveSkillService:_ClearPreviewActiveSkill(false, true)

        self._world:GetService("Piece"):RefreshPieceAnim()

        self:SendCastActiveSkillCommand(activeSkillID, 0, trap:GetID())
    else
        local monsterEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
        for _, v in ipairs(monsterEntities) do
            if v:BuffView() and not v:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation) then
                v:NewEnableTransparent()
            end
        end
        ---转入技能输入状态
        ---如果已经可以发动技能，并且技能范围类型是玩家自己选的，就可以转到主动技拾取阶段了
        ---@type PickUpComponent
        local pickUpCmpt = self._world:PickUp()
        pickUpCmpt:SetCurActiveSkillInfo(activeSkillID, -1)
        pickUpCmpt:SetEntityID(trap:GetID())

        Log.notice("cast pick up active skill", activeSkillID)
    end
end

function EventListenerServiceRender:OnCastPersonaSkill(personaSkillID)
    ---@type ConfigService
    local configService = self._configService

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(personaSkillID)

    ---@type SkillScopeType
    local pickUpType = skillConfigData:GetSkillPickType()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type RenderEntityService
    local svc = self._world:GetService("RenderEntity")
    svc:DestroyGhost()

    if pickUpType == SkillPickUpType.None then
        --清理暗色格子
        previewActiveSkillService:_RevertBright()

        --主动技开始后，需要重置预览索引
        previewActiveSkillService:ResetPreview()

        previewActiveSkillService:_ClearPreviewActiveSkill(false, true)

        self._world:GetService("Piece"):RefreshPieceAnim()

        self:SendCastActiveSkillCommand(personaSkillID, 0, nil)
    else
        local monsterEntities = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID):GetEntities()
        for _, v in ipairs(monsterEntities) do
            if v:BuffView() and not v:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation) then
                v:NewEnableTransparent()
            end
        end
        ---转入技能输入状态
        ---如果已经可以发动技能，并且技能范围类型是玩家自己选的，就可以转到主动技拾取阶段了
        ---@type PickUpComponent
        local pickUpCmpt = self._world:PickUp()
        local petPstID = 0
        pickUpCmpt:SetCurActiveSkillInfo(personaSkillID, petPstID)

        Log.notice("cast pick up personaSkillID skill", personaSkillID)
    end
end

function EventListenerServiceRender:OnActiveSkillPickUp(activeSkillID, petPstID)
    -- TODO 阿克希亚扫描模块处理
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(activeSkillID, petPstID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    local curState = self:_GetCurState()
    if curState == GameStateID.PreviewActiveSkill then
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewActiveSkillFinish, 3)
        if pickUpType == SkillPickUpType.LinkLine then
            ---@type InputComponent
            local inputCmpt = self._world:Input()
            inputCmpt:SetPreviewActiveSkill(true)
        end
        ---@type UtilDataServiceShare
        local utilStatSvc = self._world:GetService("UtilData")
        if not utilStatSvc:GetStatAutoFight() then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PickUPValidGridShowChooseTarget, true)
        end
    end
end

--region 大招
function EventListenerServiceRender:OnCancelActiveSkillCast(activeSkillID, petPstID)
    ---@type TaskManager
    local taskManager = GameGlobal.TaskManager()
    local nTaskID = taskManager:CoreGameStartTask(self.TT_OnCancelActiveSkillCast, self, activeSkillID, petPstID)

    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    if not skillConfigData then
        Log.exception("OnCancelActiveSkillCast no skill config ,skillId: ", activeSkillID)
        return
    end

    -- --恢复输入状态
    -- if skillConfigData:GetSkillPickType() == SkillPickUpType.LinkLine then
    --     ---@type InputComponent
    --     local inputCmpt = self._world:Input()
    --     inputCmpt:SetPreviewActiveSkill(false)
    -- end

    --删除点选组件
    if skillConfigData:GetSkillType() == SkillType.TrapSkill then
        local casterEntity = self._world:GetEntityByID(petPstID)
        if casterEntity then
            casterEntity:RemovePreviewPickUpComponent()
        end
    end
end

function EventListenerServiceRender:TT_OnCancelActiveSkillCast(TT, activeSkillID, petPstID)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:CancelActiveSkillCast(TT, activeSkillID, petPstID)
end

--endregion

--region 取消连锁拾取
function EventListenerServiceRender:OnCancelChainSkillCast(skillID, petPstID)
    local TT_OnCancelChainSkillCast = function(TT)
        ---@type PreviewActiveSkillService
        local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
        sPreviewSkill:ClearChainPreviewData()

        sPreviewSkill:StopPreviewChainSkill(TT) --MSG50434
        YIELD(TT, 200)                          --TODO等虚影删除，否则会导致虚影不删除

        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type RenderBoardComponent
        local renderBoardCmpt = renderBoardEntity:RenderBoard()
        local taskID = renderBoardCmpt:GetDimensionClearPreviewTaskID()
        while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
            YIELD(TT)
        end

        local cmd = CancelChainSkillCommand:New()
        self._world:Player():SendCommand(cmd)
    end
    local taskManager = GameGlobal.TaskManager()
    local nTaskID = taskManager:CoreGameStartTask(TT_OnCancelChainSkillCast, self)
end

--endregion
--region 释放连锁
function EventListenerServiceRender:OnCastPickUpChainSkill()
    local CastPickUpChainSkill = function(TT)
        ---@type PreviewActiveSkillService
        local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
        sPreviewSkill:ClearChainPreviewData()
        YIELD(TT, 200) --TODO等虚影删除，否则会导致阻挡信息不会跟着传送

        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type RenderBoardComponent
        local renderBoardCmpt = renderBoardEntity:RenderBoard()
        local taskID = renderBoardCmpt:GetDimensionClearPreviewTaskID()
        while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
            YIELD(TT)
        end

        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        local cmd = CastPickUpChainSkillCommand:New()
        cmd:SetCmdPickUpResult(pickUpTargetCmpt:GetCurPickUpGridSafePos())
        self._world:Player():SendCommand(cmd)
    end
    GameGlobal.TaskManager():CoreGameStartTask(CastPickUpChainSkill, self)
end

--endregion

function EventListenerServiceRender:DoActiveSkillInstruction(TT, activeSkillID, petPstID, entityID)
    if not activeSkillID or not petPstID then
        return
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityId)
    --兼容机关和模块释放主动技
    if not petEntity then
        petEntity = self._world:GetEntityByID(entityID)
    end
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    --TODO 阿克希亚扫描模块处理
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for _, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in pairs(instructionParam._previewList) do
                local instructionSet = skillPreviewConfigData:GetActiveSkillInstructionSet()
                if instructionSet then
                    local previewContext =
                        previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, petEntity)
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
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

function EventListenerServiceRender:DoCancelPreviewInstruction(TT, activeSkillID, petPstID)
    if not activeSkillID or not petPstID then
        return
    end
    if activeSkillID <= 0 then
        return
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityId)
    if not petEntity then
        ---Bug：MSG57971 预览机关技能时，点击光灵头像，机关预览不取消
        ---施法者并非光灵时
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        local entityID = pickUpTargetCmpt:GetEntityID()
        petEntity = self._world:GetEntityByID(entityID)
    end

    if petEntity and petEntity:HasHP() then
        ---@type HPComponent
        local hp = petEntity:HP()
        hp:SetHPPosDirty(true)
    else
        return
    end
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for _, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in pairs(instructionParam._previewList) do
                local instructionSet = skillPreviewConfigData:GetCancelPreviewInstructionSet()
                if instructionSet then
                    local previewContext =
                        previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, petEntity)
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
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

function EventListenerServiceRender:DoFeatureCancelPreviewInstruction(TT, featureSkillID, featureType)
    if not featureSkillID or not featureType then
        return
    end
    if featureSkillID <= 0 then
        return
    end
    local skillHolder = FeatureServiceHelper.GetFeatureSkillHolderEntity(featureType)
    local e = skillHolder
    if not e then
        return
    end
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(featureSkillID)
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for _, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in pairs(instructionParam._previewList) do
                local instructionSet = skillPreviewConfigData:GetCancelPreviewInstructionSet()
                if instructionSet then
                    local previewContext =
                        previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, e)
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
                            previewActiveSkillService.DoPreviewInstruction,
                            previewActiveSkillService,
                            instructionSet,
                            e,
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

function EventListenerServiceRender:OnCastPickUpSkill()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    if pickUpTargetCmpt == nil then
        Log.fatal("pick up target is nil")
        return
    end

    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    local petPstID = pickUpTargetCmpt:GetPetPstid()
    local entityID = pickUpTargetCmpt:GetEntityID()
    if (entityID < 0 and petPstID < 0) or activeSkillID < 0 then
        Log.fatal("OnCastPickUpSkill id invalid")
        return
    end
    GameGlobal.TaskManager():CoreGameStartTask(self.CastPickUpActiveSkill, self, activeSkillID, petPstID, entityID)
end

function EventListenerServiceRender:OnCancelReborn()
    GameGlobal.TaskManager():CoreGameStartTask(self._CancelRebornTask, self)
end

function EventListenerServiceRender:_CancelRebornTask(TT)
    Log.debug("[match] EventListenerServiceRender:_CancelRebornTask")
    ---取消复活，玩家开始播放死亡动画
    local playerEntity = self._world:Player():GetLocalTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if utilData:PlayerIsDead(playerEntity) then
        --只有被打死才播放死亡动画。守护目标死亡 时间结束未达成目标 都不会播放死亡动画
        if playerEntity then
            local deadTriggerParam = "Death"
            playerEntity:SetAnimatorControllerTriggers({ deadTriggerParam })
            YIELD(TT, 1000)
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowGuideFailed)
    GuideHelper.IsUIGuideFailedComplete(TT)
    ---通知UI黑屏
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowTransitionEffect)
    ---黑屏到达时间后，就可以退局了
    YIELD(TT, 1000)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowUIResult, false)
end

function EventListenerServiceRender:OnPreClickHead(skillID)
    self._preClickSkillID = skillID
end

function EventListenerServiceRender:GetPreClickHeadSkillID()
    return self._preClickSkillID
end

function EventListenerServiceRender:SendCastActiveSkillCommand(skillID, petPstID, casterTrapID)
    local cmd = CastActiveSkillCommand:New()
    cmd:SetCmdActiveSkillID(skillID)
    cmd:SetCmdCasterPstID(petPstID)
    if casterTrapID then
        cmd:SetCmdCasterTrapEntityID(casterTrapID)
    end
    self._world:Player():SendCommand(cmd)
end

--- @param previewPickUpComponent PreviewPickUpComponent
function EventListenerServiceRender:SendCastPickUpActiveSkillCommand(
    skillID,
    petPstID,
    previewPickUpComponent,
    casterTrapID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local casterPetEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    local petEntity = self._world:GetEntityByID(casterPetEntityID)

    local canSend, errorType = self:_CheckCanSendActivePickSkillCmd(previewPickUpComponent, petEntity, skillID)
    if canSend then
        local cmd = CastPickUpActiveSkillCommand:New()
        cmd:SetCmdActiveSkillID(skillID)
        cmd:SetCmdCasterPstID(petPstID)
        if casterTrapID then
            cmd:SetCmdCasterTrapEntityID(casterTrapID)
        end
        local pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
        cmd:SetCmdPickUpResult(pickPosList)
        cmd:SetPickUpDirectionResult(
            previewPickUpComponent:GetPickUpDirectionPos(),
            previewPickUpComponent:GetAllDirection(),
            previewPickUpComponent:GetLastPickUpDirection()
        )
        cmd:SetReflectDir(previewPickUpComponent:GetReflectDir())
        cmd:SetCmdPickUpExtraParamResult(previewPickUpComponent:GetAllPickExtraParam())

        self._world:Player():SendCommand(cmd)
        local curstateid = self:_GetCurState()
        Log.debug("EventListenerServiceRender:SendCastPickUpActiveSkillCommand gamefsm state ", curstateid)
    else
        Log.debug(
            "EventListenerServiceRender:SendCastPickUpActiveSkillCommand error no previewPickUpComponent, skillID: ",
            skillID)

        local errorStep = ActivePickSkillCheckErrorStep.TrySend
        self:_OnCastActivePickSkillFail(errorStep, errorType, skillID, petPstID, previewPickUpComponent)
    end

    ---清理点选信息
    ---@type PickUpComponent
    local worldPickUpCmpt = self._world:PickUp()
    worldPickUpCmpt:ResetPickUpData()
end

function EventListenerServiceRender:_AutoFight(enable)
    ---@type AutoFightCommand
    local cmd = AutoFightCommand:New()
    cmd:SetCmdAutoFight(enable)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:_DoubleSpeed(speed)
    self._world:RenderBattleStat():SetEverSpeed(speed)
end

---@param casterPetEntityID number
function EventListenerServiceRender:_LogPetCasterInfo(casterPetEntityID, skillID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(casterPetEntityID)
    if petEntity == nil then
        Log.notice("caster is nil:", skillID)
        return
    end

    ---@type PetPstIDComponent
    local pstIDCmpt = petEntity:PetPstID()
    if pstIDCmpt == nil then
        return
    end

    local petTemplateID = pstIDCmpt:GetTemplateID()

    Log.notice("[Skill] Caster:", petTemplateID, ",skill:", skillID)
end

function EventListenerServiceRender:_ChangeTeamLeader(petPstID, oldPstID)
    ----@type ChangeTeamLeaderCommand
    local cmd = ChangeTeamLeaderCommand:New()
    cmd:SetNewTeamLeaderPstID(petPstID)
    cmd:SetOldTeamLeaderPstID(oldPstID)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:_OnUIChangeTeamLeader(
    newPetPstID,
    oldPetPstID,
    remainTimes,
    teamOrderBefore,
    teamOrderAfter)
    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    renderBattleService:RenderChangeTeamLeader(newPetPstID, oldPetPstID)

    GameGlobal.TaskManager():CoreGameStartTask(
        self._OnPlayBuffViewTeamOrderChange,
        self,
        newPetPstID,
        teamOrderBefore,
        teamOrderAfter
    )

    GameGlobal.TaskManager():CoreGameStartTask(self._OnPlayBuffViewChangeTeamLeader, self, newPetPstID, oldPetPstID)
end

function EventListenerServiceRender:_OnPlayBuffViewChangeTeamLeader(TT, newPetPstID, oldPetPstID)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    local petEntity = self._world:Player():GetPetEntityByPetPstID(newPetPstID)
    local oldLeaderPetEntity = self._world:Player():GetPetEntityByPetPstID(oldPetPstID)
    playBuffService:PlayBuffView(TT, NTChangeTeamLeader:New(petEntity, oldLeaderPetEntity))
end

function EventListenerServiceRender:_OnPlayBuffViewTeamOrderChange(TT, newPetPstID, teamOrderBefore, teamOrderAfter)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    local petEntity = self._world:Player():GetPetEntityByPetPstID(newPetPstID)
    local cPet = petEntity:Pet()
    local eTeam = cPet:GetOwnerTeamEntity()
    playBuffService:PlayBuffView(TT, NTTeamOrderChange:New(eTeam, teamOrderBefore, teamOrderAfter))
end

function EventListenerServiceRender:_DumpSyncLog()
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    utilCalcSvc:SaveSyncLog()
end

function EventListenerServiceRender:OnSpecialMissionQuitGame()
    ---@type UtilCalcServiceShare
    local utilCalc = self._world:GetService("UtilCalc")
    ---@type RenderBattleService
    local battleSvcR = self._world:GetService("RenderBattle")
    ---@type MatchResult
    local battleResult = utilCalc:CalcBattleResult(self._world:MatchType(), true)
    battleSvcR:NotifyUIBattleGameOver(battleResult)
end

function EventListenerServiceRender:OnClickUI2ClosePreviewMonster()
    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:ClearMonsterTrapPreview()
    if self._world:MatchType() == MatchType.MT_PopStar then
        ---清除点击表现
        ---@type PopStarServiceRender
        local popStarRSvc = self._world:GetService("PopStarRender")
        popStarRSvc:StopPreviewPopStar()
    end
end

function EventListenerServiceRender:OnUIGMCheatCommand(cmd)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnClientExceptionReport(cmd)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnBattleUISelectTargetTeamPosition(petPstID)
    local eTeam = self._world:Player():GetLocalTeamEntity()
    local ePet = eTeam:Team():GetPetEntityByPetPstID(petPstID)
    if not ePet then
        return
    end

    local targetPos = 0
    for index, pstID in ipairs(eTeam:Team():GetTeamOrder()) do
        if pstID == petPstID then
            targetPos = index
            break
        end
    end

    local cmd = CastSelectTeamOrderPositionCommand.GenerateCommand(eTeam:GetID(), petPstID, targetPos)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnClearSelectedTeamOrderPosition(petPstID)
    local eTeam = self._world:Player():GetLocalTeamEntity()
    local ePet = eTeam:Team():GetPetEntityByPetPstID(petPstID)
    if not ePet then
        return
    end

    local cmd = CastClearSelectedTeamOrderPositionCommand.GenerateCommand(eTeam:GetID(), petPstID)
    self._world:Player():SendCommand(cmd)
end

---处理战棋模式的移动按钮
function EventListenerServiceRender:OnChessUIInputMoveAction()
    --关闭移动按钮 只显示结束
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.FinishTurnOnly)
    --关闭UI碰撞
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateBlockRaycast, false)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()
    local chessPetID = pickUpResCmpt:GetPickUpChessPetEntityID()
    local chessPath = pickUpResCmpt:GetChessPetMovePath()

    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearAllChessUnitPreview()
    chessSvcRender:HdieChessPetCanMoveEffect(chessPetID)

    ----@type CastChessMoveCommand
    local cmd = CastChessMoveCommand:New()
    cmd:SetCmdCasterEntityID(chessPetID)
    cmd:SetCmdChessPath(chessPath)
    self._world:Player():SendCommand(cmd)
end

---处理战棋模式的攻击按钮
function EventListenerServiceRender:OnChessUIInputAttackAction()
    --关闭移动按钮 只显示结束
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.FinishTurnOnly)
    --关闭UI碰撞
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateBlockRaycast, false)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()
    local chessPetID = pickUpResCmpt:GetPickUpChessPetEntityID()
    local chessPath = pickUpResCmpt:GetChessPetMovePath()
    local monsterID = pickUpResCmpt:GetPickUpMonsterEntityID()
    local pickUpPos = pickUpResCmpt:GetCurChessPickUpPos()

    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearAllChessUnitPreview()
    chessSvcRender:HdieChessPetCanMoveEffect(chessPetID)

    ----@type CastChessPetAttackCommand
    local cmd = CastChessPetAttackCommand:New()
    cmd:SetCmdCasterEntityID(chessPetID)
    cmd:SetCmdChessPath(chessPath)
    cmd:SetCmdPickUpResult(pickUpPos)

    self._world:Player():SendCommand(cmd)
end

---处理战棋模式的待命按钮
function EventListenerServiceRender:OnChessUIInputSkipAction()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()
    local chessPetID = pickUpResCmpt:GetPickUpChessPetEntityID()
    local targetPos = pickUpResCmpt:GetCurChessPickUpPos()

    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearAllChessUnitPreview()
    chessSvcRender:HdieChessPetCanMoveEffect(chessPetID)

    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(chessPetID)
    ---@type MaterialAnimationComponent
    local matAnimCmpt = chessPetEntity:MaterialAnimationComponent()
    if matAnimCmpt then
        matAnimCmpt:PlayInvalid()
    end

    ---全部输入结束，切到敌方回合
    ----@type CastChessPetEndTurnCommand
    local cmd = CastChessPetEndTurnCommand:New()
    cmd:SetCmdTurnType(ChessTurnEndType.Single)
    cmd:SetTurnEndEntityID(chessPetID)
    self._world:Player():SendCommand(cmd)
end

---处理战棋模式的结束回合按钮
function EventListenerServiceRender:OnChessUIInputFinishTurnAction()
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearAllChessUnitPreview()
    chessSvcRender:HdieAllChessPetCanMoveEffect()

    ----@type CastChessPetEndTurnCommand
    local cmd = CastChessPetEndTurnCommand:New()
    cmd:SetCmdTurnType(ChessTurnEndType.All)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:FinishChessPetTurn(finishAll, targetEntityID)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPetRender)
    local chessPetEntitys = group:GetEntities()
    for i, v in ipairs(chessPetEntitys) do
        ---@type ChessPetRenderComponent
        local chessPetRenderCmpt = v:ChessPetRender()
        if finishAll then
            chessPetRenderCmpt:SetChessPetFinishTurn(true)
        elseif targetEntityID == v:GetID() then
            chessPetRenderCmpt:SetChessPetFinishTurn(true)
        end
        chessSvcRender:RefreshChessPetFinishStateRender(v)
    end
end

--引导战旗模式下的点选
function EventListenerServiceRender:OnGuideChessClick(entityID)
    local entity = self._world:GetEntityByID(entityID)
    ---@type Vector2
    local posCaster = entity:GetGridPosition()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local targetPos = boardServiceRender:GridPosition2LocationPos(posCaster, entity)
    ---@type ChessPickUpComponent
    local chessPickUpCmpt = self._world:ChessPickUp()
    chessPickUpCmpt:SetChessClickPos(targetPos)
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.ChessPickUp)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.ChessPickUp, component)
end

--引导Monster点选
function EventListenerServiceRender:OnGuideMonsterClick(entityID)
    local entity = self._world:GetEntityByID(entityID)
    ---@type Vector2
    local position = entity:GetGridPosition()
    ---@type BoardServiceRender
    local boardSvcR = self._world:GetService("BoardRender")
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    local v3Pos = boardSvcR:GridPos2RenderPos(position)
    inputCmpt:SetTouchBeginPosition(v3Pos)

    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:CheckPreviewMonsterAction(position, Vector2(0, 0))
end

--点选主动技 未成功发送（检查未通过）的处理
function EventListenerServiceRender:_OnCastActivePickSkillFail(errorStep, errorType, activeSkillID, petPstID,
                                                               previewPickUpComponent)
    local pickPosList = {}
    if previewPickUpComponent then
        pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
    end
    local cmd = ClientExceptionReportCommand.CreateAutoFightPickErrorReport(activeSkillID, errorStep, errorType,
        pickPosList)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClientExceptionReport, cmd)
    self:OnCancelActiveSkillCast(activeSkillID, petPstID)
    --GameGlobal.TaskManager():CoreGameStartTask(self._OnCastActivePickSkillFailSwithState,self)
end

--

function EventListenerServiceRender:_OnCastActivePickSkillFailSwithState(TT)
    YIELD(TT, 500)
    if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 1)
    end
end

--发送点选主动技消息前的判断
function EventListenerServiceRender:_CheckCanSendActivePickSkillCmd(previewPickUpComponent, petEntity, skillID)
    local dbgCheck = true
    if not dbgCheck then
        return true, 0
    end
    local errorType = 0
    local canSend = true
    local isReady = AutoPickCheckHelperRender.CheckPetSkillReady(petEntity, skillID)
    if not isReady then
        errorType = ActivePickSkillCheckErrorType.PetNotReady
        canSend = false
        return canSend, errorType
    end
    if previewPickUpComponent then
        local pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
        if #pickPosList == 0 then
            local ignoreCheck = previewPickUpComponent:IsIgnorePickCheck()
            if not ignoreCheck then
                canSend = false
                errorType = ActivePickSkillCheckErrorType.PickPosListEmpty
            end
        end
    else
        canSend = false
        errorType = ActivePickSkillCheckErrorType.NoActivePickCmpt
    end
    return canSend, errorType
end

function EventListenerServiceRender:OnScanFeatureSaveInfo(data)
    ---@type Entity
    local localTeamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type ScanFeatureCommand
    local cmd = ScanFeatureCommand:New(localTeamEntity:GetID(), data.skillType, data.trapID)
    self._world:Player():SendCommand(cmd)
end

-- 小秘境 选回合奖励
function EventListenerServiceRender:OnUIMiniMazeChooseWaveAward(relicID, partnerID, isOpening)
    local cmd = ChooseMiniMazeWaveAwardCommand:New()
    cmd:SetChooseRelicID(relicID)
    cmd:SetChoosePartnerID(partnerID)
    if isOpening ~= nil then
        cmd:SetIsBattleOpening(isOpening)
    end
    self._world:Player():SendCommand(cmd)
end

---处理幻境取消选择格子
function EventListenerServiceRender:OnMirageUIClearPickUp()
    ---@type MiragePickUpComponent
    local pickUpCmpt = self._world:MiragePickUp()
    pickUpCmpt:GetCurPickUpGridPos(Vector2.zero)

    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:ClearMiragePick()
end

---处理幻境确认选择格子
function EventListenerServiceRender:OnMirageUIConfirmPickUp(autoFight)
    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    piece_service:RefreshPieceAnim()

    local gridPos = nil
    if not autoFight then
        ---@type MiragePickUpComponent
        local pickUpCmpt = self._world:MiragePickUp()
        gridPos = pickUpCmpt:GetCurPickUpGridPos()
    else
        ---@type MirageServiceRender
        local mirageSvcRender = self._world:GetService("MirageRender")
        gridPos = mirageSvcRender:GetMirageAutoFightPickUpPos()
    end

    --当被堵死时，自动战斗不发消息
    if gridPos == Vector2.zero then
        return
    end

    ---@type MiragePickUpCommand
    local cmd = MiragePickUpCommand:New()
    cmd:SetPickUpGridPos(gridPos)
    self._world:Player():SendCommand(cmd)
end

---倒计时结束，强制终止幻境
function EventListenerServiceRender:OnMirageUICountDownOver()
    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    piece_service:RefreshPieceAnim()

    ---@type MiragePickUpComponent
    local pickUpCmpt = self._world:MiragePickUp()
    pickUpCmpt:GetCurPickUpGridPos(Vector2.zero)

    ---@type MirageForceCloseCommand
    local cmd = MirageForceCloseCommand:New()
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnMirageUIRefreshStep(stepNum)
    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:RefreshMirageStepNum(stepNum)
end

function EventListenerServiceRender:OnSwitchPetEquipRefine(uiState, petPstID)
    ---@type SwitchPetEquipRefineUICommand
    local cmd = SwitchPetEquipRefineUICommand:New()
    cmd:SetCmdRefineUIState(uiState)
    cmd:SetCmdCasterPstID(petPstID)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnPopStarPickUp(pos, connectPieces)
    ---@type PopStarPickUpCommand
    local cmd = PopStarPickUpCommand:New()
    cmd:SetCmdPickUpPos(pos)
    cmd:SetCmdConnectPieces(connectPieces)
    self._world:Player():SendCommand(cmd)
end

function EventListenerServiceRender:OnResolutionChanged()
    local curState = self:_GetCurState()
    if curState == GameStateID.Loading then
        Log.info("进局loading过程中改变分辨率 不处理")
        return
    end

    --更新相机fov
    ---@type CameraService
    local cameraSvc = self._world:GetService("Camera")
    if cameraSvc then
        cameraSvc:ResetFov_ForFoldableDevice()
    end

    --更新血条位置
    ---@type Entity[]
    local entities = self._world:GetGroup(self._world.BW_WEMatchers.HP):GetEntities()
    for _, e in ipairs(entities) do
        e:HP():SetHPPosDirty(true)
    end
end
