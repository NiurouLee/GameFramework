---@class UIGradeInterfaceController:UIController
_class("UIGradeInterfaceController", UIController)
UIGradeInterfaceController = UIGradeInterfaceController

function UIGradeInterfaceController:Constructor()
    self._fromPos = 0
    self._itemCountPerRow = 1
    ---@type Pet
    self._petInfo = nil
    self._oldCgName = ""
    self._attMaxNum = 5

    ---@type UIPetGradeEffPlayer
    self.effPlayer = nil

    self._petVoiceID = -1

    self._waitTime = Cfg.cfg_global["shakeWaitTime"].IntValue or 2000
    self._shakeX = Cfg.cfg_global["shakeOffsetX"].IntValue or 10
    self._shakeY = Cfg.cfg_global["shakeOffsetY"].IntValue or 10

    --1,可关闭,2,可点击
    self._closeState = 0
    -- self._canShare = self:GetModule(ShareModule):CanShare()
end

--获取滑动列表
function UIGradeInterfaceController:GetPetInfos()
end

function UIGradeInterfaceController:GetComponents()
    self._bodyLoader = self:GetUIComponent("RawImageLoader", "BodyLoader")
    local sop = self:GetUIComponent("UISelectObjectPath", "mainmenu")
    self.currencyMenu = sop:SpawnObject("UICurrencyMenu")
    self.currencyMenu:SetData({RoleAssetID.RoleAssetGold})

    self._needGoldTex = self:GetUIComponent("UILocalizationText", "needGoldCount")

    self._leftLine = self:GetUIComponent("Graphic", "leftLine")
    self._consumeName = self:GetUIComponent("Graphic", "consumeName")
    self._coinBg = self:GetUIComponent("Graphic", "coin")
    self._needcoin = self:GetUIComponent("Graphic", "needGoldCount")
    self._rightLine = self:GetUIComponent("Graphic", "rightLine")
    self._consumeRect = self:GetUIComponent("RectTransform", "xiaohaobi")

    self._bg = self:GetGameObject("bg")
    self._MaterialBtnForGuideGo = self:GetGameObject("MaterialBtnForGuide")
    self._MaterialBtnForGuideGo:SetActive(false)
    --ScrollView
    self._left = self:GetUIComponent("Transform", "left")
    self._right = self:GetUIComponent("Transform", "right")
    self._center = self:GetUIComponent("Transform", "center")

    self._safeArea = self:GetUIComponent("RectTransform", "SafeArea")
    self._animRoot = self:GetUIComponent("Animation", "UIGradeInterfaceController")

    ---@type UnityEngine.UI.GridLayoutGroup
    self._petContentLayout = self:GetUIComponent("GridLayoutGroup", "PetContent")
    --EndScrollView

    self:AttachEvent(GameEventType.PetUpGradeEvent, self.PetBreakSucceed)
    self:AttachEvent(GameEventType.PetUpGradeChangeCgEvent, self.PetUpGradeChangeCgEvent)
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)
    self:AttachEvent(GameEventType.OnOpenGiftsSucc, self.RefreshItemCount)
    self:AttachEvent(GameEventType.CloseUIBackPackBox, self.RefreshItemCount)

    local topButton = self:GetUIComponent("UISelectObjectPath", "TopButtons")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            if self.effPlayer and self.effPlayer.IsPlaying then
                self.effPlayer:Stop()
            end
            self:StopTween()
            self:DetachEvent(GameEventType.PetUpGradeEvent, self.PetBreakSucceed)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, true)

	        if self.closeCb then
                self.closeCb()
                self.closeCb =nil
                self.SkipTransitionAmin = true
            end
            self:Lock("self._animRoot:Play")
            self._animRoot:Play("uieff_GradeInterface_Out")
            GameGlobal.Timer():AddEvent(
                417,
                function()
                    self:UnLock("self._animRoot:Play")
                    self:CloseDialog()
                end
            )
        end,
        function()
            self:ShowDialog("UIHelpController", "UIGradeInterfaceController")
        end,
        function()
            UICommonHelper:GetInstance():SwitchToUIMain()
        end
    )

    --region
    self._leftView = self:GetUIComponent("UIView", "rectLeft")
    self._centerView = self:GetUIComponent("UIView", "rectCenter")
    self._rightView = self:GetUIComponent("UIView", "rectRight")
    ---@type UIGradeInfoItem
    self._leftLua = UIGradeInfoItem:New()
    ---@type UIGradeInfoItem
    self._centerLua = UIGradeInfoItem:New()
    ---@type UIGradeInfoItem
    self._rightLua = UIGradeInfoItem:New()
    self._leftLua:SetView(self._leftView)
    self._centerLua:SetView(self._centerView)
    self._rightLua:SetView(self._rightView)
    self._leftLua:OnShowItem()
    self._centerLua:OnShowItem()
    self._rightLua:OnShowItem()
    -----------------------------
    self._rectLeft = self:GetUIComponent("RectTransform", "rectLeft")
    self._rectLeft.anchoredPosition = Vector2(-200, 0)
    self._rectCenter = self:GetUIComponent("RectTransform", "rectCenter")
    self._rectCenter.anchoredPosition = Vector2(0, 0)
    self._rectRight = self:GetUIComponent("RectTransform", "rectRight")
    self._rectRight.anchoredPosition = Vector2(200, 0)
    self._alphaLeft = self:GetUIComponent("CanvasGroup", "rectLeft")
    self._alphaLeft.alpha = 0
    self._alphaLeft.blocksRaycasts = false

    self._alphaCenter = self:GetUIComponent("CanvasGroup", "rectCenter")
    self._alphaCenter.alpha = 1
    self._alphaCenter.blocksRaycasts = true

    self._alphaRight = self:GetUIComponent("CanvasGroup", "rectRight")
    self._alphaRight.alpha = 0
    self._alphaRight.blocksRaycasts = false
    -----------------------------
    self._content = self:GetUIComponent("RectTransform", "PetContent")
    -----------------------------
    self._bgCgCenter = self:GetUIComponent("RawImageLoader", "drawIconCenterCg")
    self._bgCgLeft = self:GetUIComponent("RawImageLoader", "drawIconLeftCg")
    self._bgCgRight = self:GetUIComponent("RawImageLoader", "drawIconRightCg")

    self._bgCgRectLeft = self:GetUIComponent("RectTransform", "drawIconLeft")
    self._bgCgRectCenter = self:GetUIComponent("RectTransform", "drawIconCenter")
    self._bgCgRectRight = self:GetUIComponent("RectTransform", "drawIconRight")

    self._bgCgGroupLeft = self:GetUIComponent("CanvasGroup", "drawIconLeft")
    self._bgCgGroupLeft.alpha = 0
    self._bgCgGroupCenter = self:GetUIComponent("CanvasGroup", "drawIconCenter")
    self._bgCgGroupCenter.alpha = 1
    self._bgCgGroupRight = self:GetUIComponent("CanvasGroup", "drawIconRight")
    self._bgCgGroupRight.alpha = 0
    --endregion

    self._gradeShowPool = self:GetUIComponent("UISelectObjectPath", "gradeShowPool")
    ---@type UnityEngine.CanvasGroup
    self._gradeShowPoolCanvasGroup = self:GetUIComponent("CanvasGroup", "gradeShowPool")
    self._gradeShowPoolCanvasGroup.blocksRaycasts = false

    self._closeBg = self:GetGameObject("closeBg")

    self._bgAnim = self:GetUIComponent("Animation", "bgAnim")
    self._uiAnim = self:GetUIComponent("Animation", "uiAnim")

    --喊话
    self._desc1 = self:GetUIComponent("UILocalizationText", "gradeDesc")
    self._desc2 = self:GetUIComponent("UILocalizationText", "gradeDesc2")

    --可以开启礼包
    self._openGiftTips = self:GetGameObject("openGiftTips")

    -- self._shareBtnGo = self:GetGameObject("ShareBtn")
    -- self._shareBtnGo:SetActive(false)
end

function UIGradeInterfaceController:OnShow(uiParams)
    ---@type PetModule
    self._petModule = GameGlobal.GameLogic():GetModule(PetModule)
    ---@type RoleModule
    self._roleModule = GameGlobal.GetModule(RoleModule)
    --获取星灵信息
    self:RequestAllPetInfos()

    local petid = uiParams[1]

    self.closeCb = uiParams[2]

    self:GetComponents()

    self._currIndex = self:FindOpenPetIndex(petid)
    self._currIndexTemp = self._currIndex

    self._petInfo = self._petInfos[self._currIndex]

    self._curMaxLv = self._petInfo:GetMaxLevel()
    self._curAtk = self._petInfo:GetPetAttack()
    self._curDef = self._petInfo:GetPetDefence()
    self._curHp = self._petInfo:GetPetHealth()

    self._petPstID = self._petInfo:GetPstID()

    self:OnShowInfos()

    self:InitPetScrollView()
    
    if GameGlobal.GetModule(GuideModule):IsGuideProcess(5110) then --觉醒引导
       self._MaterialBtnForGuideGo:SetActive(true)
    else
        self._MaterialBtnForGuideGo:SetActive(false)
    end

end

function UIGradeInterfaceController:OnShowInfos()
    if self._petInfos[self._currIndex - 1] then
        self._leftLua:SetData(self._currIndex - 1, self._petInfos[self._currIndex - 1])
    end
    if self._petInfos[self._currIndex] then
        self._centerLua:SetData(self._currIndex, self._petInfos[self._currIndex])
    end
    if self._petInfos[self._currIndex + 1] then
        self._rightLua:SetData(self._currIndex + 1, self._petInfos[self._currIndex + 1])
    end
end

--region
------------------------------------------------------------获取星灵信息
function UIGradeInterfaceController:RequestAllPetInfos()
    local petInfos = self._petModule.uiModule:GetSortedPets()
    ---@type MatchPet[]
    self._petInfos = {}
    for i = 1, #petInfos do
        local petInfo = petInfos[i]
        if petInfo:GetMaxGrade() ~= petInfo:GetPetGrade() then
            table.insert(self._petInfos, petInfo)
        end
    end
    self._listShowItemCount = table.count(self._petInfos)
end
-----------------------------------------------------进来时打开哪一个星灵
function UIGradeInterfaceController:FindOpenPetIndex(petid)
    if self._petInfos then
        for index = 1, #self._petInfos do
            if self._petInfos[index]:GetTemplateID() == petid then
                return index
            end
        end
    end
    return 1
end
function UIGradeInterfaceController:InitPetScrollView()
    ---@type UIGradePetDetailItem[]
    self._itemTable = {}

    ---@type H3DScrollViewHelper
    self._scrollViewHelper =
        H3DScrollViewHelper:New(
        self,
        "PetScrollView",
        "UIGradePetDetailItem",
        function(index, uiwidget)
            return self:_OnShowItem(index, uiwidget)
        end,
        function(index, uiwidget)
            return self:_OnHideItem(index, uiwidget)
        end
    )

    self._scrollViewHelper:SetGroupChangedCallback(
        function(index, item)
            if index + 1 > self._listShowItemCount then
                return
            end
            self:_ShowCurrIndexInfo(index + 1)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetListIndexChanged, self._petInfo:GetTemplateID())
        end
    )

    self._scrollViewHelper:SetValueChangedCallback(
        function(group, value, contentSize, itemSize)
            self:_OnValueChangedCallBack(group + 1, value, contentSize, itemSize)
        end
    )

    self._scrollRectWidth = self:GetUIComponent("RectTransform", "PetScrollView").sizeDelta.x
    local safeArea = self:GetUIComponent("RectTransform", "SafeArea")

    self._scrollViewHelper:Init(self._listShowItemCount, self._currIndex, safeArea.rect.size)

    --策划配置滑动灵敏度，大 --> 小（不灵敏 --> 灵敏）
    self._scrollViewHelper:SetNextPageOffset(0.12)
end
function UIGradeInterfaceController:_OnShowItem(index, uiwidget)
    if self._itemTable[index] == nil then
        self._itemTable[index] = uiwidget
    end

    --拿到当下这个cg
    local petData = self._petInfos[index]
    --local matCgName = petData:GetPetStaticBody()
    uiwidget:SetData(index, petData, self._currIndex)
end
function UIGradeInterfaceController:_OnHideItem(index, uiwidget)
    if self._itemTable[index] == nil then
        return
    end
    uiwidget:OnHideCallBack()
end
function UIGradeInterfaceController:_ShowCurrIndexInfo(index)
    self._currIndex = index
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GradeCheckIsCurrent, self._currIndex)
    self._petInfo = self._petInfos[index]
    self._petPstID = self._petInfo:GetPstID()

    -- 设置跳转返回数据
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    jumpData:Track_From() -- 切换时要先回退
    jumpData:Track_Pet()

    jumpData:Track_Pet(self._petPstID)
    jumpData:Track_From(self:GetName())

    -----------------------------
    self:Refresh()
    self._currIndexTemp = self._currIndex
end
function UIGradeInterfaceController:_OnValueChangedCallBack(group, value, contentSize, itemSize)
    --[[
    local di = (contentSize - itemSize)
    --分母不能等于零
    if di <= 0 then
        return
    end
    local rate = itemSize / (contentSize - itemSize)
    if rate <= 0 then
        return
    end

    local centerRate = group * rate - 0.5 * rate
    local distance = value - centerRate

    local a = math.abs(distance) / (rate * 0.5) + 0.05

    local a = 1.0 - a
    if a < 0 then
        a = 0
    elseif a > 1 then
        a = 1
    end
    ]]
    local leftRightDis = math.abs(self._left.position.x - self._right.position.x)
    local centerPosition = self._center.position
    for i = self._currIndex - 1, self._currIndex + 1 do
        if self._itemTable[i] then
            self._itemTable[i]:ChangeCanvasGroupAlpha(leftRightDis, centerPosition.x)
        end
    end

    if
        self._content.localPosition.x > 0 or
            self._content.localPosition.x < -self._content.sizeDelta.x + self._scrollRectWidth
     then
        return
    end

    --name
    local c2c = self._itemTable[self._currIndex]:GetC2C()
    local nameRate = c2c / leftRightDis
    local posx = nameRate * 200

    self._rectCenter.anchoredPosition = Vector2(posx, 0)
    self._rectLeft.anchoredPosition = Vector2(posx - 200, 0)
    self._rectRight.anchoredPosition = Vector2(posx + 200, 0)

    self._alphaCenter.alpha = 1 - nameRate * 2

    if c2c < 0 then
        self._alphaLeft.alpha = 0
        self._alphaRight.alpha = nameRate * 2
    elseif c2c > 0 then
        self._alphaLeft.alpha = nameRate * 2
        self._alphaRight.alpha = 0
    else
        self._alphaLeft.alpha = 0
        self._alphaRight.alpha = 0
    end

    --cg
    local cgRate = c2c / leftRightDis
    local posx_cg = cgRate * 300

    self._bgCgRectCenter.anchoredPosition = Vector2(posx, 0)
    self._bgCgRectLeft.anchoredPosition = Vector2(posx - 300, 0)
    self._bgCgRectRight.anchoredPosition = Vector2(posx + 300, 0)

    self._bgCgGroupCenter.alpha = 1 - cgRate * 2

    if c2c < 0 then
        self._bgCgGroupLeft.alpha = 0
        self._bgCgGroupRight.alpha = cgRate * 2
    elseif c2c > 0 then
        self._bgCgGroupLeft.alpha = cgRate * 2
        self._bgCgGroupRight.alpha = 0
    else
        self._bgCgGroupLeft.alpha = 0
        self._bgCgGroupRight.alpha = 0
    end
end
--endregion

function UIGradeInterfaceController:OnHide()
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)
    self:DetachEvent(GameEventType.OnOpenGiftsSucc, self.RefreshItemCount)
    self:DetachEvent(GameEventType.CloseUIBackPackBox, self.RefreshItemCount)

    if self._petVoiceID > 0 then
        AudioHelperController.StopUIVoice(self._petVoiceID)
        self._petVoiceID = -1
    end
    if self.goldEvent then
        GameGlobal.Timer():CancelEvent(self.goldEvent)
    end
    if self._changeCgEvent then
        GameGlobal.Timer():CancelEvent(self._changeCgEvent)
    end
    if self._secondAnimEvent then
        GameGlobal.Timer():CancelEvent(self._secondAnimEvent)
    end
    if self._closeEvent then
        GameGlobal.Timer():CancelEvent(self._closeEvent)
    end
    if self._thirdEvent then
        GameGlobal.Timer():CancelEvent(self._thirdEvent)
    end
    if self._audioEvent then
        GameGlobal.Timer():CancelEvent(self._audioEvent)
    end
    if self._scrollViewHelper then
        self._scrollViewHelper:Dispose()
    end

    self:Release()

    -- 设置跳转返回数据
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    jumpData:Track_From()
    jumpData:Track_Pet()
end

function UIGradeInterfaceController:OnItemCountChanged()
    self._centerLua:ShowConsumMaterial()
    if self._leftLua then
        self._leftLua:ShowConsumMaterial()
    end
    if self._rightLua then
        self._rightLua:ShowConsumMaterial()
    end

    self:Refresh()
end

function UIGradeInterfaceController:OnUpdate(deltaTimeMS)
    if self.effPlayer then
        self.effPlayer:Update(deltaTimeMS / 1000)
    end
    if self._showPanel then
        self._showPanel:OnUpdate(deltaTimeMS)
    end
end

function UIGradeInterfaceController:Release()
    self._petModule = nil
    self._petInfo = nil
    self._petPstID = 0

    if self._centerLua then
        -- body
        self._centerLua:Dispose()
        self._centerLua = nil
    end
    if self._leftLua then
        -- body
        self._leftLua:Dispose()
        self._leftLua = nil
    end
    if self._rightLua then
        -- body
        self._rightLua:Dispose()
        self._rightLua = nil
    end
end
function UIGradeInterfaceController:Refresh()
    self._oldCgName = self._petInfo:GetPetStaticBody(PetSkinEffectPath.BODY_GRADE)

    self:ShowInfo()
    self:ShowBigCg()
    self:ShowNeedGold()

    --改变背景
    local imageLoader = self:GetUIComponent("RawImageLoader", "BgLoader")
    UICommonHelper:GetInstance():ChangePetTagBackground(self._petInfo:GetTemplateID(), imageLoader, false)
    self._currIndexTemp = self._currIndex
end

function UIGradeInterfaceController:ShowNeedGold()
    local gradeLevel = self._petInfo:GetPetGrade()
    if self._petInfo:GetMaxGrade() == gradeLevel then
        return
    end
    local cfg = Cfg.cfg_pet_grade {PetID = self._petInfo:GetTemplateID(), Grade = gradeLevel + 1}
    local gradeNeedItemList = cfg[1].NeedItem
    self._needGoldCount = 0
    for key, value in pairs(gradeNeedItemList) do
        local data = string.split(value, ",")
        if tonumber(data[1]) == RoleAssetID.RoleAssetGold then
            self._needGoldCount = tonumber(data[2])
            break
        end
    end
    self._needGoldTex:SetText(self._needGoldCount)

    --判断变色
    local goldEnough = false
    local bagNum = self._roleModule:GetGold()
    local color
    if bagNum < self._needGoldCount then
        color = Color(249 / 255, 54 / 255, 54 / 255)
    else
        goldEnough = true
        color = Color(250 / 255, 237 / 255, 92 / 255)
    end
    if color ~= nil then
        self._leftLine.color = color
        self._consumeName.color = color
        --self._coinBg.color = color
        self._needcoin.color = color
        self._rightLine.color = color
    end

    --检查材料是否足够，不够的话显示tips
    --添加检测金币
    if goldEnough then
        self:ShowOpenGiftTips()
    end
end
function UIGradeInterfaceController:ShowOpenGiftTips()
    self._canOpenGift = false
    local show = false
    local canGrade = self._centerLua:CanGradeClick()
    if canGrade then
        local needList = {}
        local needMatList = self._centerLua:GetNeedMatList()
        if needMatList then
            for i = 1, #needMatList do
                table.insert(needList, needMatList[i])
            end
        end

        --去掉金钱检测
        -- local bagNum = self._roleModule:GetGold()
        -- if bagNum < self._needGoldCount then
        --     local needGold = {}
        --     needGold.id = RoleAssetID.RoleAssetGold
        --     needGold.count = self._needGoldCount - bagNum
        --     table.insert(needList,needGold)
        -- end

        if table.count(needList) > 0 then
            if self:CheckGiftEnough(needList) then
                show = true
            end
        end
    end
    self._openGiftTips:SetActive(show)
end
function UIGradeInterfaceController:CheckGiftEnough(needList)
    local matList = needList
    --检查礼包够不够获得这么多材料
    local giftEnough, giftDatas = HelperProxy:GetInstance():GetGiftsFromNeedMat(needList)
    self._giftDatas = giftDatas
    self._canOpenGift = giftEnough
    return giftEnough
end
function UIGradeInterfaceController:ShowInfo()
    if self._currIndexTemp > self._currIndex then
        self._rectRight.anchoredPosition = self._rectRight.anchoredPosition - Vector2(400, 0)

        local rightLuaTemp = self._rightLua
        self._rightLua = self._centerLua
        self._centerLua = self._leftLua
        self._leftLua = rightLuaTemp

        local rightRectTemp = self._rectRight
        self._rectRight = self._rectCenter
        self._rectCenter = self._rectLeft
        self._rectLeft = rightRectTemp

        local alphaRightTemp = self._alphaRight
        self._alphaRight = self._alphaCenter
        self._alphaCenter = self._alphaLeft
        self._alphaLeft = alphaRightTemp

        if self._petInfos[self._currIndex - 1] then
            self._leftLua:RefreshData(self._currIndex - 1, self._petInfos[self._currIndex - 1], false)
        end
    elseif self._currIndexTemp < self._currIndex then
        self._rectLeft.anchoredPosition = self._rectLeft.anchoredPosition + Vector2(400, 0)

        local leftLuaTemp = self._leftLua
        self._leftLua = self._centerLua
        self._centerLua = self._rightLua
        self._rightLua = leftLuaTemp

        local leftRectTemp = self._rectLeft
        self._rectLeft = self._rectCenter
        self._rectCenter = self._rectRight
        self._rectRight = leftRectTemp

        local alphaLeftTemp = self._alphaLeft
        self._alphaLeft = self._alphaCenter
        self._alphaCenter = self._alphaRight
        self._alphaRight = alphaLeftTemp

        if self._petInfos[self._currIndex + 1] then
            self._rightLua:RefreshData(self._currIndex + 1, self._petInfos[self._currIndex + 1], false)
        end
    end

    self._alphaCenter.blocksRaycasts = true
    self._alphaRight.blocksRaycasts = false
    self._alphaLeft.blocksRaycasts = false
end

function UIGradeInterfaceController:ShowBigCg()
    if self._currIndexTemp > self._currIndex then
        self._bgCgRectRight.anchoredPosition = self._bgCgRectRight.anchoredPosition - Vector2(600, 0)
        local bgCgTemp = self._bgCgRight

        self._bgCgRight = self._bgCgCenter
        self._bgCgCenter = self._bgCgLeft
        self._bgCgLeft = bgCgTemp

        local bgCgRectTemp = self._bgCgRectRight

        self._bgCgRectRight = self._bgCgRectCenter
        self._bgCgRectCenter = self._bgCgRectLeft
        self._bgCgRectLeft = bgCgRectTemp

        local bgCgGroupTemp = self._bgCgGroupRight

        self._bgCgGroupRight = self._bgCgGroupCenter
        self._bgCgGroupCenter = self._bgCgGroupLeft
        self._bgCgGroupLeft = bgCgGroupTemp
    elseif self._currIndexTemp < self._currIndex then
        local bgCgTemp = self._bgCgLeft

        self._bgCgLeft = self._bgCgCenter
        self._bgCgCenter = self._bgCgRight
        self._bgCgRight = bgCgTemp

        local bgCgRectTemp = self._bgCgRectLeft

        self._bgCgRectLeft.anchoredPosition = self._bgCgRectLeft.anchoredPosition + Vector2(600, 0)

        self._bgCgRectLeft = self._bgCgRectCenter
        self._bgCgRectCenter = self._bgCgRectRight
        self._bgCgRectRight = bgCgRectTemp

        local bgCgGroupTemp = self._bgCgGroupLeft

        self._bgCgGroupLeft = self._bgCgGroupCenter
        self._bgCgGroupCenter = self._bgCgGroupRight
        self._bgCgGroupRight = bgCgGroupTemp
    end

    local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue

    if self._itemTable[self._currIndex - 1] then
        local leftCgName = self._itemTable[self._currIndex - 1]:GetCgName()

        UICG.SetTransform(self._bgCgLeft.transform, self:GetName() .. "_color", leftCgName)
        self._bgCgLeft:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        self._bgCgLeft:LoadImage(leftCgName)
        local loadAlpha = self:GetUIComponent("LoadAlphaPost", "drawIconLeftCg")
        loadAlpha:SetData()
    end
    if self._itemTable[self._currIndex] then
        local centerCgName = self._itemTable[self._currIndex]:GetCgName()

        UICG.SetTransform(self._bgCgCenter.transform, self:GetName() .. "_color", centerCgName)
        self._bgCgCenter:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        self._bgCgCenter:LoadImage(centerCgName)
        local loadAlpha = self:GetUIComponent("LoadAlphaPost", "drawIconCenterCg")
        loadAlpha:SetData()
    end
    if self._itemTable[self._currIndex + 1] then
        local rightCgName = self._itemTable[self._currIndex + 1]:GetCgName()

        UICG.SetTransform(self._bgCgRight.transform, self:GetName() .. "_color", rightCgName)
        self._bgCgRight:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        self._bgCgRight:LoadImage(rightCgName)
        local loadAlpha = self:GetUIComponent("LoadAlphaPost", "drawIconRightCg")
        loadAlpha:SetData()
    end
end

function UIGradeInterfaceController:RefreshItemCount()
    --监听使用礼包的事件
    if self._petInfos[self._currIndex - 1] then
        self._leftLua:RefreshItemCount()
    end
    if self._petInfos[self._currIndex] then
        self._centerLua:RefreshItemCount()
    end
    if self._petInfos[self._currIndex + 1] then
        self._rightLua:RefreshItemCount()
    end

    self:ShowNeedGold()
end

function UIGradeInterfaceController:GradeButtonOnClick(go)
    if self._canOpenGift then
        -- 打开开礼包界面
        local title = StringTable.Get("str_pet_config_grade_open_gift_title")
        self:ShowDialog("UIOpenGiftGetMatController", self._giftDatas, title)
    else
        if self._centerLua:GradeButtonOnClick() then
            --金币
            local bagNum = self._roleModule:GetGold()
            if bagNum < self._needGoldCount then
                self:GoldDOShakePosition()
                return
            end
            local pstID = self._petInfo:GetPstID()
            ---@type UIPetModule
            local uiModule = self._petModule.uiModule
            --觉醒的提升
            self._skillVaryInfosParams = uiModule:GetDiffWithGrade(self._petInfo, false)

            self:StartGrade(pstID)
        end
    end
end

function UIGradeInterfaceController:GoldDOShakePosition()
    if self._goldTweer then
        if self._goldTweer:IsPlaying() then
            return
        end
    end
    if self._goldTweer then
        self._goldTweer:Kill()
        self._consumeRect.anchoredPosition = Vector2(0, 0)
    end
    if self.goldEvent then
        GameGlobal.Timer():CancelEvent(self.goldEvent)
    end
    self:SetColor(false)
    self._goldTweer =
        self._consumeRect:DOShakePosition(1, Vector3(self._shakeX, self._shakeY, 0)):OnComplete(
        function()
            self:StartTimer()
        end
    )
end

function UIGradeInterfaceController:StartTimer()
    self.goldEvent =
        GameGlobal.Timer():AddEvent(
        self._waitTime,
        function()
            self:SetColor(true)
        end
    )
end

function UIGradeInterfaceController:SetColor(isDefaultColor)
    local color = nil
    if isDefaultColor then
        --判断变色
        local bagNum = self._roleModule:GetGold()
        if bagNum < self._needGoldCount then
            color = Color(249 / 255, 54 / 255, 54 / 255)
        end
    else
        color = Color(249 / 255, 54 / 255, 54 / 255)
    end
    if color ~= nil then
        self._leftLine.color = color
        self._consumeName.color = color
        --self._coinBg.color = color
        self._needcoin.color = color
        self._rightLine.color = color
    end
end

function UIGradeInterfaceController:StopTween()
    self._centerLua:StopTween()
end

function UIGradeInterfaceController:StartGrade(pstID)
    self:Lock("UIGradeInterfaceController:StartGrade")
    GameGlobal.TaskManager():StartTask(self.GradeCallBack, self, pstID)
end

function UIGradeInterfaceController:GradeCallBack(TT, pstID)
    local res = self._petModule:RequestPetBreak(TT, pstID)

    if res:GetSucc() then
        Log.debug("###[UIGradeInterfaceController]up grade !!!")
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundGradeUp)
        local varyPetInfo = self._petModule:GetPet(self._petPstID)
        self._petInfo = varyPetInfo
        self._petModule.uiModule:SetCurSelctPet(varyPetInfo)
        ---@type UIGradeShowGrowth
        self._showPanel = self._gradeShowPool:SpawnObject("UIGradeShowGrowth")

        self._showPanel:SetData(
            self._petInfo,
            self._skillVaryInfosParams,
            self._curMaxLv,
            self._curAtk,
            self._curDef,
            self._curHp
        )

        local currGrade = self._petInfo:GetPetGrade()
        local skinid = self._petInfo:GetSkinId()
        local cfg_pet_voice
        local cfgs = Cfg.cfg_pet_voice {PetID = self._petInfo:GetTemplateID(), SkinID = skinid}
        if cfgs and next(cfgs) then
            cfg_pet_voice = cfgs[1]
        else
            cfg_pet_voice = Cfg.cfg_pet_voice {PetID = self._petInfo:GetTemplateID(), SkinID = nil}[1]
        end
        if cfg_pet_voice then
            local gradeDesc = nil
            local _gradeDesc = nil
            if currGrade == 1 then
                _gradeDesc = cfg_pet_voice.Grade1Up
            elseif currGrade == 2 then
                _gradeDesc = cfg_pet_voice.Grade2Up
            elseif currGrade == 3 then
                _gradeDesc = cfg_pet_voice.Grade3Up
            end
            if _gradeDesc then
                gradeDesc = _gradeDesc[1][1]
            end
            if gradeDesc == nil then
                Log.error("###星灵觉醒成功，星灵-->", self._petInfo:GetTemplateID(), "，当前觉醒阶段-->", currGrade, "，但是GradeUp文本字段为空")
            else
                local cfg_audio = AudioHelperController.GetCfgAudio(gradeDesc)
                local texDesc
                if cfg_audio then
                    texDesc = cfg_audio.Content
                else
                    Log.error("###cfg_audio is nil ! id --> ", gradeDesc)
                end
                self._desc1:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(texDesc)))
                self._desc2:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(texDesc)))
            end
        else
            Log.error("###cfg_pet_voice is nil ! id --> ", self._petInfo:GetTemplateID(), "| skinid --> ", skinid)
        end

        GameGlobal.EventDispatcher():Dispatch(GameEventType.PetUpGradeEvent, self._petPstID)
        self._bgAnim:Play("UIGradeInterfaceController_bg")
        self._uiAnim:Play("UIGradeInterfaceController_RightAnchor")

        --开启计时,多久之后切立绘
        if self._changeCgEvent then
            GameGlobal.Timer():CancelEvent(self._changeCgEvent)
        end
        self._changeCgEvent =
            GameGlobal.Timer():AddEvent(
            2466,
            function()
                self:ChangeCgEvent()
            end
        )
        if self._secondAnimEvent then
            GameGlobal.Timer():CancelEvent(self._secondAnimEvent)
        end
        self._secondAnimEvent =
            GameGlobal.Timer():AddEvent(
            6000,
            function()
                self:SecondAnimEvent()
            end
        )

        if self._audioEvent then
            GameGlobal.Timer():CancelEvent(self._audioEvent)
        end
        self._audioEvent =
            GameGlobal.Timer():AddEvent(
            3000,
            function()
                --播放升维成功的语音
                local tplID = self._petInfo:GetTemplateID()
                ---@type PetAudioModule
                local pm = GameGlobal.GetModule(PetAudioModule)
                if currGrade == 1 then
                    pm:PlayPetAudio("Grade1Up", tplID)
                elseif currGrade == 2 then
                    pm:PlayPetAudio("Grade2Up", tplID)
                elseif currGrade == 3 then
                    pm:PlayPetAudio("Grade3Up", tplID)
                end
            end
        )
    else
        self:UnLock("UIGradeInterfaceController:StartGrade")

        Log.fatal(" up grade  failed !!! result --> ", res:GetResult())
    end
end

function UIGradeInterfaceController:SecondAnimEvent()
    self._closeState = 1
    self:UnLock("UIGradeInterfaceController:StartGrade")
    --MSG19023	（QA_张江丽）星灵觉醒QA_觉醒后数据自动显示_20210309.docx	5	QA-待制作	李学森, 1958	03/09/2021
    self:closeBgOnClick()
end

function UIGradeInterfaceController:ChangeCgEvent()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PetUpGradeChangeCgEvent, self._petPstID)
end

function UIGradeInterfaceController:PetUpGradeChangeCgEvent(pstid)
    if pstid == self._petPstID then
        --时装影响 满觉醒获得觉醒皮肤 此时应该已经将觉醒皮肤设为当前皮肤
        local centerCgName = self._petInfo:GetPetStaticBody(PetSkinEffectPath.BODY_GRADE)
        UICG.SetTransform(self._bgCgCenter.transform, self:GetName() .. "_color", centerCgName)
        self._bgCgCenter:LoadImage(centerCgName)
        local loadAlpha = self:GetUIComponent("LoadAlphaPost", "drawIconCenterCg")
        loadAlpha:SetData()
    end
end

function UIGradeInterfaceController:PetBreakSucceed(pstid)
    self._closeBg:SetActive(true)
end

function UIGradeInterfaceController:CanClose()
    self._closeState = 2
    self:UnLock("UIGradeInterfaceController:StartGrade")
end

function UIGradeInterfaceController:closeBgOnClick()
    if self._closeState == 1 then
        self:Lock("UIGradeInterfaceController:StartGrade")

        self._bgAnim:Play("UIGradeInterfaceController_bg_1")
        self._uiAnim:Play("UIGradeInterfaceController_RightAnchor_1")

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.PlayAnimation_UIGradePetDetailItem,
            self._petInfo:GetPstID()
        )

        self._gradeShowPoolCanvasGroup.blocksRaycasts = true

        if self._thirdEvent then
            GameGlobal.Timer():CancelEvent(self._thirdEvent)
        end
        self._thirdEvent =
            GameGlobal.Timer():AddEvent(
            1500,
            function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetUpGradeThird)
            end
        )

        if self._closeEvent then
            GameGlobal.Timer():CancelEvent(self._closeEvent)
        end
        self._closeEvent =
            GameGlobal.Timer():AddEvent(
            4000,
            function()
                -- self._shareBtnGo:SetActive(self._canShare)
                self:CanClose()
            end
        )
    elseif self._closeState == 2 then
        local lockId = "UIGradeInterfaceController:closeBgOnClick_closeState_2"
        self:Lock(lockId)
        self._uiAnim:Play("UIGradeInterfaceController_RightAnchor_Out")
        self:StartTask(
            function(TT)
                if self.closeCb then
                    self.closeCb()
                    self.closeCb =nil
                    self.SkipTransitionAmin = true
                end
                YIELD(TT, 533)
                self:UnLock(lockId)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, true)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideGradeUpDone, self._petInfo:GetPetGrade())
                self:CloseDialog()
            end,
            self
        )
    end
end

VaryType = {
    fight = 0, --战斗
    work = 1, --工作
    drawing = 2 --立绘
}
_enum("VaryType", VaryType)

function UIGradeInterfaceController:GetGuideItem()
    return self._rightLua:GetGuideItem()
end

function UIGradeInterfaceController:MaterialBtnForGuideOnClick(go)
    --return self._rightLua:GetGuideItem()
    self._MaterialBtnForGuideGo:SetActive(false)
    return self._centerLua:ClickGuideItem()
end