--
---@class UIWidgetFeatureCardInfo : UICustomWidget
_class("UIWidgetFeatureCardInfo", UICustomWidget)
UIWidgetFeatureCardInfo = UIWidgetFeatureCardInfo
--初始化
function UIWidgetFeatureCardInfo:OnShow(uiParams)
    self:InitWidget()
    self:ResetState()
    self:RefreshAll()
end
function UIWidgetFeatureCardInfo:OnHide()
    if self._players then
        for i,player in ipairs(self._players) do
            if player:IsPlaying() then
                player:Stop()
            end
        end
    end
    self._matRes = {}
end
--获取ui组件
function UIWidgetFeatureCardInfo:InitWidget()
    --允许模拟输入
    self.enableFakeInput = true
    self._selectMax = 3
    self._players = {}
    --generated--
    ---@type UnityEngine.GameObject
    self.root = self:GetGameObject("Root")
    ---@type UnityEngine.GameObject
    self.cardA = self:GetGameObject("CardA")
    ---@type UnityEngine.GameObject
    self.cardB = self:GetGameObject("CardB")
    ---@type UnityEngine.GameObject
    self.cardC = self:GetGameObject("CardC")
    ---@type RawImageLoader
    self.cardImgA = self:GetUIComponent("RawImageLoader", "CardImgA")
    self.cardImgAGo = self:GetGameObject("CardImgA")
    ---@type RawImageLoader
    self.cardImgB = self:GetUIComponent("RawImageLoader", "CardImgB")
    self.cardImgBGo = self:GetGameObject("CardImgB")
    ---@type RawImageLoader
    self.cardImgC = self:GetUIComponent("RawImageLoader", "CardImgC")
    self.cardImgCGo = self:GetGameObject("CardImgC")

    self.cardNumBgA = self:GetGameObject("CardNumBgA")
    self.cardNumBgB = self:GetGameObject("CardNumBgB")
    self.cardNumBgC = self:GetGameObject("CardNumBgC")
    ---@type UILocalizationText
    self.cardNumA = self:GetUIComponent("UILocalizationText", "CardNumA")
    ---@type UILocalizationText
    self.cardNumB = self:GetUIComponent("UILocalizationText", "CardNumB")
    ---@type UILocalizationText
    self.cardNumC = self:GetUIComponent("UILocalizationText", "CardNumC")
    ---@type RawImageLoader
    self.selectedFillArea1 = self:GetUIComponent("RawImageLoader", "SelectedFillArea1")
    self.selectedFillAreaRect1 = self:GetUIComponent("RectTransform", "SelectedFillArea1")
    self.selectedFillAreaGo1 = self:GetGameObject("SelectedFillArea1")
    ---@type RawImageLoader
    self.selectedFillArea2 = self:GetUIComponent("RawImageLoader", "SelectedFillArea2")
    self.selectedFillAreaRect2 = self:GetUIComponent("RectTransform", "SelectedFillArea2")
    self.selectedFillAreaGo2 = self:GetGameObject("SelectedFillArea2")
    ---@type RawImageLoader
    self.selectedFillArea3 = self:GetUIComponent("RawImageLoader", "SelectedFillArea3")
    self.selectedFillAreaRect3 = self:GetUIComponent("RectTransform", "SelectedFillArea3")
    self.selectedFillAreaGo3 = self:GetGameObject("SelectedFillArea3")
    ---@type RawImageLoader
    self.selectedCardImg1 = self:GetUIComponent("RawImageLoader", "SelectedCardImg1")
    ---@type RawImageLoader
    self.selectedCardImg2 = self:GetUIComponent("RawImageLoader", "SelectedCardImg2")
    ---@type RawImageLoader
    self.selectedCardImg3 = self:GetUIComponent("RawImageLoader", "SelectedCardImg3")
    ---@type UnityEngine.GameObject
    self.skillDetailArea = self:GetGameObject("SkillDetailArea")
    ---@type UILocalizationText
    self.skillTitleText = self:GetUIComponent("UILocalizationText", "SkillTitleText")
    ---@type RawImageLoader
    self.skillDescBg = self:GetUIComponent("RawImageLoader", "SkillDescBg")
    ---@type UILocalizationText
    self.skillDescText = self:GetUIComponent("UILocalizationText", "SkillDescText")
    ---@type UnityEngine.UI.Button
    self.castBtn = self:GetUIComponent("Button", "CastBtn")
    self.dragCardGo = self:GetGameObject("DragCard")
    ---@type UnityEngine.RectTransform
    self.dragCardTran = self:GetUIComponent("RectTransform", "DragCard")
    ---@type RawImageLoader
    self.dragCardImg = self:GetUIComponent("RawImageLoader", "DragCardImg")
    self.dragCardImgGo = self:GetGameObject("DragCardImg")
    self._buffEffPosRect = self:GetUIComponent("RectTransform", "CardBuffBegin")

    ---@type UnityEngine.Animation
    self._dragCardAnim = self:GetUIComponent("Animation", "DragCard")
    ---@type UnityEngine.Animation
    self._cardBagAnim = self:GetUIComponent("Animation", "CardBagArea")
    ---@type UnityEngine.Animation
    self._rootAnim = self:GetUIComponent("Animation", "UIWidgetFeatureCardInfo")
    self._selAnim1 = self:GetUIComponent("Animation", "SelectedCell1")
    self._selAnim2 = self:GetUIComponent("Animation", "SelectedCell2")
    self._selAnim3 = self:GetUIComponent("Animation", "SelectedCell3")

    self._castTextTmp = self:GetUIComponent("UILocalizedTMP", "CastText")
    self._closeTextTmp = self:GetUIComponent("UILocalizedTMP", "CloseText")
    self._matRes = {}
    
    --generated end--
    self:InitLocalData()
end
function UIWidgetFeatureCardInfo:SetFontMat(lable,resname) 
    local res  = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    table.insert(self._matRes ,res)
    if not res  then 
        return 
    end 
    local obj  = res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end 
function UIWidgetFeatureCardInfo:InitLocalData()
    self.depotUi = {
        [FeatureCardType.A] = {
            go = self.cardA,
            numGo = self.cardNumBgA,
            numText = self.cardNumA,
            imgLoader = self.cardImgA,
            imgGo = self.cardImgAGo,
            imgResMore = "n21_jieruo_red5",
            imgRes = {[0]="n21_jieruo_red0",[1]="n21_jieruo_red1",[2]="n21_jieruo_red2",[3]="n21_jieruo_red3"},
        },
        [FeatureCardType.B] = {
            go = self.cardB,
            numGo = self.cardNumBgB,
            numText = self.cardNumB,
            imgLoader = self.cardImgB,
            imgGo = self.cardImgBGo,
            imgResMore = "n21_jieruo_yellow5",
            imgRes = {[0]="n21_jieruo_yellow0",[1]="n21_jieruo_yellow1",[2]="n21_jieruo_yellow2",[3]="n21_jieruo_yellow3"},
        },
        [FeatureCardType.C] = {
            go = self.cardC,
            numGo = self.cardNumBgC,
            numText = self.cardNumC,
            imgLoader = self.cardImgC,
            imgGo = self.cardImgCGo,
            imgResMore = "n21_jieruo_blue4",
            imgRes = {[0]="n21_jieruo_blue0",[1]="n21_jieruo_blue1",[2]="n21_jieruo_blue2",[3]="n21_jieruo_blue3"},
        },
    }
    self.selectedUi = {
        [1] = {
            go = self.selectedFillAreaGo1,
            rect = self.selectedFillAreaRect1,
            imgLoader = self.selectedCardImg1,
            anim = self._selAnim1,
            animNamePutDown = "SelectedCell1_putdown",
            animNameIn = "SelectedCell1_enlarge",
            animNameOut = "SelectedCell1_recover",
            animNameUnselected = "SelectedCell1_off",
            moveInPlayer = nil,
            moveOutPlayer = nil
        },
        [2] = {
            go = self.selectedFillAreaGo2,
            rect = self.selectedFillAreaRect2,
            imgLoader = self.selectedCardImg2,
            anim = self._selAnim2,
            animNamePutDown = "SelectedCell2_putdown",
            animNameIn = "SelectedCell2_enlarge",
            animNameOut = "SelectedCell2_recover",
            animNameUnselected = "SelectedCell2_off",
            moveInPlayer = nil,
            moveOutPlayer = nil
        },
        [3] = {
            go = self.selectedFillAreaGo3,
            rect = self.selectedFillAreaRect3,
            imgLoader = self.selectedCardImg3,
            anim = self._selAnim3,
            animNamePutDown = "SelectedCell3_putdown",
            animNameIn = "SelectedCell3_enlarge",
            animNameOut = "SelectedCell3_recover",
            animNameUnselected = "SelectedCell3_off",
            moveInPlayer = nil,
            moveOutPlayer = nil
        },
    }
    self.selectedCardRes = {
        [FeatureCardType.A] = {res="n21_jieruo_ka_red"},
        [FeatureCardType.B] = {res="n21_jieruo_ka_yellow"},
        [FeatureCardType.C] = {res="n21_jieruo_ka_blue"},
    }
    self.skillLocalInfoDic = {
        [1] = {title="abc",infoParamType=2},--给队尾
        [2] = {title="aaa",infoParamType=1},--给队长
        [3] = {title="aab",infoParamType=0},--恢复san 不需要填文本
    }
    self.comTypeToSkillLocalInfoDic = {--把详细的组合转到三大类型组合 对应self.skillLocalInfoDic的key
        [FeatureCardCompositionType.ABC] = 1,
        [FeatureCardCompositionType.AAA] = 2,
        [FeatureCardCompositionType.BBB] = 2,
        [FeatureCardCompositionType.CCC] = 2,
        [FeatureCardCompositionType.AAB] = 3,
        [FeatureCardCompositionType.AAC] = 3,
        [FeatureCardCompositionType.BBA] = 3,
        [FeatureCardCompositionType.BBC] = 3,
        [FeatureCardCompositionType.CCA] = 3,
        [FeatureCardCompositionType.CCB] = 3,
    }

    self:AttachDragEvent(FeatureCardType.A)
    self:AttachDragEvent(FeatureCardType.B)
    self:AttachDragEvent(FeatureCardType.C)

    self._dragEndDisappearAnimNames = {
        [FeatureCardType.A]="DragCard_sun",
        [FeatureCardType.B]="DragCard_moon",
        [FeatureCardType.C]="DragCard_star",
    }
    self._dragEndDisRefreshDepotAnimNames = {
        [FeatureCardType.A]="CardBagArea_A",
        [FeatureCardType.B]="CardBagArea_B",
        [FeatureCardType.C]="CardBagArea_C",
    }
    self:SetFontMat( self._castTextTmp ,"battle_feature_card_info_text_mt.mat") 
    self:SetFontMat( self._closeTextTmp ,"battle_feature_card_info_text_mt.mat") 
end
function UIWidgetFeatureCardInfo:SetUIBattle(uiBattle)
    self._uiBattle = uiBattle
end
function UIWidgetFeatureCardInfo:GetSkillLocalInfo(compositionType)
    local dicKey = self.comTypeToSkillLocalInfoDic[compositionType]
    if dicKey then
        return self.skillLocalInfoDic[dicKey]
    end
end
function UIWidgetFeatureCardInfo:ResetState()
    self.canCast = false
    self._curSkillID = 0
end
function UIWidgetFeatureCardInfo:RefreshAll()
    if not self._initData then
        return
    end
    self:RefreshCardDepotInfo()
    self:RefreshCardSelectedInfo()
    self:RefreshSkillInfo()
    self:RefreshCastBtn()
end
---@param skillInitData FeatureEffectParamCard
function UIWidgetFeatureCardInfo:Init(skillInitData,castCb,cancelCb)
    self._initData = skillInitData
    self._castCb = castCb
    self._cancelCb = cancelCb
    self._curSkillID = 0
    self.canCast = false
    self._uiCastClicked = false--发动点击一次后置为true 避免重复发送消息
    local cards = FeatureServiceHelper.GetCards()
    self._cards = {}
    for cardType,count in pairs(cards) do
        self._cards[cardType] = count
    end
    self._selectedCards = {}

    self:RefreshAll()
    self:PlayEnterAudio()
end
function UIWidgetFeatureCardInfo:GetSelectedCount()
    local count = 0
    for index = 1, self._selectMax do
        local cardType = self._selectedCards[index]
        if cardType and cardType > 0 then
            count = count + 1
        end
    end
    return count
end
function UIWidgetFeatureCardInfo:InsertToSelected(cardType,tarIndex)
    if not tarIndex then
        for index = 1, self._selectMax do
            local cardType = self._selectedCards[index]
            if cardType and cardType > 0 then
            else
                self._selectedCards[index] = cardType
                return
            end
        end
    end
    local curCardType = self._selectedCards[tarIndex]
    if curCardType and curCardType > 0 then
    else
        self._selectedCards[tarIndex] = cardType
    end
end
function UIWidgetFeatureCardInfo:RemoveSelected(index)
    self._selectedCards[index] = 0
end
function UIWidgetFeatureCardInfo:IsSelectedSlotEmpty(index)
    local card = self._selectedCards[index]
    if card and card > 0 then
        return false
    end
    return true
end
function UIWidgetFeatureCardInfo:SelectCard(cardType,tarIndex)
    if self._cards[cardType] and self._cards[cardType] > 0 then
    else
        return -1
    end
    if not tarIndex then
        local bHasEmptySlot = false
        for i = 1, self._selectMax do
            if self:IsSelectedSlotEmpty(i) then
                bHasEmptySlot = true
                tarIndex = i
                break
            end
        end
        if not bHasEmptySlot then
            return 0
        end
    end
    if self:GetSelectedCount() < self._selectMax then
        self._cards[cardType] = self._cards[cardType] - 1
        self:InsertToSelected(cardType,tarIndex)
    end
    return tarIndex
end
function UIWidgetFeatureCardInfo:UnselectCard(cardIndex)
    if self._selectedCards[cardIndex] then
        local cardType = self._selectedCards[cardIndex]
        self:RemoveSelected(cardIndex)
        if not self._cards[cardType] then
            self._cards[cardType] = 0
        end
        if self._cards[cardType] then
            self._cards[cardType] = self._cards[cardType] + 1
        end
    end
end
function UIWidgetFeatureCardInfo:IsSelectedCardsEnough()
    if self._selectedCards and (self:GetSelectedCount() == self._selectMax) then
        return true
    end
    return false
end
function UIWidgetFeatureCardInfo:CheckCurSkillCastCondition()
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curSkillID)
    if not skillConfigData then
        return false
    end
    return FeatureServiceHelper.CheckFeatureSkillCastCondition(FeatureType.Card,self._curSkillID)
end

function UIWidgetFeatureCardInfo:RefreshSkillInfo()
    if self:IsSelectedCardsEnough() then
        if self._curSkillID and self._curSkillID > 0 then
        else
            --动效
            self:UIAnimOnCardEnough()
        end
        self.skillDetailArea:SetActive(true)
        local comType = FeatureServiceHelper.CaclCardCompositionType(self._selectedCards)
        local skillLocalInfo = self:GetSkillLocalInfo(comType)
        if skillLocalInfo then
            local skillID = self._initData:GetCardSkillDic()[comType]
            if skillID then
                self._curSkillID = skillID
                --self.canCast = true
                local log = nil
                self.canCast,log,self._cannotCastReason = self:CheckCurSkillCastCondition()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._curSkillID)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPersonaSkill, FeatureType.Card, self._curSkillID)
            end
            ---@type SkillConfigData
            local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curSkillID)
            if skillConfigData then
                local title = skillConfigData:GetSkillName()
                local skillTitle = StringTable.Get(title)
                --local skillTitle = StringTable.Get(skillLocalInfo.title)
                self.skillTitleText:SetText(skillTitle)
                local skillDesc = ""
                local desc = skillConfigData:GetSkillDesc()
                if skillLocalInfo.infoParamType == 0 then--不填充
                    skillDesc = StringTable.Get(desc)
                elseif skillLocalInfo.infoParamType == 1 then--填充队长名字
                    local nameOri = self:_GetTeamLeaderName()
                    local name = StringTable.Get(nameOri)
                    skillDesc = StringTable.Get(desc,name)
                elseif skillLocalInfo.infoParamType == 2 then--填充队尾名字
                    local nameOri = self:_GetTeamTailName()
                    local name = StringTable.Get(nameOri)
                    skillDesc = StringTable.Get(desc,name)
                end
                self.skillDescText:SetText(skillDesc)
            end
        else
            self:ResetState()
            self.skillDetailArea:SetActive(false)
        end
    else
        if self._curSkillID and self._curSkillID > 0 then
            self:OnCancelSkill()
        end
        self:ResetState()
        self._cannotCastReason = BattleUIActiveSkillCannotCastReason.CardNotEnough
        self.skillDetailArea:SetActive(false)
    end
end
function UIWidgetFeatureCardInfo:OnCancelSkill()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.StopPreviewFeatureSkill,
        false,
        true,
        self._curSkillID,
        FeatureType.Card
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, -1)
    self:UIAnimOnSkillCancel()
end
function UIWidgetFeatureCardInfo:_GetTeamLeaderName()
    return self._uiBattle:GetUITeamLeaderName()
end
function UIWidgetFeatureCardInfo:_GetTeamTailName()
    return self._uiBattle:GetUITeamTailName()
end
function UIWidgetFeatureCardInfo:RefreshCastBtn()
    if self.canCast then
        self.castBtn.interactable = true
        local toColor = Color(255 / 255, 255 / 255, 255 / 255, 1)
        self._castTextTmp.color = toColor
    else
        self.castBtn.interactable = false
        local toColor = Color(255 / 255, 255 / 255, 255 / 255, 180 / 255)
        self._castTextTmp.color = toColor
    end
end
function UIWidgetFeatureCardInfo:RefreshCardDepotInfo()
    self:RefreshOneCardDepotInfo(FeatureCardType.A)
    self:RefreshOneCardDepotInfo(FeatureCardType.B)
    self:RefreshOneCardDepotInfo(FeatureCardType.C)
end
function UIWidgetFeatureCardInfo:RefreshOneCardDepotInfo(cardType)
    local uiInfo = self.depotUi[cardType]
    local cardNum = self._cards[cardType]
    if uiInfo then
        if cardNum and cardNum > 0 then
            uiInfo.numGo:SetActive(true)
            uiInfo.numText:SetText(cardNum)
            local res = uiInfo.imgRes[cardNum] or uiInfo.imgResMore
            uiInfo.imgLoader:LoadImage(res)
        else
            uiInfo.imgLoader:LoadImage(uiInfo.imgRes[0])
            uiInfo.numGo:SetActive(true)
            uiInfo.numText:SetText(0)
        end
    end
end
--拖牌时临时把卡牌数减1
function UIWidgetFeatureCardInfo:TmpDecressOneCardDepotInfo(cardType)
    local uiInfo = self.depotUi[cardType]
    local oriCardNum = self._cards[cardType]
    local cardNum = 0
    if oriCardNum and oriCardNum > 0 then
        cardNum = oriCardNum -1
    end
    if uiInfo then
        if cardNum and cardNum > 0 then
            uiInfo.numGo:SetActive(true)
            uiInfo.numText:SetText(cardNum)
            local res = uiInfo.imgRes[cardNum] or uiInfo.imgResMore
            uiInfo.imgLoader:LoadImage(res)
        else
            uiInfo.imgLoader:LoadImage(uiInfo.imgRes[0])
            uiInfo.numGo:SetActive(true)
            uiInfo.numText:SetText(0)
        end
    end
end
function UIWidgetFeatureCardInfo:RefreshCardSelectedInfo()
    for i=1,self._selectMax do
        self:RefreshOneCardSelectedInfo(i)
    end
end
function UIWidgetFeatureCardInfo:RefreshOneCardSelectedInfo(index)
    local uiInfo = self.selectedUi[index]
    local cardType = self._selectedCards[index]
    if uiInfo then
        if cardType and cardType > 0 then
            uiInfo.go:SetActive(true)
            local res = self.selectedCardRes[cardType].res
            uiInfo.imgLoader:LoadImage(res)
        else
            uiInfo.go:SetActive(false)
        end
    end
end
--设置数据
function UIWidgetFeatureCardInfo:SetData()
end
--按钮点击
function UIWidgetFeatureCardInfo:CloseBtnOnClick(go)
    if self._cancelCb then
        self._cancelCb(self._curSkillID)
    end
end
--按钮点击
function UIWidgetFeatureCardInfo:CloseArea1OnClick(go)
    self:CloseBtnOnClick(nil)
end
--按钮点击
function UIWidgetFeatureCardInfo:CloseArea2OnClick(go)
    self:CloseBtnOnClick(nil)
end
--按钮点击
function UIWidgetFeatureCardInfo:CastBtnOnClick(go)
    self:OnCastClick()
end

--按钮点击
function UIWidgetFeatureCardInfo:SelectedCardImg1OnClick(go)
    self:UnselectCard(1)
    self:RefreshAll()
    self:UIAnimOnUnSelected(1)
end
--按钮点击
function UIWidgetFeatureCardInfo:SelectedCardImg2OnClick(go)
    self:UnselectCard(2)
    self:RefreshAll()
    self:UIAnimOnUnSelected(2)

end
--按钮点击
function UIWidgetFeatureCardInfo:SelectedCardImg3OnClick(go)
    self:UnselectCard(3)
    self:RefreshAll()
    self:UIAnimOnUnSelected(3)
end
function UIWidgetFeatureCardInfo:AutoCardImgOnClick(cardType)
    if FeatureCardType.A == cardType then
        self:CardImgAOnClick(nil)
    elseif FeatureCardType.B == cardType then
        self:CardImgBOnClick(nil)
    elseif FeatureCardType.C == cardType then
        self:CardImgCOnClick(nil)
    end
end
--按钮点击
function UIWidgetFeatureCardInfo:CardImgAOnClick(go)
    local toSlotIndex = self:SelectCard(FeatureCardType.A)
    if toSlotIndex > 0 then
        self:RefreshAll()
        AudioHelperController.PlayUISoundAutoRelease(2522)
        self:UIAnimOnPutDownSelected(toSlotIndex)
    end
end
--按钮点击
function UIWidgetFeatureCardInfo:CardImgBOnClick(go)
    local toSlotIndex = self:SelectCard(FeatureCardType.B)
    if toSlotIndex > 0 then
        self:RefreshAll()
        AudioHelperController.PlayUISoundAutoRelease(2522)
        self:UIAnimOnPutDownSelected(toSlotIndex)
    end
end
--按钮点击
function UIWidgetFeatureCardInfo:CardImgCOnClick(go)
    local toSlotIndex = self:SelectCard(FeatureCardType.C)
    if toSlotIndex > 0 then
        self:RefreshAll()
        AudioHelperController.PlayUISoundAutoRelease(2522)
        self:UIAnimOnPutDownSelected(toSlotIndex)
    end
end

function UIWidgetFeatureCardInfo:OnCastClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetFeatureCardInfo", input = "TmpCastOnClick", args = {} }
    )
    if self._uiCastClicked then
        return
    end
    if (not self.canCast) then
        if not self:MissionCanCast() then
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        elseif self._cannotCastReason then
            local textKey = ActiveSkillCannotCastReasonText[self._cannotCastReason]
            local text = StringTable.Get(textKey)
            ToastManager.ShowToast(text)
        else
            local text = StringTable.Get("str_match_cannot_cast_skill_reason")
            ToastManager.ShowToast(text)
        end
    end

    if self._castCb and self.canCast then
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curSkillID)
        ---@type SkillPickUpType
        local pickUpType = skillConfigData:GetSkillPickType()

        if self:MissionCanCast() then
            self.castBtn.interactable = false --避免重复点击
            self._uiCastClicked = true--避免重复点击
            --释放动效
            self:UIAnimOnCast(pickUpType)
            Log.info("[Card] cast on click ")
            --self._castCb(self._curSkillID, pickUpType)
        else
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        end
    end
end
function UIWidgetFeatureCardInfo:MissionCanCast()
    -- do
    --     return true--无视关卡禁用
    -- end
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

function UIWidgetFeatureCardInfo:OnCardDragBegin(cardType)
    local cardNum = self._cards[cardType]
    if cardNum and cardNum > 0 then
        self._dragingCard = true
        self._dragingCardCurSlot = 0
        self:ShowDragCard(cardType)
        self:TmpDecressOneCardDepotInfo(cardType)
        AudioHelperController.PlayUISoundAutoRelease(2522)
        self._dragingSoundID = AudioHelperController.PlayUISoundResource(2525, true)
    end
end
function UIWidgetFeatureCardInfo:ShowDragCard(cardType)
    self.dragCardGo:SetActive(true)
    local res = self.selectedCardRes[cardType].res
    self.dragCardImgGo:SetActive(true)
    self.dragCardImg:LoadImage(res)
end
function UIWidgetFeatureCardInfo:OnDragCardEnd(cardType)
    if self._dragingSoundID then
        AudioHelperController.StopUISound(self._dragingSoundID)
    end
    if self._dragingCard then
        self._dragingCard = false
        self._dragingCardCurSlot = 0
        local toSlotIndex = 0
        for index,info in pairs(self.selectedUi) do
            local tran = info.rect
            local localPos = tran:InverseTransformPoint(self.dragCardTran.position)
            if tran.rect:Contains(localPos) then
                toSlotIndex = index
                break
            end
        end
        if toSlotIndex == 0 then
            self.dragCardImgGo:SetActive(false)
            --播卡牌溶解
            self:UIAnimOnDragCardEnd(cardType)
            return
        end
        if not self:IsSelectedSlotEmpty(toSlotIndex) then
            self:UnselectCard(toSlotIndex)
            --self:RefreshAll()
        end
        self:SelectCard(cardType,toSlotIndex)
        self:RefreshAll()
        self:HideDragCard()
        self:UIAnimOnPutDownSelected(toSlotIndex)
    end
end
function UIWidgetFeatureCardInfo:HideDragCard()
    self.dragCardGo:SetActive(false)
    --local tarColor = Color.white
    --self.dragCardImg:SetColor(tarColor)--动效设置了透明 恢复一下
    self.dragCardImgGo:SetActive(false)
end
function UIWidgetFeatureCardInfo:RefreshDragCardPos(screenPos)
    if self._dragingCard and self.dragCardTran then
        local camera = GameGlobal.UIStateManager():GetControllerCamera(self.uiOwner:GetName())
        local pos = UIHelper.ScreenPointToWorldPointInRectangle(self.dragCardTran.parent, screenPos, camera)
        self.dragCardTran.position = pos


        --动效
        if self._dragingCard then
            local toSlotIndex = 0
            for index,info in pairs(self.selectedUi) do
                local tran = info.rect
                local localPos = tran:InverseTransformPoint(self.dragCardTran.position)
                if tran.rect:Contains(localPos) then
                    toSlotIndex = index
                    break
                end
            end
            if toSlotIndex == 0 then
                if self._dragingCardCurSlot > 0 then
                    self:UIAnimOnMoveOutSelected(self._dragingCardCurSlot)
                    self._dragingCardCurSlot = 0
                end
            else
                if self._dragingCardCurSlot ~= toSlotIndex then
                    if self._dragingCardCurSlot > 0 then
                        self:UIAnimOnMoveOutSelected(self._dragingCardCurSlot)
                    end
                    self:UIAnimOnMoveInSelected(toSlotIndex)
                    self._dragingCardCurSlot = toSlotIndex
                end
                
            end
        end
    end
end
function UIWidgetFeatureCardInfo:AttachDragEvent(cardType)
    --拖动
    local hostGo = nil
    local uiInfo = self.depotUi[cardType]
    if uiInfo then
        hostGo = uiInfo.imgGo
    end
    if not hostGo then
        return
    end
    local etl = UICustomUIEventListener.Get(hostGo)
    self:AddUICustomEventListener(
        etl,
        UIEvent.BeginDrag,
        function(ped)
            --填充跟随图片
            self:OnCardDragBegin(cardType)
            --GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamItemLongPress, true, self._slot, self._id)
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Drag,
        function(ped)
            self:RefreshDragCardPos(ped.position)
            --GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamUpdateReplaceCardPos, ped.position)
        end
    )
    local endDragFunc = function()
        self:OnDragCardEnd(cardType)
        
        --GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamItemLongPress, false, self._slot, self._id)
    end
    self:AddUICustomEventListener(
        etl,
        UIEvent.EndDrag,
        function(ped)
            endDragFunc()
        end
    )
    -- self:AddUICustomEventListener(
    --     etl,
    --     UIEvent.Click,
    --     function(go)
    --         if self._callback then
    --             self._callback()
    --         end
    --     end
    -- )
    if not EDITOR then
        self:AddUICustomEventListener(
            etl,
            UIEvent.ApplicationFocus,
            function(b)
                if not b then
                    if not etl.IsDragging then
                        return
                    end
                    etl.IsDragging = false
                    endDragFunc()
                end
            end
        )
    end
end

----------------动效--------------
function UIWidgetFeatureCardInfo:UIAnimOnDragCardEnd(cardType)
    local animName = self._dragEndDisappearAnimNames[cardType]
    if animName then
        self:Lock("UIAnimOnDragCardEnd")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._dragCardAnim, animName),
                EZTL_Callback:New(
                    function()
                        self:UIAnimOnDragCardEndRefreshDepot(cardType)
                        self:RefreshCardDepotInfo()
                        self:HideDragCard()
                        self:UnLock("UIAnimOnDragCardEnd")
                    end
                )
            },
            "抽牌ui动效"
        )
        player:Play(tl)
        AudioHelperController.PlayUISoundAutoRelease(2527)
        table.insert(self._players,player)
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnDragCardEndRefreshDepot(cardType)
    local animName = self._dragEndDisRefreshDepotAnimNames[cardType]
    if animName then
        --self:Lock("UIAnimOnDragCardEndRefreshDepot")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._cardBagAnim, animName),
                EZTL_Callback:New(
                    function()
                        self:UnLock("UIAnimOnDragCardEndRefreshDepot")
                    end
                )
            },
            "拖牌空地释放ui动效"
        )
        player:Play(tl)
        table.insert(self._players,player)
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnCardEnough()
    local animName = "UIWidgetFeatureCardInfo_skill"
    if animName then
        self:Lock("UIAnimOnCardEnough")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._rootAnim, animName),
                EZTL_Callback:New(
                    function()
                        self:UnLock("UIAnimOnCardEnough")
                    end
                )
            },
            "卡牌足够"
        )
        player:Play(tl)
        AudioHelperController.PlayUISoundAutoRelease(2519)
        table.insert(self._players,player)
    end
end

function UIWidgetFeatureCardInfo:UIAnimOnCast(pickUpType)
    --local hideDelayMs = 4000
    local hideDelayMs = 3870
    --local hideDelayMs = 2800
    local animName = "UIWidgetFeatureCardInfo_skill_start"
    if animName then
        --self:Lock("UIAnimOnCast")
        local player = EZTL_Player:New()
        local tl1 = EZTL_PlayAnimation:New(self._rootAnim, animName)
        local tl2 = EZTL_Callback:New(
            function()
                --self:UnLock("UIAnimOnCast")
                self._castCb(self._curSkillID, pickUpType,hideDelayMs)
            end
        )
        local tl3 = EZTL_Wait:New(hideDelayMs,"发动")
        local tl =
            EZTL_Parallel:New({tl1, tl2, tl3}, EZTL_EndTag.All, nil, "卡牌技发动")
        player:Play(tl)
        AudioHelperController.PlayUISoundAutoRelease(2529)
        table.insert(self._players,player)
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnPutDownSelected(slotIndex)
    local selectUi = self.selectedUi[slotIndex]
    if not selectUi then
        return
    end
    if selectUi.moveInPlayer then
        if selectUi.moveInPlayer:IsPlaying() then
            selectUi.moveInPlayer:Stop()
        end
        selectUi.moveInPlayer = nil
    end
    if selectUi.moveOutPlayer then
        if selectUi.moveOutPlayer:IsPlaying() then
            selectUi.moveOutPlayer:Stop()
        end
        selectUi.moveOutPlayer = nil
    end
    if selectUi.putDownPlayer then
        if selectUi.putDownPlayer:IsPlaying() then
            selectUi.putDownPlayer:Stop()
        end
        selectUi.putDownPlayer = nil
    end
    local anim = selectUi.anim
    local animName = selectUi.animNamePutDown
    if animName then
        --self:Lock("UIAnimOnPutDownSelected")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(anim, animName),
                EZTL_Callback:New(
                    function()
                        self:UnLock("UIAnimOnPutDownSelected")
                    end
                )
            },
            "动效"
        )
        player:Play(tl)
        AudioHelperController.PlayUISoundAutoRelease(2524)
        table.insert(self._players,player)
        selectUi.putDownPlayer = player
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnMoveInSelected(slotIndex)
    local selectUi = self.selectedUi[slotIndex]
    if not selectUi then
        return
    end
    local cardType = self._selectedCards[slotIndex]
    if cardType and cardType > 0 then--有卡牌时，动画会把卡牌弄没 先屏蔽
        return
    end
    
    if selectUi.moveInPlayer then
        return
    end
    if selectUi.moveOutPlayer then
        if selectUi.moveOutPlayer:IsPlaying() then
            selectUi.moveOutPlayer:Stop()
        end
        selectUi.moveOutPlayer = nil
    end
    local anim = selectUi.anim
    local animName = selectUi.animNameIn
    if animName then
        --self:Lock("UIAnimOnMoveInSelected")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(anim, animName),
                EZTL_Callback:New(
                    function()
                        --self:UnLock("UIAnimOnMoveInSelected")
                    end
                )
            },
            "动效"
        )
        player:Play(tl)
        table.insert(self._players,player)

        selectUi.moveInPlayer = player
    end
end

function UIWidgetFeatureCardInfo:UIAnimOnMoveOutSelected(slotIndex)
    local selectUi = self.selectedUi[slotIndex]
    if not selectUi then
        return
    end
    local cardType = self._selectedCards[slotIndex]
    if cardType and cardType > 0 then--有卡牌时，动画会把卡牌弄没 先屏蔽
        return
    end
    if selectUi.moveOutPlayer then
        return
    end
    if selectUi.moveInPlayer then
        if selectUi.moveInPlayer:IsPlaying() then
            selectUi.moveInPlayer:Stop()
        end
        selectUi.moveInPlayer = nil
    end
    local anim = selectUi.anim
    local animName = selectUi.animNameOut
    if animName then
        --self:Lock("UIAnimOnMoveOutSelected")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(anim, animName),
                EZTL_Callback:New(
                    function()
                        --self:UnLock("UIAnimOnMoveOutSelected")
                    end
                )
            },
            "动效"
        )
        player:Play(tl)
        table.insert(self._players,player)
        selectUi.moveOutPlayer = player
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnUnSelected(slotIndex)
    local selectUi = self.selectedUi[slotIndex]
    if not selectUi then
        return
    end
    if selectUi.moveInPlayer then
        if selectUi.moveInPlayer:IsPlaying() then
            selectUi.moveInPlayer:Stop()
        end
        selectUi.moveInPlayer = nil
    end
    if selectUi.moveOutPlayer then
        if selectUi.moveOutPlayer:IsPlaying() then
            selectUi.moveOutPlayer:Stop()
        end
        selectUi.moveOutPlayer = nil
    end
    if selectUi.putDownPlayer then
        if selectUi.putDownPlayer:IsPlaying() then
            selectUi.putDownPlayer:Stop()
        end
        selectUi.putDownPlayer = nil
    end
    local anim = selectUi.anim
    local animName = selectUi.animNameUnselected
    if animName then
        anim:Play(animName)
        --self:Lock("UIAnimOnUnSelected")
        -- local player = EZTL_Player:New()
        -- local tl =
        --     EZTL_Sequence:New(
        --     {
        --         EZTL_PlayAnimation:New(anim, animName),
        --         EZTL_Wait:New(200, ""),
        --         EZTL_Callback:New(
        --             function()
        --                 self:UnLock("UIAnimOnUnSelected")
        --             end
        --         )
        --     },
        --     "取消选牌"
        -- )
        -- player:Play(tl)
        -- table.insert(self._players,player)
    end
end
function UIWidgetFeatureCardInfo:UIAnimOnSkillCancel()
    local animName = "UIWidgetFeatureCardInfo_skill_out"
    if animName then
        self:Lock("UIAnimOnSkillCancel")
        local player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._rootAnim, animName),
                EZTL_Callback:New(
                    function()
                        self:UnLock("UIAnimOnSkillCancel")
                    end
                )
            },
            "关闭界面"
        )
        player:Play(tl)
        table.insert(self._players,player)
    end
end
function UIWidgetFeatureCardInfo:PlayEnterAudio()
    AudioHelperController.PlayUISoundAutoRelease(2524)
end
function UIWidgetFeatureCardInfo:GetCardBuffEffBeginScreenPos()
    local pos = self._buffEffPosRect.position
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self._uiBattle:GetName())
    local screenPos = camera:WorldToScreenPoint(pos)
    return screenPos
end
function UIWidgetFeatureCardInfo:GetCardBuffEffBeginPos()
    local pos = self._buffEffPosRect.position
    return pos
end