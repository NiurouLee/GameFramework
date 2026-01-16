require("rawimage_loader_helper")
require("spine_loader_helper")

---@class UISpiritDetailGroupController : UIController
_class("UISpiritDetailGroupController", UIController)
UISpiritDetailGroupController = UISpiritDetailGroupController

function UISpiritDetailGroupController:Constructor()
    self._spriteWithElement = {
        [1] = "spirit_xiangqing_di7",
        [2] = "spirit_xiangqing_di4",
        [3] = "spirit_xiangqing_di6",
        [4] = "spirit_xiangqing_di5"
    }
    self._colorWithElement = {
        [1] = Color(16 / 255, 132 / 255, 213 / 255),
        [2] = Color(211 / 255, 44 / 255, 9 / 255),
        [3] = Color(137 / 255, 157 / 255, 0 / 255),
        [4] = Color(209 / 255, 166 / 255, 2 / 255)
    }
    self._currentTaskID = -1
    ---@type MatchPet[]
    self._petInfos = nil
    self._maxStarLevel = 6
    self._maxCountElement = 3
    self._listShowItemCount = 0
    self._openDetailIndex = 1
    self._cgStateTable = nil
    self._index = 0
    self._intimacyTweener = nil
    self._expTweener = nil
    self._showBtnTweener = nil
    self._showMoodTweener = nil

    self._firstIn = 0

    --图集
    self._uiPetDeTailAtlas = self:GetAsset("UIPetDetail.spriteatlas", LoadType.SpriteAtlas)
    self._uiPetElementAtlas = self:GetAsset("UIPetElement.spriteatlas", LoadType.SpriteAtlas)
    self._uiHeartItemAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    self._atlasAwake = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)

    self._prof2Img = {
        [2001] = "spirit_prof_5",
        [2002] = "spirit_prof_1",
        [2003] = "spirit_prof_3",
        [2004] = "spirit_prof_7"
    }
    self._prof2Tex = {
        [2001] = "str_pet_tag_job_name_color_change",
        [2002] = "str_pet_tag_job_name_return_blood",
        [2003] = "str_pet_tag_job_name_attack",
        [2004] = "str_pet_tag_job_name_function"
    }
    self._elem2str = {
        [1] = "str_pet_filter_water_element",
        [2] = "str_pet_filter_fire_element",
        [3] = "str_pet_filter_sen_element",
        [4] = "str_pet_filter_electricity_element"
    }
end

function UISpiritDetailGroupController:OnShow(uiParams)
    self:Lock("UIOpenPetDetail")
    ---@type UICustomPetData
    self._customPetData = uiParams[3]
    self._cfg_pet_element = Cfg.cfg_pet_element {}
    if not self._cfg_pet_element then
        Log.fatal("[error] cfg_pet_element is nil")
        return
    end
    --[[

    if uiParams[2] then
        self._closeCallback = uiParams[2]
    end
    ]]
    self:InitWigets()
    ---@type UIHeartItem
    self._heartItem = uiParams[4]
    ---@type UIItem
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)

    self._mazeModule = self:GetModule(MazeModule)
    self._petModule = GameGlobal.GameLogic():GetModule(PetModule)
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    if self._customPetData and self._customPetData:IsShowBtnInfo() then
        self._backBtns:SetData(
            function()
                self:CallUIMethod("UIHeartSpiritController", "RefreshEquipRed")
                GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"backBtn"}, true)
                self:CloseDialog()
            end
        )
        local lookBtnTran = self:GetUIComponent("RectTransform", "LookBtn")
        lookBtnTran.anchoredPosition = Vector2(405, lookBtnTran.anchoredPosition.y)
    else
        self._backBtns:SetData(
            function()
                --[[
                    if self._closeCallback then
                        self._closeCallback()
                    end
                    ]]
                self:CallUIMethod("UIHeartSpiritController", "RefreshEquipRed")
                GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"backBtn"}, true)
                self:CloseDialog()
            end,
            function()
                self:ShowDialog("UIHelpController", "UISpiritDetailGroupController")
                -- ToastManager.ShowToast(StringTable.Get("str_pet_config_function_no_open"))
            end
        )
    end

    self:GetUIComponents()
    self._BtnsPos = self._Btns.anchoredPosition

    --定义动画UI状态
    self._btnsIsOpen = true

    ---@type UnityEngine.RectTransform
    self._safeArea = self:GetUIComponent("RectTransform", "SafeArea")
    self._canvas = self._safeArea.parent:GetComponent("RectTransform")
    self._redPoint = self:GetGameObject("gradeRedPoiot")

    local petID = uiParams[1]
    --秘境编队进入修改界面
    self._fromMaze = uiParams[2]
    self:ShowMazeInfo()
    --获取星灵信息
    self:RequestAllPetInfos()

    if petID then
        self._currIndex = self:FindOpenPetIndex(petID)
    else
        --self._currIndex = self:FindOpenPetIndexByPetTempId(petTempId)
        self._currIndex = 1
    end

    self._currIndexTemp = self._currIndex

    --材质球缓存池,spine缓存池
    self._rawImageLoaderHelper = RawImageLoaderHelper:New()
    self._rawImageLoaderHelper:Init(20)
    self._spineLoaderHelper = SpineLoaderHelper:New()
    self._spineLoaderHelper:Init(self._root, 20)

    ---@type UIPetDetailItem[]
    self._itemTable = {}
    self._scrollViewHelper =
        H3DScrollViewHelper:New(
        self,
        "PetScrollView",
        "UIPetDetailItem",
        function(index, uiwidget)
            return self:_OnShowItem(index, uiwidget)
        end,
        function(index, uiwidget)
            return self:_OnHideItem(index, uiwidget)
        end
    )

    local safesize = self._canvas.rect.size
    --safesize.x = safesize.x * (self._safeArea.anchorMax.x - self._safeArea.anchorMin.x)
    safesize.x = safesize.x + 1
    safesize.y = safesize.y + 1

    ---@type H3DScrollViewHelper
    self._scrollViewHelper:SetGroupChangedCallback(
        function(index, item)
            if index + 1 > self._listShowItemCount then
                return
            end
            self:ShowCurrIndexInfo(index + 1)
        end
    )

    self._scrollViewHelper:SetValueChangedCallback(
        function(group, value, contentSize, itemSize)
            self:OnValueChangedCallBack(group + 1, value, contentSize, itemSize)
        end
    )

    self._groupSizeX = safesize.x
    self._scrollViewHelper:Init(self._listShowItemCount, self._currIndex, safesize)

    --策划配置滑动灵敏度，大 --> 小（不灵敏 --> 灵敏）
    self._scrollViewHelper:SetNextPageOffset(0.06)

    self:CustomPetInfo()

    self:AttachEvents()

    self:CheckRedPoint()

    self:CheckSkinRedPoint()
    --[[

        self._guideLevelUpGO = self:GetGameObject("GuideLevelUp")
        self._guideLevelUpGO:SetActive(false)
        self._guideLevelUpRect = self:GetUIComponent("RectTransform", "GuideLevelUp")
        self._guideLevelUpCanvasGroup = self:GetUIComponent("CanvasGroup", "GuideLevelUp")
        self:CheckGuideLevelUp()
        ]]
    --检查功能解锁
    self:_RefreshFunctionLockStatus()

    self:PlayItemAnim(1)
    self:UnLock("UIOpenPetDetail")
end

function UISpiritDetailGroupController:InitWigets()
    self.equipRedGo = self:GetGameObject("equipRedPoint")
end

function UISpiritDetailGroupController:CustomPetInfo()
    local btnInfo = self:GetGameObject("BtnInfo")
    local customLevel = self:GetGameObject("CustomLevel")
    if self._customPetData then
        local rightAnchor = self:GetGameObject("RightAnchor")
        rightAnchor:SetActive(false)
        self._openBtns:SetActive(false)
        self._levelInfoGo:SetActive(false)
        self._mazeGrade:SetActive(false)
        customLevel:SetActive(true)
        local profImg = self:GetUIComponent("Image", "CustomProf")
        local prof = self._petInfos[self._currIndex]:GetProf()
        profImg.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[prof])
        local gradImg = self:GetUIComponent("Image", "CustomAwake")
        local pet = self._petInfos[self._currIndex]
        local petId = pet:GetTemplateID()
        local awaken = pet:GetPetGrade()
        gradImg.sprite = self._atlasAwake:GetSprite(UIPetModule.GetAwakeSpriteName(petId, awaken))
        btnInfo:SetActive(self._customPetData:IsShowBtnInfo())
        local btnInfoImageLoader = self:GetUIComponent("RawImageLoader", "BtnInfo")
        btnInfoImageLoader:LoadImage(self._customPetData:GetBtnInfoName())
    else
        customLevel:SetActive(false)
        btnInfo:SetActive(false)
    end
end

function UISpiritDetailGroupController:BtnInfoOnClick()
    if self._customPetData then
        local callback = self._customPetData:GetBtnInfoCallback()
        if callback then
            callback()
        end
    end
end

-- 优先判断觉醒 -->突破
function UISpiritDetailGroupController:GuideTrigger()
    local guideModule = self:GetModule(GuideModule)
    if guideModule:GuideInProgress() then
        return
    end
    local petInfo = self._petInfos and self._petInfos[self._currIndex]
    local petTempId = petInfo and petInfo:GetTemplateID()
    local grade = petInfo and petInfo:GetPetGrade()
    local triggerGrade = false
    if not petTempId then
        return
    end
    --觉醒
    if grade == 0 then
        local cfg = Cfg.cfg_pet_grade {PetID = petTempId, Grade = 1}[1]
        -- 等级大于需要等级  材料充足
        if petInfo:GetPetLevel() >= cfg.NeedLevel and self:HasGuideItems(cfg.NeedItem) then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.GuideGrade,
                function(trigger)
                    triggerGrade = trigger
                end
            )
        end
    end
    -- 突破
    if not triggerGrade then
        local cfg = Cfg.cfg_pet_awakening {PetID = petTempId, Awakening = 1}[1]
        if self:HasGuideItems(cfg.NeedItem) then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideAwake)
        end
    end
end

--检查突破红点
function UISpiritDetailGroupController:CheckRedPoint()
    local petId = self._petInfos[self._currIndex]:GetTemplateID()
    local petModule = GameGlobal.GetModule(PetModule)
    local pet = petModule:GetPetByTemplateId(petId)
    local isShow = pet:CanPetBreak()
    self._redPoint:SetActive(isShow)
end

-- 引导觉醒材料是否充足
function UISpiritDetailGroupController:HasGuideItems(needItems)
    local roleModule = self:GetModule(RoleModule)
    for _, value in ipairs(needItems) do
        local b = string.split(value, ",")
        local itemId = tonumber(b[1])
        local itemCount = tonumber(b[2])
        local ownItemCount = roleModule:GetAssetCount(itemId)
        if ownItemCount < itemCount then
            return false
        end
    end
    return true
end

function UISpiritDetailGroupController:_RefreshFunctionLockStatus()
    --角色 故事
    local s = self:GetUIComponent("UISelectObjectPath", "book")
    local bookButtonFunction = s:SpawnObject("UIFunctionLockButton")
    bookButtonFunction:SetFunctionType(GameModuleID.MD_PetStory, ButtonLockType.OnlyTips)
    --角色送礼物
    local s = self:GetUIComponent("UISelectObjectPath", "giftImg")
    local bookButtonFunction = s:SpawnObject("UIFunctionLockButton")
    bookButtonFunction:SetFunctionType(GameModuleID.MD_PetStory, ButtonLockType.OnlyTips)

    --角色送礼物
    local clothGo = self:GetGameObject("clothes")
    if clothGo then
        clothGo:SetActive(true)
        if EngineGameHelper.EnableAppleVerifyBulletin() then
            -- 审核服不显示按钮
            clothGo:SetActive(false)

        end
    end
    local s = self:GetUIComponent("UISelectObjectPath", "clothes")
    local clothesButtonFunction = s:SpawnObject("UIFunctionLockButton")
    clothesButtonFunction:SetFunctionType(GameModuleID.MD_PetStory, ButtonLockType.OnlyTips)
end
--测试滑动回调
function UISpiritDetailGroupController:OnValueChangedCallBack(group, value, contentSize, itemSize)
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

    a = 1.0 - a
    if a < 0 then
        a = 0
    elseif a > 1 then
        a = 1
    end

    local leftRightDis = math.abs(self._left.position.x - self._right.position.x)
    local centerPosition = self._center.position
    for i = self._currIndex - 1, self._currIndex + 1 do
        if self._itemTable[i] then
            --    self._itemTable[i]:ChangeCanvasGroupAlpha(a)
            self._itemTable[i]:ChangeCanvasGroupAlpha(leftRightDis, centerPosition.x)
        end
    end

    --[[
        old
        
        self._BtnsCanvasGroup.alpha = a
        local dis = distance * 200
        if dis > 0 then
            dis = dis * -1
        end
        self._Btns.anchoredPosition = Vector2(self._BtnsPos.x, self._BtnsPos.y + dis * 1.1)
        ]]
    --[[
        --test
        local currentIndexCenterPosX = self._itemTable[self._currIndex]:GetCenterPosX()
        local diff = currentIndexCenterPosX - self._center.position.x
        local alpha = diff*2
        ]]
    --滑动的UI上的效果
    local diff = distance * self._diffValue
    self._logoRect.anchoredPosition = Vector2(diff, self._logoRect.anchoredPosition.y)
    self._logoGroup.alpha = a
    self._infoRect.anchoredPosition = Vector2(diff, self._infoRect.anchoredPosition.y)
    self._infoGroup.alpha = a
    self._leftDownRect.anchoredPosition = Vector2(diff, self._leftDownRect.anchoredPosition.y)
    self._leftDownGroup.alpha = a
    self._rightAnchorRect.anchoredPosition = Vector2(diff, self._rightAnchorRect.anchoredPosition.y)
    self._rightAnchorGroup.alpha = a
    self._skillsRect.anchoredPosition = Vector2(diff * -0.5 + 278, self._skillsRect.anchoredPosition.y)

    self._breakGroup.alpha = a
    self._gradeGroup.alpha = a
end

function UISpiritDetailGroupController:SetMazeInfo()
    local pet = self._petInfos[self._currIndex]
    local petId = pet:GetTemplateID()
    local awaken = pet:GetPetGrade()
    self._mazeGradeImg.sprite = self._atlasAwake:GetSprite(UIPetModule.GetAwakeSpriteName(petId, awaken))

    local prof = pet:GetProf()
    self._mazeProfImg.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[prof])
end

------------------------------------------------------------改变下标刷新信息
function UISpiritDetailGroupController:ShowCurrIndexInfo(index)
    local temp_info = self._petInfos[index]
    if temp_info then
        local l_pet_info = "{ID:" .. temp_info:GetTemplateID() .. ", level:" .. temp_info:GetPetLevel() .. "}"
        GameGlobal.UAReportForceGuideEvent("UIPetViewShowPet", {l_pet_info}, true)
    end
    self._currIndex = index
    self._currIndexTemp = index
    -- 播音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoudPetDetail)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckIsCurrent, self._currIndexTemp)

    self:ShowEquipBtn()

    self:GuideTrigger()
    self:ShowElement()
    self:ShowLogoImg()
    self:ShowName()
    self:ShowStarLevel()
    self:_SetEquipLv()
    self:ShowFeatureTag()
    self:RefreshLevelInfo()
    self:RefreshAtt()
    self:ShowProf()
    self:SetMazeInfo()
    self:CheckRedPoint()
    self:ShowLimitTag()
    self:CheckSkinRedPoint()

    --检查当前星灵是动态还是静态
    self:ShowStaticAndDynamic()

    --亲密度
    self:RefreshIntimacyInfo()
    --左下金色技能
    self:RefreshPetSKill()

    --改变背景
    local imageLoader = self:GetUIComponent("RawImageLoader", "BgLoader")
    UICommonHelper:GetInstance():ChangePetTagBackground(self._petInfos[index]:GetTemplateID(), imageLoader, true)

    --第一次进来
    if self._firstIn == 0 then
        self._firstIn = 1
    end

    local tid = self._petInfos[self._currIndex]:GetTemplateID()
    if self._petModule:BeNewPet(tid) then
        self:StartTask(
            function(TT)
                local res = self._petModule:DelNewPetMark(TT, tid)
                if res:GetSucc() then
                --GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckCardNew)
                end
            end,
            self
        )
    end

    --[[
    local indexOffset = 2
    --加载cg
    if index - indexOffset > 0 then
        local pet = self._petModule:GetPet(self._petInfos[index - indexOffset])
        local cgLast = pet:GetPetStaticBody()
        self._rawImageLoaderHelper:LoadMat(cgLast, true)
    end
    if index + indexOffset <= table.count(self._petInfos) then
        local pet = self._petModule:GetPet(self._petInfos[index + indexOffset])
        local cgNext = pet:GetPetStaticBody()

        self._rawImageLoaderHelper:LoadMat(cgNext, true)
    end
    --加载spine
    if index - indexOffset > 0 then
        local pet = self._petModule:GetPet(self._petInfos[index - indexOffset])
        local spineLast = pet:GetPetSpine()

        self._spineLoaderHelper:LoadSpine(spineLast, true)
    end
    if index + indexOffset <= table.count(self._petInfos) then
        local pet = self._petModule:GetPet(self._petInfos[index + indexOffset])
        local spineNext = pet:GetPetSpine()

        self._spineLoaderHelper:LoadSpine(spineNext, true)
    end
    ]]
end

--开启装备
function UISpiritDetailGroupController:ShowEquipBtn()
    local grade = self._petInfos[self._currIndex]:GetPetGrade()
    self._equipUnLock = (grade > 0)
    -- self._equipUnLock = self._petInfos[self._currIndex]:OpenEquip()
    self._equipLockBtn:SetActive(not self._equipUnLock)
    if not self._equipUnLock then
        self._equipTex.color = Color(63 / 255, 60 / 255, 63 / 255)
        self.equipRedGo:SetActive(false)
    else
        self._equipTex.color = Color(1, 1, 1)
        self.equipRedGo:SetActive(UIPetEquipHelper.CheckRefineRed(self._petInfos[self._currIndex]))
    end
end

function UISpiritDetailGroupController:RefreshEquipRed()
    self.equipRedGo:SetActive(UIPetEquipHelper.CheckRefineRed(self._petInfos[self._currIndex]))
end

function UISpiritDetailGroupController:ShowMazeInfo()
    self._mazeInfoTipMask:SetActive(false)
    self._openBtns:SetActive(not self._fromMaze)
    self._IntimacyInfo:SetActive(not self._fromMaze)
    self._showMazeInfoTipMask:SetActive(self._fromMaze)
    self._mazeGrade:SetActive(self._fromMaze)
    self._levelInfoGo:SetActive(not self._fromMaze)
end

---------------------------------------------------检查当前星灵是动态还是静态
function UISpiritDetailGroupController:ShowStaticAndDynamic()
    self:ChangeStaticAndDynamicTween(self._cgStateTable[self._currIndex])
end

function UISpiritDetailGroupController:mazeInfoTipMaskOnClick()
    self._mazeInfoTips:SetActive(false)
    self._mazeInfoTipMask:SetActive(false)
end
function UISpiritDetailGroupController:showMazeInfoTipMaskOnClick()
    self._mazeInfoTips:SetActive(true)
    self._mazeInfoTipMask:SetActive(true)
end

function UISpiritDetailGroupController:GetUIComponents()
    self._equipLockBtn = self:GetGameObject("equipLockBtn")
    self._equipTex = self:GetUIComponent("Graphic", "equipTex")

    -- self._head = self:GetUIComponent("RawImageLoader", "head")

    self._infoTex = self:GetUIComponent("UILocalizationText", "infoTex")

    self._infoTexContent = self:GetUIComponent("RectTransform", "infoTexContent")

    self._stars = self:GetUIComponent("UISelectObjectPath", "stars")

    self.firstBg = self:GetGameObject("firstBg")
    self.secondBg = self:GetGameObject("secondBg")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self._firstElement = self:GetUIComponent("Image", "firstElement")
    ---@type UnityEngine.UI.Image
    self._secondElement = self:GetUIComponent("Image", "secondElement")
    self._elementTex = self:GetUIComponent("UILocalizationText", "elementTex")
    --名字
    self._nameText = self:GetUIComponent("UILocalizationText", "name")
    self._englishNameText = self:GetUIComponent("UILocalizationText", "EnglishName")

    --logo
    self._logoImg = self:GetUIComponent("RawImageLoader", "logoImg")

    --等级,经验
    self._leveExpSlider = self:GetUIComponent("Slider", "LeveExpSlider")
    self._levelText = self:GetUIComponent("UILocalizationText", "levelText")

    --攻击防御生命
    self._attackText = self:GetUIComponent("UILocalizationText", "attackText")
    self._defenceText = self:GetUIComponent("UILocalizationText", "defenceText")
    self._healthText = self:GetUIComponent("UILocalizationText", "healthText")

    --动态静态
    self._dynamicText = self:GetUIComponent("UILocalizationText", "dynamicText")
    self._staticText = self:GetUIComponent("UILocalizationText", "staticText")
    self._staticAndDynamicImg = self:GetUIComponent("RectTransform", "bar")
    self._dynamicRect = self:GetUIComponent("RectTransform", "dynamicRect")
    self._staticRect = self:GetUIComponent("RectTransform", "staticRect")

    --展开亲密度的按钮
    self._intimacyLevel = self:GetUIComponent("UILocalizationText", "intimacyLevel")
    self._IntimacyInfo = self:GetGameObject("Intimacy")

    --亲密度的slider
    self._intimateSlider = self:GetUIComponent("Slider", "IntimateSlider")

    --LeftAnchorPos
    self._LeftAnchorPos = self:GetUIComponent("RectTransform", "LeftAnchorPos")

    self._colorSkillImg = self:GetUIComponent("Image", "colorSkillImg")
    self._colorSkillImgBg = self:GetUIComponent("Image", "colorSkillImgBg")

    --三个金色技能
    self._goldSkill1 = self:GetGameObject("goldSkill1")
    self._goldSkill2 = self:GetGameObject("goldSkill2")
    self._goldSkill3 = self:GetGameObject("goldSkill3")
    self._goldSkill4 = self:GetGameObject("goldSkill4")

    --三个canvasGroup
    self._BtnsCanvasGroup = self:GetUIComponent("CanvasGroup", "Btns")

    self._Btns = self:GetUIComponent("RectTransform", "Btns")

    self._root = self:GetUIComponent("RectTransform", "spinePool")

    self._left = self:GetUIComponent("RectTransform", "leftPos")
    self._right = self:GetUIComponent("RectTransform", "rightPos")
    self._center = self:GetUIComponent("RectTransform", "centerPos")

    --skillopen
    self._skillOpen = self:GetGameObject("skillOpen")

    self._awakeCount = self:GetUIComponent("Image", "awakeCount")
    self._awakeCount2 = self:GetUIComponent("Image", "awakeCount2")

    --职业
    self._profTex = self:GetUIComponent("UILocalizationText", "profTex")
    self._profImg = self:GetUIComponent("Image", "profImg")

    --动画组件
    self._uiAnim = self:GetUIComponent("Animation", "uianim")

    --按钮群
    self._openBtns = self:GetGameObject("openBtns")

    self._showMazeInfoTipMask = self:GetGameObject("showMazeInfoTipMask")

    self._mazeGradeImg = self:GetUIComponent("Image", "mazeGradeImg")
    self._mazeProfImg = self:GetUIComponent("Image", "mazeProfImg")

    self._levelInfoGo = self:GetGameObject("Level")
    self._mazeGrade = self:GetGameObject("MazeGrade")

    self._mazeInfoTipMask = self:GetGameObject("mazeInfoTipMask")

    self._mazeInfoTips = self:GetGameObject("mazeTips")

    --滑动
    self._logoRect = self:GetUIComponent("RectTransform", "logoImg")
    self._infoRect = self:GetUIComponent("RectTransform", "info")
    self._leftDownRect = self:GetUIComponent("RectTransform", "LeftDown")
    self._rightAnchorRect = self:GetUIComponent("RectTransform", "RightAnchor")
    self._skillsRect = self:GetUIComponent("RectTransform", "skills")

    self._logoGroup = self:GetUIComponent("CanvasGroup", "logoImg")
    self._infoGroup = self:GetUIComponent("CanvasGroup", "info")
    self._leftDownGroup = self:GetUIComponent("CanvasGroup", "LeftDown")
    self._rightAnchorGroup = self:GetUIComponent("CanvasGroup", "RightAnchor")

    self._gradeGroup = self:GetUIComponent("CanvasGroup", "gradeGroup")
    self._breakGroup = self:GetUIComponent("CanvasGroup", "breakGroup")
    self._limitTag = self:GetUIComponent("RawImageLoader", "limitTag")
    self._limitTagGo = self:GetGameObject("limitTag")

    --皮肤红点
    self._clothRedPoint = self:GetGameObject("clothRedPoint")
end

function UISpiritDetailGroupController:PlayInOutAnimation(inAnim)
    if inAnim then
        if self._uiAnim then
            self._uiAnim:Play("uieff_SpiritDetail_Back")
        end
    else
        if self._uiAnim then
            self._uiAnim:Play("uieff_SpiritDetail_Goto")
        end
    end

    local state = 0
    if inAnim then
        state = 3
    else
        state = 2
    end
    self:PlayItemAnim(state)
end

function UISpiritDetailGroupController:OnUpdate(dms)
    if not self._alphaState or self._alphaState == 0 then
        return
    end
    if self._alphaState == 1 then
        self._alphaValue = self._alphaValue + 0.05
    elseif self._alphaState == 2 then
        self._alphaValue = self._alphaValue - 0.066
    elseif self._alphaState == 3 then
        self._alphaValue = self._alphaValue + 0.09
    end
    if self._alphaValue > 1 then
        self._alphaValue = 1
        self._alphaState = 0
        self._itemTable[self._currIndex]:OpenAndCloseOtherAlpha(true)
    end
    if self._alphaValue < 0 then
        self._alphaValue = 0
        self._alphaState = 0
    end
    self._itemTable[self._currIndex]:SetAnimAlpha(self._alphaValue)
end

--state 1,进入，2，退出，3，返回
function UISpiritDetailGroupController:PlayItemAnim(state)
    if state == 1 then
        self._itemTable[self._currIndex]:OpenAndCloseOtherAlpha(false)
        self._alphaState = state
        self._alphaValue = 0
    elseif state == 2 then
        --[[

            self._alphaState = state
            self._alphaValue = 0
            ]]
    elseif state == 3 then
    --[[

            if self._alphaEvent then
                GameGlobal.Timer():CancelEvent(self._alphaEvent)
            end
            self._alphaEvent =
            GameGlobal.Timer():AddEvent(
                230,
                function()
                    self._alphaState = state
                    self._alphaValue = 0
                end
                )
                ]]
    end
end

function UISpiritDetailGroupController:DisposeComponents()
    --名字
    self._nameText = nil
    self._englishNameText = nil

    --logo
    self._logoImg = nil
    --等级,经验
    self._leveExpSlider = nil
    self._levelText = nil

    --亲密度的slider
    self._intimateSlider = nil

    --攻击防御生命
    self._attackText = nil
    self._defenceText = nil
    self._healthText = nil

    --图集
    self._uiPetDeTailAtlas = nil
    self._uiPetElementAtlas = nil
    self._uiHeartItemAtlas = nil

    --动态静态
    self._dynamicText = nil
    self._staticText = nil

    --展开亲密度的按钮
    self._intimacyLevel = nil

    --LeftAnchorPos
    self._LeftAnchorPos = nil

    --三个金色技能
    self._goldSkill1 = nil
    self._goldSkill2 = nil
    self._goldSkill3 = nil
    self._goldSkill4 = nil
end
----------------------------------------------------------------------事件
function UISpiritDetailGroupController:AttachEvents()
    self:AttachEvent(GameEventType.OnPetListIndexChanged, self.OnPetListIndexChanged)

    self:AttachEvent(GameEventType.PlayInOutAnimation, self.PlayInOutAnimation)
    self:AttachEvent(GameEventType.PetDataChangeEvent, self.ObservationRefresh)
    self:AttachEvent(GameEventType.OnPetSkinChange, self.ObservationRefresh)
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:AttachEvent(GameEventType.WatchPetSkinStory, self.CheckSkinRedPoint)

end
function UISpiritDetailGroupController:RemoveEvents()
    self:DetachEvent(GameEventType.PetDataChangeEvent, self.ObservationRefresh)
    self:DetachEvent(GameEventType.PlayInOutAnimation, self.PlayInOutAnimation)
    self:DetachEvent(GameEventType.OnPetSkinChange, self.ObservationRefresh)

    self:DetachEvent(GameEventType.OnPetListIndexChanged, self.OnPetListIndexChanged)
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:DetachEvent(GameEventType.WatchPetSkinStory, self.CheckSkinRedPoint)

    if self._alphaEvent then
        GameGlobal.Timer():CancelEvent(self._alphaEvent)
    end
end

----------------------------------------------------------------------名字
function UISpiritDetailGroupController:ShowName()
    local name = self._petInfos[self._currIndex]:GetPetName()
    self._nameText:SetText(StringTable.Get(name))
    local nameEn = StringTable.Get(self._petInfos[self._currIndex]:GetPetEnglishName())
    self:CheckStringLen(nameEn)
end

----------------------------------------------获得英文长度来判断是否缩放text
function UISpiritDetailGroupController:CheckStringLen(nameEn)
    self._englishNameText:SetText("")
    local scale = GameObjectHelper.GetTextScale(self._englishNameText, nameEn, 437)
    self._englishNameText:GetComponent("Transform").localScale = Vector3(scale, 1, 1)
end

---------------------------------------------------------星星数量,升维,跃迁
function UISpiritDetailGroupController:ShowStarLevel()
    local petStar = self._petInfos[self._currIndex]:GetPetStar()
    local awakenStep = self._petInfos[self._currIndex]:GetPetAwakening()
    self._stars:SpawnObjects("UIPetIntimacyStar", petStar)
    local stars = self._stars:GetAllSpawnList()
    for i = 1, #stars do
        stars[i]:Refresh(i <= awakenStep)
    end

    for i = 1, 6 do
        local starImg = self:GetUIComponent("Image", "star" .. i)
        if i <= petStar then
            starImg.gameObject:SetActive(true)
            if i <= awakenStep then
                starImg.sprite = self._uiPetDeTailAtlas:GetSprite("spirit_xiangqing_icon22")
            else
                starImg.sprite = self._uiPetDeTailAtlas:GetSprite("spirit_xiangqing_icon21")
            end
        else
            starImg.gameObject:SetActive(false)
        end
    end

    --跃迁
    local pet = self._petInfos[self._currIndex]
    local petId = pet:GetTemplateID()
    local awaken = pet:GetPetGrade()
    local spriteName = UIPetModule.GetAwakeSpriteName(petId, awaken)
    self._awakeCount.sprite = self._atlasAwake:GetSprite(spriteName)
    self._awakeCount2.sprite = self._atlasAwake:GetSprite(spriteName)
end

function UISpiritDetailGroupController:_SetEquipLv()
    local obj = UIWidgetHelper.SpawnObject(self, "_equipLv", "UIPetEquipLvIcon")
    obj:SetData(self._petInfos[self._currIndex], true)

    local btnIcon = UIWidgetHelper.SpawnObject(self, "_equipLvBtnIcon", "UIPetEquipLvIcon")
    btnIcon:SetData(self._petInfos[self._currIndex], false)
end

------------------------------------------------------------------左上标签
function UISpiritDetailGroupController:ShowFeatureTag()
    local petTags = self._petInfos[self._currIndex]:GetPetTags()
    local realFeatureCount = table.count(petTags)
    local tagLine1 = self:GetGameObject("tagLine1")
    local tagLine2 = self:GetGameObject("tagLine2")
    tagLine1:SetActive(true)
    tagLine2:SetActive(true)
    if realFeatureCount == 1 then
        tagLine1:SetActive(false)
        tagLine2:SetActive(false)
    elseif realFeatureCount == 2 then
        tagLine2:SetActive(false)
    end
    for index = 1, self._maxCountElement do
        local _tagGo = self:GetGameObject("tagIcon" .. index)
        if index <= realFeatureCount then
            _tagGo:SetActive(true)
            local tagID = petTags[index]
            local cfg = Cfg.cfg_pet_tags[tagID]
            if cfg ~= nil then
                local _tagText = self:GetUIComponent("UILocalizationText", "Text" .. index)

                _tagText:SetText(StringTable.Get(cfg.Name))
            end
        else
            _tagGo:SetActive(false)
        end
    end
end

---------------------------------------------------------------------职业
function UISpiritDetailGroupController:ShowProf()
    local prof = self._petInfos[self._currIndex]:GetProf()
    self._profTex:SetText(StringTable.Get(self._prof2Tex[prof]))
    self._profImg.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[prof])
end

----------------------------------------------------------------等级和经验
function UISpiritDetailGroupController:RefreshLevelInfo()
    local curGrateMaxLevel = self._petInfos[self._currIndex]:GetMaxLevel()
    local curLevel = self._petInfos[self._currIndex]:GetPetLevel()

    self._levelText:SetText(
        curLevel .. "<size=45><color=#acacac>/</color><color=#f96601>" .. curGrateMaxLevel .. "</color></size>"
    )

    self._infoTexContent.anchoredPosition = Vector2(self._infoTexContent.anchoredPosition.x, 0)

    local cfg_pet = Cfg.cfg_pet[self._petInfos[self._currIndex]:GetTemplateID()]
    if cfg_pet then
        self._infoTex:SetText(StringTable.Get(cfg_pet.Desc))
    else
        Log.fatal("###pet_detail -- cfg_pet is nil ! id -- " .. self._petInfos[self._currIndex]:GetTemplateID())
    end

    local itemIcon = self._petInfos[self._currIndex]:GetPetItemIcon(PetSkinEffectPath.ITEM_ICON_PET_DETAIL)
    self.uiItem:SetData({icon = itemIcon, itemId = self._petInfos[self._currIndex]:GetTemplateID()})

    --经验条分开
    self:ExpSlider(curGrateMaxLevel, curLevel)
end

----------------------------------------------------------------等级和经验
function UISpiritDetailGroupController:ExpSlider(curGrateMaxLevel, curLevel)
    local rate = 0

    if curLevel >= curGrateMaxLevel then
        --self._leveExpSlider.value = 1
        rate = 1
    else
        local curLevelExp = self._petInfos[self._currIndex]:GetPetExp()
        local upLevelAllExp = self._petInfos[self._currIndex]:GetLevelUpNeedExp()
        rate = curLevelExp / upLevelAllExp
    end
    if self._firstIn == 0 then
        self._leveExpSlider.value = rate
    else
        --[[
                old
                if self._currentTaskID ~= -1 then
                    self._expStop = true
                end
                self._currentTaskID = GameGlobal.TaskManager():StartTask(self.OnExpSlider, self, rate)
                ]]
        if self._expTweener then
            self._expTweener:Kill()
        end
        self._expTweener =
            self._leveExpSlider:DOValue(0, 0.2):OnComplete(
            function()
                self._expTweener = self._leveExpSlider:DOValue(rate, 0.2)
            end
        )
    end
end

--旧的经验动画
--[[
    function UISpiritDetailGroupController:OnExpSlider(TT, rate)
        YIELD(TT)
        
        while self._leveExpSlider.value > 0 do
            if self._expStop then
                self._expStop = false
                return
            end
            self._leveExpSlider.value = self._leveExpSlider.value - 0.1
            YIELD(TT)
        end
        
        if self._expStop then
            self._expStop = false
            return
        end
        YIELD(TT)
        while self._leveExpSlider.value < rate do
            if self._expStop then
                self._expStop = false
                return
            end
            self._leveExpSlider.value = self._leveExpSlider.value + 0.1
            YIELD(TT)
        end
        self._currentTaskID = -1
    end
    ]]
----------------------------------------------------------------亲密度的值

function UISpiritDetailGroupController:_RefreshIntimacyExpBar()
    local petData = self._petInfos[self._currIndex]
    local level = petData:GetPetAffinityLevel()
    local maxLevel = petData:GetPetAffinityMaxLevel()
    local curExp = petData:GetPetAffinityExp() - Cfg.cfg_pet_affinity_exp[level].NeedAffintyExp
    local maxExp = petData:GetPetAffinityMaxExp(level)
    local percent = curExp / maxExp
    if level >= maxLevel then
        percent = 1
    end
    self._intimateSlider.value = percent
end

function UISpiritDetailGroupController:RefreshIntimacyInfo()
    local petData = self._petInfos[self._currIndex]
    local level = petData:GetPetAffinityLevel()
    local maxLevel = petData:GetPetAffinityMaxLevel()
    local cfg = Cfg.cfg_pet_affinity_exp[level]
    if not cfg then
        Log.fatal("### cfg_pet_affinity_exp not exist level:", level)
        return
    end
    local curExp = petData:GetPetAffinityExp() - cfg.NeedAffintyExp
    local maxExp = petData:GetPetAffinityMaxExp(level)
    local percent = curExp / maxExp
    if level >= maxLevel then
        percent = 1
    end
    self._intimacyLevel:SetText(level)
    self:ChangeIntiValueAnimation(percent)
end
--改变亲密度的动画
function UISpiritDetailGroupController:ChangeIntiValueAnimation(value)
    if self._intimacyTweener then
        self._intimacyTweener:Kill()
    end

    self._intimacyTweener = self._intimateSlider:DOValue(value, 0.2)
end

--------------------------------------------------------------攻击防御生命
function UISpiritDetailGroupController:RefreshAtt()
    local _attackValue
    local _defenceValue
    local _healthValue

    if self._customPetData then
        -- _attackValue = self._customPetData:GetAttacke()
        -- _defenceValue = self._customPetData:GetDef()
        -- _healthValue = self._customPetData:GetHP()
        _attackValue = self._petInfos[self._currIndex]:GetPetAttack()
        _defenceValue = self._petInfos[self._currIndex]:GetPetDefence()
        _healthValue = self._petInfos[self._currIndex]:GetPetHealth()
    else
        if self._fromMaze then
            _attackValue, _defenceValue, _healthValue =
                self._mazeModule:GetCalPetADH(self._petInfos[self._currIndex]:GetPstID())
        else
            _attackValue = self._petInfos[self._currIndex]:GetPetAttack()
            _defenceValue = self._petInfos[self._currIndex]:GetPetDefence()
            _healthValue = self._petInfos[self._currIndex]:GetPetHealth()
        end
    end

    self._attackText:SetText(_attackValue)
    self._defenceText:SetText(_defenceValue)
    self._healthText:SetText(_healthValue)
end

----------------------------------------------------------技能面板打开关闭
function UISpiritDetailGroupController:SkillBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"jineng"}, true)
    self:ShowDialog(
        "UIPetSkillDetailController",
        self._petInfos[self._currIndex],
        self._LeftAnchorPos.anchoredPosition.x,
        function()
            self._skillOpen:SetActive(false)
        end
    )
    self._skillOpen:SetActive(true)
end

function UISpiritDetailGroupController:ShowLogoImg()
    self._logoImg:LoadImage(self._petInfos[self._currIndex]:GetPetLogo())
end

------------------------------------------------------------主元素和副元素和logo
function UISpiritDetailGroupController:ShowElement()
    local cfg_pet_element = Cfg.cfg_pet_element {}

    local elementTex = ""

    if cfg_pet_element then
        local f = self._petInfos[self._currIndex]:GetPetFirstElement()
        local s = self._petInfos[self._currIndex]:GetPetSecondElement()
        self._firstElement.sprite =
            self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[f].Icon))
        if s and s > 0 then
            self.secondBg:SetActive(true)
            self._secondElement.gameObject:SetActive(true)
            self._secondElement.sprite =
                self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[s].Icon)
            )
            elementTex =
                StringTable.Get("str_pet_detail_element_" .. f) ..
                "  " .. StringTable.Get("str_pet_detail_element_" .. s)
        else
            elementTex = StringTable.Get(self._elem2str[f])
            self._secondElement.gameObject:SetActive(false)
            self.secondBg:SetActive(false)
        end
    end
    self._elementTex:SetText(elementTex)
end

-------------------------------------------------------左下金色技能的spawn
---@private
---@param scrollView UIDynamicScrollView
---@param index number
---return UIDynamicScrollViewItem
function UISpiritDetailGroupController:RefreshPetSKill()
    local _creatCount = 0
    ---@type UIPetModule
    local uiModule = self._petModule.uiModule
    self._skillDetailInfos = uiModule:GetSkillDetailInfoBySkillTypeHideExtra(self._petInfos[self._currIndex])

    _creatCount = table.count(self._skillDetailInfos)

    local tempTab = {}

    if _creatCount == 0 then
        self._goldSkill1:SetActive(false)
        self._goldSkill2:SetActive(false)
        self._goldSkill3:SetActive(false)
        self._goldSkill4:SetActive(false)
        return
    elseif _creatCount == 1 then
        table.insert(tempTab, self._goldSkill1)
        self._goldSkill1:SetActive(true)
        self._goldSkill2:SetActive(false)
        self._goldSkill3:SetActive(false)
        self._goldSkill4:SetActive(false)
    elseif _creatCount == 2 then
        table.insert(tempTab, self._goldSkill1)
        table.insert(tempTab, self._goldSkill2)
        self._goldSkill1:SetActive(true)
        self._goldSkill2:SetActive(true)
        self._goldSkill3:SetActive(false)
        self._goldSkill4:SetActive(false)
    elseif _creatCount == 3 then
        table.insert(tempTab, self._goldSkill1)
        table.insert(tempTab, self._goldSkill2)
        table.insert(tempTab, self._goldSkill3)
        self._goldSkill1:SetActive(true)
        self._goldSkill2:SetActive(true)
        self._goldSkill3:SetActive(true)
        self._goldSkill4:SetActive(false)
    elseif _creatCount == 4 then
        table.insert(tempTab, self._goldSkill1)
        table.insert(tempTab, self._goldSkill2)
        table.insert(tempTab, self._goldSkill3)
        table.insert(tempTab, self._goldSkill4)
        self._goldSkill1:SetActive(true)
        self._goldSkill2:SetActive(true)
        self._goldSkill3:SetActive(true)
        self._goldSkill4:SetActive(true)
    end

    self._colorSkillImg.color = self._colorWithElement[self._petInfos[self._currIndex]:GetPetFirstElement()]
    self._colorSkillImgBg.sprite =
        self._uiPetDeTailAtlas:GetSprite(self._spriteWithElement[self._petInfos[self._currIndex]:GetPetFirstElement()])
    for index = 1, _creatCount do
        local skillItem = tempTab[index]
        local cfg_skill = BattleSkillCfg(self._skillDetailInfos[index].skillList[1])
        if cfg_skill then
            local skillTypeStr = ""
            ---@type PetSkillType
            if cfg_skill.Type == PetSkillType.SkillType_ChainSkill then
                skillTypeStr = "str_pet_detail_left_down_skill_chain"
            elseif cfg_skill.Type == PetSkillType.SkillType_Active then
                skillTypeStr = "str_pet_detail_left_down_skill_active"
            elseif cfg_skill.Type == PetSkillType.SkillType_Passive then
                skillTypeStr = "str_pet_detail_left_down_skill_equip"
            end
            local skillName = skillItem:GetComponent("Transform"):GetChild(1):GetComponent("UILocalizationText")
            local skillIcon = skillItem:GetComponent("Transform"):GetChild(0):GetComponent("RawImageLoader")

            skillName:SetText(StringTable.Get(skillTypeStr))
            skillIcon:LoadImage(cfg_skill.Icon)
        end
    end
end

------------------------------------------------------------衣服和书的btn
function UISpiritDetailGroupController:clothesBtnOnClick(go)
    --ToastManager.ShowToast(StringTable.Get("str_pet_config_function_no_open"))
    local petid = self._petInfos[self._currIndex]:GetTemplateID()
    local pstid = self._petInfos[self._currIndex]:GetPstID()
    self:ShowDialog("UIPetSkinsMainController", PetSkinUiOpenType.PSUOT_SHOW_LIST, petid, pstid)
end
function UISpiritDetailGroupController:bookBtnOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"dangan"}, true)
    local petid = self._petInfos[self._currIndex]:GetTemplateID()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, false)
    self:ShowDialog("UIPetIntimacyMainController", petid, PetIntimacyWindowType.FilesPanel)
end

--心心
--------------------------------------------------------------亲密度按钮
function UISpiritDetailGroupController:IntimacyBtnOnClick() --心
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"haogandu"}, true)
    local petid = self._petInfos[self._currIndex]:GetTemplateID()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, false)
    self:ShowDialog("UIPetIntimacyMainController", petid, PetIntimacyWindowType.GiftPanel)
end

-------------------------------------------------------------切换动态静态
function UISpiritDetailGroupController:staticAndDynamicOnClick()
    if self._cgStateTable[self._currIndex] == DynamicAndStaticState.Static then
        GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"dynamic"}, true)
        self._cgStateTable[self._currIndex] = DynamicAndStaticState.Dynamic
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlideDynamic)
    else
        GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"static"}, true)
        self._cgStateTable[self._currIndex] = DynamicAndStaticState.Static
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlide)
    end
    self:ChangeStaticAndDynamicTween(self._cgStateTable[self._currIndex])
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.PetDetailChangeCgState,
        self._currIndex,
        self._cgStateTable[self._currIndex]
    )
    --播放切换音效
    --AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlide)
end

function UISpiritDetailGroupController:ChangeStaticAndDynamicTween(state)
    if self._dsTween then
        self._dsTween:Kill()
    end
    if state == DynamicAndStaticState.Dynamic then
        local pos = self._dynamicRect.anchoredPosition
        self._dsTween = self._staticAndDynamicImg:DOAnchorPos(pos, 0.3):SetEase(DG.Tweening.Ease.InOutCubic)

        self._dynamicText.color = Color.black
        self._staticText.color = Color(99 / 255, 99 / 255, 99 / 255, 1)
    else
        local pos = self._staticRect.anchoredPosition
        self._dsTween = self._staticAndDynamicImg:DOAnchorPos(pos, 0.3):SetEase(DG.Tweening.Ease.InOutCubic)

        self._staticText.color = Color.black
        self._dynamicText.color = Color(99 / 255, 99 / 255, 99 / 255, 1)
    end
end
--------------------------------------------------------------------升级
function UISpiritDetailGroupController:UPLevelBtnOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"shengji"}, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, false)
    self:ShowDialog("UIUpLevelInterfaceController", self._petInfos[self._currIndex]:GetTemplateID())
end

function UISpiritDetailGroupController:awakenBtnOnClick(go) --升维,判断满
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"juexing"}, true)
    local grade = self._petInfos[self._currIndex]:GetPetGrade()
    local maxGrade = self._petInfos[self._currIndex]:GetMaxGrade()
    if grade >= maxGrade then
        ToastManager.ShowToast(StringTable.Get("str_pet_config_reach_grade_max"))
        return
    end
    local starLevel = self._petInfos[self._currIndex]:GetPetStar()
    local openAwakenCfg = Cfg.cfg_global["pet_open_grade"]
    if starLevel <= openAwakenCfg.IntValue then
        ToastManager.ShowToast(StringTable.Get("str_pet_config_reach_grade_max"))
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, false)

    local aps = GameGlobal.GetModule(SerialAutoFightModule):GetApsData()
    aps:SetTrack(true)

    self:ShowDialog("UIGradeInterfaceController", self._petInfos[self._currIndex]:GetTemplateID())
end
function UISpiritDetailGroupController:gradeBtnOnClick(go) --跃迁
    -- 播音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundPetBreak)
    --判断是否可跃迁
    local star = self._petInfos[self._currIndex]:GetPetStar()
    local cfgStar = Cfg.cfg_global["pet_open_awaken"]
    if star <= cfgStar.IntValue then
        ToastManager.ShowToast(StringTable.Get("str_pet_config_reach_awake_max"))
        return
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PlayInOutAnimation, false)
    self:ShowDialog("UIBreakController", self._petInfos[self._currIndex]:GetTemplateID())
end
function UISpiritDetailGroupController:equipBtnOnClick(go) --装备
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"zhuangbei"}, true)
    if self._equipUnLock then
        self:ShowDialog("UIPetEquipController", self._petInfos[self._currIndex])
    end
end
function UISpiritDetailGroupController:equipLockBtnOnClick()
    ToastManager.ShowToast(StringTable.Get("str_pet_equip_func_unlock"))
end

--查看立绘
function UISpiritDetailGroupController:OpenBtnsOnClick()
    GameGlobal.UAReportForceGuideEvent("UIPetDetailClick", {"lihui"}, true)
    local petData = self._petInfos[self._currIndex]
    self:ShowDialog("UISpiritDetailLookCgAndSpineController", petData, self._cgStateTable[self._currIndex])
end

---@param uiwidget UIPetDetailItem
function UISpiritDetailGroupController:_OnShowItem(index, uiwidget)
    -- if self._itemTable[index] == nil then
    -- end
    self._itemTable[index] = uiwidget

    --拿到当下这个cg
    local petData = self._petInfos[index]
    local matCgName = petData:GetPetStaticBody(PetSkinEffectPath.BODY_PET_DETAIL)
    local spineName = petData:GetPetSpine(PetSkinEffectPath.BODY_PET_DETAIL)

    --local currCgMat = self._rawImageLoaderHelper:GetMat(matCgName)

    --local currSpine = self._spineLoaderHelper:GetSpine(spineName)

    --[[
        local currSpineObj = nil
        if currSpine then
            currSpineObj = currSpine.Obj
        end
        ]]
    --uiwidget:SetData(index, self._cgStateTable[index], currCgMat, currSpineObj, matCgName, spineName, self._root)

    uiwidget:SetData(index, petData, self._cgStateTable[index], matCgName, spineName, self._root, self._currIndexTemp)
end
function UISpiritDetailGroupController:_OnHideItem(index, uiwidget)
    if self._itemTable[index] == nil then
        return
    end

    uiwidget:OnHideCallBack()
end

function UISpiritDetailGroupController:OnHide()
    self:DisposeComponents()

    self:RemoveEvents()

    self._petModule.uiModule:SetTeamPets(nil)

    self._showBtnTweener = nil
    self._showMoodTweener = nil
    self._backBtns = nil

    self._cgStateTable = nil
    self._petInfos = nil
    self._petModule = nil
    self._listShowItemCount = 0
    self._openDetailIndex = 1

    self._firstIn = 0
    self._expTweener = nil
    self._intimacyTweener = nil

    self._scrollViewHelper:Dispose()

    self._rawImageLoaderHelper:Dispose()

    self._spineLoaderHelper:Dispose()
end

------------------------------------------------------------获取星灵信息
function UISpiritDetailGroupController:RequestAllPetInfos()
    --self._petModule.uiModule:ReleaseConditionLData()
    --[[
        --old
        self._petModule.uiModule:ResetSortInfos()
        self._petInfos = self._petModule.uiModule:RequestPetDatas()
        ]]
    self._petInfos = self._petModule.uiModule:GetSortedPets()

    --old
    --self._petInfos = self._petModule.uiModule:RequestPetDatasAndReturnPets()

    if self._petInfos ~= nil then
        self._listShowItemCount = table.count(self._petInfos)
        self._cgStateTable = {}
        for i = 1, self._listShowItemCount do
            self._cgStateTable[i] = DynamicAndStaticState.Dynamic
        end
    end

    self._diffValue = self._listShowItemCount * -300
end

-----------------------------------------------------进来时打开哪一个星灵
function UISpiritDetailGroupController:FindOpenPetIndex(petid)
    if self._petInfos then
        for index = 1, #self._petInfos do
            if self._petInfos[index]:GetTemplateID() == petid then
                return index
            end
        end
    end
    return 0
end

function UISpiritDetailGroupController:FindOpenPetIndexByPetTempId(petTempIdtId)
    if self._petInfos then
        for index = 1, #self._petInfos do
            if self._petInfos[index]:GetTemplateID() == petTempIdtId then
                return index
            end
        end
    end
    return 0
end
function UISpiritDetailGroupController:ObservationRefresh()
    --if self._scrollViewHelper then
    --  self._scrollViewHelper:RefreshAllShownItem()

    self:ShowCurrIndexInfo(self._currIndex)
    self:_RefreshCurPetSkinAppearance(self._currIndex)
    --end
end
---
function UISpiritDetailGroupController:_RefreshCurPetSkinAppearance(index)
    local uiwidget = self._itemTable[index]
    --拿到当下这个cg
    local petData = self._petInfos[index]
    if not uiwidget or not petData then
        return
    end
    local matCgName = petData:GetPetStaticBody(PetSkinEffectPath.BODY_PET_DETAIL)
    local spineName = petData:GetPetSpine(PetSkinEffectPath.BODY_PET_DETAIL)
    uiwidget:RefreshSkinAppearance(matCgName, spineName)
end

function UISpiritDetailGroupController:OnPetListIndexChanged(petid)
    local idx = self:FindOpenPetIndex(petid)
    self._currIndex = idx
    self._currIndexTemp = idx
    local sizex = self._groupSizeX*(idx-1)*-1
    self:GetUIComponent("RectTransform","Content").anchoredPosition = Vector2(sizex,0)
    self._scrollViewHelper:MovePanelToIndex(idx)
end

function UISpiritDetailGroupController:ShowLimitTag()
    local petId = self._petInfos[self._currIndex]:GetTemplateID()
    local cfg = Cfg.cfg_pet_limit_tag[petId]
    if cfg then
        self._limitTagGo:SetActive(true)
        self._limitTag:LoadImage(cfg.Res)
        local rect = self:GetUIComponent("RectTransform", "limitTag")
        rect.sizeDelta = Vector2(cfg.Size[1], cfg.Size[2])
    else
        self._limitTagGo:SetActive(false)
    end
end

function UISpiritDetailGroupController:OnItemCountChange()
    --检查突破红点
    self:CheckRedPoint()
end

function UISpiritDetailGroupController:GetCurrentPetInfos()
    return self._petInfos[self._currIndex]
end

--检查皮肤红点
function UISpiritDetailGroupController:CheckSkinRedPoint()
    local petId = self._petInfos[self._currIndex]:GetTemplateID()
    local petModule = GameGlobal.GetModule(PetModule)
    local pet = petModule:GetPetByTemplateId(petId)
    local isShow = pet:IsShowSkinRedPoint()
    self._clothRedPoint:SetActive(isShow)
end

--[[


---------------------------新手引导↓ 弱引导----------------------------------
function UISpiritDetailGroupController:CheckGuideLevelUp()
    local curGrateMaxLevel = self._petInfos[self._currIndex]:GetMaxLevel()
    local curLevel = self._petInfos[self._currIndex]:GetPetLevel()
    local minLevel = Cfg.cfg_guide_const["guide_train_level_min"].IntValue
    --等级
    if curLevel > minLevel and curLevel < curGrateMaxLevel then
    else
        self._guideLevelUpGO:SetActive(false)
        return
    end
    -- 关卡
    local missionModule = self:GetModule(MissionModule)
    local needMissionId = Cfg.cfg_guide_const["guide_train_level_mission"].IntValue
    if not missionModule:IsPassMissionID(needMissionId) then
        self._guideLevelUpGO:SetActive(false)
        return
    end
    -- 物品数量
    ---@type RoleModule
    local roleModule = self:GetModule(RoleModule)
    local targetItemIds = {}
    local ok = false
    for index, itemId in ipairs(targetItemIds) do
        if roleModule:GetAssetCount(itemId) > 0 then
            ok = true
            break
        end
    end
    if not ok then
        self._guideLevelUpGO:SetActive(false)
        return
    end
    self._guideLevelUpGO:SetActive(true)
    local duration = 0.5
    self._guideLevelUpCanvasGroup.alpha = 0.7
    self._guideLevelUpRect.anchoredPosition = Vector2(-400, -129)

    self._guideLevelUpCanvasGroup:DOFade(1.0, duration)
    self._guideLevelUpRect:DOAnchorPosX(0, duration):OnComplete(
        function()
            self:StartTask(
                function(TT)
                    YIELD(TT, 5000)
                    self._guideLevelUpCanvasGroup:DOFade(0, duration)
                    self._guideLevelUpRect:DOAnchorPosX(400, duration):OnComplete(
                        function()
                            self._guideLevelUpGO:SetActive(false)
                        end
                    )
                end,
                self
            )
        end
    )
end
]]
