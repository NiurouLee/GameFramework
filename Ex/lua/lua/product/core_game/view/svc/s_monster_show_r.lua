--[[------------------------------------------------------------------------------------------
    MonsterShowRenderService 怪物进场展示相关Service——渲染
]] --------------------------------------------------------------------------------------------

_class("MonsterShowRenderService", BaseService)
---@class MonsterShowRenderService:BaseService
MonsterShowRenderService = MonsterShowRenderService

function MonsterShowRenderService:Constructor(world)

end

--创建血条Entity
---@param eMonster Entity
function MonsterShowRenderService:CreateMonsterHPEntity(eMonster)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local cMonsterID = eMonster:MonsterID()
    local monsterId = cMonsterID:GetMonsterID()
    --正常模型资源
    local monsterResPath = monsterConfigData:GetMonsterResPath(monsterId)
    --幻象 要使用星灵模型资源
    ---@type BuffViewComponent
    local buffCmpt = eMonster:BuffView()
    local petEID = buffCmpt:GetBuffValue("ChangeModelWithPetIndex")
    if petEID then
        local petEntity = self._world:GetEntityByID(petEID)
        monsterResPath = petEntity:Asset():GetResPath()
    end

    eMonster:ReplaceAsset(NativeUnityPrefabAsset:New(monsterResPath, false)) --重置资源路径

    ---根据需要修改怪物材质，有些历史怪物是有四属性材质的
    ---@type RenderEntityService
    local renderEntitySvc = self._world:GetService("RenderEntity")
    renderEntitySvc:ModifyElementMaterial(eMonster)

    --血条
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local cHP = eMonster:HP()
    local maxhp = utilDataSvc:GetCurrentLogicMaxHP(eMonster)
    local curHP = maxhp
    if utilDataSvc:IsUseCurHPInitRedHP(eMonster) then
        curHP = utilDataSvc:GetCurrentLogicHP(eMonster)
    end
    eMonster:ReplaceRedAndMaxHP(curHP, maxhp)

    local hpOffset = monsterConfigData:GetMonsterHPHeightOffset(monsterId)
    cHP:SetHPOffset(hpOffset)

    if not table.icontains(BattleConst.NotShowHUDHPMonsters, cMonsterID:GetMonsterClassID()) then
        local hpConfigID = 0
        if eMonster:HasBoss() then
            hpConfigID = EntityConfigIDRender.BossHPSlider
        else
            hpConfigID = EntityConfigIDRender.HPSlider
        end
        local eMonsterHP = sEntity:CreateRenderEntity(hpConfigID)
        local resPath = eMonsterHP:Asset():GetResPath()
        eMonsterHP:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, false))

        --替换血条样式，因为机关血条也会复用，所以每次都刷。
        local go = eMonsterHP:View().ViewWrapper.GameObject
        local uiview = go:GetComponent("UIView")

        --region MSG56458
        ---@type UnityEngine.RectTransform
        local uiRoot = uiview:GetUIComponent("RectTransform", "Root")
        local v2Size = Vector2.zero
        v2Size.x = BattleConst.HUDHPSliderDefaultWidth * monsterConfigData:GetMonsterHUDHPWidthScale(monsterId)
        v2Size.y = uiRoot.sizeDelta.y
        uiRoot.sizeDelta = v2Size
        --endregion MSG56458

        ---@type UnityEngine.UI.Image
        local redImg = uiview:GetUIComponent("Image", "realRed")
        local spriteRed = uiview:GetUIComponent("Image", "spriteRed")
        local spriteBlue = uiview:GetUIComponent("Image", "spriteBlue")
        local spriteType3 = uiview:GetUIComponent("Image", "spriteType3")

        local hudHPBarType = monsterConfigData:GetMonsterHUDHPBarType(monsterId)

        if hudHPBarType == MonsterHUDHPBarType.Red then
            redImg.sprite = spriteRed.sprite
        elseif hudHPBarType == MonsterHUDHPBarType.Blue then
            redImg.sprite = spriteBlue.sprite
        elseif hudHPBarType == MonsterHUDHPBarType.Purple then
            redImg.sprite = spriteType3.sprite
        end

        local sliderEntityID = eMonsterHP:GetID()
        cHP:SetHPSliderEntityID(sliderEntityID)

        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local elementType = utilDataSvc:GetEntityElementPrimaryType(eMonster)

        TaskManager:GetInstance():CoreGameStartTask(
            InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
            InnerGameHelperRender:GetInstance(),
            eMonsterHP,
            elementType
        ) --加载icon
        return eMonsterHP
    end
end

---根据传进来的位置列表，创建一组怪物
---@param eMonsters Entity[]
function MonsterShowRenderService:CreateMonsterHPEntities(eMonsters)
    for _, v in ipairs(eMonsters) do
        self:CreateMonsterHPEntity(v)
    end
end

---展示召唤的怪物
---@param summonTransformData MonsterTransformParam
---@param monsterEntity Entity
function MonsterShowRenderService:ShowSummonMonster(TT, monsterEntity, summonTransformData, onlyShow)
    self:CreateMonsterHPEntity(monsterEntity)

    ---@type HPComponent
    local cHP = monsterEntity:HP()
    local eidHPBar = cHP:GetHPSliderEntityID()
    local hpBarEntity = self._world:GetEntityByID(eidHPBar)

    --if hpBarEntity then
    --    self:ShowMonsterHPBar(TT, monsterEntity, hpBarEntity)
    --end

    ---@type MonsterIDComponent
    local monsterIDCmpt = monsterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    local bodyArea = monsterEntity:BodyArea()

    ---召唤时指定的位置
    local summonPos = summonTransformData:GetPosition()
    local summonDir = summonTransformData:GetRotation()

    --先压暗格子
    ---@type PieceServiceRender
    local sPiece = self._world:GetService("Piece")

    for i, p in ipairs(bodyArea:GetArea()) do
        local pos = p + summonPos
        sPiece:SetPieceAnimDown(pos)
    end

    ---播出生剧情
    self:_PlayBornStory(TT, monsterEntity:GetID(), monsterID)

    ---挂特效
    self:_AttachBornEffect(monsterEntity)

    ---以下逻辑认为怪物在出生时，总应该设置在高度为0的位置；进度条里会把怪物提到一个较高的位置，比如1000，这里需要放下来
    monsterEntity:SetLocation(summonPos + monsterEntity:GetGridOffset(), summonDir)

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:CreateMonsterAreaOutlineEntity(monsterEntity)

    --幻象小怪 使用星灵的模型 播放阴影材质
    ---@type BuffViewComponent
    local buffCmpt = monsterEntity:BuffView()
    local modelPetIndex = buffCmpt:GetBuffValue("ChangeModelWithPetIndex")
    if modelPetIndex then
        monsterEntity:PlayMaterialAnim("common_shadoweff")
    end

    if onlyShow then
        ---只显示模型 不播放出生动画或出生技能
        monsterEntity:SetViewVisible(true)
    else
        local showAppearTaskID = self:_PlayMonsterBorn(TT, monsterEntity, summonPos)
        while not TaskHelper:GetInstance():IsTaskFinished(showAppearTaskID) do
            YIELD(TT)
        end
    end

    ---显示BOSS的UI血条
    self:_ShowBossUIHPBar(true)
    if hpBarEntity then
        self:ShowMonsterHPBar(TT, monsterEntity, hpBarEntity)
    end

    self:PlayAppearTriggeredTrap(TT, monsterEntity)
    self:PlayHideTrap(TT, monsterEntity)
end

function MonsterShowRenderService:PlayAppearTriggeredTrap(TT, monsterEntity)
    if not monsterEntity:HasAppearTriggerTrap() then
        return
    end

    ---@type AppearTriggerTrapComponent
    local cAppearTriggerTrap = monsterEntity:AppearTriggerTrap()
    local tEntities, tResults = cAppearTriggerTrap:GetData()

    local t = {}
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")
    for _, eTrap in ipairs(tEntities) do
        trapSvc:PlayTrapTriggerSkill(TT, eTrap, false, monsterEntity)
    end
end

function MonsterShowRenderService:PlayHideTrap(TT, monsterEntity)
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")

    local pos = monsterEntity:GetGridPosition()
    local tv2Body = monsterEntity:BodyArea():GetArea()
    for _, v2Body in ipairs(tv2Body) do
        local v2 = pos + v2Body
        trapSvc:ShowHideTrapAtPos(v2, false)
    end
end

--2020.6.19 修改怪物
---@param eMonsters Entity[]
function MonsterShowRenderService:ShowMonsters(TT, eMonsters, bornPosList)
    if not eMonsters or table.count(eMonsters) <= 0 then
        Log.fatal("### [ShowMonsters] eMonsters no data")
        return
    end

    ---@type PlaySkillService
    local sPlaySkill = self._world:GetService("PlaySkill")

    ---@type PieceServiceRender
    local sPiece = self._world:GetService("Piece")
    sPlaySkill:ResetWaitFreeList()

    local listWaitTask_ShowMonster = {}

    for i, casterEntity in ipairs(eMonsters) do
        ---@type MonsterIDComponent
        local monsterIDCmpt = casterEntity:MonsterID()
        local monsterID = monsterIDCmpt:GetMonsterID()

        while not casterEntity:View() do
            YIELD(TT)
        end
        ---@type HPComponent
        local cHP = casterEntity:HP()
        cHP:SetShowHPSliderState(false)

        local bodyArea = casterEntity:BodyArea()
        if not bodyArea then
            Log.exception("[MonsterShow] 怪物没有BodyArea，id:", monsterID)
            return
        end

        local birthPos = casterEntity:GetGridPosition()
        if bornPosList and #bornPosList >= i then
            birthPos = bornPosList[i]
        end

        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        if skillEffectResultContainer then --怪物出生技是个传送？
            ---@type SkillEffectResult_Teleport
            local teleportEffectResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
            if teleportEffectResult then
                birthPos = teleportEffectResult:GetPosOld()
            end
        end

        --如果在棋盘的其他面
        if casterEntity:HasOutsideRegion() then
            ---@type OutsideRegionComponent
            local OutsideRegion = casterEntity:OutsideRegion()
            local boardIndex = OutsideRegion:GetBoardIndex()

            ---@type Entity
            local renderBoardEntity = self._world:GetRenderBoardEntity()
            ---@type RenderMultiBoardComponent
            local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
            local boardRoot = renderMultiBoardCmpt:GetMultiBoardRootGameObject(boardIndex)
            if boardRoot then
                casterEntity:View():GetGameObject().transform.parent = boardRoot.transform
            end
        else
            --先压暗格子
            local gridPos = birthPos
            for i, p in ipairs(bodyArea:GetArea()) do
                local pos = p + gridPos
                sPiece:SetPieceAnimDown(pos)
            end
        end

        ---播出生剧情
        self:_PlayBornStory(TT, casterEntity:GetID(), monsterID)

        ---挂特效
        self:_AttachBornEffect(casterEntity)

        if casterEntity:HasBoss() then
            casterEntity:SetViewVisible(false)
        end

        ---以下逻辑认为怪物在出生时，总应该设置在高度为0的位置；进度条里会把怪物提到一个较高的位置，比如1000，这里需要放下来
        casterEntity:SetLocation(birthPos + casterEntity:GetGridOffset(), casterEntity:GetGridDirection())
        ---@type RenderEntityService
        local renderEntityService = self._world:GetService("RenderEntity")
        renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
        local showAppearTaskID = self:_PlayMonsterBorn(TT, casterEntity, birthPos)
        if showAppearTaskID > 0 then
            table.insert(listWaitTask_ShowMonster, showAppearTaskID)
        end

        --幻象小怪 使用星灵的模型 播放阴影材质
        ---@type BuffViewComponent
        local buffCmpt = casterEntity:BuffView()
        local modelPetIndex = buffCmpt:GetBuffValue("ChangeModelWithPetIndex")
        if modelPetIndex then
            casterEntity:PlayMaterialAnim("common_shadoweff")
        end

        if casterEntity:HasOutsideRegion() then
            --在棋盘的其他面要设置角度
            casterEntity:View():GetGameObject().transform.localEulerAngles = Vector3(0, 0, 0)
        end
    end

    ---等待所有怪物出场表现播放完毕
    local listWaitTask = sPlaySkill:GetWaitFreeList()
    table.appendArray(listWaitTask_ShowMonster, listWaitTask)
    while not TaskHelper:GetInstance():IsAllTaskFinished(listWaitTask_ShowMonster) do
        YIELD(TT)
    end

    for i, casterEntity in ipairs(eMonsters) do
        if casterEntity:HasBoss() then
            casterEntity:SetViewVisible(true)
        end
    end

    ---显示BOSS的UI血条
    self:_ShowBossUIHPBar()

    local tTaskIDs = {}
    for _, eMonster in ipairs(eMonsters) do
        local id = TaskManager:GetInstance():CoreGameStartTask(self.PlayAppearTriggeredTrap, self, eMonster)
        if id then
            table.insert(tTaskIDs, id)
        end

        self:PlayHideTrap(TT, eMonster)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(tTaskIDs) do
        YIELD(TT)
    end
end

---@param casterEntity Entity 施法者
function MonsterShowRenderService:_PlayMonsterBorn(TT, casterEntity, bornPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local nAppearSkillID = utilDataSvc:GetAppearSkillId(casterEntity)
    if nAppearSkillID and not utilDataSvc:IsArchivedBattle() then
        return self:_ShowAppearSkill(casterEntity, nAppearSkillID)
    else
        ---出生特效
        if not casterEntity:HasOutsideRegion() then
            --在棋盘的其他面不播放通用的出生特效
            self:_ShowBornEffect(casterEntity, bornPos)
        end

        casterEntity:SetViewVisible(true) ---显示模型

        ---@type HPComponent
        local hpCmpt = casterEntity:HP()
        local hpSliderID = hpCmpt:GetHPSliderEntityID()
        local hpSliderEntity = self._world:GetEntityByID(hpSliderID)

        self:ShowMonsterHPBar(TT, casterEntity, hpSliderEntity)
    end

    return -1
end

---@param casterEntity Entity 施法者
function MonsterShowRenderService:_PlayBornStory(TT, casterEntityID, monsterTemplateID)
    ---@type InnerStoryService
    local sInnerStory = self._world:GetService("InnerStory")

    sInnerStory:CheckMonsterShowAndDeadStoryTips(StoryMonsterShowType.AfterShow, monsterTemplateID, casterEntityID)
    if sInnerStory:CheckMonsterShowAndDeadStoryBanner(StoryShowType.BeginMonsterShow, monsterTemplateID) then
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
end

---@param casterEntity Entity 施法者
function MonsterShowRenderService:_AttachBornEffect(casterEntity)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")

    --怪物常驻特效ID列表
    local monsterConfigData = self._configService:GetMonsterConfigData()

    ---@type MonsterIDComponent
    local monsterIDCmpt = casterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    ---持久特效
    local permanentEffectArray = monsterConfigData:GetMonsterPermanentEffectID(monsterID)
    self:_ShowAppearEffect(sEffect, casterEntity, permanentEffectArray, 0)
    --待机特效
    local idleEffectArray = monsterConfigData:GetMonsterIdleEffectID(monsterID)
    self:_ShowAppearEffect(sEffect, casterEntity, idleEffectArray, 1)

    --存档特效
    local archEffCom = casterEntity:ArchivedEffect()
    if archEffCom then
        self:_ShowAppearEffect(sEffect, casterEntity, archEffCom.EffectIDs, 2)
    end

    --精英永久特效
    self:_CreateEntityEliteEffect(casterEntity, monsterID)
end

---@param casterEntity Entity 施法者
function MonsterShowRenderService:_ShowBornEffect(casterEntity, bornPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    ---@type RandomServiceRender
    local randomSvc = self._world:GetService("RandomRender")

    local nAppearSkillID = utilDataSvc:GetAppearSkillId(casterEntity)

    if not nAppearSkillID then
        local elementType = utilDataSvc:GetEntityElementPrimaryType(casterEntity)
        local nDefaultEffId = sEffect:GetMonsterShowEffIdByEntity(casterEntity, elementType, casterEntity:HasBoss())
        if table.intable(BattleConst.MonsterBornEffectList, nDefaultEffId) then
            local audioId =
                BattleConst.MonsterBornAudioList[randomSvc:RenderRand(1, table.count(BattleConst.MonsterBornAudioList))]
            AudioHelperController.PlayInnerGameSfx(audioId)
        end
        if nDefaultEffId then
            ---@type GridLocationComponent
            local gridLocCmpt = casterEntity:GridLocation()
            local offset = gridLocCmpt:GetGridOffset()
            local effectPos = bornPos + offset
            sEffect:CreateWorldPositionEffect(nDefaultEffId, effectPos)
        end
    end
end

---出生特效，返回一个协程ID
---@param casterEntity Entity 施法者
function MonsterShowRenderService:_ShowAppearSkill(casterEntity, nAppearSkillID)
    if nAppearSkillID and nAppearSkillID > 0 then
        local monsterClassId = casterEntity:MonsterID():GetMonsterClassID()

        local hpCmpt = casterEntity:HP()
        local hpSliderID = hpCmpt:GetHPSliderEntityID()
        local hpSliderEntity = self._world:GetEntityByID(hpSliderID)

        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            self._PlayAppearSkill,
            self,
            casterEntity,
            hpSliderEntity,
            nAppearSkillID
        ) ---主动技的出场表现，需要启动一个协程

        return taskID
    end

    return -1
end

--显示UI上的BOSS大血条
function MonsterShowRenderService:_ShowBossUIHPBar(isSummon)
    local bossIds = SortedArray:New(Algorithm.COMPARE_CUSTOM, self.SortBosses)
    local gMonster = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
    local eBossList = gMonster:GetEntities()
    local isWorldBoss = false
    local worldBossData = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if eBossList and table.count(eBossList) > 0 then
        for i, v in ipairs(eBossList) do
            ---@type BossComponent
            local bossCmpt = v:Boss()
            if not bossCmpt:IsHasShow() then
                bossCmpt:SetShowState(true)
                ---@type MonsterIDComponent
                local cMonsterId = v:MonsterID()
                local templateId = cMonsterId:GetMonsterID()
                local sepHPList = v:HP():GetHPLockSepList()
                local percent = v:HP():GetRedHP() / v:HP():GetMaxHP()
                local hasInit = v:HP():IsInitWorldBoss()

                local worldBossCurHPImageID = 0
                local worldBossPreHPImageID = 0
                if not v:HasDeadFlag() and cMonsterId:IsWorldBoss() and not hasInit then
                    ---@type MonsterConfigData
                    local monsterConfigData = self._configService:GetMonsterConfigData()
                    local stage, imageData = monsterConfigData:GetWorldBossConfig(templateId)
                    isWorldBoss = true
                    v:HP():InitWorldBossHPData(stage, imageData)
                    v:HP():SetWorldBossState(true)
                    worldBossCurHPImageID = v:HP():GetCurStageImage()
                    worldBossPreHPImageID = v:HP():GetPreStageImage()
                end
                --如果挂了BUFF 表示先不显示大血条
                ---@type BuffViewComponent
                local buffView = v:BuffView()

                if not v:HasDeadFlag() and not buffView:HasBuffEffect(BuffEffectType.NotShowBossHP) then
                    local hpBarType
                    if v:MonsterID():IsEliteMonster() then
                        hpBarType = HPBarType.EliteBoss
                    else
                        hpBarType = HPBarType.Boss
                    end
                    local hpEnergyBuffEffectType = utilDataSvc:GetEntityBuffValue(v, "HPEnergyBuffEffectType")
                    local hpEnergyVal = 0
                    local maxHPEnergyVal = 0
                    if hpEnergyBuffEffectType then
                        hpEnergyVal = utilDataSvc:GetBuffLayer(v, hpEnergyBuffEffectType)
                        ---@type BuffViewInstance
                        local bvinst = InnerGameHelperRender.GetSingleBuffByBuffEffect(v:GetID(), hpEnergyBuffEffectType)
                        if bvinst then
                            maxHPEnergyVal = bvinst:BuffConfigData():GetMaxLayerCount()
                        end
                        maxHPEnergyVal = math.max(hpEnergyVal, maxHPEnergyVal)
                    end
                    local elementType = nil
                    ---获取召唤怪的属性，因为Boss的UI血条需要显示召唤继承的属性，而非配置属性
                    if isSummon then
                        elementType = v:Element():GetPrimaryType()
                    end
                    local id = {
                        pstId = v:GetID(),
                        tplId = templateId,
                        isVice = self:IsViceBoss(v),
                        sepHPList = sepHPList,
                        percent = percent,
                        worldBossCurImageID = worldBossCurHPImageID,
                        worldBossPreImageID = worldBossPreHPImageID,
                        HPBarType = hpBarType,
                        hpEnergyVal = hpEnergyVal,
                        maxHPEnergyVal = maxHPEnergyVal,
                        curElement = elementType,
                    }
                    if isWorldBoss and bossIds:Size() > 0 then
                    else
                        bossIds:Insert(id)
                    end
                end
            end
        end
    end

    -----
    local gMonsters = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local eMonsterList = gMonsters:GetEntities()
    if eMonsterList and table.count(eMonsterList) > 0 then
        for i, v in ipairs(eMonsterList) do
            local cMonsterId = v:MonsterID()
            local templateId = cMonsterId:GetMonsterID()
            local sepHPList = v:HP():GetHPLockSepList()
            --如果挂了BUFF 表示显示大血条
            ---@type BuffViewComponent
            local buffView = v:BuffView()
            if not v:HasDeadFlag() and buffView:HasBuffEffect(BuffEffectType.CurShowBossHP) then
                local hpBarType
                if v:MonsterID():IsEliteMonster() then
                    hpBarType = HPBarType.EliteBoss
                else
                    hpBarType = HPBarType.Boss
                end
                local hpEnergyBuffEffectType = utilDataSvc:GetEntityBuffValue(v, "HPEnergyBuffEffectType")
                local hpEnergyVal = 0
                local maxHPEnergyVal = 0
                if hpEnergyBuffEffectType then
                    hpEnergyVal = utilDataSvc:GetBuffLayer(v, hpEnergyBuffEffectType)
                    ---@type BuffViewInstance
                    local bvinst = InnerGameHelperRender.GetSingleBuffByBuffEffect(v:GetID(), hpEnergyBuffEffectType)
                    if bvinst then
                        maxHPEnergyVal = bvinst:BuffConfigData():GetMaxLayerCount()
                    end
                    maxHPEnergyVal = math.max(hpEnergyVal, maxHPEnergyVal)
                end
                local elementType = nil
                ---获取召唤怪的属性，因为Boss的UI血条需要显示召唤继承的属性，而非配置属性
                if isSummon then
                    elementType = v:Element():GetPrimaryType()
                end
                local id = {
                    pstId = v:GetID(),
                    tplId = templateId,
                    isVice = self:IsViceBoss(v),
                    sepHPList = sepHPList,
                    entity = v,
                    HPBarType = hpBarType,
                    hpEnergyVal = hpEnergyVal,
                    maxHPEnergyVal = maxHPEnergyVal,
                    curElement = elementType,
                }
                bossIds:Insert(id)
            end
        end
    end
    if bossIds:Size() == 1 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowBossHp, bossIds, isWorldBoss)
    end
end

---@private
function MonsterShowRenderService.SortBosses(id1, id2)
    local tplId1 = id1.tplId
    local tplId2 = id2.tplId
    if tplId1 < tplId2 then
        return 1
    elseif tplId1 > tplId2 then
        return -1
    else
        return 0
    end
end

---是否副BOSS
function MonsterShowRenderService:IsViceBoss(e)
    ---@type MonsterIDComponent
    local cMonsterId = e:MonsterID()
    local templateId = cMonsterId:GetMonsterID()
    local list = Cfg.cfg_global["vice_boss_template_id_list"].ArrayValue
    return table.icontains(list, templateId)
end

function MonsterShowRenderService:_ShowAppearEffect(effectService, entityWork, listEffectID, nEffectType)
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
            elseif 0 == nEffectType then
                effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
            elseif 2 == nEffectType then
                effectHolderCmpt:AttachEffectByEffectID(effectID, effectEntity:GetID())
            end
        end
    end
end

---@param casterEntity Entity
---@param hpBarEntity Entity
function MonsterShowRenderService:_PlayAppearSkill(TT, casterEntity, hpBarEntity, skillID)
    ---@type PlaySkillService
    local sPlaySkill = self._world:GetService("PlaySkill")
    local taskId = sPlaySkill:PlaySkillView(casterEntity, skillID)
    while not TaskHelper:GetInstance():IsTaskFinished(taskId) do
        YIELD(TT)
    end
    self:ShowMonsterHPBar(TT, casterEntity, hpBarEntity)
end

---@param monsterEntity Entity
---@param hpBarEntity Entity
function MonsterShowRenderService:ShowMonsterHPBar(TT, monsterEntity, hpBarEntity)
    ----@type BuffViewComponent
    local buffViewCmpt = monsterEntity:BuffView()
    if buffViewCmpt then
        local lockHPList = buffViewCmpt:GetBuffValue("LockHPList")
        if lockHPList then
            monsterEntity:ReplaceInitHPLockSepList(lockHPList)
        end
    end

    local cMonsterID = monsterEntity:MonsterID()
    local monsterId = cMonsterID:GetMonsterID()
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local cfgMonsterClass = monsterConfigData:GetMonsterClass(monsterId)

    local isHPBarEnabled = cfgMonsterClass.IsHPBarEnabled ~= false
    --在其他面棋盘不显示血条
    local hasOutsideRegion = monsterEntity:HasOutsideRegion()
    if isHPBarEnabled and not hasOutsideRegion then
        local cHP = monsterEntity:HP()
        cHP:SetShowHPSliderState(true)

        monsterEntity:ReplaceHPComponent()
    end

    --血条上面显示buff
    ---@type HPComponent
    local hpCmpt = monsterEntity:HP()
    local uiHpBuffInfoWidget = hpCmpt:GetUIHpBuffInfoWidget()
    if hpBarEntity and not uiHpBuffInfoWidget then
        local go = hpBarEntity:View().ViewWrapper.GameObject
        local uiview = go:GetComponent("UIView")
        ---@type UISelectObjectPath
        local buffRootPath = uiview:GetUIComponent("UISelectObjectPath", "buffRoot")
        if buffRootPath then
            local buffRoot = UICustomWidgetPool:New(self, buffRootPath)
            buffRoot:SpawnObjects("UIHPBuffInfo", 1)
            ---@type UIHPBuffInfo
            local uiHPBuffInfo = buffRoot:GetAllSpawnList()[1]
            uiHPBuffInfo:SetData(monsterEntity:GetID())
            hpCmpt:SetUIHpBuffInfoWidget(buffRoot)
        end
    end

    --血条上面的反制主动技信息
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, monsterEntity:GetID())

    --怪物初始buff
    ---@type PlayBuffService
    local sPlayBuff = self._world:GetService("PlayBuff")
    ---@type BuffViewComponent
    local buffViewComponent = monsterEntity:BuffView()
    if buffViewComponent then
        local viewIns = buffViewComponent:GetBuffViewInstanceArray()
        for _, inst in ipairs(viewIns) do
            local context = inst:GetBuffViewContext()
            if context and context.isMonsterBornBuff then
                sPlayBuff:PlayAddBuff(TT, inst)
            end
        end
    end
    sPlayBuff:PlayBuffView(TT, NTMonsterShow:New(monsterEntity)) --通知怪物生成
end

---@param eTrapList Entity[]
---@param eMonsterList Entity[]
function MonsterShowRenderService:CreateInternalRefreshMonster(TT, eTrapList, eMonsterList,showInterval)
    local taskIDList = {}
    if eTrapList and table.count(eTrapList) > 0 then
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(trapServiceRender.ShowTraps, trapServiceRender, eTrapList)
        table.insert(taskIDList, taskID)
    end
    if eMonsterList and table.count(eMonsterList) > 0 then
        self:CreateMonsterHPEntities(eMonsterList)

        for _, e in ipairs(eMonsterList) do
            local monsterId = e:MonsterID():GetMonsterID()
            if e:HasBoss() then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideBossComing, true, monsterId)
                YIELD(TT, 2000)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideBossComing, false)
            end
        end

        for _, e in ipairs(eMonsterList) do
            local monsterTaskID = TaskManager:GetInstance():CoreGameStartTask(
                self.ShowMonsters, self, {e})
            table.insert(taskIDList, monsterTaskID)
            if showInterval and showInterval > 0 then
                YIELD(TT,showInterval)
            end
        end
    end
    if table.count(taskIDList) > 0 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIInternalRefreshMonster)
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function MonsterShowRenderService:CreateMonsterEffect(entity, monsterID)
    ---@type EffectHolderComponent
    local effectHolderCmpt = entity:EffectHolder()
    if not effectHolderCmpt then
        return
    end

    --怪物常驻特效ID列表
    local monsterConfigData = self._configService:GetMonsterConfigData()
    --创建特效
    local permanentEffectArray = monsterConfigData:GetMonsterPermanentEffectID(monsterID)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    --持久特效
    if permanentEffectArray then
        for _, effectID in ipairs(permanentEffectArray) do
            local effectEntity = sEffect:CreateEffect(effectID, entity)
            effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
        end
    end
    local idleEffectArray = monsterConfigData:GetMonsterIdleEffectID(monsterID)
    --待机特效
    if idleEffectArray then
        for _, effectID in ipairs(idleEffectArray) do
            local effectEntity = sEffect:CreateEffect(effectID, entity)
            effectHolderCmpt:AttachIdleEffect(effectEntity:GetID())
        end
    end

    --精英永久特效
    self:_CreateEntityEliteEffect(entity, monsterID)
end

---怪物死亡表现
function MonsterShowRenderService:DoAllMonsterDeadRender(TT, wait)
    local monsterDeadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadFlag)
    if not monsterDeadGroup or table.count(monsterDeadGroup) <= 0 then
        return
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local entityIDs = {}
    for _, e in ipairs(monsterDeadGroup:GetEntities()) do
        table.insert(entityIDs, e:GetID())
    end

    --查询死亡的entity上是否有被召唤的信息，如果召唤者是同批次的死亡者，则需要把这个死亡的entity提出来
    local isDeadEntitySummoner = {}
    for _, e in ipairs(monsterDeadGroup:GetEntities()) do
        if e:HasSummoner() then
            if table.intable(entityIDs, e:Summoner():GetSummonerEntityID()) then
                table.insert(isDeadEntitySummoner, e)
            end
        end
    end

    local deadTaskArray = {}
    for _, e in ipairs(monsterDeadGroup:GetEntities()) do
        if not table.intable(isDeadEntitySummoner, e) then
            local curDeadTaskID = TaskManager:GetInstance():CoreGameStartTask(self._DoOneMonsterDead, self, e)
            deadTaskArray[#deadTaskArray + 1] = curDeadTaskID
        end
    end
    --从ClientRoleTurnResultSystem 连线普攻致死传flase 表示不等待死亡表现 就进入下一状态机
    if wait == nil or wait == true then
        while not TaskHelper:GetInstance():IsAllTaskFinished(deadTaskArray) do
            YIELD(TT)
        end
    end

    --需要等召唤者的死亡技能表现完成后，将entity的召唤表现完成后，才可以继续播放死亡表现
    local deadTaskArraySecond = {}
    for _, e in ipairs(isDeadEntitySummoner) do
        local curDeadTaskID = TaskManager:GetInstance():CoreGameStartTask(self._DoOneMonsterDead, self, e)
        deadTaskArraySecond[#deadTaskArraySecond + 1] = curDeadTaskID
    end
    if wait == nil or wait == true then
        while not TaskHelper:GetInstance():IsAllTaskFinished(deadTaskArraySecond) do
            YIELD(TT)
        end
    end
end

---@param monsterEntity Entity 死亡目标
function MonsterShowRenderService:_DoOneMonsterDead(TT, monsterEntity)
    if monsterEntity:MonsterID() == nil then
        return
    end
    if monsterEntity == nil or monsterEntity:HasShowDeath() then ---如果怪物已经处于死亡表现过程
        --Log.notice("MonsterDeath has begin")
        return
    end

    monsterEntity:AddShowDeath() ---添加死亡过程标记状态

    local visible = monsterEntity:IsViewVisible()
    if not visible then ---如果目标是隐藏状态，不需要启动死亡流程
    --Log.fatal("monster is invisible")
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --死亡动画时长
    local deathTimeLen = self:_CalcDeathTimeLength(monsterEntity)

    --如果有特效连线的组件 删除掉
    if monsterEntity:HasEffectLineRenderer() then
        monsterEntity:RemoveEffectLineRenderer()
    end

    if monsterEntity:TrailEffectEx() then
        local viewWrapper = monsterEntity:View().ViewWrapper
        local trailEffectExCmpt =
            viewWrapper.GameObject.transform:Find("Root").gameObject:GetComponent(typeof(TrailsFX.TrailEffectEx))

        if trailEffectExCmpt then
            UnityEngine.Object.Destroy(trailEffectExCmpt)
        end
        monsterEntity:RemoveTrailEffectEx()
    end

    ---@type DropAssetComponent
    local dropCmpt = monsterEntity:DropAsset()
    if dropCmpt then
        self:PlayMonsterDrop(TT, dropCmpt:GetDropAsset()) --掉落表现（虚拟经济，如金币、秘境币等）
    end

    --删除怪物的常驻特效和预警特效
    self:_DestroyEffectAndWarnging(monsterEntity)

    --掉落技表现（掉落机关，如情报等）
    local dropSkillTaskID = 0
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local dropSkillId = utilDataSvc:GetDropSkill(monsterEntity)
    if dropSkillId and dropSkillId > 0 then
        dropSkillTaskID = playSkillService:PlaySkillView(monsterEntity, dropSkillId)
    end

    ---@type PlayBuffService
    local sPlayBuff = self._world:GetService("PlayBuff")
    sPlayBuff:PlayBuffView(TT, NTMonsterDeadStart:New(monsterEntity))

    ---强制刷新红血条逻辑
    ---现在有的地方会出现，刷了逻辑血量，但没更新红血量，导致会出现逻辑血量为0，红血量还大于0的情况
    ---这样修改的结果，会出现红血量和白血量一起更新的情况。这时候可以跟下日
    monsterEntity:ReplaceRedHPAndWhitHP(0)

    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterIDCmpt = monsterEntity:MonsterID()

    --死亡技能
    local deadSkillTaskID = 0
    local deadSkillId = monsterConfigData:GetMonsterDeathSkillID(monsterIDCmpt:GetMonsterID())
    if deadSkillId and deadSkillId > 0 then --播死亡技
        deadSkillTaskID = playSkillService:PlaySkillView(monsterEntity, deadSkillId)
    end
    if deadSkillTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(deadSkillTaskID) do
            YIELD(TT)
        end
    end

    --死亡非技能表现，动作
    local deadTriggerParam = "Death"
    monsterEntity:SetAnimatorControllerTriggers({deadTriggerParam})
    --死亡非技能表现，音效
    local isSyncAnim = self:_IsDeathAudioSyncAnimation(monsterEntity)
    if isSyncAnim then
        self:_PlayMonsterDeathAudio(monsterEntity)
    end
    -- local deadEffectDelay = 200
    -- YIELD(TT, deathTimeLen - deadEffectDelay)
    if not isSyncAnim then
        self:_PlayMonsterDeathAudio(monsterEntity)
    end
    --死亡非技能表现，特效
    local deadEffectWaitTime = 1
    local deadEffectEntityIDList = self:_PlayDeadEffect(TT, monsterEntity) ---返回一个死亡特效的entityID列表
    YIELD(TT, deadEffectWaitTime * 1000)

    if monsterEntity == nil then
        Log.fatal("monster entity is nil")
    end

    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)
    --上面的显示坐标是模型中点有.5  ，要减去逻辑的偏移
    local workPos = curPos - monsterEntity:GridLocation():GetGridOffset()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local pieceService = self._world:GetService("Piece")

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(monsterEntity)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    for _, p in ipairs(bodyArea) do
        local pos = workPos + p
        if gameFsmStateID ~= GameStateID.PickUpChainSkillTarget and gameFsmStateID ~= GameStateID.ChainAttack then
            local curPieceAnim = pieceService:GetPieceAnimation(pos)
            if curPieceAnim == "Down" then
                pieceService:SetPieceAnimUp(pos) -- 脚底动画
            end
        end
        sTrapRender:ShowHideTrapAtPos(pos, true) --显示机关(绷带剑盾)
    end

    local cHP = monsterEntity:HP()

    local sliderEntityID = monsterEntity:HP():GetHPSliderEntityID()
    ---@type Entity
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    if sliderEntity then
        cHP:WidgetPoolCleanup()
        self._world:DestroyEntity(sliderEntity)

        --清空buff图标
        local uiHpBuffInfoWidget = cHP:GetUIHpBuffInfoWidget()
        if uiHpBuffInfoWidget then
            ---@type UIHPBuffInfo
            local uiHPBuffInfo = uiHpBuffInfoWidget:GetAllSpawnList()[1]
            uiHPBuffInfo:OnOnwerEntityDead()
        end
    else
        Log.fatal(
            "[_DoOneMonsterDead] sliderEntity is nil!   monsterEntityID=",
            monsterEntity:GetID(),
            " sliderEntityID ",
            sliderEntityID,
            "  Log.traceback()",
            Log.traceback()
        )

        local hpGroup = self._world:GetGroup(self._world.BW_WEMatchers.HP)
        for _, e in ipairs(hpGroup:GetEntities()) do
            if e:IsViewVisible() then
                Log.fatal("[_DoOneMonsterDead] hud IsViewVisible()   HPEntityID=", e:GetID())
            end
        end
    end

    if dropSkillTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(dropSkillTaskID) do
            YIELD(TT)
        end
    end
    --死亡触发通知
    sPlayBuff:PlayBuffView(TT, NTMonsterDead:New(monsterEntity))

    sPlayBuff:PlayBuffView(TT, NTMonsterDeadEnd:New(monsterEntity))

    sPlayBuff:RemoveAllBuff(TT, monsterEntity)
    ---需要先清理掉死亡特效ID列表
    ---特效不消除 让它自己消失
    -- if deadEffectEntityIDList then
    --     for _, effectEntityID in ipairs(deadEffectEntityIDList) do
    --         local effectEntity = self._world:GetEntityByID(effectEntityID)
    --         if effectEntity then
    --             self._world:DestroyEntity(effectEntity)
    --         end
    --     end
    -- end
    if monsterEntity:HasBoss() then
        self._world:EventDispatcher():Dispatch(GameEventType.HideBossHp, monsterEntity:GetID())
    end
    --local bossGroup = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
    --if 0 == #bossGroup:GetEntities() then
    --    self._world:EventDispatcher():Dispatch(GameEventType.HideBossHp)
    --end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIMonsterDeadCountUpdate)
    --死亡特效有3秒  需要播放1秒的死亡动画以后  实际进入死亡
    --所以开了2秒的死亡表现延时  再关闭怪物
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT, 2000)

            --死亡非技能表现，死亡后特效
            self:_PostDeadEffect(monsterEntity)

            monsterEntity:SetViewVisible(false)

            ---@type EffectService
            local fxsvc = self._world:GetService("Effect")

            --删除创建的特效
            fxsvc:ClearEntityEffect(monsterEntity)

            ---@type ShowDeathComponent
            local showDeathCmpt = monsterEntity:ShowDeath()
            showDeathCmpt:SetShowDeathEnd(true)
        end
    )
end

function MonsterShowRenderService:_CalcDeathTimeLength(monsterEntity)
    local deadAnimName = "death"
    ---@type ViewComponent
    local viewCmpt = monsterEntity:View()
    if viewCmpt == nil then
        return 0
    end
    local monsterObj = viewCmpt:GetGameObject()
    local animTimeLen = GameObjectHelper.GetActorAnimationLength(monsterObj, deadAnimName)
    animTimeLen = animTimeLen * 1000
    if animTimeLen <= 0 then
        Log.fatal("animTimeLen is zero ", animTimeLen, " actor", monsterObj.name)
    end
    return animTimeLen
end

---删除怪物的常驻特效和预警特效
function MonsterShowRenderService:_DestroyEffectAndWarnging(monsterEntity)
    --删除怪物前，先删掉其身上挂的常驻特效
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    sEffect:DestroyStaticEffect(monsterEntity)
    Log.notice("MonsterDead TemplateID:", monsterEntity:MonsterID():GetMonsterID(), " EntityID:", monsterEntity:GetID())
    ---@type EntityPoolServiceRender
    local entityPoolSvcR = self._world:GetService("EntityPool")
    --删除预警范围
    local warningAreaGroup = self._world:GetGroup(self._world.BW_WEMatchers.DamageWarningAreaElement)
    local destroyList = {}
    local entityID = monsterEntity:GetID()
    for _, areaEntity in ipairs(warningAreaGroup:GetEntities()) do
        if areaEntity:DamageWarningAreaElement():GetOwnerEntityID() == entityID then
            destroyList[#destroyList + 1] = areaEntity
        end
    end
    for i = 1, #destroyList do
        local entity = destroyList[i]
        ---@type DamageWarningAreaElementComponent
        local cmpt = entity:DamageWarningAreaElement()
        cmpt:ClearOwnerEntityID()
        local entityConfigID =cmpt:GetEntityConfigID()
        if entityConfigID then
            entityPoolSvcR:DestroyCacheEntity(entity,entityConfigID)
        else
            entityPoolSvcR:DestroyCacheEntity(entity,EntityConfigIDRender.WarningArea)
        end
        cmpt:ClearOwnerEntityID()
    end
end

---掉落表现（虚拟经济，如金币、秘境币等）
function MonsterShowRenderService:PlayMonsterDrop(TT, drop)
    if not drop then
        return
    end
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    --{Drops = {asset = asset, effect = (v.dropEffectID or 0)}, Pos = monsterEntity:GridLocation():Center()}
    playSkillService:DoDropAnimation(drop.Drops, drop.Pos)
end

---死亡音效是否要和死亡动作同步播放
---@param deadMonsterEntity Entity
function MonsterShowRenderService:_IsDeathAudioSyncAnimation(deadMonsterEntity)
    local cMonsterID = deadMonsterEntity:MonsterID()
    if not cMonsterID then
        return false
    end
    local monsterID = cMonsterID:GetMonsterID()
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local isSyncAnim = monsterConfigData:DeathAudioSyncAnimation(monsterID)
    return isSyncAnim
end

---@param deadMonsterEntity Entity
function MonsterShowRenderService:_PlayMonsterDeathAudio(deadMonsterEntity)
    local monsterIDCmpt = deadMonsterEntity:MonsterID()
    if monsterIDCmpt == nil then
        return false
    end
    local monsterID = monsterIDCmpt:GetMonsterID()
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local deathAudioID = monsterConfigData:GetDeathAudioID(monsterID)
    if deathAudioID == nil then
        deathAudioID = CriAudioIDConst.SouncCoreGameMonsterDeath
    end
    AudioHelperController.PlayInnerGameSfx(deathAudioID)
end

---播放死亡特效
---@param deadMonsterEntity Entity
---@return array 特效ID列表
function MonsterShowRenderService:_PlayDeadEffect(TT, deadMonsterEntity)
    local deadEffectEntityIDList = {}

    local monsterDeadType = DeathShowType.None

    local monsterIDCmpt = deadMonsterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()
    local monsterConfigData = self._configService:GetMonsterConfigData()
    ---@type DeathShowType
    local deathShowType = monsterConfigData:GetDeathShowType(monsterID)
    monsterDeadType = deathShowType
    local deathEffectID = nil
    if monsterDeadType == DeathShowType.DissolveLight then
        deadMonsterEntity:NewPlayDeadLight()
        deathEffectID = BattleConst.MonsterDeadEffectLight
    elseif monsterDeadType == DeathShowType.DissolveDark then
        deadMonsterEntity:NewPlayDeadDark()
        deathEffectID = BattleConst.MonsterDeadEffectDark
    else
        deathEffectID = monsterConfigData:GetDeathShowEffectID(monsterID)
    end
    if deathEffectID then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        if type(deathEffectID) == "number" then
            deathEffectID = {deathEffectID}
        end
        for i, effID in ipairs(deathEffectID) do
            local effectEntity = effectService:CreateEffect(effID, deadMonsterEntity)
            deadEffectEntityIDList[#deadEffectEntityIDList + 1] = effectEntity:GetID()
        end
    end

    if deadMonsterEntity == nil then
        Log.fatal("entity is dead---------------------")
    end
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    innerStoryService:CheckMonsterShowAndDeadStoryTips(
        StoryMonsterShowType.BeginDeadAnimation,
        monsterID,
        deadMonsterEntity:GetID()
    )
    if innerStoryService:CheckMonsterShowAndDeadStoryBanner(StoryShowType.AfterMonsterDead, monsterID) then
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
    return deadEffectEntityIDList
end

function MonsterShowRenderService:_PostDeadEffect(deadMonsterEntity)
    deadMonsterEntity:StopMaterialAnimLayer(MaterialAnimLayer.Death)
end

function MonsterShowRenderService:PlaySpawnInWave(TT, traps, monsters,showInterval)
    self:CreateInternalRefreshMonster(TT, traps, monsters,showInterval)
end

---把Loading时未加载到空中的怪物放下来（主要用于提早放下来的情况，比如炸弹BOSS）
---@param isShow boolean 是否显示
function MonsterShowRenderService:PullDownNotLoadHighMonsters()
    local g = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(g:GetEntities()) do
        local monsterClassId = e:MonsterID():GetMonsterClassID()
        if table.icontains(BattleConst.NotLoadHighMonsters, monsterClassId) then --不加载在空中的怪物不需要隐藏
            e:SetPosition(e:GetGridPosition() + e:GetGridOffset())

            --那些不移动到空中的也要先关闭血条
            ---@type HPComponent
            local cHP = e:HP()
            if cHP then
                cHP:SetShowHPSliderState(false)
            end
        end
    end
end

---@param monsterEntity Entity 死亡目标
---消亡
function MonsterShowRenderService:DoOneMonsterFeatureDead(TT, monsterEntity)
    if monsterEntity:MonsterID() == nil then
        return
    end
    if monsterEntity == nil or monsterEntity:HasShowDeath() then ---如果怪物已经处于死亡表现过程
        return
    end

    monsterEntity:AddShowDeath() ---添加死亡过程标记状态

    local visible = monsterEntity:IsViewVisible()
    if not visible then ---如果目标是隐藏状态，不需要启动死亡流程
    end

    --如果有特效连线的组件 删除掉
    if monsterEntity:HasEffectLineRenderer() then
        monsterEntity:RemoveEffectLineRenderer()
    end

    --删除怪物的常驻特效和预警特效
    self:_DestroyEffectAndWarnging(monsterEntity)

    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterIDCmpt = monsterEntity:MonsterID()

    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)
    --上面的显示坐标是模型中点有.5  ，要减去逻辑的偏移
    local workPos = curPos - monsterEntity:GridLocation():GetGridOffset()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local pieceService = self._world:GetService("Piece")

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(monsterEntity)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    for _, p in ipairs(bodyArea) do
        local pos = workPos + p
        if gameFsmStateID ~= GameStateID.PickUpChainSkillTarget and gameFsmStateID ~= GameStateID.ChainAttack then
            local curPieceAnim = pieceService:GetPieceAnimation(pos)
            if curPieceAnim == "Down" then
                pieceService:SetPieceAnimUp(pos) -- 脚底动画
            end
        end
        sTrapRender:ShowHideTrapAtPos(pos, true) --显示机关(绷带剑盾)
    end

    local cHP = monsterEntity:HP()
    local sliderEntityID = monsterEntity:HP():GetHPSliderEntityID()
    ---@type Entity
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    if sliderEntity then
        cHP:WidgetPoolCleanup()
        self._world:DestroyEntity(sliderEntity)

        --清空buff图标
        local uiHpBuffInfoWidget = cHP:GetUIHpBuffInfoWidget()
        if uiHpBuffInfoWidget then
            ---@type UIHPBuffInfo
            local uiHPBuffInfo = uiHpBuffInfoWidget:GetAllSpawnList()[1]
            uiHPBuffInfo:OnOnwerEntityDead()
        end
    end

    ---@type PlayBuffService
    local sPlayBuff = self._world:GetService("PlayBuff")
    sPlayBuff:RemoveAllBuff(TT, monsterEntity)

    monsterEntity:SetViewVisible(false)

    --删除创建的特效
    ---@type EffectService
    local fxsvc = self._world:GetService("Effect")
    fxsvc:ClearEntityEffect(monsterEntity)

    ---@type ShowDeathComponent
    local showDeathCmpt = monsterEntity:ShowDeath()
    showDeathCmpt:SetShowDeathEnd(true)
end

function MonsterShowRenderService:MonsterGridAnimDown()
    ---@type PieceServiceRender
    local sPiece = self._world:GetService("Piece")
    local globalMonsterGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    local monsterPosList ={}
    for _, e in ipairs(globalMonsterGroup) do
        if not e:HasDeadMark() and not e:HasOutsideRegion() then
            local bodyArea = e:BodyArea()
            local gridPos = e:GetGridPosition()
            for i, p in ipairs(bodyArea:GetArea()) do
                local pos = p + gridPos
                table.insert(monsterPosList,pos)
            end
        end
    end
    ---@type  PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieceTable = env:GetAllPieceType()
    for x, columnDic in pairs(pieceTable) do
        for y, curGridType in pairs(columnDic) do
            local curGridPos = Vector2(x, y)
            if not table.Vector2Include(monsterPosList,curGridPos) then
                sPiece:SetPieceAnimNormal(curGridPos)
            else
                sPiece:SetPieceAnimDown(curGridPos)
            end
        end
    end
end

--死亡过程不播放死亡技能、死亡动画、死亡特效和音效
---@param monsterEntity Entity 死亡目标
function MonsterShowRenderService:PlayOneMonsterSpDead(TT, monsterEntity)
    if monsterEntity:MonsterID() == nil then
        return
    end
    if monsterEntity == nil or monsterEntity:HasShowDeath() then ---如果怪物已经处于死亡表现过程
        --Log.notice("MonsterDeath has begin")
        return
    end

    monsterEntity:AddShowDeath() ---添加死亡过程标记状态

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --如果有特效连线的组件 删除掉
    if monsterEntity:HasEffectLineRenderer() then
        monsterEntity:RemoveEffectLineRenderer()
    end

    if monsterEntity:TrailEffectEx() then
        local viewWrapper = monsterEntity:View().ViewWrapper
        local trailEffectExCmpt =
        viewWrapper.GameObject.transform:Find("Root").gameObject:GetComponent(typeof(TrailsFX.TrailEffectEx))

        if trailEffectExCmpt then
            UnityEngine.Object.Destroy(trailEffectExCmpt)
        end
        monsterEntity:RemoveTrailEffectEx()
    end

    ---@type DropAssetComponent
    local dropCmpt = monsterEntity:DropAsset()
    if dropCmpt then
        self:PlayMonsterDrop(TT, dropCmpt:GetDropAsset()) --掉落表现（虚拟经济，如金币、秘境币等）
    end

    --删除怪物的常驻特效和预警特效
    self:_DestroyEffectAndWarnging(monsterEntity)

    --掉落技表现（掉落机关，如情报等）
    local dropSkillTaskID = 0
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local dropSkillId = utilDataSvc:GetDropSkill(monsterEntity)
    if dropSkillId and dropSkillId > 0 then
        dropSkillTaskID = playSkillService:PlaySkillView(monsterEntity, dropSkillId)
    end

    ---@type PlayBuffService
    local sPlayBuff = self._world:GetService("PlayBuff")
    sPlayBuff:PlayBuffView(TT, NTMonsterDeadStart:New(monsterEntity))

    ---强制刷新红血条逻辑
    ---现在有的地方会出现，刷了逻辑血量，但没更新红血量，导致会出现逻辑血量为0，红血量还大于0的情况
    ---这样修改的结果，会出现红血量和白血量一起更新的情况。这时候可以跟下日
    monsterEntity:ReplaceRedHPAndWhitHP(0)

    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterIDCmpt = monsterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    innerStoryService:CheckMonsterShowAndDeadStoryTips(
        StoryMonsterShowType.BeginDeadAnimation,
        monsterID,
        monsterEntity:GetID()
    )
    if innerStoryService:CheckMonsterShowAndDeadStoryBanner(StoryShowType.AfterMonsterDead, monsterID) then
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
    YIELD(TT, 1000)

    if monsterEntity == nil then
        Log.fatal("monster entity is nil")
    end

    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)
    --上面的显示坐标是模型中点有.5  ，要减去逻辑的偏移
    local workPos = curPos - monsterEntity:GridLocation():GetGridOffset()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local pieceService = self._world:GetService("Piece")

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(monsterEntity)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    for _, p in ipairs(bodyArea) do
        local pos = workPos + p
        if gameFsmStateID ~= GameStateID.PickUpChainSkillTarget and gameFsmStateID ~= GameStateID.ChainAttack then
            local curPieceAnim = pieceService:GetPieceAnimation(pos)
            if curPieceAnim == "Down" then
                pieceService:SetPieceAnimUp(pos) -- 脚底动画
            end
        end
        sTrapRender:ShowHideTrapAtPos(pos, true) --显示机关(绷带剑盾)
    end

    local cHP = monsterEntity:HP()

    local sliderEntityID = monsterEntity:HP():GetHPSliderEntityID()
    ---@type Entity
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    if sliderEntity then
        cHP:WidgetPoolCleanup()
        self._world:DestroyEntity(sliderEntity)

        --清空buff图标
        local uiHpBuffInfoWidget = cHP:GetUIHpBuffInfoWidget()
        if uiHpBuffInfoWidget then
            ---@type UIHPBuffInfo
            local uiHPBuffInfo = uiHpBuffInfoWidget:GetAllSpawnList()[1]
            uiHPBuffInfo:OnOnwerEntityDead()
        end
    else
        Log.fatal(
            "[PlayOneMonsterDeadBySPEffect] sliderEntity is nil!   monsterEntityID=",
            monsterEntity:GetID(),
            " sliderEntityID ",
            sliderEntityID,
            "  Log.traceback()",
            Log.traceback()
        )

        local hpGroup = self._world:GetGroup(self._world.BW_WEMatchers.HP)
        for _, e in ipairs(hpGroup:GetEntities()) do
            if e:IsViewVisible() then
                Log.fatal("[PlayOneMonsterDeadBySPEffect] hud IsViewVisible()   HPEntityID=", e:GetID())
            end
        end
    end

    if dropSkillTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(dropSkillTaskID) do
            YIELD(TT)
        end
    end
    --死亡触发通知
    sPlayBuff:PlayBuffView(TT, NTMonsterDead:New(monsterEntity))

    sPlayBuff:PlayBuffView(TT, NTMonsterDeadEnd:New(monsterEntity))

    sPlayBuff:RemoveAllBuff(TT, monsterEntity)
    if monsterEntity:HasBoss() then
        self._world:EventDispatcher():Dispatch(GameEventType.HideBossHp, monsterEntity:GetID())
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIMonsterDeadCountUpdate)
    --死亡特效有3秒  需要播放1秒的死亡动画以后  实际进入死亡
    --所以开了2秒的死亡表现延时  再关闭怪物
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT, 2000)

            --死亡非技能表现，死亡后特效
            self:_PostDeadEffect(monsterEntity)

            monsterEntity:SetViewVisible(false)

            ---@type EffectService
            local fxsvc = self._world:GetService("Effect")

            --删除创建的特效
            fxsvc:ClearEntityEffect(monsterEntity)

            ---@type ShowDeathComponent
            local showDeathCmpt = monsterEntity:ShowDeath()
            showDeathCmpt:SetShowDeathEnd(true)
        end
    )
end

---@param entity Entity
---@param monsterID number
function MonsterShowRenderService:_CreateEntityEliteEffect(entity, monsterID)
    ---@type EffectHolderComponent
    local effectHolderCmpt = entity:EffectHolder()
    if not effectHolderCmpt then
        return
    end

    ---@type EffectService
    local effectSvc = self._world:GetService("Effect")

    ---@type MonsterIDComponent
    local monsterIDCmpt = entity:MonsterID()
    if not monsterIDCmpt then
        return
    end
    --精英永久特效
    local isEliteMonster = monsterIDCmpt:IsEliteMonster()
    if isEliteMonster then
        ---QA：MSG57883 精英词缀显示效果优化
        ---精英词条没配置特效列表，则使用原精英特效
        local eliteIDs = monsterIDCmpt:GetEliteIDArray()
        local effIDList = self:GetEliteEffectIDList(entity, eliteIDs)
        for _, id in ipairs(effIDList) do
            local effectEntity = effectSvc:CreateEffect(id, entity)
            effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
            effectHolderCmpt:AddEliteEffID(id, effectEntity:GetID())
        end
    end
end

function MonsterShowRenderService:GetEliteEffectIDList(entity, eliteIDArray)
    local effIDList = {}
    ---@type MonsterIDComponent
    local monsterIDCmpt = entity:MonsterID()
    if not monsterIDCmpt then
        return effIDList
    end
    local monsterID = monsterIDCmpt:GetMonsterID()

    local bodyAreaCount = entity:BodyArea():GetAreaCount()

    ---QA：MSG57883 精英词缀显示效果优化
    ---精英词条没配置特效列表，则使用原精英特效
    local eliteEffIDList = {}
    for _, eliteID in ipairs(eliteIDArray) do
        local cfgElite = Cfg.cfg_monster_elite[eliteID]
        if cfgElite and cfgElite.EffectID then
            table.insert(eliteEffIDList, cfgElite.EffectID)
        end
    end
    if #eliteEffIDList > 0 then
        for _, effIDStr in ipairs(eliteEffIDList) do
            local effIDStrList = string.split(effIDStr, ",")
            if effIDStrList and #effIDStrList == 2 then
                local effectID = tonumber(effIDStrList[1])
                if bodyAreaCount ~= 1 then
                    effectID = tonumber(effIDStrList[2])
                end
                if not table.icontains(effIDList, effectID) then
                    table.insert(effIDList, effectID)
                end
            end
        end
    else
        local monsterConfigData = self._configService:GetMonsterConfigData()
        local disableEliteEffect = monsterConfigData:IsDisableEliteEffect(monsterID)
        if not disableEliteEffect then
            local effectID = BattleConst.EliteMonsterPermanentEffectBodyArea1
            if bodyAreaCount == 4 then
                effectID = BattleConst.EliteMonsterPermanentEffectBodyArea4
            end
            table.insert(effIDList, effectID)
        end
    end

    return effIDList
end
