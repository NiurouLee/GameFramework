--[[------------------------------------------------------------------------------------------
    InnerGameHelperRender : 存放一些局内公共函数
    这个对象有点乱，抽空要改掉
]] --------------------------------------------------------------------------------------------

---@class InnerGameHelperRender: Singleton
_class("InnerGameHelperRender", Singleton)
InnerGameHelperRender = InnerGameHelperRender

function InnerGameHelperRender:Constructor()
    self._ElementIconAtlas = ResourceManager:GetInstance():SyncLoadAsset("InnerUI.spriteatlas", LoadType.SpriteAtlas)
    self.atlasProperty = ResourceManager:GetInstance():SyncLoadAsset("Property.spriteatlas", LoadType.SpriteAtlas)
end

function InnerGameHelperRender:Dispose()
    if self._ElementIconAtlas then
        self._ElementIconAtlas:Dispose()
        self._ElementIconAtlas = nil
    end
    --[[
    for i = 1, #self._elementSprites do
        UnityEngine.Object.Destroy(self._elementSprites[i])
    end
    self._elementSprites = {}
    ]]
end

---@param elementType ElementType
function InnerGameHelperRender:GetLifeBarIconByElement(elementType)
    if not self.atlasProperty then
        self.atlasProperty = ResourceManager:GetInstance():SyncLoadAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    end
    local iconName = Cfg.cfg_pet_element[elementType]
    if not iconName then
        Log.fatal("GetConfigIconFailed ElementType:", elementType)
        return
    end
    local sprite =
        self.atlasProperty.Obj:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(iconName.Icon .. "_battle"))
    return sprite
end

function InnerGameHelperRender:GetImageFromInnerUI(imageName)
    if not self._ElementIconAtlas then
        self._ElementIconAtlas =
            ResourceManager:GetInstance():SyncLoadAsset("InnerUI.spriteatlas", LoadType.SpriteAtlas)
    end
    return self._ElementIconAtlas.Obj:GetSprite(imageName)
end

--如果存在的话通过Entitiy获得里面存储的GameObject，没有返回nil
function InnerGameHelperRender:GetGameObject(entity)
    local viewCmpt = entity:View()
    if viewCmpt == nil then
        return nil
    end
    local gameObj = viewCmpt:GetGameObject()
    return gameObj
end

---通过HpSliderEntity创建上面的元素图标
---@return  boolean
function InnerGameHelperRender:SetHpSliderElementIcon(TT, entity, elementType)
    local gameObject = self:GetGameObject(entity)
    if not gameObject then
        Log.fatal("SetHpSliderElementIcon Failed ElementType:", elementType)
        return false
    end
    ---@type UIView
    local uiView = gameObject:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local elementIcon = uiView:GetUIComponent("Image", "imgElement")
    if elementIcon and elementType ~= 0 then
        elementIcon.gameObject:SetActive(true)
        elementIcon.sprite = self:GetLifeBarIconByElement(elementType)
    else
        elementIcon.gameObject:SetActive(false)
    end
    ---@type UnityEngine.UI.Image
    local imgBG = uiView:GetUIComponent("Image", "imgBG")
    ---@type UnityEngine.GameObject
    local eff_glow = uiView:GetGameObject("eff_glow")
    imgBG.gameObject:SetActive(false)
    eff_glow:SetActive(false)
    return true
end

function InnerGameHelperRender:IsUIBannerComplete(TT)
    ---等待对话框创建
    local uiBannerShow = GameGlobal.UIStateManager():IsShow("UIStoryBanner")
    while uiBannerShow == false do
        uiBannerShow = GameGlobal.UIStateManager():IsShow("UIStoryBanner")
        YIELD(TT)
        if not GameGlobal:GetInstance():IsCoreGameRunning() then
            return
        end
    end

    while uiBannerShow == true do
        uiBannerShow = GameGlobal.UIStateManager():IsShow("UIStoryBanner")
        YIELD(TT)
        if not GameGlobal:GetInstance():IsCoreGameRunning() then
            return
        end
    end
end

function InnerGameHelperRender:SetKeepAnimatorControllerStateOnDisable(casterEntity, bDisable)
    local gameObject = casterEntity:View().ViewWrapper.GameObject
    if not gameObject then
        Log.fatal("[SetKeepAnimatorControllerStateOnDisable] gameObject is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local rootGO = gameObject.transform:Find("Root")
    if not rootGO then
        Log.fatal("[SetKeepAnimatorControllerStateOnDisable] rootGO is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local animator = rootGO:GetComponent("Animator")
    if not animator then
        animator = gameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
    end
    if not animator then
        Log.fatal("[SetKeepAnimatorControllerStateOnDisable] animator is Nil")
        return
    end
    local bData = bDisable or true
    local nOldData = animator.keepAnimatorControllerStateOnDisable
    animator.keepAnimatorControllerStateOnDisable = bData
    return nOldData
end

function InnerGameHelperRender:SetAnimatorControllerTrigger(entity, triggerTable, needUpdate)
    local gameObject = entity:View().ViewWrapper.GameObject
    if not gameObject then
        Log.fatal("[SetAnimatorControllerTrigger] gameObject is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local rootGO = gameObject.transform:Find("Root")
    if not rootGO then
        Log.fatal("[SetAnimatorControllerTrigger] rootGO is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local animator = rootGO:GetComponent("Animator")
    if not animator then
        animator = gameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
    end
    if not animator then
        Log.fatal("[SetAnimatorControllerTrigger] animator is Nil", Log.traceback())
        return
    end

    for i = 1, #triggerTable do
        animator:SetTrigger(triggerTable[i])
    end
    if needUpdate then
        animator:Update(0)
    end
end

function InnerGameHelperRender:SetAnimatorControllerBool(entity, boolTable)
    local gameObject = entity:View().ViewWrapper.GameObject
    if not gameObject then
        Log.fatal("[SetAnimatorControllerBool] gameObject is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local rootGO = gameObject.transform:Find("Root")
    if not rootGO then
        Log.fatal("[SetAnimatorControllerBool] rootGO is Nil")
        return
    end
    ---@type UnityEngine.Animator
    local animator = rootGO:GetComponent("Animator")
    if not animator then
        animator = gameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
    end
    if not animator then
        Log.fatal("[SetAnimatorControllerBool] animator is Nil")
        return
    end

    for param, value in pairs(boolTable) do
        animator:SetBool(param, value)
    end
end

---@return MainWorld
function InnerGameHelperRender.GetMainWorld()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()

    return mainWorld
end

---获取机关本回合还可以使用技能的次数
function InnerGameHelperRender.GetTrapCurRoundCanCastSkillCount(trapEntityID)
    local oneRoundLimit = InnerGameHelperRender.GetTrapAttribute(trapEntityID, "OneRoundLimit")
    local castSkillRound = InnerGameHelperRender.GetTrapAttribute(trapEntityID, "CastSkillRound")
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type BattleStatComponent
    local battleStatCmpt = world:BattleStat()
    local curRound = battleStatCmpt:GetLevelTotalRoundCount()
    for _, round in ipairs(castSkillRound) do
        if round == curRound then
            oneRoundLimit = oneRoundLimit - 1
        end
    end

    return oneRoundLimit
end

function InnerGameHelperRender.GetTrapAttribute(trapEntityID, attribute)
    local world = InnerGameHelperRender.GetMainWorld()
    local e = world:GetEntityByID(trapEntityID)
    ---@type AttributesComponent
    local attributesComponent = e:Attributes()
    return attributesComponent:GetAttribute(attribute)
end

function InnerGameHelperRender.GetTrapCanCastSkill(trapEntityID)
    local world = InnerGameHelperRender.GetMainWorld()
    local trapLogic = world:GetService("TrapLogic")
    local e = world:GetEntityByID(trapEntityID)
    local ret = trapLogic:CanCastTrapSkill(e)
    return ret
end

function InnerGameHelperRender.CalcUIPos(trapEntityID)
    local world = InnerGameHelperRender.GetMainWorld()
    local trapRender = world:GetService("TrapRender")
    local e = world:GetEntityByID(trapEntityID)
    local ret = trapRender:CalcUIPos(e)
    return ret
end

function InnerGameHelperRender.GetTrapActiveSkillList(trapEntityID)
    local world = InnerGameHelperRender.GetMainWorld()
    local trapLogic = world:GetService("TrapLogic")
    local e = world:GetEntityByID(trapEntityID)
    local ret = trapLogic:GetTrapActiveSkillList(e)
    return ret
end

---
function InnerGameHelperRender.GetTrapIsCastSkillByRound(trapEntityID)
    local world = InnerGameHelperRender.GetMainWorld()
    local e = world:GetEntityByID(trapEntityID)
    return e:TrapRender():GetTrapRender_IsCastSkillByRound()
end

function InnerGameHelperRender.GetUIBuffViewArray(entityID, onBlood)
    local world = GameGlobal:GetInstance():GetMainWorld()
    local entity = world:GetEntityByID(entityID)

    if not entity then
        return {}
    end

    -- if entity:HasDeadFlag() then
    --     return {}
    -- end

    local buffViewComponent = entity:BuffView()
    if buffViewComponent == nil then
        return {}
    end

    local buffViewArray = buffViewComponent:GetBuffViewShowList(onBlood)
    if not buffViewArray or #buffViewArray == 0 then
        return {}
    end

    local arr = {}
    for _, buff in ipairs(buffViewArray) do
        if buff and buff:BuffConfigData():GetBuffShowBuffIcon() then
            table.insert(arr, buff)
        end
    end
    return arr
end

function InnerGameHelperRender.GetBuffViewByPetPstID(petPstID)
    local world = GameGlobal:GetInstance():GetMainWorld()
    local entity = nil
    local group = world:GetGroup(world.BW_WEMatchers.PetPstID)
    local petEntities = group:GetEntities()
    for i, e in ipairs(petEntities) do
        local cPetPstID = e:PetPstID()
        if petPstID == cPetPstID:GetPstID() then
            entity = e
            break
        end
    end

    if not entity then
        return {}
    end

    local buffViewComponent = entity:BuffView()
    if buffViewComponent == nil then
        return {}
    end

    local buffViewArray = buffViewComponent:GetBuffViewInstanceArray()
    return buffViewArray
end

function InnerGameHelperRender.GetBuffValue(petPstID, key)
    local world = GameGlobal:GetInstance():GetMainWorld()
    ---@type Entity
    local entity = nil
    local group = world:GetGroup(world.BW_WEMatchers.PetPstID)
    local petEntities = group:GetEntities()
    for i, e in ipairs(petEntities) do
        local cPetPstID = e:PetPstID()
        if petPstID == cPetPstID:GetPstID() then
            entity = e
            break
        end
    end

    if not entity then
        return
    end

    local buffViewComponent = entity:BuffView()
    if buffViewComponent == nil then
        return
    end

    return buffViewComponent:GetBuffValue(key)
end

function InnerGameHelperRender.IsEntityDead(entityID)
    local world = GameGlobal:GetInstance():GetMainWorld()
    local entity = world:GetEntityByID(entityID)

    return (not entity) or (entity:HasDeadFlag())
end

function InnerGameHelperRender.GetSingleBuffByBuffEffect(entityID, buffEffectType)
    local world = GameGlobal:GetInstance():GetMainWorld()
    local entity = world:GetEntityByID(entityID)

    if not entity then
        return
    end

    -- if entity:HasDeadFlag() then
    --     return
    -- end

    local buffViewComponent = entity:BuffView()
    if buffViewComponent == nil then
        return
    end

    ---@type BuffViewInstance
    local buffViewInstance = buffViewComponent:GetSingleBuffByBuffEffect(buffEffectType)

    return buffViewInstance
end

function InnerGameHelperRender.RemoveBuffViewInstance(entityID, buffViewInstance)
    local world = GameGlobal:GetInstance():GetMainWorld()
    local entity = world:GetEntityByID(entityID)

    if not entity then
        return
    end

    if buffViewInstance then
        entity:RemoveBuffViewInstance(buffViewInstance)
    end
end

function InnerGameHelperRender.GridPos2WorldPos(pos)
    local basePos = Vector3(-4, 0, -3) --逻辑格子的(1,1)点对应的渲染坐标位置
    local pieceHeight = 0
    local xOffset = pos.x - 1
    local zOffset = pos.y - 1
    local gridRenderPos = basePos + Vector3(xOffset, pieceHeight, zOffset)
    local camera = GameGlobal:GetInstance():GetMainWorld():MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(gridRenderPos)

    return screenPos
end

function InnerGameHelperRender.WorldPos2ScreenPos(worldPos)
    local camera = GameGlobal:GetInstance():GetMainWorld():MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(worldPos)
    return screenPos
end

function InnerGameHelperRender.UICheckIsFifthPet(petPstID)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type UtilDataServiceShare
    local shareDataSvc = mainWorld:GetService("UtilData")
    return shareDataSvc:IsFifthPetInTeamOrder(petPstID)
end
function InnerGameHelperRender.UICheckIsFourthPet(petPstID)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type UtilDataServiceShare
    local shareDataSvc = mainWorld:GetService("UtilData")
    return shareDataSvc:IsFourthPetInTeamOrder(petPstID)
end
---判断是否是第四个或者第八个
function InnerGameHelperRender.UICheckIsEndPet(petPstID)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type UtilDataServiceShare
    local shareDataSvc = mainWorld:GetService("UtilData")
    return shareDataSvc:IsFourthOrEightPetInTeamOrder(petPstID)
end


function InnerGameHelperRender.UISetUIPetAccumulateNum(petPstID, num)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type AutoTestService
    local svc = mainWorld:GetService("AutoTest")
    if svc then
        svc:WriteBlackBoard_Test("UIPetAccNum_" .. petPstID, num)
    end
end

function InnerGameHelperRender.UISetUIPetPassiveSkillBuffLayerNum(petPstID, num)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type AutoTestService
    local svc = mainWorld:GetService("AutoTest")
    if svc then
        svc:WriteBlackBoard_Test("UIPetBuffLayerNum_" .. petPstID, num)
    end
end

function InnerGameHelperRender.UISetHPBuffIcon(entityID, t)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type AutoTestService
    local svc = mainWorld:GetService("AutoTest")
    if svc then
        svc:WriteBlackBoard_Test("UIHPBuff_" .. entityID, t)
    end
end

function InnerGameHelperRender.UISetHPLayerShieldCount(entityID, count)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type AutoTestService
    local svc = mainWorld:GetService("AutoTest")
    if svc then
        svc:WriteBlackBoard_Test("UIHPLayerShieldCount_" .. entityID, count)
    end
end

---根据词条ID，查找出现的关卡，此方法组合了一些工具函数
---用的时候可以参考下
function InnerGameHelperRender._FindLevelByEliteID()
    local eliteIDList = {
        100101,
        100102,
        100103,
        100401
    }

    ---找到对应的怪物列表，如果有其他需求，可以在这里重写这个怪物ID列表
    local eliteMonsterIDList = InnerGameHelperRender._FindEliteMonsterIDList(eliteIDList)

    ---找到对应的怪物刷新列表
    local refreshMonsterIDList = InnerGameHelperRender._FindRefreshMonsterIDList(eliteMonsterIDList)

    ---找到刷新列表
    local refreshIDList = InnerGameHelperRender._FindRefreshIDList(refreshMonsterIDList)

    ---找到波次列表
    local waveIDList = InnerGameHelperRender._FindWaveIDList(refreshIDList)

    ---找到关卡列表
    local levelIDList = InnerGameHelperRender._FindLevelIDList(waveIDList)
end

function InnerGameHelperRender._FindEliteMonsterIDList(eliteIDList)
    local eliteMonsterIDList = {}
    local monsterList = Cfg.cfg_monster()
    for _, monsterConfig in pairs(monsterList) do
        if monsterConfig.EliteID then
            for _, eliteID in pairs(monsterConfig.EliteID) do
                local contain = table.icontains(eliteIDList, eliteID)
                if contain then
                    eliteMonsterIDList[#eliteMonsterIDList + 1] = monsterConfig.ID
                    Log.fatal("eliteID:", eliteID, " FindLevel_monsterID：", monsterConfig.ID)
                end
            end
        end
    end
    return eliteMonsterIDList
end

function InnerGameHelperRender._FindRefreshMonsterIDList(eliteMonsterIDList)
    local refreshMonsterIDList = {}
    local refreshMonster = Cfg.cfg_refresh_monster()
    for _, refreshMonsterConfig in pairs(refreshMonster) do
        if refreshMonsterConfig.MonsterIDList then
            for _, monsterID in pairs(refreshMonsterConfig.MonsterIDList) do
                local contain = table.icontains(eliteMonsterIDList, monsterID)
                if contain then
                    refreshMonsterIDList[#refreshMonsterIDList + 1] = refreshMonsterConfig.ID
                    Log.fatal("monsterID:", monsterID, " FindLevel_refreshMonsterID：", refreshMonsterConfig.ID)
                end
            end
        end
    end

    return refreshMonsterIDList
end

function InnerGameHelperRender._FindRefreshIDList(refreshMonsterIDList)
    local refreshIDList = {}
    local refresh = Cfg.cfg_refresh()
    for _, refreshConfig in pairs(refresh) do
        if refreshConfig.MonsterRefreshIDList then
            for _, monsterRefreshID in pairs(refreshConfig.MonsterRefreshIDList) do
                local contain = table.icontains(refreshMonsterIDList, monsterRefreshID)
                if contain then
                    refreshIDList[#refreshIDList + 1] = refreshConfig.ID
                    Log.fatal("monsterRefreshID:", monsterRefreshID, " FindLevel_refreshMonsterID：", refreshConfig.ID)
                end
            end
        end
    end
    return refreshIDList
end

function InnerGameHelperRender._FindWaveIDList(refreshIDList)
    local waveIDList = {}
    local wave = Cfg.cfg_monster_wave()
    for _, waveConfig in pairs(wave) do
        local contain = table.icontains(refreshIDList, waveConfig.WaveBeginRefreshID)
        if contain then
            waveIDList[#waveIDList + 1] = waveConfig.ID
            Log.fatal("RefreshID:", waveConfig.WaveBeginRefreshID, " FindLevel_waveID：", waveConfig.ID)
        end

        if waveConfig.WaveInternalRefresh then
            for _, refreshConfigList in pairs(waveConfig.WaveInternalRefresh) do
                local contain = table.icontains(refreshIDList, refreshConfigList.refreshID)
                if contain then
                    waveIDList[#waveIDList + 1] = waveConfig.ID
                    Log.fatal("refreshID:", refreshConfigList.refreshID, " FindLevel_refreshMonsterID：", waveConfig.ID)
                end
            end
        end
    end
    return waveIDList
end

function InnerGameHelperRender._FindLevelIDList(waveIDList)
    local levelIDList = {}

    local levelDic = {}
    local level = Cfg.cfg_level()
    for _, levelConfig in pairs(level) do
        if levelConfig.MonsterWave then
            for _, waveCfgID in pairs(levelConfig.MonsterWave) do
                local contain = table.icontains(waveIDList, waveCfgID)
                if contain then
                    levelDic[levelConfig.ID] = true
                end
            end
        end
    end

    for levelID, v in pairs(levelDic) do
        levelIDList[#levelIDList + 1] = levelID
        Log.fatal(" FindLevel_levelConfigID ", levelID)
    end

    return levelIDList
end

--机关是否被覆盖
---@param trapID number
---@param petPstId number
---@return boolean
function InnerGameHelperRender:IsTrapCovered(trapID, petPstId)
    ---@type MainWorld
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type TrapServiceLogic
    local trapServiceLogic = world:GetService("TrapLogic")
    if not trapServiceLogic then
        return false
    end

    local isOverlap = trapServiceLogic:IsTrapCovered(trapID, petPstId)

    return isOverlap
end

function InnerGameHelperRender.IsDoneCompleteCondition(...)
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type CompleteConditionService
    local lsvcComplete = world:GetService("CompleteCondition")
    return lsvcComplete:IsDoneCompleteCondition(...)
end

function InnerGameHelperRender.IsPetSilence(petPstID)
    ---@type MainWorld
    local mainWorld = GameGlobal:GetInstance():GetMainWorld()
    ---@type UtilDataServiceShare
    local shareDataSvc = mainWorld:GetService("UtilData")
    return shareDataSvc:IsSilenceState(petPstID)
end

function InnerGameHelperRender.GetEntityAttribute(entityID, attribute)
    local world = InnerGameHelperRender.GetMainWorld()
    local e = world:GetEntityByID(entityID)
    if not e then
        return
    end
    ---@type AttributesComponent
    local attributesComponent = e:Attributes()
    return attributesComponent:GetAttribute(attribute)
end

--region 光灵出战顺序修改队列
function InnerGameHelperRender.UICurrentTeamOrderRequestFinished()
    ---@type RenderBattleStatComponent
    local renderStat = InnerGameHelperRender.GetMainWorld():RenderBattleStat()
    renderStat:MarkCurrentTeamOrderRequestFinished()

    ---@type RenderBattleService
    local renderBattleService = GameGlobal:GetInstance():GetMainWorld():GetService("RenderBattle")
    renderBattleService:TryPopNextChangeTeamOrderView()
end
--endregion

function InnerGameHelperRender.GetLocalMatchPetByTemplateID(tid)
    ---@type UtilDataServiceShare
    local utilData = InnerGameHelperRender.GetMainWorld():GetService("UtilData")
    return utilData:GetLocalMatchPetByTemplateID(tid)
end

---机关召唤数量是否达到上限
function InnerGameHelperRender.IsTrapSummonCountLimit(trapEntityID)
    ---@type MainWorld
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type TrapServiceLogic
    local trapLogic = world:GetService("TrapLogic")
    local e = world:GetEntityByID(trapEntityID)
    local ret = trapLogic:IsSummonCountLimit(e)
    return ret
end

---消灭星星：获取挑战关阶段信息
function InnerGameHelperRender.GetPopStarStageInfo()
    ---@type MainWorld
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type PopStarServiceLogic
    local popStarSvc = world:GetService("PopStarLogic")
    return popStarSvc:GetPopStarStageInfo()
end

---消灭星星：获取挑战关阶段信息
function InnerGameHelperRender.GetPopStarCurScore()
    ---@type MainWorld
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type PopStarServiceLogic
    local popStarSvc = world:GetService("PopStarLogic")
    return popStarSvc:GetPopGridNum()
end

---消灭星星：获取挑战关阶段BuffID列表
function InnerGameHelperRender.GetPopStarStageBuffIDList()
    ---@type MainWorld
    local world = InnerGameHelperRender.GetMainWorld()
    ---@type BuffLogicService
    local buffSvc = world:GetService("BuffLogic")

    return buffSvc:GetPopStarStageBuffIDList()
end
