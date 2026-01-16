--[[------------------------------------------------------------------------------------------
    TrapServiceRender : 机关表现
]] --------------------------------------------------------------------------------------------

_class("TrapServiceRender", BaseService)
---@class TrapServiceRender: BaseService
TrapServiceRender = TrapServiceRender

function TrapServiceRender:Constructor(world)
    self._trapEffectFun = {}

    ---@type TrapTargetSelector 机关目标选择器
    self._trapTargetSelector = TrapTargetSelector:New(world)

    ---机关技能表现协程任务列表
    self._listTrapTask = {}

    ---1代表左下，2代表左上，3代表右下，4代表右上
    ---以下是1920*1080分辨率基础上的偏移参考值
    self._offsetDic = {}
    self._offsetDic[1] = Vector2(400, 80)
    self._offsetDic[2] = Vector2(400, -80)
    self._offsetDic[3] = Vector2(-400, 80)
    self._offsetDic[4] = Vector2(-400, -80)
end

function TrapServiceRender:Initialize()
    ---@type RenderEntityService
    self._entityRenderService = self._world:GetService("RenderEntity")
end

--设置机关显隐
---@param trapEntity Entity
---@param isShow boolean
---@param trapRenderCmpt TrapRenderComponent
---@param playSkillService PlaySkillService
function TrapServiceRender:_ShowHideTrap(trapEntity, isShow, trapRenderCmpt, playSkillService)
    local showSkillID = trapRenderCmpt:GetShowSkillID()
    local hideSkillID = trapRenderCmpt:GetHideSkillID()

    if isShow then
        if showSkillID and showSkillID > 0 then
            local canPlayShow = trapRenderCmpt:IsTrapCanPlayShowSkill()
            if canPlayShow then
                playSkillService:PlaySkillView(trapEntity, showSkillID)
                trapRenderCmpt:SetTrapCanPlayShowSkill(false)
                trapRenderCmpt:SetTrapCanPlayHideSkill(true)
            end
        else
            trapEntity:SetViewVisible(true)
        end
    else
        if hideSkillID and hideSkillID > 0 then
            local canPlayHide = trapRenderCmpt:IsTrapCanPlayHideSkill()
            if canPlayHide then
                playSkillService:PlaySkillView(trapEntity, hideSkillID)
                trapRenderCmpt:SetTrapCanPlayHideSkill(false)
                trapRenderCmpt:SetTrapCanPlayShowSkill(true)
            end
        else
            trapEntity:SetViewVisible(false)
        end
    end
end

---怪物进入格子时隐藏机关
---@param pos Vector2
function TrapServiceRender:ShowHideTrapAtPos(pos, isShow)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    if not utilSvc then
        return --剧情模式没有 直接返回
    end

    local traps = utilSvc:GetTrapsAtPos(pos)
    for _, e in ipairs(traps) do
        local trapPos = e:GridLocation().Position
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        if
            trapRenderCmpt and (trapRenderCmpt:GetHideUnderAI() or trapRenderCmpt:GetHideUnderTeam()) and
                not e:HasDeadFlag()
         then
            self:_ShowHideTrap(e, isShow, trapRenderCmpt, playSkillService)
        end
    end
end

---玩家连线进入格子时隐藏机关
---@param pos Vector2
function TrapServiceRender:ShowHideTrapByChainMove(pos, isShow)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local traps = utilSvc:GetTrapsAtPos(pos)
    for _, e in ipairs(traps) do
        local trapPos = e:GridLocation().Position
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        if trapRenderCmpt and trapRenderCmpt:GetHideUnderTeam() and not e:HasDeadFlag() then
            self:_ShowHideTrap(e, isShow, trapRenderCmpt, playSkillService)
        end
    end
end

---@param TT TaskToken
---@param trapEntityArray Entity[]
---@param isHideOnBegin boolean
function TrapServiceRender:ShowTraps(TT, trapEntityArray, isHideOnBegin)
    local taskIDs = {}
    for _, e in ipairs(trapEntityArray) do
        local tid = GameGlobal.TaskManager():CoreGameStartTask(self.CreateSingleTrapRender, self, e, isHideOnBegin)
        if tid then
            table.insert(taskIDs, tid)
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
end

---@param TT TaskToken
---@param trapEntity Entity trap entity
---@param isHideOnBegin boolean
function TrapServiceRender:CreateSingleTrapRender(TT, trapEntity, isHideOnBegin)
    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")

    local trapID = trapEntity:TrapID():GetTrapID()

    local trapData = trapConfigData:GetTrapData(trapID)
    local pos = trapEntity:GetGridPosition()
    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()
    if trapRenderCmpt:IsHasShow() then
        Log.info("TrapServiceRender: trap has shown, entityID = ", trapEntity:GetID())
        return
    end

    trapRenderCmpt:InitByTrapData(trapID, trapData)
    trapRenderCmpt:SetTrapBornRound(BattleStatHelper.GetLevelTotalRoundCount())
    self:_TrapViewAppear(TT, trapEntity, trapData, isHideOnBegin)

    self:_PlaySingleTrapAppearSkill(TT, trapEntity, trapData)
	
    self:_OnSetGridPieceElement({trapEntity})

    local summoner = trapEntity:GetSummonerEntity()

    local cRenderBattleStat = self._world:RenderBattleStat()

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    ---@type NTTrapShow
    local nt = NTTrapShow:New(trapEntity, summoner)
    if summoner then
        nt:SetIsFirstSummon(not cRenderBattleStat:IsTrapSummonedByCasterBefore(trapID, summoner:GetID()))
    end
    playBuffSvc:PlayBuffView(TT, nt)

    if trapData.TriggerWhileSpawn then
        self:_PlayTriggerWhileSpawn(TT, trapEntity)
    end

    local gridPosition = trapEntity:GetGridPosition()
    --如果机关是0层，关闭同位置的配置了隐藏技能的机关
    if trapRenderCmpt:GetTrapLevel() == 0 then
        self:ShowHideTrapAtPos(gridPosition, false)
    end
    trapRenderCmpt:SetHasShowState(true)

    trapEntity:HP():SetShowHPSliderState(false)

    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()
    local trapData = trapConfigData:GetTrapData(trapRenderCmpt:GetTrapID())
    local hp = trapRenderCmpt:GetTrapCreationResult():GetTrapHP()
    local hpMax = trapRenderCmpt:GetTrapCreationResult():GetTrapHPMax()
    if hp and hp > 0 then
        trapEntity:ReplaceRedAndMaxHP(hp, hpMax)
    end

    --需要显示血条的机关
    if trapData.HPSliderType and trapData.HPSliderType ~= 0 then
        local trap_hpslider_entity = entityService:CreateRenderEntity(EntityConfigIDRender.TrapHPSlider)
        --血条
        self:_CreateHpSlider(trapEntity, trap_hpslider_entity, trapData)

        --血条上面显示buff
        self:_CreateBuffInfo(trapEntity, trap_hpslider_entity)

        --需要保护的机关
        if trapRenderCmpt:GetTrapType() == TrapType.Protected then
            --机关释放主动技能的能量条
            self:_CreateTrapSkillInfo(trapEntity, trap_hpslider_entity)
        end
    end

    --显示回合倒计时数字
    self:_CreateTrapRoundInfo(trapData, trapEntity)
    self:_InitTrapInfoPosition(trapData, trapEntity)

    if summoner then
        cRenderBattleStat:AddTrapIDByCasterEntityID(trapID, summoner:GetID())
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapRenderShow, trapRenderCmpt:GetTrapID())
    local areaArray = {}
    if trapData.Area then
        for i, str in ipairs(trapData.Area) do
            local numStr = string.split(str, ",")
            local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
            table.insert(areaArray, vec2)
        end
    else
        table.insert(areaArray, Vector2.zero)
    end
    ---@type NTTrapShowEnd
    local ntTrapShowEnd = NTTrapShowEnd:New(trapEntity, summoner,pos,areaArray)
    if summoner then
        ntTrapShowEnd:SetIsFirstSummon(not cRenderBattleStat:IsTrapSummonedByCasterBefore(trapID, summoner:GetID()))
    end
    playBuffSvc:PlayBuffView(TT, ntTrapShowEnd)
end

---@param TT TaskToken
---@param trapEntity Entity
function TrapServiceRender:_TrapViewAppear(TT, trapEntity, trapData, isHideOnBegin)
    local trapRenderCmpt = trapEntity:TrapRender()
    local appearSkillID = trapRenderCmpt:GetAppearSkillID()

    if trapRenderCmpt:IsSkillHadPlay(appearSkillID) then
        -- 这里因为原先的代码里有判断逻辑，拆分时保留了原样，如果不需要这里可以去掉
        Log.info("TrapServiceRender: trap appear skill had play, entityID = ", trapEntity:GetID())
        return
    end

    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceServiceR = self._world:GetService("Piece")

    local trapID = trapEntity:TrapID():GetTrapID()
    local pos = trapEntity:GetGridPosition()

    local resPath = trapData.ResPath
    if trapData.TypeParam and trapData.TypeParam.isBrokenGrid then
        local pieceEntity = pieceServiceR:FindPieceEntity(pos)
        local pieceType = pieceEntity:Piece():GetPieceType()
        resPath = boardServiceR:_GetBrokenGridPrefabPath(pieceType)
    end
    if resPath then
        self:_ReplaceAsset(trapEntity, resPath, isHideOnBegin)
    else
        Log.error("ShowTrap error resPath is nil, trapID=", trapID, " entityID=", trapEntity:GetID())
    end
    --创建头顶回合数字
    self:CreateTrapHeadShow(trapData, trapEntity)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --持久特效
    self:_ShowAppearEffect(effectService, trapEntity, trapData.PermanentEffect, 0)
    --待机特效
    self:_ShowAppearEffect(effectService, trapEntity, trapData.IdleEffect, 1)

    -- GridPieceElement字段处理，逻辑是一样的，但调的接口不一样
    local areaArray = {}
    if trapData.Area then
        for i, str in ipairs(trapData.Area) do
            local numStr = string.split(str, ",")
            local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
            table.insert(areaArray, vec2)
        end
    else
        table.insert(areaArray, Vector2.zero)
    end
    if trapData.TrapType == TrapType.TerrainAbyss and trapData.GridPieceElement then
        for _, areaPos in ipairs(areaArray) do
            boardServiceR:ReCreateGridEntity(trapData.GridPieceElement, pos + areaPos)
        end
    end
end

function TrapServiceRender:_OnSetGridPieceElement(eTraps)
    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    for _, trapEntity in ipairs(eTraps) do
        local trapID = trapEntity:TrapID():GetTrapID()
        local trapData = trapConfigData:GetTrapData(trapID)

        if trapData.TrapType ~= TrapType.TerrainAbyss then
            local areaArray = {}
            if trapData.Area then
                for i, str in ipairs(trapData.Area) do
                    local numStr = string.split(str, ",")
                    local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
                    table.insert(areaArray, vec2)
                end
            else
                table.insert(areaArray, Vector2.zero)
            end

            local pos = trapEntity:GetGridPosition()

            if trapData.GridPieceElement then
                for _, areaPos in ipairs(areaArray) do
                    boardServiceR:ReCreateGridEntity(trapData.GridPieceElement, pos + areaPos)
                end
            end
        end
    end
end

---血条
---@param trapEntity Entity
function TrapServiceRender:_CreateHpSlider(trapEntity, eHPBar, trapData)
    eHPBar:SetViewVisible(false)

    ---@type HPComponent
    local hpCmpt = trapEntity:HP()
    hpCmpt:SetShowHPSliderState(true)
    hpCmpt:SetHPOffset(trapData.HeightOffset)
    local sliderEntityID = eHPBar:GetID()
    hpCmpt:SetHPSliderEntityID(sliderEntityID)
    hpCmpt:SetHPPosDirty(true)
    eHPBar:SetViewVisible(true)

    --替换血条样式，因为机关血条也会复用，所以每次都刷。
    local go = eHPBar:View().ViewWrapper.GameObject
    local uiview = go:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local redImg = uiview:GetUIComponent("Image", "red")
    local spriteRed = uiview:GetUIComponent("Image", "spriteRed")
    local spriteBlue = uiview:GetUIComponent("Image", "spriteBlue")
    local blueHp = trapData.HPSliderColor and trapData.HPSliderColor == 1
    redImg.sprite = (blueHp == true and spriteBlue.sprite or spriteRed.sprite)

    --显示为次数血条
    if trapData.HPSliderType == 2 then
        hpCmpt:SetShowTrapSep(true)
    end
end

---血条上面显示buff
---@param trapEntity Entity
function TrapServiceRender:_CreateBuffInfo(trapEntity, eHPBar)
    ---@type HPComponent
    local hpCmpt = trapEntity:HP()
    local uiHpBuffInfoWidget = hpCmpt:GetUIHpBuffInfoWidget()
    if not uiHpBuffInfoWidget then
        local go = eHPBar:View().ViewWrapper.GameObject
        local uiview = go:GetComponent("UIView")
        ---@type UISelectObjectPath
        local buffRootPath = uiview:GetUIComponent("UISelectObjectPath", "buffRoot")
        if buffRootPath then
            local buffRoot = UICustomWidgetPool:New(self, buffRootPath)
            buffRoot:SpawnObject("UIHPBuffInfo")
            ---@type UIHPBuffInfo
            local uiHPBuffInfo = buffRoot:GetAllSpawnList()[1]
            uiHPBuffInfo:SetData(trapEntity:GetID())
            hpCmpt:SetUIHpBuffInfoWidget(buffRoot)
        end
    end
end

---机关释放主动技能的能量条
---@param trapEntity Entity
function TrapServiceRender:_CreateTrapSkillInfo(trapEntity, eHPBar)
    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()
    if #trapRenderCmpt:GetActiveSkillID() > 0 then
        local go = eHPBar:View().ViewWrapper.GameObject
        local uiview = go:GetComponent("UIView")
        ---@type UISelectObjectPath
        local skillRootPath = uiview:GetUIComponent("UISelectObjectPath", "skillRoot")
        if skillRootPath then
            local skillRoot = UICustomWidgetPool:New(eHPBar, skillRootPath)
            ---@type UIHPBuffInfo
            skillRoot:SpawnObject("UITrapSkillInfo")
            skillRoot:GetAllSpawnList()[1]:SetData(trapEntity:GetID())
            ---@type HPComponent
            local hpCmpt = trapEntity:HP()
            hpCmpt:SetUITrapSkillInfoWidget(skillRoot)
        end
    end
end

---机关头顶上的UI显示 （炮台 炸弹）
---@param trapEntity Entity
function TrapServiceRender:CreateTrapHeadShow(trapData, trapEntity)
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")

    if trapData.HeadShowType == TrapHeadShowType.HeadShowRound then
        local roundInfoEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadTrapRoundInfo)
        roundInfoEntity:ReplaceAsset(NativeUnityPrefabAsset:New("hud_trap_round_info.prefab"))
        roundInfoEntity:AddHUD()
        trapEntity:ReplaceTrapRoundInfoRender(roundInfoEntity:GetID(), trapData.HeadShowType, trapData.ShowParam)
    elseif trapData.HeadShowType == TrapHeadShowType.GridShowRound then
        local roundInfoEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadTrapRoundInfo)
        roundInfoEntity:ReplaceAsset(NativeUnityPrefabAsset:New("GridRoundInfo.prefab"))
        trapEntity:ReplaceTrapRoundInfoRender(roundInfoEntity:GetID(), trapData.HeadShowType, trapData.ShowParam)
    elseif trapData.HeadShowType == TrapHeadShowType.HeadShowLevel then
        local roundInfoEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadTrapRoundInfo)
        roundInfoEntity:ReplaceAsset(NativeUnityPrefabAsset:New("hud_trap_level_info.prefab"))
        roundInfoEntity:AddHUD()
        trapEntity:ReplaceTrapRoundInfoRender(roundInfoEntity:GetID(), trapData.HeadShowType, trapData.ShowParam)
    elseif trapData.HeadShowType == TrapHeadShowType.GridShowAnim then
        trapEntity:ReplaceTrapRoundInfoRender(nil, trapData.HeadShowType, trapData.ShowParam)
    elseif trapData.HeadShowType == TrapHeadShowType.HeadShowSummonIndex then
        local roundInfoEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadTrapRoundInfo)
        roundInfoEntity:ReplaceAsset(NativeUnityPrefabAsset:New("hud_trap_level_info.prefab"))
        roundInfoEntity:AddHUD()
        trapEntity:ReplaceTrapRoundInfoRender(roundInfoEntity:GetID(), trapData.HeadShowType, trapData.ShowParam)
    elseif trapData.ShowParam and trapData.ShowParam.roundTotal then
        trapEntity:ReplaceTrapRoundInfoRender(nil, trapData.HeadShowType, trapData.ShowParam)
    end
end

---显示回合倒计时数字
---@param trapEntity Entity
function TrapServiceRender:_CreateTrapRoundInfo(trapData, trapEntity)
    ---@type RenderAttributesComponent
    local attrCmpt = trapEntity:RenderAttributes()
    ---@type TrapRoundInfoRenderComponent
    local roundRender = trapEntity:TrapRoundInfoRender()
    if roundRender then
        local curRound = attrCmpt:GetAttribute("CurrentRound") or 1
        local totalRound = attrCmpt:GetAttribute("TotalRound")
        local last_effect_id = roundRender:GetLastEffectId()
        local inAnimName =roundRender:GetInAnimName()
        local outAnimName =roundRender:GetOutAnimName()
        if last_effect_id then
            --符文默认当前回合是0  所以创建的时候需要+1
            local cur_effect_id = last_effect_id - totalRound + 1

            local entityID = roundRender:GetRoundInfoEntityID()
            local entity = self._world:GetEntityByID(entityID)
            if entity then
                self._world:DestroyEntity(entity)
            end
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            local posSummon = trapEntity:GridLocation().Position
            entity = effectService:CreateCommonGridEffect(cur_effect_id, posSummon)
            roundRender:SetRoundInfoEntityID(entity:GetID())
            roundRender:SetEffectID(cur_effect_id)
        elseif inAnimName then
            local roundCount = totalRound - curRound+1
            self:_PlayRoundCountTrapAnim(trapEntity,roundCount)
        end
    end
end

function TrapServiceRender:_PlayRoundCountTrapAnim(trapEntity, roundCount)
    ---@type TrapRoundInfoRenderComponent
    local roundRender = trapEntity:TrapRoundInfoRender()
    local inAnimName =roundRender:GetInAnimName()
    local outAnimName =roundRender:GetOutAnimName()
    local childCount =roundRender:GetChildCount()
    if trapEntity and trapEntity:View() then
        ---@type UnityEngine.GameObject
        local gridGameObj = trapEntity:View().ViewWrapper.GameObject
        ---@type UnityEngine.GameObject[]
        local goList ={}
        for i = 1, childCount do
            local stringName = "0".. tostring(i)
            local go= GameObjectHelper.FindChild(gridGameObj.transform,stringName)
            table.insert(goList,go)
        end

        ----@type RenderBattleService
        local renderBattleService = self._world:GetService("RenderBattle")
        for i, v in ipairs(goList) do
            if  i<= roundCount then
                if roundRender:GetCurChildAnimState(i) ~= true then
                    renderBattleService:PlayAnimationByGameObject(v, { inAnimName })
                end
                roundRender:SetCurChildAnimState(i,true)
            else
                if roundRender:GetCurChildAnimState(i) ~= false then
                    renderBattleService:PlayAnimationByGameObject(v, { outAnimName })
                end
                roundRender:SetCurChildAnimState(i,false)
            end
        end

    end
end

---初始化头顶信息位置
function TrapServiceRender:_InitTrapInfoPosition(trapData, trapEntity)
    if trapData.HeadShowType == TrapHeadShowType.HeadShowRound then
        ---@type TrapRoundInfoRenderComponent
        local render = trapEntity:TrapRoundInfoRender()
        local round_entity_id = render:GetRoundInfoEntityID()
        local round_entity = self._world:GetEntityByID(round_entity_id)
        self._entityRenderService:SetHudPosition(trapEntity, round_entity, render:GetOffset())
    elseif trapData.HeadShowType == TrapHeadShowType.GridShowRound then
    end
end

--region 机关资源
---@param e Entity
function TrapServiceRender:_ReplaceAsset(e, resPath, isHideOnBegin)
    e:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, not isHideOnBegin))
end

function TrapServiceRender:_ShowAppearEffect(effectService, entityWork, listEffectID, nEffectType)
    if nil == listEffectID then
        return
    end
    for _, effectID in ipairs(listEffectID) do
        local effectEntity = effectService:CreateEffect(effectID, entityWork)
        ---@type EffectHolderComponent
        local effectHolderCmpt = entityWork:EffectHolder()
        if effectHolderCmpt ~= nil then
            if 1 == nEffectType then
                effectHolderCmpt:AttachIdleEffect(effectEntity:GetID())
            else
                effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
            end
        end
    end
end

--endregion

---检查机关状态  播放退场技能表现
function TrapServiceRender:RenderTrapState(TT, destroyType, calcStateTraps)
    local taskIDList = {}

    for _, e in ipairs(calcStateTraps) do
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        local taskID = TaskManager:GetInstance():CoreGameStartTask(self.PlayTrapDisappearSkill, self, {e})
        table.insert(taskIDList, taskID)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---触发型的机关 2020-06-16 韩玉信
---@param entityObject Entity   触发机关的对象，不是机关本身
function TrapServiceRender:ChainMovePlayTrapTrigger(triggerTraps, entityObject)
    local nTrapCount = table.count(triggerTraps)
    if nTrapCount <= 0 then
        return nil
    end
    local listTaskReturn = {}
    for i = 1, nTrapCount do
        ---@type Entity
        local entityTrap = triggerTraps[i]
        local listTaskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                self:PlayTrapTriggerSkill(TT, entityTrap, false, entityObject)
            end
        )
        if listTaskID then
            table.insert(listTaskReturn, listTaskID)
        end
    end

    table.appendArray(self._listTrapTask, listTaskReturn)
    return listTaskReturn
end

--根据机关的RaceType判断可不可以被目标触发
function TrapServiceRender:CanSelectByRaceType(trap, target)
    return self._trapTargetSelector:CanSelectTarget(trap, target)
end

---执行机关的触发表现
---@param trapEntity Entity
---@return Array taskIds
function TrapServiceRender:PlayTrapTriggerSkill(TT, trapEntity, playGroupTrap, triggerEntity)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    local cTrapRender = trapEntity:TrapRender()
    local triggerSkillContainer = cTrapRender:GetTriggerSkillResultContainer()
    if triggerSkillContainer then
        trapEntity:SkillRoutine():SetResultContainer(triggerSkillContainer)
    end

    ---@type UtilDataServiceShare
    -- local utilSvc = self._world:GetService("UtilData")
    -- local triggerSkillId = utilSvc:GetTrapTriggerSkillIDByTriggerEntity(trapEntity, triggerEntity)

    local skillResult = trapEntity:SkillRoutine():GetResultContainer()
    local triggerSkillId = skillResult:GetSkillID()
    --local targetid = skillResult:GetScopeResult():GetTargetIDs()[1]
    Log.debug("PlayTrapTriggerSkill() triggerSkillId=", triggerSkillId, " triggerEngity=", triggerEntity:GetID())

    local isSuperGrid = trapEntity:TrapRender():GetTrapRender_IsSuperGrid()
    local isPoorGrid = trapEntity:TrapRender():GetTrapRender_IsPoorGrid()
    local pos = trapEntity:GetGridPosition()
    --技能演播
    local DOStartSkillRoutine = function(TT, e, skillId)
        playBuffSvc:PlayBuffView(TT, NTTrapSkillStart:New(e, skillId, triggerEntity))
        playSkillService:PlaySkillViewSync(TT, e, skillId)
        playBuffSvc:PlayBuffView(TT, NTTrapSkillEnd:New(e, skillId, triggerEntity))
    end
    if triggerSkillId and triggerSkillId > 0 then
        DOStartSkillRoutine(TT, trapEntity, triggerSkillId)
    end

    --组合机关
    if playGroupTrap then
        local traps = self:GetGroupTrap(trapEntity)
        if traps and table.count(traps) > 0 then
            for _, e in ipairs(traps) do
                local skillId = e:TrapRender():GetTriggerSkillID()
                if skillId then
                    DOStartSkillRoutine(TT, e, skillId)
                end
            end
        end
    end

    if isSuperGrid then
        local nt = NTSuperGridTriggerEnd:New(pos)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)
    end

    if isPoorGrid then
        local nt = NTPoorGridTriggerEnd:New(pos)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)
    end
end

---执行机关的触发表现 并返回taskIds
function TrapServiceRender:PlayTrapTriggerSkillTasks(TT, traps, playGroupTrap, triggerEntity)
    if traps and #traps > 0 then
        for _, trapEntity in ipairs(traps) do
            self:PlayTrapTriggerSkill(TT, trapEntity, playGroupTrap, triggerEntity)
        end
    end
end

function TrapServiceRender:_PlayTransferTrapDestroy(TT, transferOldEntityID)
    local taskIds = {}
    if not transferOldEntityID then
        return
    end

    local transferOldEntity = self._world:GetEntityByID(transferOldEntityID)
    if not transferOldEntity then
        return
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type TrapRenderComponent
    local transferOldEntityRender = transferOldEntity:TrapRender()
    local skillId = transferOldEntityRender:GetDieSkillID()
    local hadPlayDead = transferOldEntityRender:GetHadPlayDead()
    if not hadPlayDead and skillId and skillId > 0 then
        local res = transferOldEntity:SkillRoutine():GetResultContainer("TrapDieSkill")
        transferOldEntity:SkillRoutine():SetResultContainer(res)
        local taskId = playSkillService:PlaySkillView(transferOldEntity, skillId)
        if taskId then
            table.insert(taskIds, taskId)
        end
        transferOldEntityRender:SetHadPlayDead()
    end

    if taskIds then
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
            YIELD(TT)
        end
    end

    self:DestroyTrap(TT, transferOldEntity)
end

---@param e Entity
---@param trapData table cfg_trap
function TrapServiceRender:_PlaySingleTrapAppearSkill(TT, e, trapData)
    local taskIds = {}

    if not e:HasView() then
        YIELD(TT)
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type TrapRenderComponent
    local trapCmpt = e:TrapRender()
    ---机关转化机制：在有指定机关的位置上召唤时，使用新的trapID，旧机关被销毁
    local transferTrapEntityID = trapCmpt:GetTrapCreationResult():GetTransferTrapID()
    self:_PlayTransferTrapDestroy(TT, transferTrapEntityID)

    --原坐标 替换掉的机关 销毁表现
    local replaceTrapId = trapCmpt:GetTrapCreationResult():GetReplaceTrapID()
    if replaceTrapId then
        local replaceTrap = self._world:GetEntityByID(replaceTrapId)
        if replaceTrap then
            ---@type TrapRenderComponent
            local replaceTrapRender = replaceTrap:TrapRender()
            local skillId = replaceTrapRender:GetDieSkillID()
            local hadPlayDead = replaceTrapRender:GetHadPlayDead()
            if not hadPlayDead and skillId and skillId > 0 then
                local res = replaceTrap:SkillRoutine():GetResultContainer("TrapDieSkill")
                replaceTrap:SkillRoutine():SetResultContainer(res)
                local taskId = playSkillService:PlaySkillView(replaceTrap, skillId)
                if taskId then
                    table.insert(taskIds, taskId)
                end
                replaceTrapRender:SetHadPlayDead()
            end
            if taskIds then
                while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
                    YIELD(TT)
                end
            end

            self:DestroyTrap(TT, replaceTrap)
        end
    end

    --如果在棋盘的其他面
    ---@type OutsideRegionComponent
    local outsideRegion = e:OutsideRegion()
    if outsideRegion then
        local boardIndex = outsideRegion:GetBoardIndex()
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type RenderMultiBoardComponent
        local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
        local boardRoot = renderMultiBoardCmpt:GetMultiBoardRootGameObject(boardIndex)
        if boardRoot then
            local gameObject = e:View():GetGameObject()
            gameObject.transform.parent = boardRoot.transform
            --在棋盘的其他面要设置角度
            gameObject.transform.localEulerAngles = Vector3(0, 0, 0)
        end
    end

    local showParam = trapData.ShowParam
    local dir = e:GetGridDirection()
    local forceDirection = false

    if showParam then
        local randomRotationOnBoard = tonumber(showParam.RandomRotationOnBoard)
        if randomRotationOnBoard then
            randomRotationOnBoard = randomRotationOnBoard * 200
            dir = Vector3.New(math.random(0, randomRotationOnBoard) * 0.01 - 1, 0, math.random(0, randomRotationOnBoard) * 0.01 - 1)
            forceDirection = true
        end
    end

    e:SetLocation(e:GetGridPosition() + e:GetGridOffset(), dir, forceDirection)

    e:SetViewVisible(true)
    local skillId = trapCmpt:GetAppearSkillID()
    ---登场技能就不重复播了
    if skillId and skillId > 0 and not trapCmpt:IsSkillHadPlay(skillId) then
        local appearSkillContainer = e:TrapRender():GetAppearSkillResultContainer()
        if appearSkillContainer then
            e:SkillRoutine():SetResultContainer(appearSkillContainer)
        end
        local taskId = playSkillService:PlaySkillView(e, skillId)
        trapCmpt:SetHadPlaySkill(skillId)
        if taskId then
            table.insert(taskIds, taskId)
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
        YIELD(TT)
    end
end

---@param e Entity
function TrapServiceRender:_PlayTriggerWhileSpawn(TT, e)
    local cTrapRender = e:TrapRender()
    local triggerSkillContainer = cTrapRender:GetTriggerSkillResultContainer()
    local triggerEntity = cTrapRender:GetTriggerSkillTriggeredEntity()
    if triggerSkillContainer and triggerEntity then
        self:PlayTrapTriggerSkill(TT, e, true, triggerEntity)
    end
end

---播放机关的出场技表现过程，纯表现函数
---@param traps Entity[]
function TrapServiceRender:PlayTrapAppearSkill(TT, traps)
    local taskIds = {}
    if not traps or table.count(traps) <= 0 then
        return taskIds
    end
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    for _, e in ipairs(traps) do
        if not e:HasView() then
            YIELD(TT)
        end

        ---@type TrapRenderComponent
        local trapCmpt = e:TrapRender()
        ---机关转化机制：在有指定机关的位置上召唤时，使用新的trapID，旧机关被销毁
        local transferTrapEntityID = trapCmpt:GetTrapCreationResult():GetTransferTrapID()
        self:_PlayTransferTrapDestroy(TT, transferTrapEntityID)

        --原坐标 替换掉的机关 销毁表现
        local replaceTrapId = trapCmpt:GetTrapCreationResult():GetReplaceTrapID()
        if replaceTrapId then
            local replaceTrap = self._world:GetEntityByID(replaceTrapId)
            if replaceTrap then
                ---@type TrapRenderComponent
                local replaceTrapRender = replaceTrap:TrapRender()
                local skillId = replaceTrapRender:GetDieSkillID()
                local hadPlayDead = replaceTrapRender:GetHadPlayDead()
                if not hadPlayDead and skillId and skillId > 0 then
                    local res = replaceTrap:SkillRoutine():GetResultContainer("TrapDieSkill")
                    replaceTrap:SkillRoutine():SetResultContainer(res)
                    local taskId = playSkillService:PlaySkillView(replaceTrap, skillId)
                    if taskId then
                        table.insert(taskIds, taskId)
                    end
                    replaceTrapRender:SetHadPlayDead()
                end
                table.appendArray(self._listTrapTask, taskIds)
                if taskIds then
                    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
                        YIELD(TT)
                    end
                end

                self:DestroyTrap(TT, replaceTrap)
            end
        end

        --如果在棋盘的其他面
        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion then
            local boardIndex = outsideRegion:GetBoardIndex()
            ---@type Entity
            local renderBoardEntity = self._world:GetRenderBoardEntity()
            ---@type RenderMultiBoardComponent
            local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
            local boardRoot = renderMultiBoardCmpt:GetMultiBoardRootGameObject(boardIndex)
            if boardRoot then
                local gameObject = e:View():GetGameObject()
                gameObject.transform.parent = boardRoot.transform
                --在棋盘的其他面要设置角度
                gameObject.transform.localEulerAngles = Vector3(0, 0, 0)
            end
        end

        e:SetLocation(e:GetGridPosition() + e:GetGridOffset(), e:GetGridDirection())

        e:SetViewVisible(true)
        local skillId = trapCmpt:GetAppearSkillID()
        ---登场技能就不重复播了
        if skillId and skillId > 0 and not trapCmpt:IsSkillHadPlay(skillId) then
            local appearSkillContainer = e:TrapRender():GetAppearSkillResultContainer()
            if appearSkillContainer then
                e:SkillRoutine():SetResultContainer(appearSkillContainer)
            end
            local taskId = playSkillService:PlaySkillView(e, skillId)
            trapCmpt:SetHadPlaySkill(skillId)
            if taskId then
                table.insert(taskIds, taskId)
            end
        end
    end
    table.appendArray(self._listTrapTask, taskIds)
    if taskIds then
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
            YIELD(TT)
        end
    end
    --MSG45699 临时：这个过程本来应该是一个一个机关播，先播出场技，然后播notify触发表现，再播这个创建时触发的触发技表现
    --现在是一大堆task一起等的，想让出场技结束只能在这里做
    local triggerWhileSpawnTaskID = {}
    for _, e in ipairs(traps) do
        local cTrapRender = e:TrapRender()
        local triggerSkillContainer = cTrapRender:GetTriggerSkillResultContainer()
        local triggerEntity = cTrapRender:GetTriggerSkillTriggeredEntity()
        if triggerSkillContainer and triggerEntity then
            local id = GameGlobal.TaskManager():CoreGameStartTask(self.PlayTrapTriggerSkill,self, e, true, triggerEntity)
            if id then
                table.insert(triggerWhileSpawnTaskID, id)
            end
        end
    end
    table.appendArray(self._listTrapTask, triggerWhileSpawnTaskID)
    while not TaskHelper:GetInstance():IsAllTaskFinished(triggerWhileSpawnTaskID) do
        YIELD(TT)
    end

    -- 清理掉这些数据
    for _, e in ipairs(traps) do
        e:TrapRender():SetAppearSkillResultContainer()
        e:TrapRender():SetTriggerSkillResultContainer()
        e:TrapRender():SetTriggerSkillTriggeredEntity()
    end

    return taskIds
end

---播放退场技能表现
---@param traps Entity[]
function TrapServiceRender:PlayTrapDisappearSkill(TT, traps)
    local taskIds = {}
    if not traps or table.count(traps) <= 0 then
        return taskIds
    end
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    for _, e in ipairs(traps) do
        ---@type TrapRenderComponent
        local cTrap = e:TrapRender()
        local skillId = cTrap:GetDisappearSkillID()

        ---@type DeadMarkComponent
        local deadMarkCmpt = e:DeadMark()
        local deadNotPlayDisappear = cTrap:GetDeadNotPlayDisappear()
        local canPlayDisappear = true
        if deadNotPlayDisappear == 1 and deadMarkCmpt and deadMarkCmpt:GetDeadCasterID() ~= nil then
            canPlayDisappear = false
        end
		
        if skillId and skillId > 0 and canPlayDisappear then
            local taskId = playSkillService:PlaySkillView(e, skillId)
            if taskId then
                table.insert(taskIds, taskId)
            end
        end
    end
    if taskIds then
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
            YIELD(TT)
        end
    end

    self:DestroyTrapList(TT, traps)
    return taskIds
end

function TrapServiceRender:RenderPlayTrapsDie(TT, traps)
    ---@type Entity[]
    local deadTraps = {}
    for _, e in pairs(traps) do
        if e:HasDeadFlag() then
            table.insert(deadTraps, e)
        end
    end
    if not deadTraps or table.count(deadTraps) <= 0 then
        return
    end

    local taskId = self:PlayTrapDieSkill(TT, deadTraps)
    JOIN(TT, taskId)
end

---执行机关的连锁前技表现
function TrapServiceRender:PlayTrapPreChainSkill(trapIds)
    ---@type PlaySkillService
    local sPlaySkill = self._world:GetService("PlaySkill")
    local taskIds = {}
    for i, id in ipairs(trapIds) do
        local e = self._world:GetEntityByID(id)
        ---@type TrapRenderComponent
        local cTrap = e:TrapRender()
        if cTrap then
            local skillId = cTrap:GetPreChainSkillID()
            if skillId and skillId > 0 then
                local taskId = sPlaySkill:PlaySkillView(e, skillId)
                table.insert(taskIds, taskId)
            end
        end
    end
    return taskIds
end

---删除整个数组内的Trap
function TrapServiceRender:DestroyTrapList(TT, es, bForce)
    if not es then
        return
    end
    for i, e in ipairs(es) do
        self:DestroyTrap(TT, e, bForce)
    end
end

---@param es Entity[]
---统一删除机关接口，会处理所删除机关的Block信息，所有删除机关的地方必须调这个
function TrapServiceRender:DestroyTrap(TT, entityWork, bForce)
    if not entityWork then
        return
    end
    ---@type TrapRenderComponent
    local trapRenderCmpt = entityWork:TrapRender()
    if not trapRenderCmpt then
        return
    end
    --如果是需要保护的机关不销毁
    if not bForce and trapRenderCmpt:GetTrapType() == TrapType.Protected then
        return
    end
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    ---@type NTTrapDeadStart
    local ntTrapDeadStart = NTTrapDeadStart:New(entityWork)
    local ntTrapDead = NTTrapDead:New(entityWork)
    local ownEntity = entityWork:GetSummonerEntity()
    if ownEntity then
        ntTrapDeadStart:SetOwnerEntity(ownEntity)
        ntTrapDead:SetOwnerEntity(ownEntity)
    end
    playBuffSvc:PlayBuffView(TT, ntTrapDeadStart)
    playBuffSvc:PlayBuffView(TT, ntTrapDead)
    self:DestoryHPSlider(entityWork)
    self:DestroyTrapRoundInfoRender(entityWork)

    ---@type EffectService
    local fxsvc = self._world:GetService("Effect")
    --删除创建的特效
    fxsvc:ClearEntityEffect(entityWork)
    entityWork:SetViewVisible(false)
    trapRenderCmpt:SetHadPlayDestroy()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapRenderDestroy, trapRenderCmpt:GetTrapID())
end

---播放死亡技过程
function TrapServiceRender:PlayTrapDieSkill(TT, traps, donotPlayDie)
    local taskIds = {}
    if not traps or table.count(traps) <= 0 then
        return taskIds
    end

    if not donotPlayDie then
        local dieTrapList = {}
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        ---@param e Entity
        for _, e in ipairs(traps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            local hadPlayDead = trapRenderCmpt:GetHadPlayDead()
            --没有播放过死亡表现
            if not hadPlayDead then
                local skillId = trapRenderCmpt:GetDieSkillID()
                if skillId and skillId > 0 then
                    local res = e:SkillRoutine():GetResultContainer("TrapDieSkill")
                    e:SkillRoutine():SetResultContainer(res)
                    local taskId = playSkillService:PlaySkillView(e, skillId)
                    if taskId then
                        table.insert(taskIds, taskId)
                    end
                end
                trapRenderCmpt:SetHadPlayDead()

                --如果机关是0层，打开同位置的配置了隐藏技能的机关
                local renderPos = e:GetRenderGridPosition()
                if trapRenderCmpt:GetTrapLevel() == 0 then
                    self:ShowHideTrapAtPos(renderPos, true)
                end

                table.insert(dieTrapList, e)
            end
        end
        table.appendArray(self._listTrapTask, taskIds)
        if taskIds then
            while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
                YIELD(TT)
            end
        end

        self:DestroyTrapList(TT, dieTrapList)
    else
        ---@param e Entity
        for _, e in ipairs(traps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            trapRenderCmpt:SetHadPlayDead()
        end
        self:DestroyTrapList(TT, traps)
    end

    return taskIds
end

---销毁机关血条
function TrapServiceRender:DestoryHPSlider(e)
    ---@type HPComponent
    local cHP = e:HP()
    if cHP then
        cHP:ResetHP(0, cHP:GetMaxHP())
        cHP:WidgetPoolCleanup()
        local sliderEntityID = cHP:GetHPSliderEntityID()
        local sliderEntity = self._world:GetEntityByID(sliderEntityID)
        if sliderEntity then
            self._world:DestroyEntity(sliderEntity)
        end
    end
end

---销毁机关身上的倒计时实体
---@param e Entity
function TrapServiceRender:DestroyTrapRoundInfoRender(e)
    local render = e:TrapRoundInfoRender()
    if render then
        local eId = render:GetRoundInfoEntityID()
        local eRound = self._world:GetEntityByID(eId)
        if eRound then
            self._world:DestroyEntity(eRound)
            e:RemoveTrapRoundInfoRender()
        end
    end
end

---判断触发型机关的技能是否播放完成
function TrapServiceRender:IsTrapViewTaskOver()
    if nil == self._listTrapTask then
        return true
    end

    return TaskHelper:GetInstance():IsAllTaskFinished(self._listTrapTask)
end

function TrapServiceRender:ClearTrapViewTask()
    self._listTrapTask = {}
end

---播放机关死亡，挂了deadflag的目标
function TrapServiceRender:PlayAllTrapDead(TT)
    ---@type Entity[]
    local deadTraps = {}
    local deadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadFlag)
    for _, e in ipairs(deadGroup:GetEntities()) do
        if e:HasTrapID() and e:TrapRender():GetTrapType() ~= TrapType.BombByHitBack then
            table.insert(deadTraps, e)
        end
    end

    if table.count(deadTraps) <= 0 then
        return
    end

    local taskId = self:PlayTrapDieSkill(TT, deadTraps)
    JOIN(TT, taskId)
end

function TrapServiceRender:PlayOneTrapDead(TT, trapEntity)
    if not trapEntity:HasDeadFlag() then
        return
    end

    local taskId = self:PlayTrapDieSkill(TT, {trapEntity})
    --while not TaskHelper:GetInstance():IsAllTaskFinished({ taskId }) do
    --    YIELD(TT)
    --end
    JOIN(TT, taskId)
end

---@param e Entity
function TrapServiceRender:CanDestroyAtOnce(e)
    ---@type TrapRenderComponent
    local trapRenderCmpt = e:TrapRender()
    if not trapRenderCmpt then
        return false
    end
    if trapRenderCmpt:GetTrapType() == TrapType.Protected then
        return false
    end
    if e:HasDeadFlag() then
        return true
    end
    return false
end

---检查是否是符文机关
---@param e Entity
function TrapServiceRender:IsRuneTrap(e)
    if not e:HasTrapRender() then
        return false
    end

    ---@type TrapRenderComponent
    local trapRenderCmpt = e:TrapRender()
    ---@type TrapEffectType
    local trapEffectType = trapRenderCmpt:GetTrapRenderEffectType()
    if trapEffectType == TrapEffectType.RuneChange then
        return true
    end

    return false
end

---@param trapEntity Entity
function TrapServiceRender:CalcUIPos(trapEntity)
    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()

    --守护机关不变坐标  其他有主动技的机关 根据位置不同 变化坐标
    if trapRenderCmpt:GetTrapRender_IsAircraftCore() then
        return Vector3(310, 80, 0)
    end

    ---@type GuideModule
    local guideModule = GameGlobal.GetModule(GuideModule)
    if trapRenderCmpt:GetTrapRender_IsCastSkillByRound() and guideModule:GuideInProgress() then --是新手引导
        return Vector3(-100, 0, 0)
    end

    local camera = self._world:MainCamera():Camera()
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    local inputPos = inputCmpt:GetTouchBeginPosition()

    if not inputPos then
        inputPos = trapEntity:Location():GetPosition()
    end

    local screenPos = camera:WorldToScreenPoint(inputPos)
    local areaIndex = self:_CalcAreaIndex(screenPos, camera)
    local baseOffset = self._offsetDic[areaIndex]
    local areaOffset = Vector2(baseOffset.x, baseOffset.y)
    ---根据当前的屏幕分辨率做一次适配
    local baseWidth = 1920
    local baseHeight = 1080
    local adaptWidth = (UnityEngine.Screen.width * areaOffset.x) / baseWidth
    local adaptHeight = (UnityEngine.Screen.height * areaOffset.y) / baseHeight
    areaOffset.x = adaptWidth
    areaOffset.y = adaptHeight

    local targetScreenPos = areaOffset + screenPos

    local sw = ResolutionManager.ScreenWidth()
    local rw = ResolutionManager.RealWidth()
    local rh = ResolutionManager.RealHeight()

    --这里注意一下   是否考虑屏幕缩放比例
    local factor = rw / sw
    local sx, sy = targetScreenPos.x * factor - (rw / 2), targetScreenPos.y * factor - (rh / 2)
    -- local sx, sy = targetScreenPos.x - (rw / 2), targetScreenPos.y - (rh / 2)
    targetScreenPos = Vector2(sx, sy)

    return targetScreenPos
end

---1代表左下，2代表左上，3代表右下，4代表右上
function TrapServiceRender:_CalcAreaIndex(screenPos, camera)
    local halfPixelWidth = camera.pixelWidth / 2
    local halfPixelHeight = camera.pixelHeight / 2

    local areaIndex = 0
    if screenPos.x <= halfPixelWidth then
        if screenPos.y <= halfPixelHeight then
            areaIndex = 1
        else
            areaIndex = 2
        end
    else
        if screenPos.y <= halfPixelHeight then
            areaIndex = 3
        else
            areaIndex = 4
        end
    end

    return areaIndex
end

function TrapServiceRender:GetGroupTrap(eTrapRender)
    ---@type TrapRenderComponent
    local cTrap = eTrapRender:TrapRender()

    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local traps = {}

    local triggerTargetTrapID = cTrap:GetGroupTriggerTrapID()
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        ---@type TrapRenderComponent
        local cTrapInGroup = trapEntity:TrapRender()
        if
            (eTrapRender:GetID() ~= trapEntity:GetID() and cTrap:GetGroupID() ~= 0 and cTrapInGroup:GetGroupID() ~= 0 and
                cTrap:GetGroupID() == cTrapInGroup:GetGroupID() and
                ((not triggerTargetTrapID) or (triggerTargetTrapID == cTrapInGroup:GetTrapID())))
         then
            table.insert(traps, trapEntity)
        end
    end
    return traps
end

function TrapServiceRender:UpdateTrapGridRound()
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type Entity[]
    local groupEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.TrapRoundInfoRender)
    for i, e in ipairs(groupEntityList) do
        self:UpdateTrapExistShow(e)
    end
end
---@param entity Entity
function TrapServiceRender:_UpdateTrapGridShowRound(entity,reInit)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local roundRenderCmpt = entity:TrapRoundInfoRender()
    --if roundRenderCmpt:GetHeadShowType() == TrapHeadShowType.GridShowRound then
        local attrCmpt = entity:RenderAttributes()
        local curRound = attrCmpt:GetAttribute("CurrentRound") or 1
        local totalRound = attrCmpt:GetAttribute("TotalRound")
        local pos = entity:GridLocation().Position

        ---播放特效
        local last_effect_id = roundRenderCmpt:GetLastEffectId()
        local cur_effect_id = last_effect_id - totalRound + curRound
        if reInit then
            --cur_effect_id = last_effect_id - totalRound + 1
        end
        local pre_effect_id = roundRenderCmpt:GetEffectID()
        if pre_effect_id == nil then
            roundRenderCmpt:SetEffectID(last_effect_id - totalRound + 1) --设置第一个倒计时特效
            return
        end

        if reInit or (pre_effect_id ~= cur_effect_id and pre_effect_id ~= last_effect_id)  then
            local entityID = roundRenderCmpt:GetRoundInfoEntityID()
            local entity = self._world:GetEntityByID(entityID)
            if entity then
                self._world:DestroyEntity(entity)
            end

            entity = effectService:CreateCommonGridEffect(cur_effect_id, pos)
            roundRenderCmpt:SetRoundInfoEntityID(entity:GetID())
            roundRenderCmpt:SetEffectID(cur_effect_id)
        end
    --end
end

---@param entity Entity
function TrapServiceRender:UpdateTrapExistShow(entity,reInit)
    local roundRenderCmpt = entity:TrapRoundInfoRender()
    if roundRenderCmpt:GetHeadShowType() == TrapHeadShowType.GridShowRound then
        self:_UpdateTrapGridShowRound(entity,reInit)
    elseif roundRenderCmpt:GetHeadShowType() == TrapHeadShowType.GridShowAnim then
        self:_UpdateTrapGridShowAnim(entity)
    end
end
---@param entity Entity
function TrapServiceRender:_UpdateTrapGridShowAnim(entity)
    ---@type RenderAttributesComponent
    local attrCmpt = entity:RenderAttributes()
    local curRound = attrCmpt:GetAttribute("CurrentRound") or 1
    local totalRound = attrCmpt:GetAttribute("TotalRound")
    ---@type TrapRoundInfoRenderComponent
    local roundRender = entity:TrapRoundInfoRender()
    local inAnimName =roundRender:GetInAnimName()
    if inAnimName then
        local roundCount = totalRound - curRound+1
        self:_PlayRoundCountTrapAnim(entity,roundCount)
    end
end
function TrapServiceRender:UpdateAllTrapSummonIndex()
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type Entity[]
    local groupEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.TrapRoundInfoRender)
    for i, e in ipairs(groupEntityList) do
        self:UpdateTrapSummonIndex(e)
    end
end
---@param entity Entity
function TrapServiceRender:UpdateTrapSummonIndex(entity)
    local roundRenderCmpt = entity:TrapRoundInfoRender()
    if roundRenderCmpt:GetHeadShowType() == TrapHeadShowType.HeadShowSummonIndex then
        self:_UpdateTrapSummonIndex(entity)
    end
end
---@param entity Entity
function TrapServiceRender:_UpdateTrapSummonIndex(entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type TrapRenderComponent
    local trapRenderCmpt = entity:TrapRender()
    local trapID = trapRenderCmpt:GetTrapID()
    local trapEntityID = entity:GetID()
    local entityIDList = utilDataSvc:GetSummonMeantimeLimitEntityID(trapID)
    local curIndex = 1
    for index, recordEntityID in ipairs(entityIDList) do
        if trapEntityID == recordEntityID then
            curIndex = index
            break
        end
    end
    ---@type TrapRoundInfoRenderComponent
    local roundRender = entity:TrapRoundInfoRender()
    local round_entity_id = roundRender:GetRoundInfoEntityID()
    local round_entity = self._world:GetEntityByID(round_entity_id)
    local num = curIndex
    local go = round_entity:View().ViewWrapper.GameObject
    local uiview = go:GetComponent("UIView")
    if uiview and num then
        local numText = uiview:GetUIComponent("UILocalizationText", "LevelNumText")
        if numText then
            numText:SetText(num)
        end
    end
    roundRender:SetIsShow(true)
    round_entity:SetViewVisible(true)
    --强制刷新一次
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:SetHudPosition(entity, round_entity, roundRender:GetOffset())
end

--region PrismEffectTrap
---获得该坐标的十字棱镜机关
function TrapServiceRender:GetPrismEffectTrap(pos)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local trapEntities = trapGroup:GetEntities()

    -- ---@type UtilDataServiceShare
    -- local utilSvc = self._world:GetService("UtilData")
    -- local trapEntities = utilSvc:GetTrapsAtPos(pos)

    for _, e in ipairs(trapEntities) do
        ---@type Entity
        local trapEntity = e
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        if
            not e:HasDeadFlag() and not e:HasDeadMark() and trapRenderCmpt:IsPrismEffectTrap() and
                trapEntity:GetRenderGridPosition() == pos
         then
            return e
        end
    end

    return nil
end

---设置该坐标的十字棱镜机关的显示和隐藏。关闭旧的，新的根据active显示隐藏
function TrapServiceRender:SetPrismEffectTrapShow(pos, beforePieceType, afterPieceType, active)
    local prismEffectTrap = self:GetPrismEffectTrap(pos)
    if not prismEffectTrap then
        return
    end

    ---@type EffectHolderComponent
    local effectHolderCmpt = prismEffectTrap:EffectHolder()
    if not effectHolderCmpt then
        prismEffectTrap:AddEffectHolder()
        effectHolderCmpt = prismEffectTrap:EffectHolder()
    end

    local oldPrismEffectID = GameResourceConst.PrismEffectID[beforePieceType]
    local oldEffectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[oldPrismEffectID]
    if oldEffectEntityIdList then
        local oldEffectEntity = self._world:GetEntityByID(oldEffectEntityIdList[1])
        local go = oldEffectEntity:View():GetGameObject()
        go:SetActive(false)
    end

    local prismEffectID = GameResourceConst.PrismEffectID[afterPieceType]
    local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[prismEffectID]
    local effectEntity
    if effectEntityIdList then
        effectEntity = self._world:GetEntityByID(effectEntityIdList[1])
    end

    --没有还关闭 就不创建了
    if (not effectEntity and active == false) or afterPieceType == nil then
        return
    end

    if not effectEntity then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        effectEntity = effectService:CreateEffect(prismEffectID, prismEffectTrap)
        if effectEntity then
            effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
        end

        -- GameGlobal.TaskManager():CoreGameStartTask(
        --     function(TT)
        --         YIELD(TT)
        --         if effectEntity then
        --             effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
        --             local go = effectEntity:View():GetGameObject()
        --             go:SetActive(active)
        --         end
        --     end
        -- )
    end

    if effectEntity then
        local go = effectEntity:View():GetGameObject()
        go:SetActive(active)
    end
end

function TrapServiceRender:OnClosePreviewPrismEffectTrap(pos)
    local prismEffectTrap = self:GetPrismEffectTrap(pos)
    if not prismEffectTrap then
        return
    end

    for i = PieceType.Blue, PieceType.Any do
        local curPieceType = i
        self:SetPrismEffectTrapShow(pos, nil, curPieceType, false)
    end
end

function TrapServiceRender:OnPlayPreviewPrismEffectTrapAnim(pos, pieceType, pieceAnim)
    local prismEffectTrap = self:GetPrismEffectTrap(pos)
    if not prismEffectTrap then
        return
    end

    self:SetPrismEffectTrapShow(pos, nil, pieceType, true)
    self:OnPrismEffectTrapPlayAnimWithPieceAnim(prismEffectTrap, pieceAnim)
end

function TrapServiceRender:OnPrismEffectTrapPlayAnimWithPieceAnim(trapEntity, anim)
    --预览中需要关闭的情况 直接返回
    local previewAnimNeedClose = {"Black", "Sliver", "Gray", "Color", "AtkColor", "Invalid", "Reflash"}
    if table.intable(previewAnimNeedClose, anim) then
        return
    end

    --预览中需要压暗的情况
    local previewAnimNeedDown = {"Dark", "Down"}
	
    --有怪物在上面，格子播放压暗动画
    local renderPos = trapEntity:GetRenderGridPosition()
    ---@type PieceServiceRender
    local pieceServiceR = self._world:GetService("Piece")
    local curPieceAnim = pieceServiceR:GetPieceAnimation(renderPos)

    ---@type EffectHolderComponent
    local effectHolderCmpt = trapEntity:EffectHolder()
    for i = PieceType.Blue, PieceType.Any do
        local pieceType = i

        local prismEffectID = GameResourceConst.PrismEffectID[pieceType]
        -- GameResourceConst.PrismEffectName
        local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[prismEffectID]
        if effectEntityIdList then
            local effectEntity = self._world:GetEntityByID(effectEntityIdList[1])
            local effectObject = effectEntity:View():GetGameObject()

            local animNameBase = GameResourceConst.PrismEffectName[pieceType]
            local animName = animNameBase .. "out"
            local anActive = false

            if curPieceAnim == "Down" or table.intable(previewAnimNeedDown, anim) then
                animName = animNameBase .. "in"
                anActive = true
            end

            self:PrismEffectPlayAnim(effectObject, animName, anActive)
        end
    end
end

function TrapServiceRender:PrismEffectPlayAnim(effectObject, animName, anActive)
    local lj_gezi_an = GameObjectHelper.FindChild(effectObject.transform, "lj_gezi_an")
    if lj_gezi_an.gameObject.activeInHierarchy == anActive then
       return
    end

    -- ---@type UnityEngine.Animation
    -- local anim = effectObject:GetComponentInChildren(typeof(UnityEngine.Animation))
    -- if not anim then
    --     return
    -- end

    -- anim:Play(animName)
    lj_gezi_an.gameObject:SetActive(anActive)
end

--endregion PrismEffectTrap
