

---@class UIDataActiveSkillUIInfo : Object
_class("UIDataActiveSkillUIInfo",Object)
UIDataActiveSkillUIInfo = UIDataActiveSkillUIInfo
function UIDataActiveSkillUIInfo:Constructor(skillId, maxPower, leftPower, canCast,showAlreadyCast,showPowerInfo)
    self._skillId = skillId
    self._maxPower = maxPower
    self._leftPower = leftPower
    self._canCast = canCast
    self._showAlreadyCast = showAlreadyCast
    self._showPowerInfo = showPowerInfo
end
---@class UIDataBattlePetSkillInfo : Object
_class("UIDataBattlePetSkillInfo",Object)
UIDataBattlePetSkillInfo = UIDataBattlePetSkillInfo
function UIDataBattlePetSkillInfo:Constructor(skillId, ready, power,maxPower, skillTriggerType)
    self._skillId = skillId
    self._ready = ready
    self._power = power
    self._maxPower = maxPower
    self._skillTriggerType = skillTriggerType
end
---@class UIExtraSkillCDUiData : Object
_class("UIExtraSkillCDUiData",Object)
UIExtraSkillCDUiData = UIExtraSkillCDUiData
function UIExtraSkillCDUiData:Constructor(infoGo,cdGo,energyText,alreadyCastGo)
    self._infoGo = infoGo
    self._infoShow = true
    self._cdGo = cdGo
    self._energyText = energyText
    self._alreadyCastGo = alreadyCastGo
    self._alreadyCastShow = false
end
-------------------------

_class("UIWidgetBattlePet", UICustomWidget)
---@class UIWidgetBattlePet:UICustomWidget
UIWidgetBattlePet = UIWidgetBattlePet

function UIWidgetBattlePet:OnShow()
    self.enableFakeInput = true

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattleAtlas = self:GetAsset("InnerUI.spriteatlas", LoadType.SpriteAtlas)
    --刻度对应血量
    self._dialLine2Hp = Cfg.cfg_global["UIWidgetBattlePet_dialLine2Hp"].IntValue or 200
    self._bigDiaLine = Cfg.cfg_global["UIWidgetBattlePet_bigDiaLine"].IntValue or 5
    --血量刻度检测偏移
    self._dialLineCheckShowOffset = 1 / 15

    ---@type number
    self.petIndex = 0
    ---@type number
    self.petPstID = 0
    self._showMultiBuffLayer = nil
    ---@type UnityEngine.RectTransform
    self._offset = self:GetUIComponent("RectTransform", "offset")
    self._tweenerOffset = nil

    ---@type boolean
    self._autoFightState = false
    self._autoFightForbiddenStr = StringTable.Get("str_battle_forbidden_operation_in_autofight")

    local effCharge = self:GetGameObject("EffCharge").transform --剩余回合转换能量特效
    self._effCharge = UIHelper.GetGameObject("UIEff_UIWidgetBattlePet_Charge.prefab")
    self._effCharge.transform:SetParent(effCharge, false)
    -- ---@type UnityEngine.Animation
    -- self._animEffCharge = self._effCharge:GetComponent("Animation")
    -- self._effChargeState = self._animEffCharge:get_Item("UIEff_UIWidgetBattlePet_Charge")
    -- self._effChargeState.normalizedTime = 1
    -- self._animEffCharge:Play()

    ---@type UILocalizationText
    self._txt1 = self:GetUIComponent("UILocalizationText", "txt1")
    ---@type UILocalizationText
    self._txt2 = self:GetUIComponent("UILocalizationText", "txt2")
    ---@type DG.Tweening.Sequence
    self._sWhiteEnergy = nil
    ---@type UILocalizationText
    self.txtEnergy = self:GetUIComponent("UILocalizationText", "CurEnergyText")
    ---@type UILocalizationText
    self.txtEnergyMax = self:GetUIComponent("UILocalizationText", "MaxEnergyText")

    --下面几个元素都是用于处理被动技能的图标
    self._PassiveSkillGO = self:GetGameObject("PassiveSkill")
    ---@type UILocalizationText
    self._txtAccumulate = self:GetUIComponent("UILocalizationText", "AccumulateTxt")
    self._txtAccumulate1 = self:GetUIComponent("UILocalizationText", "AccumulateTxt1")
    ---@type UnityEngine.UI.Image
    self._imageIconA = self:GetUIComponent("Image", "ImageIconA")
    self._imageIconA1 = self:GetUIComponent("Image", "ImageIconA1")
    ---@type UnityEngine.UI.Image
    self._imageIconB = self:GetUIComponent("Image", "ImageIconB")
    self._imageIconB1 = self:GetUIComponent("Image", "ImageIconB1")
    ---@type UnityEngine.UI.Image
    self._imageIconC = self:GetUIComponent("Image", "ImageIconC")
    self._imageIconC1 = self:GetUIComponent("Image", "ImageIconC1")
    ---@type UnityEngine.UI.Image
    self._imageIconD = self:GetUIComponent("Image", "ImageIconD")
    self._imageIconD1 = self:GetUIComponent("Image", "ImageIconD1")
    ---@type UnityEngine.UI.Image
    self._imageDiamondBlack = self:GetUIComponent("Image", "ImageDiamondBlack")
    ---@type UnityEngine.UI.Image
    self._imageDiamondLight = self:GetUIComponent("Image", "ImageDiamondLight")

    ---@type UnityEngine.RectTransform
    self._imageDiamondBlackRect = self:GetUIComponent("RectTransform", "ImageDiamondBlack")
    ---@type UnityEngine.RectTransform
    self._imageDiamondLightRect = self:GetUIComponent("RectTransform", "ImageDiamondLight")

    ---@type UILocalizationText
    -- self.txtLocalName = self:GetUIComponent("UILocalizationText", "LocalName")
    ---@type UILocalizationText
    -- self.txtEnglishName = self:GetUIComponent("UILocalizationText", "EnglishName")

    ---@type RawImageLoader
    self.headIcon = self:GetUIComponent("RawImageLoader", "HeadIcon")
    ---@type RawImageLoader
    self._imgChainSkillIcon = self:GetUIComponent("RawImageLoader", "imgChainSkillIcon")
    self._goChainSkillIcon = self:GetGameObject("imgChainSkillIcon")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self._attrMain = self:GetUIComponent("Image", "Attribute")
    ---@type UnityEngine.UI.Image
    self._attrVice = self:GetUIComponent("Image", "Attribute2")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.uiBattleAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)

    ---@type UnityEngine.GameObject
    self.activeSkillUIPos = self:GetGameObject("ActiveSkillUIPos")

    self.cancelActiveSkillUIPos = self:GetGameObject("CancelActiveSkillUIPos")

    ---@type UnityEngine.GameObject
    self._touchArea = self:GetGameObject("TouchArea")
    self._touchArea:SetActive(false)
    self._effParent = self:GetGameObject("EffPowerFull")

    self.headMask = self:GetUIComponent("Image", "headMask")

    self.powerFull = UIHelper.GetGameObject("UIEff_energyfull.prefab")
    self.powerFull.transform:SetParent(self._effParent.transform, false)
    self.powerFull:SetActive(false)

    ---@type UnityEngine.GameObject
    self.previewAddBuff = self:GetGameObject("PreviewAddBuff")
    self.previewAddBuff.gameObject:SetActive(true)
    self.previewAddBuffEffect = UIHelper.GetGameObject("UIEff_BuffPre.prefab")
    self.previewAddBuffEffect.transform:SetParent(self.previewAddBuff.transform, false)
    self.previewAddBuffEffect:SetActive(false)
    --self.previewSkillArrow = self:GetUIComponent("Image", "PreviewArrow")
    --self:HidePreviewArrow()

    --MazeTest
    self._hp = self:GetGameObject("hp")
    self._hpSlider = self:GetUIComponent("Slider", "hpSlider")
    self._hpvalue = self:GetUIComponent("Image", "hpvalue")
    self._hpvalueRect = self:GetUIComponent("RectTransform", "dialLines")
    self._dialLines = self:GetUIComponent("UISelectObjectPath", "dialLines")
    self._grayMask = self:GetGameObject("grayMask")
    ---@type UnityEngine.RectTransform
    self._showAddHpPos = self:GetUIComponent("RectTransform", "showAddHpPos")
    self._showAddHpGo = self:GetGameObject("showAddHpPos")

    self._addTex = self:GetUIComponent("UILocalizationText", "addTex")
    self._redTex = self:GetUIComponent("UILocalizationText", "redTex")

    --不再使用的特效 不需要加载 且没有主动释放
    --self._fillPowerEffect = UIHelper.GetGameObject("uieff_uiwidgetbattlepet_nengliang.prefab")
    --self._fillPowerEffect.transform:SetParent(self._effParent.transform, false)
    --self._fillPowerEffect:SetActive(false)

    ---CD增加的动画
    self._rootAnimation = self:GetUIComponent("Animation", "root")
    self._addCdAnimation = false

    self._skillReadyGO = self:GetGameObject("UISkillReady")
    ---@type UnityEngine.UI.Image
    self._skillReadyBG = self:GetUIComponent("Image", "skillReadyBG")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._skillReadyBGAtlas = self:GetAsset("UISkillReady.spriteatlas", LoadType.SpriteAtlas)

    self.alreadyCastActiveImage = self:GetGameObject("AlreadyCastActiveImage")
    self.alreadyCastActiveImage:SetActive(false)
    self._cdGO = self:GetGameObject("Energy")
    self._cdGO:SetActive(not GuideHelper.DontShowMainSkillMission())
    --助战
    self._helpPetGO = self:GetGameObject("helppet")
    self._helpPetGO:SetActive(false)
    
    --region 卡牌模块 buff图标
    --两种buff，每种对应一个图标，当两个buff都显示时，变为第三种图标
    self._cardBuffAreaGo = self:GetGameObject("CardBuffArea")
    self._cardBuffEffPosRect = self:GetUIComponent("RectTransform", "CardBuffArea")
    self._cardFlyEffGo = self:GetGameObject("CardFlyEff")
    self._cardBuffEffGo = self:GetGameObject("CardBuffEff")

    ---@type UnityEngine.Animation
    self._cardBuffAnim = self:GetUIComponent("Animation", "CardBuffArea")
    local cardBuffIcon1Go = self:GetGameObject("CardBuffIcon1")
    local cardBuffIcon2Go = self:GetGameObject("CardBuffIcon2")
    local cardBuffIcon3Go = self:GetGameObject("CardBuffIcon3")
    self._featureCardBuffIconGoDic = {
        [1] = cardBuffIcon1Go,
        [2] = cardBuffIcon2Go,
        [3] = cardBuffIcon3Go,
    }
    if self._cardBuffAreaGo then
        self._cardBuffAreaGo:SetActive(false)
    end
    self._featureCardBuffState = 0 --0、1、2、3
    self:AttachEvent(GameEventType.FeaturePetUIAddCardBuff, self._OnFeaturePetUIAddCardBuff)
    self:AttachEvent(GameEventType.FeaturePetUIPreviewAddCardBuff, self._OnFeaturePetUIPreviewAddCardBuff)
    self:AttachEvent(GameEventType.FeaturePetUIPreviewRecoverCardBuff, self._OnFeaturePetUIPreviewRecoverCardBuff)
    self:AttachEvent(GameEventType.FeatureListInit, self._OnFeatureListInit)--杰诺皮肤 影响相关特效
    --endregion
    --region 长按，点击
    self._timerEvent = nil
    self._switchTimeEvent = nil
    ---由当前倍速动态设置
    self._pressTime = HelperProxy:GetInstance():GetFixTimeLen(277) --长按弹出详细信息的时间 (毫秒)
    self._switchTimeLength = 100 --切换头像的延迟时间

    self._goSelectTeamPositionButton = self:GetGameObject("SelectTeamPos")

    local etl = UICustomUIEventListener.Get(self._touchArea)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(go)
            self:OnDown(go)
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Unhovered,
        function(go)
            self:OnLeave()
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Hovered,
        function(go)
            self:OnEnter()
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            self:OnUp(go)
        end
    )
    --endregion

    self:InitLogicData()

    self:AttachEvent(GameEventType.PetShowPreviewArrow, self.ShowPreviewArrow)
    self:AttachEvent(GameEventType.PetHidePreviewArrow, self.HidePreviewArrow)
    self:AttachEvent(GameEventType.InOutQueue, self.InOutQueue)
    self:AttachEvent(GameEventType.FlushPetChainSkillItem, self.FlushPetChainSkillItem)
    self:AttachEvent(GameEventType.ShowHideChainSkillCG, self.ShowHideChainSkillCG)
    self:AttachEvent(GameEventType.ShowGuideMask, self._ShowGuideMask)
    self:AttachEvent(GameEventType.ShowStoryBanner, self._ShowStoryBanner)
    self:AttachEvent(GameEventType.ActiveBattlePet, self._ActiveBattlePet)
    self:AttachEvent(GameEventType.UIFeatureSkillInfoShow, self._UIFeatureSkillInfoShow)
    self:AttachEvent(GameEventType.AutoFight, self._AutoFight)
    self:AttachEvent(GameEventType.ChangePetActiveSkill, self._OnChangePetActiveSkill)
    self:AttachEvent(GameEventType.ChangePetExtraActiveSkill, self._OnChangePetExtraActiveSkill)

    self._csAnimSealedCurse = self:GetUIComponent("Animation", "uieff_zuzhoubuff_01")
    self.isSealedCurse = false
    self.sealedCurseBuffSeq = 0
    self._goSealedCurseDuration = self:GetGameObject("SealedCurseDuration")
    self._sealedCurseDurationText = self:GetUIComponent("UILocalizationText", "SealedCurseDurationText")
    self:AttachEvent(GameEventType.BattlePetIconSealedCurse, self._OnSealedCurseFlagChanged)
    self:AttachEvent(GameEventType.ToggleTeamLeaderChangeUI, self._OnShowTeamLeaderChangeUI)
    self:AttachEvent(GameEventType.BuffRoundCountChanged, self._OnBuffRoundCountChanged)



    self._csAnimSealedCurseClickBan = self:GetUIComponent("Animation", "UIBanned")

    self:AttachEvent(GameEventType.BattleUIShowHideSelectTeamPositionButton, self.ShowHideSelectTeamPositionButton)
    self:AttachEvent(GameEventType.BattleUISelectTargetTeamPosition, self.OnBattleUISelectTargetTeamPosition)
    ---@type UnityEngine.GameObject
    self._overloadRootGo = self:GetGameObject("overloadIcon")
    self.isOverload= false
    ---@type UnityEngine.GameObject
    self._overloadPos1GO = self:GetGameObject("overloadIconPos1")
    ---@type UnityEngine.GameObject
    self._overloadPos2GO = self:GetGameObject("overloadIconPos2")
    self._overloadRootGo:SetActive(false)
    self._overloadPos1GO:SetActive(false)
    self._overloadPos2GO:SetActive(false)
    self._overloadPos1 = 49.8
    self._overloadPos2 = 13.39
    self:AttachEvent(GameEventType.SetPetOverloadState, self._SetPetOverloadState)

    self._silenceForbiddenStr = "str_battle_silence_tips"
    
    self._isBuffSetCanNotReady = false
    self._isBuffSetCanNotReadyForExtra = {}
    self:AttachEvent(GameEventType.SetActiveSkillCanNotReady, self._OnSetActiveSkillCanNotReady)

    self:AttachEvent(GameEventType.ForceInitPassiveIcon, self._ForceInitPassiveIcon)
    self._passiveIconInited = false
    self._attachedActivatePassive = false
    self:AttachEvent(GameEventType.ForceInitPassiveAccumulate, self._ForceInitPassiveAccumulate)
    self._passiveAccumulateInited = false

    self._players = {}

    self:AttachEvent(GameEventType.ShowPowerfullRoundCountUI, self._OnShowPowerfullRoundCountUI)
    ---@type UnityEngine.GameObject
    self._powerfullRoundCountAreaGO = self:GetGameObject("PowerfullRoundCountArea")
    self._powerfullRoundCountImgGO = self:GetGameObject("PowerfullRoundCountImg")
    ---@type UnityEngine.UI.Image
    self._powerfullRoundCountImg = self:GetUIComponent("Image", "PowerfullRoundCountImg")
    if self._powerfullRoundCountAreaGO then
        self._powerfullRoundCountAreaGO:SetActive(false)
    end
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattle1Atlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    self._showPowerfullRoundCount = false--逻辑上是否要显示技能有已就绪回合数 光灵米洛斯 部分情况下ui会隐藏

    self:AttachEvent(GameEventType.ScanFeatureReplaceUIActiveSkillID, self._OnScanFeatureReplaceUIActiveSkillID)

    self._cdAndPassiveContainer = self:GetGameObject("CDAndPassiveSkill")
    self._chainEnergyContainer = self:GetGameObject("ChainEnergy")
    ---@type UISelectObjectPath
    self._chainEnergyFactory = self:GetUIComponent("UISelectObjectPath", "ChainEnergy")

    self:AttachEvent(GameEventType.UIMultiActiveSkillCastClick, self._OnUIMultiActiveSkillCastClick)
    self:AttachEvent(GameEventType.UIMultiSkillClickIndex, self._OnUIMultiSkillClickIndex)
    self._recordMultiSkillLastClickIndex = 1--多主动 记录上次点选技能index

    self._powerInfoArea = self:GetGameObject("PowerInfoArea")
    self._multiPowerInfoArea = self:GetGameObject("MultiPowerInfoArea")
    self._powerInfoArea:SetActive(true)
    self._multiPowerInfoArea:SetActive(false)

    local multiPowerInfoGo_1 = self:GetGameObject("MultiPowerInfo_1")
    local multiPowerInfoGo_2 = self:GetGameObject("MultiPowerInfo_2")
    local multiCdGO_1 = self:GetGameObject("Energy_1")
    local multiCdGO_2 = self:GetGameObject("Energy_2")
    ---@type UILocalizationText
    local multiTxtEnergy_1 = self:GetUIComponent("UILocalizationText", "CurEnergyText_1")
    local multiTxtEnergy_2 = self:GetUIComponent("UILocalizationText", "CurEnergyText_2")
    local alreadyCastActiveImage_1 = self:GetGameObject("AlreadyCastActiveImage_1")
    local alreadyCastActiveImage_2 = self:GetGameObject("AlreadyCastActiveImage_2")

    self._singleSkillCDUi = UIExtraSkillCDUiData:New(self._powerInfoArea,self._cdGO,self.txtEnergy,self.alreadyCastActiveImage)
    self._multiSkillCDUi = {}
    self._multiSkillCDUi[1] = UIExtraSkillCDUiData:New(multiPowerInfoGo_1,multiCdGO_1,multiTxtEnergy_1,alreadyCastActiveImage_1)
    self._multiSkillCDUi[2] = UIExtraSkillCDUiData:New(multiPowerInfoGo_2,multiCdGO_2,multiTxtEnergy_2,alreadyCastActiveImage_2)
    self._skillCDUiDic = {}
end

function UIWidgetBattlePet:OnHide()
    UIHelper.DestroyGameObject(self.powerFull)
    UIHelper.DestroyGameObject(self._effCharge)
    UIHelper.DestroyGameObject(self.previewAddBuffEffect)
    self:DetachEvent(GameEventType.InOutQueue, self.InOutQueue)
    self:DetachEvent(GameEventType.FlushPetChainSkillItem, self.FlushPetChainSkillItem)
    self:DetachEvent(GameEventType.ShowHideChainSkillCG, self.ShowHideChainSkillCG)
    self:DetachEvent(GameEventType.ShowGuideMask, self._ShowGuideMask)
    self:DetachEvent(GameEventType.ShowStoryBanner, self._ShowStoryBanner)
    self:DetachEvent(GameEventType.ActiveBattlePet, self._ActiveBattlePet)
    self:DetachEvent(GameEventType.UIFeatureSkillInfoShow, self._UIFeatureSkillInfoShow)
    self:DetachEvent(GameEventType.AutoFight, self._AutoFight)
    self:DetachEvent(GameEventType.ActivatePassive, self.ActivatePassive)
    self:DetachEvent(GameEventType.SetAccumulateNum, self.SetAccumulateNum)
    self:DetachEvent(GameEventType.ChangePetActiveSkill, self._OnChangePetActiveSkill)
    self:DetachEvent(GameEventType.ChangePetExtraActiveSkill, self._OnChangePetExtraActiveSkill)
    self:DetachEvent(GameEventType.BattlePetIconSealedCurse, self._OnSealedCurseFlagChanged)
    self:DetachEvent(GameEventType.SetActiveSkillCanNotReady, self._OnSetActiveSkillCanNotReady)
    self:DetachEvent(GameEventType.ToggleTeamLeaderChangeUI, self._OnShowTeamLeaderChangeUI)
    self:DetachEvent(GameEventType.BuffRoundCountChanged, self._OnBuffRoundCountChanged)
    self:DetachEvent(GameEventType.BattleUIShowHideSelectTeamPositionButton, self.ShowHideSelectTeamPositionButton)
    self:DetachEvent(GameEventType.BattleUISelectTargetTeamPosition, self.OnBattleUISelectTargetTeamPosition)
    self:DetachEvent(GameEventType.SetPetOverloadState, self._SetPetOverloadState)
    self:DetachEvent(GameEventType.ForceInitPassiveIcon, self._ForceInitPassiveIcon)
    self:DetachEvent(GameEventType.ForceInitPassiveAccumulate, self._ForceInitPassiveAccumulate)
    self:DetachEvent(GameEventType.ShowOverloadPassiveAccumulate, self._ShowOverloadPassiveAccumulate)
    self:DetachEvent(GameEventType.ShowPowerfullRoundCountUI, self._OnShowPowerfullRoundCountUI)
    if self._players then
        for i,player in ipairs(self._players) do
            if player:IsPlaying() then
                player:Stop()
            end
        end
    end
    if self._cardEffTimerHandler then
        GameGlobal.Timer():CancelEvent(self._cardEffTimerHandler)
        self._cardEffTimerHandler = nil
    end
end

function UIWidgetBattlePet:InitLogicData()
    self.isReady = false
    self.skillID = nil
    self.Power = 0
    self.isDead = false
    ---点击 长按 抬手回调
    self.clickCallback = nil

    ---星灵的数据模板ID
    self._petTemplateID = -1

    ---星灵主动技默认是CD
    self.skillTriggerType = SkillTriggerType.Energy

    self._useSubActiveSkill = false
    self.extraSkillIDList = nil
    self.extraSkillInfoDic = nil
    self.useMultiPowerUi = false
    self._variantSkillList = nil
end

function UIWidgetBattlePet:PstID()
    return self.petPstID
end

function UIWidgetBattlePet:Dead()
    return self.isDead
end

function UIWidgetBattlePet:Index()
    return self.uiid
end

---@param petData MatchPet
function UIWidgetBattlePet:InitUIWidgetPet(
    index,
    petPstID,
    petData,
    clickCallback,
    switchCallback,
    multiSkillClickCallback,
    multiSkillSwitchCallback,
    uiBattle)
    --宝宝基础数据
    self.uiid = index
    self.petIndex = index
    self.sortIndex = index
    self.petPstID = petPstID
    self._petTemplateID = petData:GetTemplateID()
    ---@type UIBattle
    self._uiBattle = uiBattle
    ---@type boolean
    self._isHelpPet = petData:IsHelpPet()

    -- self.txtLocalName:SetText(StringTable.Get(petData:GetPetName()))
    -- self.txtEnglishName:SetText(StringTable.Get(petData:GetPetEnglishName()))

    --宝宝技能数据
    self.skillID = petData:GetPetActiveSkill()
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID, self.petPstID)
    self.skillTriggerType = skillConfigData:GetSkillTriggerType()
    local uiCdCount = 0
    if self.skillTriggerType == SkillTriggerType.Energy then--处理多技能多cd的ui
        uiCdCount = 1
        local cdUiData = self._multiSkillCDUi[uiCdCount]
        if cdUiData then
            self._skillCDUiDic[self.skillID] = cdUiData
        end
    end
    local extraSkillIDList = petData:GetPetExtraActiveSkill()
    if extraSkillIDList then
        if #extraSkillIDList > 0 then
            self.extraSkillIDList = extraSkillIDList
            self.extraSkillInfoDic = {}
            for index, skillId in ipairs(self.extraSkillIDList) do
                local ready = false
                local power = 0
                local maxPower = 0
                ---@type SkillConfigData
                local skillConfigData = ConfigServiceHelper.GetSkillConfigData(skillId, self.petPstID)
                local skillTriggerType = skillConfigData:GetSkillTriggerType()
                local triggerPower = skillConfigData:GetSkillTriggerParam()
                maxPower = triggerPower
                if skillTriggerType == SkillTriggerType.LegendEnergy then
                    power = 0
                elseif skillTriggerType == SkillTriggerType.Energy then
                    power = triggerPower
                    uiCdCount = uiCdCount + 1
                    if uiCdCount > 1 then
                        self.useMultiPowerUi = true
                        --多套cd
                        local cdUiData = self._multiSkillCDUi[uiCdCount]
                        if cdUiData then
                            self._skillCDUiDic[skillId] = cdUiData
                        end
                        self._powerInfoArea:SetActive(false)
                        self._multiPowerInfoArea:SetActive(true)
                    end
                end
                self.extraSkillInfoDic[skillId] = UIDataBattlePetSkillInfo:New(skillId, ready, power,maxPower, skillTriggerType)
            end
        end
    end
    --主动技变体
    local variantActiveSkillInfo = petData:GetEquipRefineVariantActiveSkillInfo()
    if variantActiveSkillInfo then
        local variantSkillList = variantActiveSkillInfo[self.skillID]
        if variantSkillList and #variantSkillList > 0 then
            self._variantSkillList = variantSkillList
        end
    end
    if uiCdCount == 1 then
        self.useMultiPowerUi = false
        self._skillCDUiDic[self.skillID] = self._singleSkillCDUi
        self._powerInfoArea:SetActive(true)
        self._multiPowerInfoArea:SetActive(false)
    elseif uiCdCount == 0 then
        self.useMultiPowerUi = false
        self._powerInfoArea:SetActive(false)
        self._multiPowerInfoArea:SetActive(false)
    end

    self._passiveSkillID = petData:GetPetPassiveSkill()

    
    local triggerPower = skillConfigData:GetSkillTriggerParam()

    self.txtEnergyMax:SetText(triggerPower)
    self.maxPower = triggerPower

    --传说星灵
    if self.skillTriggerType == SkillTriggerType.LegendEnergy then
        self._cdAndPassiveContainer:SetActive(true)
        self._chainEnergyContainer:SetActive(false)
        --策划说不继承 默认0
        self:OnChangeLegendPower(0)
    elseif self.skillTriggerType == SkillTriggerType.BuffLayer then
        self._cdAndPassiveContainer:SetActive(false)
        self._chainEnergyContainer:SetActive(true)

        ---@type UIWidgetChainActiveEnergy[]
        self._chainEnergyLights = self._chainEnergyFactory:SpawnObjects("UIWidgetChainActiveEnergy", 3)
        for lightIndex, lightItem in ipairs(self._chainEnergyLights) do
            lightItem:InitData(petPstID, lightIndex)
        end
    else
        self._cdAndPassiveContainer:SetActive(true)
        self._chainEnergyContainer:SetActive(false)
        --星灵
        local power = triggerPower

        --星灵秘境继承CD
        if GameGlobal:GetInstance().GetModule(MatchModule):GetMatchType() == MatchType.MT_Maze then
            local petPower = petData._power
            if petPower >= 0 then
                power = petPower
            end
        end

        self:OnChangePower(power)

        if self.Power == 0 then
            self:OnPowerReady(false)
        end
    end
    self:InitUiForExtraSkill()

    --头像及属性图标
    self.headIcon:LoadImage(petData:GetPetHead(PetSkinEffectPath.HEAD_ICON_CHAIN_SKILL_PREVIEW))
    local headChain = petData:GetHeadChain(PetSkinEffectPath.HEAD_ICON_CHAIN_SKILL_PREVIEW)
    self._imgChainSkillIcon:LoadImage(headChain)
    self:ShowElement(petData)

    --点击 长按 松手的回调
    if clickCallback then
        self.clickCallback = clickCallback
    end

    if switchCallback then
        self.switchCallback = switchCallback
    end

    if multiSkillClickCallback then
        self.multiSkillClickCallback = multiSkillClickCallback
    end

    if multiSkillSwitchCallback then
        self.multiSkillSwitchCallback = multiSkillSwitchCallback
    end

    --连琐
    self._mainAttr = petData:GetPetFirstElement()
    self._viceAttr = petData:GetPetSecondElement()
    self:ShowHideChainSkillCG(self.petPstID, false)
    self.petElement = petData:GetPetFirstElement()
    self.helpPetKey = petData:GetHelpPetKey()
    --被动技能图标初始化
    self:InitPassiveSkill()

    --传说星灵
    if self:IsIncludeSkillTriggerType(SkillTriggerType.LegendEnergy) and not self._hideLegendEnergy then
        self:InitLegendEnergySkill()
    end

    --MazeTest
    self:InitMazeInfo()

    --SkillReadyEff
    self:InitSkillReadyEff()
    --助战
    self:InitHelpPetIcon()

    if ((Log.loglevel < ELogLevel.None) and (BattleConst.NonFormalPetWarningEnabled)) then
        local cfgPet = Cfg.cfg_pet[self._petTemplateID]
        self:GetGameObject("WorkInProgressMark"):SetActive(cfgPet.Formal ~= 1)
    end
end
function UIWidgetBattlePet:InitUiForExtraSkill()
    if self.extraSkillIDList then
        for skillId, skillInfo in pairs(self.extraSkillInfoDic) do
            ---@type UIDataBattlePetSkillInfo
            local uiInfo = skillInfo
            local skillTriggerType = uiInfo._skillTriggerType
            if skillTriggerType == SkillTriggerType.LegendEnergy then
                self._cdAndPassiveContainer:SetActive(true)
                self._chainEnergyContainer:SetActive(false)
                --策划说不继承 默认0
                self:OnChangeLegendPowerForExtraSkill(uiInfo._skillId,0)
            elseif skillTriggerType == SkillTriggerType.Energy then
                self._cdAndPassiveContainer:SetActive(true)
                self._chainEnergyContainer:SetActive(false)
                --星灵
                local power = uiInfo._maxPower
                self:OnChangePowerForExtraSkill(uiInfo._skillId,power)
        
                if uiInfo._power == 0 then
                    self:OnPowerReadyForExtraSkill(uiInfo._skillId,false)
                end
            end
        end
    end
end

function UIWidgetBattlePet:IsSelfHelpPet()
    return self.helpPetKey and self.helpPetKey > 0
end

--助战小图标
function UIWidgetBattlePet:InitHelpPetIcon()
    if self:IsSelfHelpPet() then
        self._helpPetGO:SetActive(true)
    else
        self._helpPetGO:SetActive(false)
    end
end

function UIWidgetBattlePet:InitSkillReadyEff()
    local element2Color = {
        [1] = "sprite_skill_shui",
        [2] = "sprite_skill_huo",
        [3] = "sprite_skill_sen",
        [4] = "sprite_skill_lei"
    }
    local animationName = element2Color[self.petElement]

    self._skillReadyBG.sprite = self._skillReadyBGAtlas:GetSprite(animationName)
end

function UIWidgetBattlePet:InitMazeInfo()
    local match = self:GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    local matchPets = enterData:GetLocalMatchPets()
    self._fromMaze = (MatchType.MT_Maze == enterData._match_type)

    self._hp:SetActive(self._fromMaze)
    if self._fromMaze then
        ----@type MatchPet
        local pet = matchPets[self.petPstID]
        local hp = math.floor(pet:GetPetCurHealth())
        self._lastHp = hp
        self._upper = math.floor(pet:GetPetHealth())
        local rate = hp / self._upper
        self._hpvalue.fillAmount = rate
        self._hpSlider.value = rate

        local hpvaluewidth = self._hpvalueRect.sizeDelta.x
        local dialLineCount = math.ceil(self._upper / self._dialLine2Hp) - 1
        self._dialLines:SpawnObjects("UIWidgetPetHpDialLine", dialLineCount)
        ---@type UIWidgetPetHpDialLine[]
        self._dialLineItems = self._dialLines:GetAllSpawnList()
        for i = 1, #self._dialLineItems do
            local posx = (hpvaluewidth / self._upper * self._dialLine2Hp * i)
            local middleImg = (i % self._bigDiaLine == 0)
            local show = (hp > (i * self._dialLine2Hp))
            self._dialLineItems[i]:SetData(i, posx, middleImg, show)
        end
        self._grayMask:SetActive(hp <= 0)
    end
end

function UIWidgetBattlePet:FlushPetHp(mazePetInfo)
    if self._fromMaze then
        if self.isDead and mazePetInfo.is_dead then
            return
        end
        self._upper = mazePetInfo.max_hp
        local hp = mazePetInfo.cur_hp
        local changeValue = mazePetInfo.change_value
        local rate = hp / self._upper

        if mazePetInfo.is_dead then
            self.powerFull:SetActive(false)
        elseif self.isDead then
            --如果是传说星灵释放主动技
            if self.skillTriggerType == SkillTriggerType.LegendEnergy then
                self:OnChangeLegendPower(self.Power)
            else
                self:OnChangePower(self.Power)
            end
            self:FlushPetHp_RefreshExtraSkillPower()
        end
        self.isDead = mazePetInfo.is_dead

        local addHp
        local addHpValue = math.modf(hp - self._lastHp)
        if changeValue then
            addHpValue = changeValue
        end
        if addHpValue > 0 then
            addHp = true
        elseif addHpValue < 0 then
            addHp = false
        else
            return
        end
        self._lastHp = hp
        if self._hpSliderTweener then
            self._hpSliderTweener:Kill()
        end

        self._addTex.gameObject:SetActive(addHp)
        self._redTex.gameObject:SetActive(not addHp)
        self._showAddHpGo:SetActive(true)

        if addHp then
            self._addTex:SetText("+" .. addHpValue)

            self._hpSlider.value = rate

            self._hpSliderTweener = self._hpvalue:DOFillAmount(rate, 0.5)
        else
            self._redTex:SetText(addHpValue)

            self._hpvalue.fillAmount = rate

            self._hpSliderTweener = self._hpSlider:DOValue(rate, 0.5)
        end
        --飘雪动画
        if self._addHpTweener then
            self._addHpTweener:Kill()
        end
        ---@type DG.Tweening.Tweener
        self._addHpTweener = self._showAddHpPos:DOAnchorPosY(80, 0.5):OnComplete(
            function()
                self._showAddHpGo:SetActive(false)
                self._showAddHpPos.anchoredPosition = Vector2(0, 0)
            end
        )

        if self._dialLineItems then
            for i = 1, #self._dialLineItems do
                local show = (hp > (i * self._dialLine2Hp))
                self._dialLineItems[i]:FlushShow(show)
            end
        end

        self._grayMask:SetActive(hp <= 0)
    end
end
function UIWidgetBattlePet:FlushPetHp_RefreshExtraSkillPower()
    if not self.extraSkillIDList then
        return
    end
    for skillId, skillInfo in pairs(self.extraSkillInfoDic) do
        ---@type UIDataBattlePetSkillInfo
        local uiInfo = skillInfo
        local skillTriggerType = uiInfo._skillTriggerType
        if skillTriggerType == SkillTriggerType.LegendEnergy then
            self:OnChangeLegendPowerForExtraSkill(uiInfo._skillId,uiInfo._power)
        elseif skillTriggerType == SkillTriggerType.Energy then
            self:OnChangePowerForExtraSkill(uiInfo._skillId,uiInfo._power)
        end
    end
end
function UIWidgetBattlePet:_ShowHideCdGo(skillID,bShow)
    ---@type UIExtraSkillCDUiData
    local uiInfo = self._skillCDUiDic[skillID]
    if not uiInfo then
        return
    end
    if GuideHelper.DontShowMainSkillMission() then
        uiInfo._cdGo:SetActive(false)
    else
        uiInfo._cdGo:SetActive(bShow)
    end
end
function UIWidgetBattlePet:_ShowHideAlreadyCastGo(skillID,bShow)
    ---@type UIExtraSkillCDUiData
    local uiInfo = self._skillCDUiDic[skillID]
    if not uiInfo then
        return
    end
    uiInfo._alreadyCastGo:SetActive(bShow)
    uiInfo._alreadyCastShow = bShow
end
function UIWidgetBattlePet:_RefreshPowerArea(skillID,curPower,newPower,ready)
    ---@type UIExtraSkillCDUiData
    local uiInfo = self._skillCDUiDic[skillID]
    if not uiInfo then
        return
    end
    if curPower == 0 then
        if GuideHelper.DontShowMainSkillMission() then
            uiInfo._cdGo:SetActive(false)
        else
            uiInfo._cdGo:SetActive(newPower ~= 0)
        end
    end

    if ready or curPower == 0 then
        uiInfo._alreadyCastGo:SetActive(false)
        uiInfo._alreadyCastShow = false
    end
    uiInfo._energyText:SetText(tostring(newPower))
end
function UIWidgetBattlePet:OnChangePower(power, effect)
    --如果是传说星灵释放主动技
    if self.skillTriggerType == SkillTriggerType.LegendEnergy then
        self.Power = power
        self:_ShowHideCdGo(self.skillID)
        return
    end

    if power <= 0 then
        power = 0
    end
    self:_RefreshPowerArea(self.skillID,self.Power,power,self.isReady)
    if self.Power == power then
        return
    end

    self.Power = power

    self:_OnPlayPowerAddEffect(effect,self.Power)
end

function UIWidgetBattlePet:OnChangePowerAndWatch(power, isReady, watch)
    if power <= 0 then
        power = 0
    end
    self.isReady = isReady

    self:_RefreshPowerArea(self.skillID,self.Power,power,self.isReady)

    self.Power = power

    -- --白表 显示CD
    -- self:_ShowHideCdGo(self.skillID, (watch == false) )
    --灰表
    self:_ShowHideAlreadyCastGo(self.skillID, watch)

    self.powerFull:SetActive(isReady)
end

---刷新传说光灵能量
function UIWidgetBattlePet:OnChangeLegendPower(power, effect, logicReady, maxValue, forceColorWhite)
    --[[
        关于MSG46289 maxValue 和 forceColorWhite
        LegendPower这个值从机制上只有常量上限。策划说的上限其实是每次增加的时候不超过最大值。
        因为这个值不是光灵的基础配置，运行时增加legendPower的行为不一定知道他的上限，表现上也无法判断
        所以这个需求的细则是：
            * 添加legendPower时如果配置了最大值，则根据最大值判断是否变黄；
            * 只要释放了技能，就一定变成白色，不从数值判断。
        对这个需求的时候说过，再有类似的需求，需要从逻辑本身保证光灵身上有“能量上限”这个明确的数据。另，RoundEnterSystem:_UpdatePetPower因使用常量上限而非角色上限，从那边进来的调用不能传maxValue
    ]]
    --如果是传说星灵释放主动技
    if self.skillTriggerType ~= SkillTriggerType.LegendEnergy then
        if self:IsIncludeSkillTriggerType(SkillTriggerType.LegendEnergy) then
            for skillId, skillInfo in pairs(self.extraSkillInfoDic) do
                if skillInfo._skillTriggerType == SkillTriggerType.LegendEnergy then
                --额外技能有能量体系
                self:OnChangeLegendPowerForExtraSkill(skillId,power, effect, logicReady, maxValue, forceColorWhite)
                end
            end
        end
        return
    end

    --常规CD一直关闭
    self:_ShowHideCdGo(self.skillID,false)
    self:_ShowHideAlreadyCastGo(self.skillID,false)
    --原被动buff的层数显示
    --self._PassiveSkillGO.gameObject:SetActive(power ~= 0)
    if not self._hideLegendEnergy then
        self._PassiveSkillGO.gameObject:SetActive(true)
        self._txtAccumulate.gameObject:SetActive(power ~= 0)
        self._txtAccumulate:SetText(tostring(power))
    end

    InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, power)

    -- MSG46289->MSG46384
    if forceColorWhite then
        self._txtAccumulate.color = Color.white
        self._imageIconA.color = Color.white
        self._imageIconB.color = Color.white
        self._imageIconC.color = Color.white
        self._imageIconD.color = Color.white
    elseif maxValue then
        local color = Color.white
        if (power >= maxValue) then
            color = Color.New(1, 0.98823529, 0.058823529, 1) -- #fffc0f
        end
        self._txtAccumulate.color = color
        self._imageIconA.color = color
        self._imageIconB.color = color
        self._imageIconC.color = color
        self._imageIconD.color = color
    end

    if self.Power == power then
        return
    end

    self.Power = power
end
function UIWidgetBattlePet:OnChangePowerForExtraSkill(skillId,power, effect)
    ---@type UIDataBattlePetSkillInfo
    local uiInfo = self.extraSkillInfoDic[skillId]
    if not uiInfo then
        return
    end
    --如果是传说星灵释放主动技
    if uiInfo._skillTriggerType == SkillTriggerType.LegendEnergy then
        uiInfo._power = power
        self:_ShowHideCdGo(skillId,false)
        return
    end
    if power <= 0 then
        power = 0
    end
    self:_RefreshPowerArea(skillId,uiInfo._power,power,uiInfo._ready)
    if uiInfo._power == power then
        return
    end

    uiInfo._power = power

    self:_OnPlayPowerAddEffect(effect,uiInfo._power)
end

---刷新传说光灵能量
function UIWidgetBattlePet:OnChangeLegendPowerForExtraSkill(skillId,power, effect, logicReady, maxValue, forceColorWhite)
    --[[
        关于MSG46289 maxValue 和 forceColorWhite
        LegendPower这个值从机制上只有常量上限。策划说的上限其实是每次增加的时候不超过最大值。
        因为这个值不是光灵的基础配置，运行时增加legendPower的行为不一定知道他的上限，表现上也无法判断
        所以这个需求的细则是：
            * 添加legendPower时如果配置了最大值，则根据最大值判断是否变黄；
            * 只要释放了技能，就一定变成白色，不从数值判断。
        对这个需求的时候说过，再有类似的需求，需要从逻辑本身保证光灵身上有“能量上限”这个明确的数据。另，RoundEnterSystem:_UpdatePetPower因使用常量上限而非角色上限，从那边进来的调用不能传maxValue
    ]]
    ---@type UIDataBattlePetSkillInfo
    local uiInfo = self.extraSkillInfoDic[skillId]
    if not uiInfo then
        return
    end
    --原被动buff的层数显示
    --self._PassiveSkillGO.gameObject:SetActive(power ~= 0)
    if not self._hideLegendEnergy then
        self._PassiveSkillGO.gameObject:SetActive(true)
        self._txtAccumulate.gameObject:SetActive(power ~= 0)
        self._txtAccumulate:SetText(tostring(power))
    end
    InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, power)

    -- MSG46289->MSG46384
    if forceColorWhite then
        self._txtAccumulate.color = Color.white
        self._imageIconA.color = Color.white
        self._imageIconB.color = Color.white
        self._imageIconC.color = Color.white
        self._imageIconD.color = Color.white
    elseif maxValue then
        local color = Color.white
        if (power >= maxValue) then
            color = Color.New(1, 0.98823529, 0.058823529, 1) -- #fffc0f
        end
        self._txtAccumulate.color = color
        self._imageIconA.color = color
        self._imageIconB.color = color
        self._imageIconC.color = color
        self._imageIconD.color = color
    end

    if uiInfo._power == power then
        return
    end

    uiInfo._power = power
end

---展示能量填充
function UIWidgetBattlePet:_OnPlayPowerAddEffect(effect,power)
    if GuideHelper.DontShowMainSkillMission() then
        return
    end
    if self:MissionCanCast() then
        if power > 0 then
            self._effCharge:SetActive(false)
            if effect then
                self._effCharge:SetActive(true)
            end
        end
    end
end

function UIWidgetBattlePet:OnPowerReady(playReminder, previouslyReady)
    if GuideHelper.DontShowMainSkillMission() then
        self.powerFull:SetActive(false)
        return
    end
    if self._isBuffSetCanNotReady then
        return
    end

    if self:MissionCanCast() then
        if not self.isDead then
            self.powerFull:SetActive(true)
        end
        if playReminder and (not previouslyReady) then
            --播放能量满提示音乐
            local pm = GameGlobal.GetModule(PetAudioModule)
            pm:PlayPetAudio("Charge", self._petTemplateID)

            --根据宝宝属性演播特效
            self._skillReadyGO:SetActive(false)
            self._skillReadyGO:SetActive(true)
        end
    end
    self:_ShowHideCdGo(self.skillID,false)
    self.isReady = true

    if self.skillTriggerType ~= SkillTriggerType.LegendEnergy then
        self.Power = 0
        self._addCdAnimation = false
    end
end

function UIWidgetBattlePet:OnPowerCancelReady(addCdAnimation)
    if self:MissionCanCast() then
        if not self.isDead then
            if self:IsExtraSkillHasReady() then
            else
                self.powerFull:SetActive(false)
            end
        end
    end

    self.isReady = false
    if self.skillTriggerType ~= SkillTriggerType.LegendEnergy then
        self:_ShowHideCdGo(self.skillID,true)
        if addCdAnimation ~= 0 then
            self._addCdAnimation = true
        end
    end
end
function UIWidgetBattlePet:OnPowerReadyForExtraSkill(skillId,playReminder,previousReady)
    ---@type UIDataBattlePetSkillInfo
    local uiInfo = self.extraSkillInfoDic[skillId]
    if not uiInfo then
        return
    end
    if GuideHelper.DontShowMainSkillMission() then
        self.powerFull:SetActive(false)
        return
    end
    if self._isBuffSetCanNotReady then
        return
    end
    if self._isBuffSetCanNotReadyForExtra[skillId] then
        return
    end
    if self:MissionCanCast() then
        if not self.isDead then
            self.powerFull:SetActive(true)
        end
        if playReminder and not previousReady then
            --播放能量满提示音乐
            local pm = GameGlobal.GetModule(PetAudioModule)
            pm:PlayPetAudio("Charge", self._petTemplateID)

            --根据宝宝属性演播特效
            self._skillReadyGO:SetActive(false)
            self._skillReadyGO:SetActive(true)
        end
    end
    --附加技 不影响现有的cdGo 待下波扩展 sjs_todo
    self:_ShowHideCdGo(skillId,false)
    self:_ShowHideAlreadyCastGo(skillId,false)
    uiInfo._ready = true

    if uiInfo._skillTriggerType ~= SkillTriggerType.LegendEnergy then
        uiInfo._power = 0
        self._addCdAnimation = false
    end
end

function UIWidgetBattlePet:OnPowerCancelReadyForExtraSkill(skillId,addCdAnimation)
    ---@type UIDataBattlePetSkillInfo
    local uiInfo = self.extraSkillInfoDic[skillId]
    if not uiInfo then
        return
    end
    uiInfo._ready = false
    if self:MissionCanCast() then
        if not self.isDead then
            if self.isReady or self:IsExtraSkillHasReady() then
            else
                self.powerFull:SetActive(false)
            end
        end
    end

    if uiInfo._skillTriggerType ~= SkillTriggerType.LegendEnergy then
        self:_ShowHideCdGo(skillId,true)
        if addCdAnimation ~= 0 then
            self._addCdAnimation = true
        end
    end
end


function UIWidgetBattlePet:OnShowPetInfoInish()
    if not self._addCdAnimation then
        return
    end
    self._addCdAnimation = false

    self._rootAnimation:Play("uieff_jiacdbuff")
end

function UIWidgetBattlePet:MissionCanCast()
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    if enterData:GetMatchType() == MatchType.MT_Mission then
        local currentMissionId = enterData:GetMissionCreateInfo().mission_id
        local current_mission_cfg = Cfg.cfg_mission[currentMissionId]
        if current_mission_cfg == nil then
            return true
        end

        local missionCanCast = current_mission_cfg.CastSkillLimit
        return missionCanCast
    end
    return true
end

function UIWidgetBattlePet:FlushIndex(idx)
    self.petIndex = idx
end

---@return UnityEngine.GameObject
function UIWidgetBattlePet:GetActiveSkillUIPos()
    return self.activeSkillUIPos
end

function UIWidgetBattlePet:GetCancelSkillUIPos()
    return self.cancelActiveSkillUIPos
end

---@return boolean
---@param petPstID number
function UIWidgetBattlePet:IsMyPet(petPstID)
    if self.petPstID == petPstID then
        return true
    end
    return false
end

function UIWidgetBattlePet:GetPetPstID()
    return self.petPstID
end
function UIWidgetBattlePet:GetPetTemplateID()
    return self._petTemplateID
end
--释放技能后清空能能量槽
function UIWidgetBattlePet:ClearPower(castSkillID)
    if GuideHelper.DontShowMainSkillMission() then
        self:_ShowHideCdGo(self.skillID,false)
        return
    end
    if self.extraSkillIDList and table.icontains(self.extraSkillIDList,castSkillID) then
        return self:ClearPowerForExtraSkill(castSkillID)
    end
    if self.skillTriggerType == SkillTriggerType.LegendEnergy then
        --传说光灵
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID, self:GetPetPstID())
        --TODO 阿克希亚扫描模块处理
        local costLegendPower = skillConfigData:GetSkillTriggerParam()
        local cfgCostLegendPower = costLegendPower--罗伊 技能根据点选 消耗不同
        --罗伊 根据点选不同 消耗能量不同
        costLegendPower = self:_GetLegendPowerConstByExtraParam(costLegendPower,skillConfigData, self._uiBattle:GetCurPickExtraParam(self.skillID))
        self.Power = self.Power - costLegendPower

        if self.Power < cfgCostLegendPower then
            self.isReady = false
            if self:IsExtraSkillHasReady() then
            else
                self.powerFull:SetActive(false)
            end
        end

        --刷新传说光灵能量
        self:OnChangeLegendPower(self.Power, nil, nil, nil, true)
    else
        --普通光灵
        self.Power = 0
        self.isReady = false
        if self:IsExtraSkillHasReady() then
        else
            self.powerFull:SetActive(false)
        end
        self:_ShowHideAlreadyCastGo(self.skillID,true)
    end
end
function UIWidgetBattlePet:ClearPowerForExtraSkill(castSkillID)
    ---@type UIDataBattlePetSkillInfo
    local uiInfo = self.extraSkillInfoDic[castSkillID]
    if not uiInfo then
        return
    end
    if uiInfo._skillTriggerType == SkillTriggerType.LegendEnergy then
        --传说光灵
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(uiInfo._skillId, self:GetPetPstID())
        --TODO 阿克希亚扫描模块处理
        local costLegendPower = skillConfigData:GetSkillTriggerParam()
        local cfgCostLegendPower = costLegendPower--罗伊 技能根据点选 消耗不同
        --罗伊 根据点选不同 消耗能量不同
        costLegendPower = self:_GetLegendPowerConstByExtraParam(costLegendPower,skillConfigData, self._uiBattle:GetCurPickExtraParam(uiInfo._skillId))
        uiInfo._power = uiInfo._power - costLegendPower
        
        cfgCostLegendPower = self:CalcNextMinCostLegendPowerByExtraParam(cfgCostLegendPower,skillConfigData)
        if uiInfo._power < cfgCostLegendPower then
            uiInfo._ready = false
            if self.isReady or self:IsExtraSkillHasReady() then
            else
                self.powerFull:SetActive(false)
            end
        end

        --刷新传说光灵能量
        self:OnChangeLegendPowerForExtraSkill(uiInfo._skillId,uiInfo._power, nil, nil, nil, true)
    else
        --普通光灵
        uiInfo._power = 0
        uiInfo._ready = false
        if self.isReady or self:IsExtraSkillHasReady() then
        else
            self.powerFull:SetActive(false)
        end
        self:_ShowHideAlreadyCastGo(uiInfo._skillId,true)
    end
    if self.isReady or self:IsExtraSkillHasReady() then
    else
        self.powerFull:SetActive(false)
    end
    return
end
---罗伊 根据点选不同 消耗能量不同
---@param skillConfigData SkillConfigData
function UIWidgetBattlePet:_GetLegendPowerConstByExtraParam(defaultCost,skillConfigData,extraParam)
    local cost = defaultCost
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if cfgExtraParam then
            if cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then--罗伊 点机关和空格子消耗能量不同
                if extraParam then
                    if table.icontains(extraParam, SkillTriggerTypeExtraParam.PickPosNoCfgTrap) then
                        cost = cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
                    end
                end
            elseif cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                cost = BattleStatHelper.CalcZhongxuForceMovementCostByPick(self.petPstID,skillConfigData:GetID())
                if cost < 0 then
                    cost = defaultCost
                end
            end
        end
    end
    return cost
end
function UIWidgetBattlePet:CalcNextMinCostLegendPowerByExtraParam(defaultCost,skillConfigData)
    local cost = defaultCost
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if cfgExtraParam then
            if cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                --取本次最低消耗（位移怪物一格）
                cost = BattleStatHelper.CalcZhongxuForceMovementNextMinCost(self.petPstID,skillConfigData:GetID())
                if cost < 0 then
                    cost = defaultCost
                end
            end
        end
    end
    return cost
end
function UIWidgetBattlePet:OnChangeHeadAlpha(alpha)
    local color = self.headMask.color
    color.a = alpha
    self.headMask.color = color
end

function UIWidgetBattlePet:ShowPreviewArrow(pstIds)
    if pstIds and table.icontains(pstIds, self.petPstID) then
        --self.previewSkillArrow.gameObject:SetActive(true)
        self.previewAddBuffEffect:SetActive(true)
        self.powerFull:SetActive(false)
        self:OnChangeHeadAlpha(0)
    else
        --self.previewSkillArrow.gameObject:SetActive(false)
        self.previewAddBuffEffect:SetActive(false)
    end
end

function UIWidgetBattlePet:HidePreviewArrow()
    self.previewAddBuffEffect:SetActive(false)
    --self.previewSkillArrow.gameObject:SetActive(false)
    if self.isReady or self:IsExtraSkillHasReady() then
        self.powerFull:SetActive(true)
    end
end

function UIWidgetBattlePet:DoGuideClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady)
end

function UIWidgetBattlePet:GetSkillID()
    return self.skillID
end

function UIWidgetBattlePet:ShowElement(pet)
    if pet == nil then
        return
    end
    local cfg_pet_element = Cfg.cfg_pet_element {}
    if cfg_pet_element then
        local _1stElement = pet:GetPetFirstElement()
        if _1stElement then
            self._attrMain.gameObject:SetActive(true)
            self._attrMain.sprite = self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[_1stElement].Icon .. "_battle")
            )
        else
            self._attrMain.gameObject:SetActive(false)
        end
        local _2ndElement = pet:GetPetSecondElement()
        if _2ndElement then
            self._attrVice.gameObject:SetActive(true)
            self._attrVice.sprite = self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[_2ndElement].Icon .. "_battle")
            )
        else
            self._attrVice.gameObject:SetActive(false)
        end
    end
end

---@param out boolean true出列false入列
function UIWidgetBattlePet:InOutQueue(petPstID, out)
    if petPstID ~= self.petPstID then
        return
    end
    if self.isDead then
        return
    end
    if self._tweenerOffset then
        self._tweenerOffset:Complete()
    end
    local duration = 0.2
    local offsetEndX = 0
    if out then
        offsetEndX = -25
    end
    self._tweenerOffset = self._offset:DOAnchorPosX(offsetEndX, duration)
end

function UIWidgetBattlePet:FlushPetChainSkillItem(isLocal, chainPathLen, elementType, firstElementType)
    if not isLocal then
        return
    end

    if chainPathLen == 0 then --如果没有连锁，入列
        self:InOutQueue(self.petPstID, false)
        return
    elseif chainPathLen == 1 then --如果只连锁一个，表示Touch队长脚下格子
        if self.petIndex == 1 then --如果是队长
            self:InOutQueue(self.petPstID, true)
        else
            self:InOutQueue(self.petPstID, false)
            return
        end
    else
        if self.petIndex == 1 then
            self:InOutQueue(self.petPstID, true)
        else
            if self.isSealedCurse then 
                self:InOutQueue(self.petPstID, false)
                return 
            end

            local forceMatch = BattleStatHelper.CheckForceMatch(self.petPstID)
            if forceMatch then 
                self:InOutQueue(self.petPstID, true)
                return 
            end

            local isElementMatch = self:CheckElementMatch(elementType,firstElementType)
            if isElementMatch then 
                self:InOutQueue(self.petPstID, true)
            else
                self:InOutQueue(self.petPstID, false)
            end
        end
    end
end

function UIWidgetBattlePet:CheckElementMatch(elementType,firstElementType)
    if self._mainAttr == elementType or self._viceAttr == elementType then 
        return true
    end

    if firstElementType ~= nil then 
        if self._mainAttr == firstElementType or self._viceAttr == firstElementType then 
            return true
        end
    end

    return false
end

function UIWidgetBattlePet:_HidePetInfo()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetBattlePet", input = "_HidePetInfo", args = {} }
    )
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
    else
        self:OnUpCallback()
    end
end

function UIWidgetBattlePet:_ShowGuideMask(isShow)
    self:_HidePetInfo()
end

function UIWidgetBattlePet:_ShowStoryBanner()
    self:_HidePetInfo()
end

function UIWidgetBattlePet:_ActiveBattlePet()
    if self._touchArea then
        if not self:IsAutoFighting() then
            self._touchArea:SetActive(true)
        end
    end
end
function UIWidgetBattlePet:_UIFeatureSkillInfoShow(bShow,featureType)
    if FeatureType.Card == featureType then
        if self._touchArea then
            if bShow then
                self._touchArea:SetActive(not bShow)
            else
                if not self:IsAutoFighting() then
                    self._touchArea:SetActive(not bShow)
                end
            end
        end
        self._cardBuffAreaGo:SetActive(bShow)
    end
end


---显隐连锁技立绘
function UIWidgetBattlePet:ShowHideChainSkillCG(petPstID, isShow)
    if petPstID ~= self.petPstID then
        return
    end
    self:_HidePetInfo()
    local s, e = 30, 700
    if not isShow then
        s, e = e, s
    end
    self._goChainSkillIcon.transform:DOAnchorPosX(s, 0.2):OnStart(
        function()
            if isShow then
                self._goChainSkillIcon:SetActive(true)
                self._offset.gameObject:SetActive(false)
                self._skillReadyGO:SetActive(false)
            end
            self._goChainSkillIcon.transform.anchoredPosition = Vector2(e, 0)
        end
    ):OnComplete(
        function()
            if not isShow then
                self._goChainSkillIcon:SetActive(false)
                self._offset.gameObject:SetActive(true)
                if self._chainEnergyLights then
                    for _, lightItem in ipairs(self._chainEnergyLights) do
                        lightItem:DelayedAnimation()
                    end
                end
            end
        end
    )
end

function UIWidgetBattlePet:CancelSwitchTimer()
    if self._switchTimeEvent then
        Log.notice("CancelSwitchTimer")
        GameGlobal.Timer():CancelEvent(self._switchTimeEvent)
        self._switchTimeEvent = nil
    end
end

-----@param perPower number 增加的能量值
--function UIWidgetBattlePet:RemainRoundCount2PowerPet(perPower)
--    self._effChargeState.normalizedTime = 0
--    self._animEffCharge:Play()
--    self:AddPower(perPower)
--end

function UIWidgetBattlePet:_AutoFight(enable)
    self._autoFightState = enable
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
    end
    if self._touchArea then
        self._touchArea:SetActive(not enable)
    end
end

--获取当前星灵是否可发动主动技，不可发动时返回文字提示
function UIWidgetBattlePet:GetCanCastAndReason(curSkillID)
    local missonCanCast = false
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    if enterData:GetMatchType() == MatchType.MT_Mission then
        local currentMissionId = enterData:GetMissionCreateInfo().mission_id
        local current_mission_cfg = Cfg.cfg_mission[currentMissionId]
        if current_mission_cfg == nil then
            missonCanCast = true
        end
        local missionCanCast = current_mission_cfg.CastSkillLimit
        missonCanCast = missionCanCast
        if not missonCanCast then
            return false, StringTable.Get("str_match_pickup_skill_limit")
        end
    end
    local reasonByBuffSetCanNotReadyReason = BattleStatHelper.CheckCanCastActiveSkill_GetCantReadyReasonByBuff(self:GetPetPstID(),curSkillID)
    if reasonByBuffSetCanNotReadyReason then
        local textKey = ActiveSkillCannotCastReasonText[reasonByBuffSetCanNotReadyReason]
        local text = StringTable.Get(textKey)
        local forceTips = true
        return false,text,forceTips
    end
    if self.skillID == curSkillID then
        if not self.isReady then
            return false, StringTable.Get("str_match_cannot_cast_skill_reason")
        end
        if not self:LegendPowerEnoughToCast() then
            local forceTips = true
            return false,StringTable.Get("str_battle_skill_energy_enough"),forceTips
        end
    else
        if self.extraSkillInfoDic then
            ---@type UIDataBattlePetSkillInfo
            local uiInfo = self.extraSkillInfoDic[curSkillID]
            if uiInfo then
                if not uiInfo._ready then
                    return false, StringTable.Get("str_match_cannot_cast_skill_reason")
                end
            end
        else
            if self._variantSkillList then
                if table.icontains(self._variantSkillList,curSkillID) then
                    --是变体技能
                    if not self.isReady then
                        return false, StringTable.Get("str_match_cannot_cast_skill_reason")
                    end
                    if not self:LegendPowerEnoughToCast() then
                        local forceTips = true
                        return false,StringTable.Get("str_battle_skill_energy_enough"),forceTips
                    end
                end
			else
				---走到这里，说明初始化失败了
            	return false, StringTable.Get("str_match_cannot_cast_skill_reason")
            end
        end
    end

    -- if not BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID,self.skillID) then
    --     return false, StringTable.Get("str_battle_team_leader_active_skill_disabled")
    -- end

    return true, nil
end
---在点选技能 无法释放时，点击灰色确认按钮 弹提示的检查-能量不够释放（罗伊）
function UIWidgetBattlePet:LegendPowerEnoughToCast()
    if self.skillTriggerType == SkillTriggerType.LegendEnergy then
        --传说光灵
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID, self:GetPetPstID())
        local costLegendPower = skillConfigData:GetSkillTriggerParam()
        --罗伊 根据点选不同 消耗能量不同
        costLegendPower = self:_GetLegendPowerConstByExtraParam(costLegendPower,skillConfigData, self._uiBattle:GetCurPickExtraParam(self.skillID))
        if self.Power < costLegendPower then
            return false
        end
    else
    end
    return true
end

function UIWidgetBattlePet:InitLegendEnergySkill()
    self._imageDiamondLight.gameObject:SetActive(false)
    self._imageDiamondBlack.gameObject:SetActive(false)
    self._imageIconA.gameObject:SetActive(true)
    self._imageIconB.gameObject:SetActive(false)
    self._imageIconC.gameObject:SetActive(false)
    self._imageIconD.gameObject:SetActive(false)
end


function UIWidgetBattlePet:InitPassiveSkill()
    if not self._passiveSkillID or self._passiveSkillID == 0 then
        Log.info("passiveSkillCfg is nil! , pettemplateid:", self._petTemplateID)
        self._PassiveSkillGO.gameObject:SetActive(false)
        return
    end
    
    local passiveSkillCfg = Cfg.cfg_passive_skill[self._passiveSkillID].ShowMethod
    if passiveSkillCfg == nil then
        Log.info("passiveSkillCfg is nil! , pettemplateid:", self._petTemplateID)
        self._PassiveSkillGO.gameObject:SetActive(false)
        return
    end
    self._PassiveSkillGO.gameObject:SetActive(true)

    if passiveSkillCfg[1] == "1" then
        local defaultLight = true
        if passiveSkillCfg[2] == "1" then
            defaultLight = true
        else
            defaultLight = false
        end
        if passiveSkillCfg[3] then
            if passiveSkillCfg[3] == "1" then
                self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_02")
                self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_01")
                self._imageDiamondLightRect.anchoredPosition = Vector2(26.8,4.7)
                self._imageDiamondBlackRect.anchoredPosition = Vector2(26.8,4.7)
            else
                self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon8")
                self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon9")
                self._imageDiamondLightRect.anchoredPosition = Vector2(20.5,4.7)
                self._imageDiamondBlackRect.anchoredPosition = Vector2(20.5,4.7)
            end
        else
            self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon8")
            self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon9")
            self._imageDiamondLightRect.anchoredPosition = Vector2(20.5,4.7)
            self._imageDiamondBlackRect.anchoredPosition = Vector2(20.5,4.7)
        end
        self._imageDiamondLight.gameObject:SetActive(defaultLight)
        self._imageDiamondBlack.gameObject:SetActive(not defaultLight)
        self._imageIconA.gameObject:SetActive(false)
        self._imageIconB.gameObject:SetActive(false)
        self._imageIconC.gameObject:SetActive(false)
        self._imageIconD.gameObject:SetActive(false)
        self._txtAccumulate.gameObject:SetActive(false)
        if defaultLight then
            InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, 1)
        else
            InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, 0)
        end
        if not self._attachedActivatePassive then
            self:AttachEvent(GameEventType.ActivatePassive, self.ActivatePassive)
            self._attachedActivatePassive = true
        end
        self._passiveIconInited = true
    end
    if passiveSkillCfg[1] == "2" or passiveSkillCfg[1] == "3" or passiveSkillCfg[1] == "4" then
        self._txtAccumulate.gameObject:SetActive(true)
        self._txtAccumulate:SetText("0")
        self._imageIconA.gameObject:SetActive(false)
        self._imageIconB.gameObject:SetActive(false)
        self._imageIconC.gameObject:SetActive(false)
        self._imageIconD.gameObject:SetActive(false)
        self._imageDiamondLight.gameObject:SetActive(false)
        self._imageDiamondBlack.gameObject:SetActive(false)
        if passiveSkillCfg[2] == "a" then
            --【零恩】第四个参数表示零恩专属热量值图标显示在A上
            if passiveSkillCfg[4] == "1" then
                self._isShowOverload = true
                self._isRed = false
                self._imageIconA.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon18")
                --【零恩】第五个参数为热量最大值，过载显示时会设置特殊颜色和更换热量值图标
                self._maxAccumulateNum = tonumber(passiveSkillCfg[5])
            end
            self._imageIconA.gameObject:SetActive(true)
        elseif passiveSkillCfg[2] == "b" then
            self._imageIconB.gameObject:SetActive(true)
        elseif passiveSkillCfg[2] == "c" then
            self._imageIconC.gameObject:SetActive(true)
        elseif passiveSkillCfg[2] == "d" then
            self._imageIconD.gameObject:SetActive(true)
        end
        if (passiveSkillCfg[1] == "4") then
            self._hideLegendEnergy = true
        end
        if self:IsIncludeSkillTriggerType(SkillTriggerType.LegendEnergy) and not self._hideLegendEnergy then --能量占用了self._txtAccumulate,如果另外有配置的buff，使用self._txtAccumulate1 (早苗)
            --self._txtAccumulate1.gameObject:SetActive(true)
            self._txtAccumulate1:SetText("0")
            self._imageIconA1.gameObject:SetActive(false)
            self._imageIconB1.gameObject:SetActive(false)
            self._imageIconC1.gameObject:SetActive(false)
            self._imageIconD1.gameObject:SetActive(false)
            self._imageDiamondLight.gameObject:SetActive(false)
            self._imageDiamondBlack.gameObject:SetActive(false)
            if passiveSkillCfg[2] == "a" then
                self._imageIconA1.gameObject:SetActive(true)
            elseif passiveSkillCfg[2] == "b" then
                self._imageIconB1.gameObject:SetActive(true)
            elseif passiveSkillCfg[2] == "c" then
                self._imageIconC1.gameObject:SetActive(true)
            elseif passiveSkillCfg[2] == "d" then
                self._imageIconD1.gameObject:SetActive(true)
            end
        end
        self._PassiveSkillGO.gameObject:SetActive(false)
        if passiveSkillCfg[3] then
            self._showMultiBuffLayer = {}
            local arr = string.split(passiveSkillCfg[3], "|")
            for _, buffID in ipairs(arr) do
                table.insert(self._showMultiBuffLayer, tonumber(buffID))
            end
        end
        -- if passiveSkillCfg[3] and passiveSkillCfg[3] ~= 0 then
        --     self._txtAccumulate:SetText(tostring(passiveSkillCfg[3]))
        -- else
        --     self._PassiveSkillGO.gameObject:SetActive(false)
        -- end
        self:AttachEvent(GameEventType.SetAccumulateNum, self.SetAccumulateNum)
        self:AttachEvent(GameEventType.ShowOverloadPassiveAccumulate, self._ShowOverloadPassiveAccumulate)
        self._passiveAccumulateInited = true
    end
end
--妮娜 一觉前无被动，但是要显示角标
--米洛斯 层数降到0后改为显示被动图标
function UIWidgetBattlePet:_ForceInitPassiveIcon(pstId,forceInitType)
    if pstId == self.petPstID then
        if not self._passiveIconInited then
            self._PassiveSkillGO.gameObject:SetActive(true)
            local defaultLight = true
            if forceInitType then
                if forceInitType == 1 then
                    self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_02")
                    self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_01")
                    self._imageDiamondLightRect.anchoredPosition = Vector2(26.8,4.7)
                    self._imageDiamondBlackRect.anchoredPosition = Vector2(26.8,4.7)
                elseif forceInitType == 2 then
                    self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon8")
                    self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon9")
                    self._imageDiamondLightRect.anchoredPosition = Vector2(20.5,4.7)
                    self._imageDiamondBlackRect.anchoredPosition = Vector2(20.5,4.7)
                end
            else
                self._imageDiamondLight.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_02")
                self._imageDiamondBlack.sprite = self._uiBattleAtlas:GetSprite("1601561_nina_san_01")
                self._imageDiamondLightRect.anchoredPosition = Vector2(26.8,4.7)
                self._imageDiamondBlackRect.anchoredPosition = Vector2(26.8,4.7)
            end

            self._imageDiamondLight.gameObject:SetActive(defaultLight)
            self._imageDiamondBlack.gameObject:SetActive(not defaultLight)
            self._imageIconA.gameObject:SetActive(false)
            self._imageIconB.gameObject:SetActive(false)
            self._imageIconC.gameObject:SetActive(false)
            self._imageIconD.gameObject:SetActive(false)
            self._txtAccumulate.gameObject:SetActive(false)
            if defaultLight then
                InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, 1)
            else
                InnerGameHelperRender.UISetUIPetAccumulateNum(self.petPstID, 0)
            end
            if not self._attachedActivatePassive then
                self:AttachEvent(GameEventType.ActivatePassive, self.ActivatePassive)
                self._attachedActivatePassive = true

                self:DetachEvent(GameEventType.SetAccumulateNum, self.SetAccumulateNum)
                self:DetachEvent(GameEventType.ShowOverloadPassiveAccumulate, self._ShowOverloadPassiveAccumulate)
            end
            self._passiveIconInited = true
        end
    end
end
function UIWidgetBattlePet:ActivatePassive(pstId, onOff)
    if pstId == self.petPstID then
        self._imageDiamondLight.gameObject:SetActive(onOff)
        self._imageDiamondBlack.gameObject:SetActive(not onOff)
        local num = onOff and 1 or 0
        InnerGameHelperRender.UISetUIPetAccumulateNum(pstId, num)
    end
end

--零恩 一觉前无被动，但是要显示累计热量层数
function UIWidgetBattlePet:_ForceInitPassiveAccumulate(pstId, buffLayerList, forceInitType, maxCount)
    if pstId == self.petPstID and not self._passiveAccumulateInited then
        self._isShowOverload = true
        self._isRed = false
        self._PassiveSkillGO.gameObject:SetActive(false)
        self._txtAccumulate.gameObject:SetActive(true)
        self._txtAccumulate:SetText("0")
        self._imageIconA.gameObject:SetActive(false)
        self._imageIconB.gameObject:SetActive(false)
        self._imageIconC.gameObject:SetActive(false)
        self._imageIconD.gameObject:SetActive(false)
        self._imageDiamondLight.gameObject:SetActive(false)
        self._imageDiamondBlack.gameObject:SetActive(false)

        self._showMultiBuffLayer = {}
        for _, buffID in ipairs(buffLayerList) do
            table.insert(self._showMultiBuffLayer, buffID)
        end

        --【零恩】第二个参数表示零恩专属热量值图标显示在A上
        if forceInitType == 1 then
            self._imageIconA.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon18")
            --【零恩】第五个参数为热量最大值，过载显示时会设置特殊颜色和更换热量值图标
            self._maxAccumulateNum = maxCount
        end
        self._imageIconA.gameObject:SetActive(true)
        self:AttachEvent(GameEventType.SetAccumulateNum, self.SetAccumulateNum)
        self:AttachEvent(GameEventType.ShowOverloadPassiveAccumulate, self._ShowOverloadPassiveAccumulate)
        self._passiveAccumulateInited = true
    end
end

--零恩 显示或隐藏热量过载表现
function UIWidgetBattlePet:_ShowOverloadPassiveAccumulate(pstId, isShowOverload)
    if pstId == self.petPstID then
        self._isShowOverload = isShowOverload
        --第二个参数传非nil，就可以激活启动获取对应bufflayer的层数
        self:SetAccumulateNum(pstId, 1)
    end
end

function UIWidgetBattlePet:SetAccumulateNum(pstId, num)
    if not pstId or not num then
        return
    end
    if pstId == self.petPstID then
        --如果是检测多个buffLayerType同时显示的
        if self._showMultiBuffLayer and table.count(self._showMultiBuffLayer) > 0 then
            local layer = 0
            local viewInstanceArray = InnerGameHelperRender.GetBuffViewByPetPstID(self.petPstID)
            for i, buffView in ipairs(viewInstanceArray) do
                if table.icontains(self._showMultiBuffLayer, buffView:BuffID()) then
                    local curLayer = buffView:GetLayerCount() or 0
                    layer = layer + curLayer
                end
            end
            num = layer
        end

        --被动技能的Buff层数和主动技能量点都需要显示
        local bothShow = false
        if num <= 0 then
            if self:IsIncludeSkillTriggerType(SkillTriggerType.LegendEnergy) and not self._hideLegendEnergy then --能量占用了self._txtAccumulate,如果另外有配置的buff，使用self._txtAccumulate1 (早苗)
                self._txtAccumulate1.gameObject:SetActive(false) --只隐藏上面的buff层数
                bothShow = true
            else
                self._PassiveSkillGO.gameObject:SetActive(false)
            end
        else
            self._PassiveSkillGO.gameObject:SetActive(true)
            if self:IsIncludeSkillTriggerType(SkillTriggerType.LegendEnergy) and not self._hideLegendEnergy then --能量占用了self._txtAccumulate,如果另外有配置的buff，使用self._txtAccumulate1 (早苗)
                self._txtAccumulate1.gameObject:SetActive(true)
                self._txtAccumulate1:SetText(tostring(num))
                bothShow = true
            else
                self._txtAccumulate:SetText(tostring(num))
                if self._maxAccumulateNum then
                    local isNeedShowOverload = false
                    if self._isShowOverload == false then
                        isNeedShowOverload = false
                    elseif num >= self._maxAccumulateNum then
                        isNeedShowOverload = true
                    elseif num < self._maxAccumulateNum then
                        isNeedShowOverload = false
                    end

                    if isNeedShowOverload ~= self._isRed then
                        if isNeedShowOverload == true then
                            local color = Color.New(0.992156862745098, 0.0470588235294118, 0.0156862745098039, 1) --#fd0c04
                            self._txtAccumulate.color = color
                            self._imageIconA.gameObject:SetActive(false)
                            self._imageIconA.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon19")
                            self._imageIconA.gameObject:SetActive(true)
                            self._isRed = true
                        else
                            self._txtAccumulate.color = Color.white
                            self._imageIconA.gameObject:SetActive(false)
                            self._imageIconA.sprite = self._uiBattleAtlas:GetSprite("thread_junei_icon18")
                            self._imageIconA.gameObject:SetActive(true)
                            self._isRed = false
                        end
                    end
                end
            end
        end

        --兼容之前白盒用例：主动技能量点和被动技能Buff层数均使用AccumulateNum
        if bothShow then
            --双显时，使用被动技能计数，用于白盒测试检查头像显示的Buff层数
            InnerGameHelperRender.UISetUIPetPassiveSkillBuffLayerNum(pstId, num)
        else
            --单显时，使用老的接口
            InnerGameHelperRender.UISetUIPetAccumulateNum(pstId, num)
        end        
    end
end

function UIWidgetBattlePet:OnDown(go)
    self._timerEvent = GameGlobal.Timer():AddEvent(
        HelperProxy:GetInstance():GetFixTimeLen(277),
        function()
            self:OnPetPressCallBack()
            self._timerEvent = nil
        end
    )
end
function UIWidgetBattlePet:_ClosePetInfo()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,false)
end
function UIWidgetBattlePet:OnUp(go)
    Log.debug("UIWidgetBattlePet:OnUp() skillID=", self.skillID)
    if self.extraSkillIDList then
        self:OnUpForHasExtraSkill(go)
        return
    end
    --技能变体 （与多主动技不会同时出现）
    if self._variantSkillList then
        self:OnUpForHasVariantSkill(go)
        return
    end
    self._uiBattle._dbgAutoFightInfo = {}
    self._uiBattle._dbgAutoFightInfo.isDead = self.isDead
    if self.isDead then
        self._uiBattle._dbgAutoFightInfo.rtnStep = 1
        return
    end
    local canCastSkill = false
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
        if GuideHelper.DontShowMainSkillMission() then
            self._uiBattle._dbgAutoFightInfo.rtnStep = 2
            return
        end
        canCastSkill = true
    else
        -- UI长按也触发引导完成
        if GuideHelper.IsUIGuideShow() and not self._leaveBtn then
            self:TriggerClickCallBack(go)
        end
    end
    if self._autoFightState then
        canCastSkill = true
    end
    if EDITOR then
        local autoTestMd = GameGlobal.GetModule(AutoTestModule)
        if autoTestMd:IsAutoTest() then
            canCastSkill = true
        end
    end
    self._uiBattle._dbgAutoFightInfo.canCastSkill = canCastSkill
    local uiPrePetId = self._uiBattle:GetPreviewPetId()
    self._uiBattle._dbgAutoFightInfo.uiPrePetId = uiPrePetId
    self._uiBattle._dbgAutoFightInfo.petPstID = self.petPstID
    self._uiBattle._dbgAutoFightInfo.skillId = self.skillID

    --local hasFeatureScan = FeatureServiceHelper.FeatureScanIsPetHasFeatureScan(self.petPstID)
    --if hasFeatureScan then
    --    local selection = FeatureServiceHelper.FeatureScanGetCurrentSelection()
    --    if not selection.skillType then
    --        ToastManager.ShowToast(StringTable.Get("str_battle_akxy_feature_ui_non_scan"))
    --        return
    --    end
    --end
    if canCastSkill then
        self:_ClosePetInfo()
    end
    if canCastSkill and self._uiBattle:GetPreviewPetId() ~= self.petPstID then
        ---只有在局内是等待输入的时候，才能显示主动技弹框
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        local enableInput = GameGlobal:GetInstance():IsInputEnable()

        self._uiBattle._dbgAutoFightInfo.rtnStep = 3
        self._uiBattle._dbgAutoFightInfo.coreGameStateID = coreGameStateID
        self._uiBattle._dbgAutoFightInfo.enableInput = enableInput

        if coreGameStateID == GameStateID.WaitInput and enableInput == true then
            self._uiBattle._dbgAutoFightInfo.rtnStep = 4

            GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            self:TriggerClickCallBack(go)
        elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget
        then
            self._uiBattle._dbgAutoFightInfo.rtnStep = 5

            if self.isSealedCurse then
                self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
                self._uiBattle._dbgAutoFightInfo.rtnStep = 6
                return
            end
            if InnerGameHelperRender.IsPetSilence(self.petPstID) then
                ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
                self._uiBattle._dbgAutoFightInfo.rtnStep = 10
                return
            end

            self._uiBattle._dbgAutoFightInfo.rtnStep = 7
            if self._switchTimeEvent == nil then
                self._uiBattle._dbgAutoFightInfo.switchTimeEvent = 0
            else
                self._uiBattle._dbgAutoFightInfo.switchTimeEvent = 1
            end

            if self._switchTimeEvent == nil then
                self._uiBattle._dbgAutoFightInfo.rtnStep = 8
                if self.switchCallback then
                    self.switchCallback(go)
                end
                --切换预览
                if self.clickCallback then
                    local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, self.skillID)
                    local cancast = self.isReady and not self.isDead and condiCheckOk
                    self.clickCallback(self.petIndex, self.skillID, self.maxPower, self.Power, cancast, go)
                end

                if not self._useSubActiveSkill then
                    Log.notice("preclickhead activeskill", self.skillID)
                    ---先通知战斗，记录一次技能ID
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self.skillID)
                    --通知战斗，切换预览
                    self._switchTimeEvent = GameGlobal.Timer():AddEvent(
                        self._switchTimeLength,
                        function()
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady,self.skillID)
                            self._switchTimeEvent = nil

                            Log.notice("preview activeskill", self.skillID)
                        end
                    )
                end

                GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            else
                Log.notice("still in switch", self.skillID)
                --self:CancelSwitchTimer()
                self._uiBattle._dbgAutoFightInfo.rtnStep = 9
            end
        end
    end

    self:OnUpCallback()
    
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick) --播放点击音效
end

function UIWidgetBattlePet:OnUpForHasExtraSkill(go)
    Log.debug("UIWidgetBattlePet:OnUpForHasExtraSkill() skillID=", self.skillID)
    if self.isDead then
        return
    end
    local canCastSkill = false
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
        if GuideHelper.DontShowMainSkillMission() then
            return
        end
        canCastSkill = true
    else
        -- UI长按也触发引导完成
        if GuideHelper.IsUIGuideShow() and not self._leaveBtn then
            self:TriggerMultiSkillClickCallBack(go)
        end
    end
    if self._autoFightState then
        canCastSkill = true
    end
    if EDITOR then
        local autoTestMd = GameGlobal.GetModule(AutoTestModule)
        if autoTestMd:IsAutoTest() then
            canCastSkill = true
        end
    end
    if canCastSkill then
        self:_ClosePetInfo()
    end
    local uiPrePetId = self._uiBattle:GetPreviewPetId()
    if canCastSkill and self._uiBattle:GetPreviewPetId() ~= self.petPstID then
        ---只有在局内是等待输入的时候，才能显示主动技弹框
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        local enableInput = GameGlobal:GetInstance():IsInputEnable()
        if coreGameStateID == GameStateID.WaitInput and enableInput == true then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            self:TriggerMultiSkillClickCallBack(go)
        elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget
        then
            if self.isSealedCurse then
                self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
                return
            end
            if InnerGameHelperRender.IsPetSilence(self.petPstID) then
                ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
                return
            end

            if self._switchTimeEvent == nil then
                if self.multiSkillSwitchCallback then
                    self.multiSkillSwitchCallback(go)
                end
                --切换预览
                if self.multiSkillClickCallback then
                    local allSkill = {}
                    table.insert(allSkill,self.skillID)
                    if self.extraSkillIDList then
                        table.appendArray(allSkill,self.extraSkillIDList)
                    end
                    local uiDataArray = {}
                    for index, skillId in ipairs(allSkill) do
                        local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, skillId)
                        local featureSvcCheck = true
                        if FeatureServiceHelper.HasFeatureType(FeatureType.Sanity) then
                            featureSvcCheck = FeatureServiceHelper.IsActiveSkillCanCastByPstID(self.petPstID, skillId, {}) --想不到吧这真是pstID
                        end
                        --local cancast = self.isReady and not self.isDead and condiCheckOk and featureSvcCheck
                        local readyAttr = BattleStatHelper.GetPetSkillReadyAttr(self.petPstID,skillId)
                        local bReady = (readyAttr and (readyAttr == 1))
                        local cancast = bReady and not self.isDead and condiCheckOk and featureSvcCheck
                        local maxPower = self.maxPower
                        local curPower = self.Power
                        local showAlreadyCast = false
                        local showPowerInfo = true
                        ---@type UIDataBattlePetSkillInfo
                        local uiDataInfo = self.extraSkillInfoDic[skillId]
                        if uiDataInfo then
                            maxPower = uiDataInfo._maxPower
                            curPower = uiDataInfo._power
                        end
                        ---@type UIExtraSkillCDUiData
                        local uiInfo = self._skillCDUiDic[skillId]
                        if uiInfo then
                            showAlreadyCast = uiInfo._alreadyCastShow
                            showPowerInfo = uiInfo._infoShow
                        end
                        local uiDataSkillInfo = UIDataActiveSkillUIInfo:New(skillId,maxPower,curPower,cancast,showAlreadyCast,showPowerInfo)
                        table.insert(uiDataArray,uiDataSkillInfo)
                    end
                    self.multiSkillClickCallback(self.petIndex, uiDataArray, go,false,self._recordMultiSkillLastClickIndex)
                end
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
                -- if not self._useSubActiveSkill then
                --     Log.notice("preclickhead activeskill", self.skillID)
                --     ---先通知战斗，记录一次技能ID
                --     GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self.skillID)
                --     --通知战斗，切换预览
                --     self._switchTimeEvent = GameGlobal.Timer():AddEvent(
                --         self._switchTimeLength,
                --         function()
                --             GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady,self.skillID)
                --             self._switchTimeEvent = nil

                --             Log.notice("preview activeskill", self.skillID)
                --         end
                --     )
                -- end

                -- GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            else
                Log.notice("still in switch", self.skillID)
                --self:CancelSwitchTimer()
            end
        end
    end

    self:OnUpCallback()
    
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick) --播放点击音效
end
function UIWidgetBattlePet:OnUpForHasVariantSkill(go)
    Log.debug("UIWidgetBattlePet:OnUpForHasVariantSkill() skillID=", self.skillID)
    if self.isDead then
        return
    end
    local canCastSkill = false
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
        if GuideHelper.DontShowMainSkillMission() then
            return
        end
        canCastSkill = true
    else
        -- UI长按也触发引导完成
        if GuideHelper.IsUIGuideShow() and not self._leaveBtn then
            self:TriggerVariantSkillClickCallBack(go)
        end
    end
    if self._autoFightState then
        canCastSkill = true
    end
    if EDITOR then
        local autoTestMd = GameGlobal.GetModule(AutoTestModule)
        if autoTestMd:IsAutoTest() then
            canCastSkill = true
        end
    end
    if canCastSkill then
        self:_ClosePetInfo()
    end
    local uiPrePetId = self._uiBattle:GetPreviewPetId()
    if canCastSkill and self._uiBattle:GetPreviewPetId() ~= self.petPstID then
        ---只有在局内是等待输入的时候，才能显示主动技弹框
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        local enableInput = GameGlobal:GetInstance():IsInputEnable()
        if coreGameStateID == GameStateID.WaitInput and enableInput == true then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            self:TriggerVariantSkillClickCallBack(go)
        elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget
        then
            if self.isSealedCurse then
                self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
                return
            end
            if InnerGameHelperRender.IsPetSilence(self.petPstID) then
                ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
                return
            end

            if self._switchTimeEvent == nil then
                if self.multiSkillSwitchCallback then
                    self.multiSkillSwitchCallback(go)
                end
                --切换预览
                if self.multiSkillClickCallback then
                    local allSkill = {}
                    table.insert(allSkill,self.skillID)
                    if self._variantSkillList then
                        table.appendArray(allSkill,self._variantSkillList)
                    end
                    local uiDataArray = {}
                    for index, skillId in ipairs(allSkill) do
                        local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, skillId)
                        local featureSvcCheck = true
                        if FeatureServiceHelper.HasFeatureType(FeatureType.Sanity) then
                            featureSvcCheck = FeatureServiceHelper.IsActiveSkillCanCastByPstID(self.petPstID, skillId, {}) --想不到吧这真是pstID
                        end
                        --local cancast = self.isReady and not self.isDead and condiCheckOk and featureSvcCheck
                        local readyAttr = BattleStatHelper.GetPetSkillReadyAttr(self.petPstID,skillId)
                        local bReady = (readyAttr and (readyAttr == 1))
                        local cancast = bReady and not self.isDead and condiCheckOk and featureSvcCheck
                        local uiDataSkillInfo = UIDataActiveSkillUIInfo:New(skillId,self.maxPower,self.Power,cancast)--sjs_todo 附加技能的cd
                        table.insert(uiDataArray,uiDataSkillInfo)
                    end
                    local isVariantSkillList = true
                    self.multiSkillClickCallback(self.petIndex, uiDataArray, go, isVariantSkillList,self._recordMultiSkillLastClickIndex)
                end
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            else
                Log.notice("still in switch", self.skillID)
            end
        end
    end

    self:OnUpCallback()
    
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick) --播放点击音效
end
function UIWidgetBattlePet:OnLeave()
    --Log.fatal("Leave: ", self.gameobject.name)
    self._leaveBtn = true
    self:_HidePetInfo()
end

function UIWidgetBattlePet:OnEnter()
    --Log.fatal("Enter: ", self.gameobject.name)
    self._leaveBtn = false
end

-- 为了引导单抽了一下
function UIWidgetBattlePet:TriggerClickCallBack(go)
    if self.isSealedCurse then
        self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end
    if InnerGameHelperRender.IsPetSilence(self.petPstID) then
        ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self.skillID)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady,self.skillID)
    if self.clickCallback then
        local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, self.skillID)
        local featureSvcCheck = true
        if FeatureServiceHelper.HasFeatureType(FeatureType.Sanity) then
            featureSvcCheck = FeatureServiceHelper.IsActiveSkillCanCastByPstID(self.petPstID, self.skillID, {}) --想不到吧这真是pstID
        end
        local cancast = self.isReady and not self.isDead and condiCheckOk and featureSvcCheck
        self.clickCallback(self.petIndex, self.skillID, self.maxPower, self.Power, cancast, go)
    end
end
function UIWidgetBattlePet:TriggerMultiSkillClickCallBack(go)
    if self.isSealedCurse then
        self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end
    if InnerGameHelperRender.IsPetSilence(self.petPstID) then
        ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end

    --GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self.skillID)
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady,self.skillID)
    if self.multiSkillClickCallback then
        local allSkill = {}
        table.insert(allSkill,self.skillID)
        if self.extraSkillIDList then
            table.appendArray(allSkill,self.extraSkillIDList)
        end
        local uiDataArray = {}
        for index, skillId in ipairs(allSkill) do
            local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, skillId)
            local featureSvcCheck = true
            if FeatureServiceHelper.HasFeatureType(FeatureType.Sanity) then
                featureSvcCheck = FeatureServiceHelper.IsActiveSkillCanCastByPstID(self.petPstID, skillId, {}) --想不到吧这真是pstID
            end
            --local cancast = self.isReady and not self.isDead and condiCheckOk and featureSvcCheck
            local readyAttr = BattleStatHelper.GetPetSkillReadyAttr(self.petPstID,skillId)
            local bReady = (readyAttr and (readyAttr == 1))
            local cancast = bReady and not self.isDead and condiCheckOk and featureSvcCheck
            local maxPower = self.maxPower
            local curPower = self.Power
            local showAlreadyCast = false
            local showPowerInfo = true
            ---@type UIDataBattlePetSkillInfo
            local uiDataInfo = self.extraSkillInfoDic[skillId]
            if uiDataInfo then
                maxPower = uiDataInfo._maxPower
                curPower = uiDataInfo._power
            end
            ---@type UIExtraSkillCDUiData
            local uiInfo = self._skillCDUiDic[skillId]
            if uiInfo then
                showAlreadyCast = uiInfo._alreadyCastShow
                showPowerInfo = uiInfo._infoShow
            end
            local uiDataSkillInfo = UIDataActiveSkillUIInfo:New(skillId,maxPower,curPower,cancast,showAlreadyCast,showPowerInfo)
            table.insert(uiDataArray,uiDataSkillInfo)
        end
        self.multiSkillClickCallback(self.petIndex, uiDataArray, go,false,self._recordMultiSkillLastClickIndex)
    end
end
function UIWidgetBattlePet:TriggerVariantSkillClickCallBack(go)
    if self.isSealedCurse then
        self._csAnimSealedCurseClickBan:Play("uieff_Battle_Banned")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end
    if InnerGameHelperRender.IsPetSilence(self.petPstID) then
        ToastManager.ShowToast(StringTable.Get(self._silenceForbiddenStr))
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, nil) -- 恢复状态
        return
    end

    --GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self.skillID)
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, self.isReady,self.skillID)
    if self.multiSkillClickCallback then
        local allSkill = {}
        table.insert(allSkill,self.skillID)
        if self._variantSkillList then
            table.appendArray(allSkill,self._variantSkillList)
        end
        local uiDataArray = {}
        for index, skillId in ipairs(allSkill) do
            local condiCheckOk = BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstID, skillId)
            local featureSvcCheck = true
            if FeatureServiceHelper.HasFeatureType(FeatureType.Sanity) then
                featureSvcCheck = FeatureServiceHelper.IsActiveSkillCanCastByPstID(self.petPstID, skillId, {}) --想不到吧这真是pstID
            end
            --local cancast = self.isReady and not self.isDead and condiCheckOk and featureSvcCheck
            local readyAttr = BattleStatHelper.GetPetSkillReadyAttr(self.petPstID,skillId)
            local bReady = (readyAttr and (readyAttr == 1))
            local cancast = bReady and not self.isDead and condiCheckOk and featureSvcCheck
            local uiDataSkillInfo = UIDataActiveSkillUIInfo:New(skillId,self.maxPower,self.Power,cancast)--sjs_todo 附加技能的cd
            table.insert(uiDataArray,uiDataSkillInfo)
        end
        local isVariantSkillList = true
        self.multiSkillClickCallback(self.petIndex, uiDataArray, go, isVariantSkillList,self._recordMultiSkillLastClickIndex)
    end
end

function UIWidgetBattlePet:_OnChangePetActiveSkill(pstId, skillID)
    if pstId ~= self.petPstID then
        return
    end
    self:_RefreshPowerUiDicOnSkillIdChanged(self.skillID,skillID)
    self.skillID = skillID
end
function UIWidgetBattlePet:_RefreshPowerUiDicOnSkillIdChanged(curSkillId,newSkillId)
    if newSkillId == curSkillId then
        return
    end
    self._skillCDUiDic[newSkillId] = self._skillCDUiDic[curSkillId]
    self._skillCDUiDic[curSkillId] = nil
end
function UIWidgetBattlePet:_OnChangePetExtraActiveSkill(pstId, oriSkillID,skillID)
    if pstId ~= self.petPstID then
        return
    end

    if self.extraSkillIDList then
        local newSkillList = {}
        for index, id in ipairs(self.extraSkillIDList) do
            if id == oriSkillID then
                table.insert(newSkillList,skillID)
            else
                table.insert(newSkillList,id)
            end
        end
        self.extraSkillIDList = newSkillList
        ---@type UIDataBattlePetSkillInfo
        local data = self.extraSkillInfoDic[oriSkillID]
        self.extraSkillInfoDic[oriSkillID] = nil
        self.extraSkillInfoDic[skillID] = data
        self:_RefreshPowerUiDicOnSkillIdChanged(oriSkillID,skillID)

        data._skillId = skillID
        --只替换了id

        local buffLimit = self._isBuffSetCanNotReadyForExtra[oriSkillID]
        if buffLimit then
            self._isBuffSetCanNotReadyForExtra[oriSkillID] = nil
            self._isBuffSetCanNotReadyForExtra[skillID] = buffLimit
        end
    end
end

function UIWidgetBattlePet:_OnSealedCurseFlagChanged(pstId, isCursed, buffSeq, duration, noMaxRound)
    if pstId ~= self.petPstID then
        return
    end

    if (not self.isSealedCurse) and (not isCursed) then
        return
    end
    ---如果是裹在状态需要图标下移
    if self.isOverload then
        if isCursed then
            --self._overloadPos1GO.transform.localPosition.y= self._overloadPos2
            self._overloadPos1GO:SetActive(false)
            self._overloadPos2GO:SetActive(true)
        else
            --self._overloadPos1GO.transform.localPosition.y= self._overloadPos1
            self._overloadPos1GO:SetActive(true)
            self._overloadPos2GO:SetActive(false)
        end
    end

    self.isSealedCurse = isCursed
    self.sealedCurseBuffSeq = buffSeq

    self._goSealedCurseDuration:SetActive(true)
    local s = (noMaxRound) and ("∞") or (tostring(duration))
    self._sealedCurseDurationText:SetText(s)

    local key = isCursed and "uieff_zuzhoubuff_01" or "uieff_zuzhoubuff_03"
    self._csAnimSealedCurse:Play(key)

    self:_CheckShowPowerfullRoundCountUI()--米洛斯
end
function UIWidgetBattlePet:_OnSetActiveSkillCanNotReady(pstId, isCanNotReady, buffSeq,extraSkillID)
    if pstId ~= self.petPstID then
        return
    end
    if extraSkillID then
        self._isBuffSetCanNotReadyForExtra[extraSkillID] = isCanNotReady
    else
        self._isBuffSetCanNotReady = isCanNotReady
    end
end

function UIWidgetBattlePet:_OnShowTeamLeaderChangeUI(isShow)
    if not self.isSealedCurse then
        return
    end

    -- 设置诅咒回合数显隐状态
    self._goSealedCurseDuration:SetActive(not isShow)
end

function UIWidgetBattlePet:_OnBuffRoundCountChanged(buffseq, roundcount, noMaxRound)
    if not self.isSealedCurse then
        return
    end

    if buffseq ~= self.sealedCurseBuffSeq then
        return
    end

    local s = (noMaxRound) and ("∞") or (tostring(roundcount))
    self._sealedCurseDurationText:SetText(s)
end

function UIWidgetBattlePet:ShowHideSelectTeamPositionButton(pstID, bShow)
    if self:IsSelfHelpPet() then
        Log.info(self._className, "help pet do not show select team position button. ")
        self._goSelectTeamPositionButton:SetActive(false)
        self:_CheckShowPowerfullRoundCountUI()--米洛斯
        return
    end

    if self.isSealedCurse then
        Log.info(self._className, "cursed pet do not show select team position button. ")
        self._goSelectTeamPositionButton:SetActive(false)
        self:_CheckShowPowerfullRoundCountUI()--米洛斯
        return
    end

    if self.petPstID == pstID then
        Log.info(self._className, "do not show select team position button on caster itself. ")
        self._goSelectTeamPositionButton:SetActive(false)
        self:_CheckShowPowerfullRoundCountUI()--米洛斯
        return
    end

    Log.debug(self._className, "ShowHideSelectTeamPositionButton: ", tostring(bShow))
    self._goSelectTeamPositionButton:SetActive(bShow)
    self:GetGameObject("SelectTeamPosDefault"):SetActive(true)
    self:GetGameObject("SelectTeamPosSelected"):SetActive(false)

    self:InOutQueue(self.petPstID, false)
    self:_CheckShowPowerfullRoundCountUI()--米洛斯
end

function UIWidgetBattlePet:SelectTeamPosOnClick(go)
    if self:IsSelfHelpPet() then
        Log.info(self._className, "help pet do not show select team position button. ")
        self._goSelectTeamPositionButton:SetActive(false)
        return
    end

    if self.isSealedCurse then
        Log.info(self._className, "cursed pet do not show select team position button. ")
        self._goSelectTeamPositionButton:SetActive(false)
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleUISelectTargetTeamPosition, self.petPstID)
end

function UIWidgetBattlePet:OnBattleUISelectTargetTeamPosition(pstID)
    if self.petPstID == pstID then
        self:InOutQueue(self.petPstID, true)

        self:GetGameObject("SelectTeamPosDefault"):SetActive(false)
        self:GetGameObject("SelectTeamPosSelected"):SetActive(true)
    else
        self:InOutQueue(self.petPstID, false)

        self:GetGameObject("SelectTeamPosDefault"):SetActive(true)
        self:GetGameObject("SelectTeamPosSelected"):SetActive(false)
    end
end

--设置是否触发了主动技子技能的使用
function UIWidgetBattlePet:SetUseSubActiveSkillState(useSubActiveSkill)
    self._useSubActiveSkill = useSubActiveSkill
end
---设置过载状态
function UIWidgetBattlePet:_SetPetOverloadState(state,petPstID)
    if self.petPstID ~= petPstID then
        return
    end
    if state==1 then
        self.isOverload = true
        self._overloadRootGo:SetActive(true)
        --self._overloadPos1GO:SetActive(true)
        if self.isSealedCurse then
            ---self._overloadPos1GO.transform.localPosition.y =self._overloadPos2
            self._overloadPos2GO:SetActive(true)
        else
            ---self._overloadPos1GO.transform.localPosition.y = self._overloadPos1
            self._overloadPos1GO:SetActive(true)
        end
    else
        self.isOverload = false
        self._overloadRootGo:SetActive(false)
        self._overloadPos1GO:SetActive(false)
        self._overloadPos2GO:SetActive(false)
    end
end
--杰诺皮肤影响ui
function UIWidgetBattlePet:_OnFeatureListInit(featureListInfo)
    if featureListInfo then
        for i,v in ipairs(featureListInfo) do
            local featureType = v:GetFeatureType()
            if featureType == FeatureType.Card then--杰诺 皮肤 影响ui
                ---@type FeatureEffectParamCard
                local cardData = v
                local cardUiType = cardData:GetUiType()
                self._featureCardUiType = cardUiType
                if cardUiType == FeatureCardUiType.Default then
                elseif cardUiType == FeatureCardUiType.Skin1 then
                    self._cardFlyEffGo = self:GetGameObject("CardFlyEff_l")
                end
            end
        end
    end
end
--- buffType 1/2 共两种buff 如果1和2同时存在，则改为显示样式3
function UIWidgetBattlePet:_OnFeaturePetUIAddCardBuff(pstId,buffType)
    if pstId ~= self.petPstID then
        return
    end
    if self._featureCardBuffState == 0 then
        self._featureCardBuffState = buffType
    elseif self._featureCardBuffState == 1 then
        if buffType == 2 then
            self._featureCardBuffState = 3
        end
    elseif self._featureCardBuffState == 2 then
        if buffType == 1 then
            self._featureCardBuffState = 3
        end
    end
    self:_RefreshFeatureCardBuffIcon(self._featureCardBuffState)
    self:UIAnimOnAddCardBuffFlyEff()
    self:UIAnimOnAddCardBuff()
end
-- 预览
function UIWidgetBattlePet:_OnFeaturePetUIPreviewAddCardBuff(pstId,buffType)
    if pstId ~= self.petPstID then
        return
    end
    local previewCardState = self._featureCardBuffState
    if previewCardState == 0 then
        previewCardState = buffType
    elseif previewCardState == 1 then
        if buffType == 2 then
            previewCardState = 3
        end
    elseif previewCardState == 2 then
        if buffType == 1 then
            previewCardState = 3
        end
    end
    self:_RefreshFeatureCardBuffIcon(previewCardState)
    self:UIAnimOnPreviewAddCardBuff()
end
--预览恢复
function UIWidgetBattlePet:_OnFeaturePetUIPreviewRecoverCardBuff()
    self:_RefreshFeatureCardBuffIcon(self._featureCardBuffState)
end
function UIWidgetBattlePet:_RefreshFeatureCardBuffIcon(state)
    if state == 0 then
        for key,iconGo in ipairs(self._featureCardBuffIconGoDic) do
            if key == state then
                iconGo:SetActive(true)
            else
                iconGo:SetActive(false)
            end
        end
        self._cardBuffEffGo:SetActive(false)
        --self._cardBuffAreaGo:SetActive(false)
    else
        self._cardBuffAreaGo:SetActive(true)
        for key,iconGo in ipairs(self._featureCardBuffIconGoDic) do
            if key == state then
                iconGo:SetActive(true)
            else
                iconGo:SetActive(false)
            end
        end
        --self._cardBuffEffGo:SetActive(true)
    end
    self:_CheckShowPowerfullRoundCountUI()--米洛斯
end

function UIWidgetBattlePet:OnPetPressCallBack()
    if BattleStatHelper.GetAutoFightStat() then
        ToastManager.ShowToast(self._autoFightForbiddenStr)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,true)
    end
end

function UIWidgetBattlePet:OnUpCallback()
    --关闭放在信息界面上，加了个关闭按钮
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,false)
end
function UIWidgetBattlePet:UIAnimOnAddCardBuff()
    local animName = "CardBuffArea"
    if self._featureCardUiType then
        if self._featureCardUiType == FeatureCardUiType.Skin1 then
            animName = "CardBuffArea_f"
        end
    end
    if animName then
        --self:Lock("UIAnimOnAddCardBuff")
        -- for key,iconGo in ipairs(self._featureCardBuffIconGoDic) do
        --     iconGo:SetActive(false)
        -- end
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_Wait:New(2700,""),
                -- EZTL_Callback:New(
                --     function()
                --         self:_RefreshFeatureCardBuffIcon(self._featureCardBuffState)
                --     end
                -- ),
                EZTL_PlayAnimation:New(self._cardBuffAnim, animName),
                EZTL_Callback:New(
                    function()
                        --self:UnLock("UIAnimOnAddCardBuff")
                    end
                )
            },
            "卡牌buff动效"
        )
        player:Play(tl)
        table.insert(self._players,player)
    end
end
function UIWidgetBattlePet:UIAnimOnPreviewAddCardBuff()
    local animName = "CardBuffArea_1"
    if self._featureCardUiType then
        if self._featureCardUiType == FeatureCardUiType.Skin1 then
            animName = "CardBuffArea_1_f"
        end
    end
    if animName then
        --self:Lock("UIAnimOnAddCardBuff")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._cardBuffAnim, animName),
                EZTL_Callback:New(
                    function()
                        --self:UnLock("UIAnimOnAddCardBuff")
                    end
                )
            },
            "卡牌buff动效预览"
        )
        player:Play(tl)
        table.insert(self._players,player)
    end
end
function UIWidgetBattlePet:UIAnimOnAddCardBuffFlyEff()
    local beginPos = self._uiBattle:GetUIFeatureCardBuffEffBeginPos()
    local targetPos = self._cardBuffEffPosRect.position
    self._cardFlyEffGo.transform.position = beginPos
    if self._cardEffTimerHandler then
        GameGlobal.Timer():CancelEvent(self._cardEffTimerHandler)
        self._cardEffTimerHandler = nil
    end
    local delayMs = 1700
    self._cardEffTimerHandler =  GameGlobal.Timer():AddEvent(delayMs, 
    function()
            self._cardFlyEffGo:SetActive(true)
            self._cardFlyEffGo.transform:DOMove(targetPos, 1):SetEase(DG.Tweening.Ease.InQuart):OnComplete(
                        function()
                            self._cardFlyEffGo:SetActive(false)
                        end
                    )
        end
    )
end
function UIWidgetBattlePet:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end

--米洛斯 技能已就绪回合数
function UIWidgetBattlePet:_OnShowPowerfullRoundCountUI(pstId,bShow,resDic)
    if pstId ~= self.petPstID then
        return
    end
    if bShow then
        if self._powerfullRoundCountAreaGO then
            --self._powerfullRoundCountAreaGO:SetActive(true)
            self._showPowerfullRoundCount = true
            if self._powerfullRoundCountImg then
                local count = BattleStatHelper.GetPreviousReadyRoundCount(pstId)
                if resDic and resDic[count] then
                    self._powerfullRoundCountImg.sprite = self._uiBattle1Atlas:GetSprite(resDic[count])
                end
            end
            self:_CheckShowPowerfullRoundCountUI()
        end
    else
        if self._powerfullRoundCountAreaGO then
            self._powerfullRoundCountAreaGO:SetActive(false)
            self._showPowerfullRoundCount = false
        end
    end
end
function UIWidgetBattlePet:_CheckShowPowerfullRoundCountUI()
    if self._powerfullRoundCountAreaGO then
        if self._showPowerfullRoundCount then
            --换队长、卡牌buff、诅咒 覆盖显示
            local canShow = false
            if self._goSelectTeamPositionButton and self._goSelectTeamPositionButton.activeSelf then
            elseif self.isSealedCurse then
            elseif self._cardBuffAreaGo and self._cardBuffAreaGo.activeSelf then
            else
                canShow = true
            end
            self._powerfullRoundCountAreaGO:SetActive(canShow)
        else
            self._powerfullRoundCountAreaGO:SetActive(false)
        end
    end
end

function UIWidgetBattlePet:_OnScanFeatureReplaceUIActiveSkillID(pstID, activeSkillID, isReady, previouslyReady)
    if self.petPstID ~= pstID then
        return
    end

    self.skillID = activeSkillID
    self:OnChangeLegendPower(self.Power)

    if isReady == 1 then
        local playReminder = not (self.isReady and isReady)
        self:OnPowerReady(playReminder, previouslyReady)
    else
        self:OnPowerCancelReady(0)
    end
end
function UIWidgetBattlePet:_OnUIMultiActiveSkillCastClick(pstID, activeSkillID, isReady)
    if self.petPstID ~= pstID then
        return
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, activeSkillID)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self.petPstID, isReady,activeSkillID)
end
function UIWidgetBattlePet:_OnUIMultiSkillClickIndex(pstID, index)
    if self.petPstID ~= pstID then
        return
    end
    self._recordMultiSkillLastClickIndex = index
end

function UIWidgetBattlePet:IsExtraSkillHasReady()
    if self.extraSkillIDList then
        -- for index, skillId in ipairs(self.extraSkillIDList) do
        --     local readyAttr = BattleStatHelper.GetPetSkillReadyAttr(self.petPstID,skillId)
        --     local bReady = (readyAttr and (readyAttr == 1))
        --     if bReady then
        --         return true
        --     end
        -- end
        for skillId, skillInfo in pairs(self.extraSkillInfoDic) do
            ---@type UIDataBattlePetSkillInfo
            local uiInfo = skillInfo
            if uiInfo._ready then
                return true
            end
        end
    end
    return false
end
function UIWidgetBattlePet:IsIncludeSkillTriggerType(skillTriggerType)
    if self.skillTriggerType == skillTriggerType then
        return true
    else
        if self.extraSkillIDList then
            for skillId, skillInfo in pairs(self.extraSkillInfoDic) do
                ---@type UIDataBattlePetSkillInfo
                local uiInfo = skillInfo
                if uiInfo._skillTriggerType == skillTriggerType then
                    return true
                end
            end
        end
    end
    return false
end

function UIWidgetBattlePet:ShowHideUiMultiPowerInfoByIndex(index,bShow)
    if self._multiSkillCDUi then
        ---@type UIExtraSkillCDUiData
        local uiInfo = self._multiSkillCDUi[index]
        if uiInfo then
            uiInfo._infoGo:SetActive(bShow)
            uiInfo._infoShow = bShow
        end
    end
end
