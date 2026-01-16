---@class UISetController:UIController
_class("UISetController", UIController)
UISetController = UISetController

function UISetController:OnShow(uiParams)
    self:AttachEvent(GameEventType.ColorBlindUpdate, self.FlushColorBlind)
    self:AttachEvent(GameEventType.ChangeBindBtnStatus, self.RefreshButtonStatus)
    self:AttachEvent(GameEventType.UIBlackChange, self.InitResolutionBangWidth)
    self:AttachEvent(GameEventType.ActiveUILoginLIRoot, self.ActiveUILoginLIRoot)
    
    self._initiating = true
    self.uiCanvasRect = self:GetUIComponent("RectTransform", "UICanvas")

    self.localDBKey = GameGlobal.GetModule(RoleModule):SkillAnimationLocalDBKey()
    self.bgmGlobal = Cfg.cfg_global["bgm_volume"].FloatValue
    self.voiceGlobal = Cfg.cfg_global["voice_volume"].FloatValue
    self.soundGlobal = Cfg.cfg_global["sound_volume"].FloatValue

    self._antiTexGo = self:GetGameObject("antiTex")
    self._antiValueGo = self:GetGameObject("System_Antialiasing")

    self._autoFightGo = self:GetGameObject("System_AutoFight")

    self.systemWindow = self:GetGameObject("SystemWindow")
    self.systemWindowScrollGo = self:GetGameObject("SystemWindowScroll")
    self.volumeWindow = self:GetGameObject("VolumeWindow")
    self.userWindow = self:GetGameObject("userWindow")
    self.btnSystem = self:GetUIComponent("Toggle", "btnSystem")
    self.btnVoice = self:GetUIComponent("Toggle", "btnVoice")
    self.btnUser = self:GetUIComponent("Toggle", "btnUser")
    self.btnChangePasswd = self:GetGameObject("btnChangePasswd")
    self.btnBind = self:GetGameObject("btnBind")

    self.UserCenterText = self:GetUIComponent("UILocalizationText","UserCenterText")

    self._langFromAnchor = self:GetUIComponent("Transform", "LanguageFromAnchor")
    self._langTargetAnchor = self:GetUIComponent("Transform", "LanguageTargetAnchor")
    self._langWindowAnchor = self:GetUIComponent("Transform", "LanguageWindowAnchor")
    self._langItems = self:GetUIComponent("UISelectObjectPath", "LanguageItems")
    self._langBtnImage = self:GetUIComponent("Image", "LanguageBtnImage")
    self._langWindow = self:GetGameObject("lan_window")
    self._langImage = self:GetUIComponent("Image", "CurLang")
    self._layoutRect = self:GetUIComponent("RectTransform", "SafeArea")
    self._langTitle = self:GetGameObject("LanguageTitle")
    self._langRoot = self:GetGameObject("LanguageRoot")
    self._langOptGo = self:GetGameObject("LanguageTargetAnchor")
    self._langSystem = self:GetGameObject("System_Language")

    self._mobileGraphicsChooseTips = self:GetGameObject("MobileGraphicsChooseTips")
    self._specialShapedScreenTabText = self:GetGameObject("SpecialShapedScreenTabText")
    self._systemScreenObj = self:GetGameObject("System_Screen")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UISetting.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self.imgColorBlind = self:GetUIComponent("Image", "imgColorBlind")
    ---@type UILocalizationText
    self.txtColorBlind = self:GetUIComponent("UILocalizationText", "txtColorBlind")

    ---@type UICommonTopButton
    self.commonTopRoot = self:GetUIComponent("UISelectObjectPath", "LeftTopAnchor")
    self.backBtns = self.commonTopRoot:SpawnObject("UICommonTopButton")
    self.backBtns:SetData(
        function()
            self:CloseDialog()
        end
    )
    local content = self:GetGameObject("UserWindowContent")
    self._userWindowContent = content.transform
    self._item = self:GetGameObject("Item")

    self.btnSystemTabButtonValueChange = function(isOn)
        if not self._initiating then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        end
        self.systemWindow:SetActive(isOn)
        self.systemWindowScrollGo:SetActive(isOn)
        self._langRoot:SetActive(isOn)
        self._langOptGo:SetActive(isOn)
    end
    self.btnVoiceTabButtonValueChange = function(isOn)
        if not self._initiating then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        end
        self.volumeWindow:SetActive(isOn)
        self._langRoot:SetActive(not isOn)
        self._langOptGo:SetActive(not isOn)
    end
    self.btnUsermTabButtonValueChange = function(isOn)
        if not self._initiating then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        end
        self.userWindow:SetActive(isOn)
        self._langRoot:SetActive(not isOn)
        self._langOptGo:SetActive(not isOn)
    end
    self.btnSystem.onValueChanged:AddListener(self.btnSystemTabButtonValueChange)
    self.btnVoice.onValueChanged:AddListener(self.btnVoiceTabButtonValueChange)
    self.btnUser.onValueChanged:AddListener(self.btnUsermTabButtonValueChange)

    self._initSettingValue = {
        bgmVolume = 100,
        soundVolume = 100,
        voiceVolume = 100,
        bgmMute = false,
        soundMute = false,
        voiceMute = false,
        GraphicsLevel = 3,
        skillAnmiIndex = 1,
        AntiIndex = 1,
        HighFrameIndex = 1,
        BangWidth = 0,
        danSwitch = true,
        AutoFightIndex = 1
    }

    self:InitToggleGraphicsAndSkillAnimation()
    self:InitToggleShowDan() --1305 世界boss头像徽章
    self:InitResolutionBangWidth()
    self:InitVolumeWindow()
    self:SetPcSliderStatus()

    self.btnSystemTabButtonValueChange(true)
    self.btnVoiceTabButtonValueChange(false)
    self.btnUsermTabButtonValueChange(false)

    self:InitButtonOnPressEffect()
    self:SetLodSetting()
    self:SetHighFrame()
    self:SetAutoFightLinkline()
    self._initiating = false

    if SDKProxy:GetInstance():IsInternationalSDK() == true then
        UIHelper.SetActive(self:GetGameObject("nameGo"), false)
        UIHelper.SetActive(self:GetGameObject("btnTexUrl3"), false)
    else
        UIHelper.SetActive(self:GetGameObject("btnTexUrl4"), false)
    end
    self._hasRequestBtnStatus = false --是否进入页面时请求过绑定数据
    self:RefreshButtonStatus()
    self:RefreshUserWindow()
    self._enterSettingValue = {} --玩家进入游戏时的设置
    for key, value in pairs(self._initSettingValue) do
        self._enterSettingValue[key] = value
    end

    self:FlushColorBlind()
    self:RefreshLanguage()
end

--设置高帧率
function UISetController:SetHighFrame()
    local count = 2
    local toggleGroupHighFrame = self:GetUIComponent("ToggleGroup", "GroupHighFrame")
    local groupHighFrameLoader = self:GetUIComponent("UISelectObjectPath", "GroupHighFrame")
    groupHighFrameLoader:SpawnObjects("UISetControllerSelectTabBtn", count)
    ---@type UISetControllerSelectTabBtn[]
    self._allHighFrameToggle = groupHighFrameLoader:GetAllSpawnList()
    for i, v in ipairs(self._allHighFrameToggle) do
        if i <= count then
            v:Init(i, "str_set_skill_animation_setting_", toggleGroupHighFrame, self.OnClickHighFrameBtn, self)
        end
    end
    local highFrameStatus = GameGlobal.GetHighFrameStatus()
    if highFrameStatus then
        self._indexHighFrame = 1
    else
        self._indexHighFrame = 2
    end
    self:OnClickHighFrameBtn(self._indexHighFrame)
end

function UISetController:OnClickHighFrameBtn(index)
    if not self._initiating then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    end

    if self._initiating then
        self:SetHighFrameStatus(index)
    else
        if self._indexHighFrame ~= index then
            if index == 1 then
                local tmpIndex = index
                index = self._indexHighFrame
                if self:ShowHighFrameTps() then
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        StringTable.Get("str_set_highframe_setting_title"),
                        StringTable.Get("str_set_highframe_setting_tips1")
                    )
                else
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.OkCancel,
                        StringTable.Get("str_set_highframe_setting_title"),
                        StringTable.Get("str_set_highframe_setting_tips"),
                        function(param)
                            self:SetHighFrameStatus(tmpIndex)
                        end
                    )
                end
            end
        end
    end

    self:SetHighFrameStatus(index)
end

function UISetController:SetHighFrameStatus(index)
    if index == 1 then
        GameGlobal.SetHighFrameStatus(true)
    else
        GameGlobal.SetHighFrameStatus(false)
    end

    if self._indexHighFrame then
        if self._allHighFrameToggle[self._indexHighFrame] then
            self._allHighFrameToggle[self._indexHighFrame]:Select(false)
        end
    end
    self._indexHighFrame = index
    if self._indexHighFrame then
        if self._allHighFrameToggle[self._indexHighFrame] then
            self._allHighFrameToggle[self._indexHighFrame]:Select(true)
        end
    end

    self._initSettingValue.HighFrameIndex = index
end

function UISetController:ShowHighFrameTps()
    -- local score = LocalDB.GetFloat("RUN_PERFORMANCE_KEY", 0)
    return false
end

--设置抗锯齿
function UISetController:SetLodSetting()
    --进去设置界面也是获取localdb的值，来给按钮赋值，设置选项时，获取setting文件，把里面的值勾上，并且设置localdb（因为在手机上lodsetting文件只在运行时生效，关闭游戏时，当前修改的设置不会保存）
    --level0和1都只勾抗锯齿组件就行，2需要联通img组件也勾上

    --先检查版本号控制显隐
    local showChoose = false
    if APPVER130 then
        showChoose = true
    end
    self._antiTexGo:SetActive(showChoose)
    self._antiValueGo:SetActive(showChoose)

    if showChoose then
        --控制值
        self._openAntialiasing = true
        local value = LocalDB.GetString("CloseAntialiasing", "null")
        if value == "close" then
            --关闭
            self._openAntialiasing = false
        else
            --开启
            self._openAntialiasing = true
        end
        self:InitLodSettingGroup()
    end
end
function UISetController:InitLodSettingGroup()
    local count = 2
    self.toggleGroupAnti = self:GetUIComponent("ToggleGroup", "GroupAntialiasing")
    self.toggleGroupAntiPath = self:GetUIComponent("UISelectObjectPath", "GroupAntialiasing")
    self.toggleGroupAntiPath:SpawnObjects("UISetControllerSelectTabBtn", count)
    ---@type UISetControllerSelectTabBtn[]
    self.allAntiToggle = self.toggleGroupAntiPath:GetAllSpawnList()
    for i, v in ipairs(self.allAntiToggle) do
        if i <= count then
            v:Init(i, "str_set_skill_animation_setting_", self.toggleGroupAnti, self.OnClickAntiTabBtn, self)
        end
    end
    local idx = 2
    if self._openAntialiasing then
        idx = 1
    end
    self:OnClickAntiTabBtn(idx, true, true)
end
function UISetController:OnClickAntiTabBtn(index, force, first)
    if not force then
        if self.indexAnti == index then
            return
        end
    end
    if not self._initiating then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    end
    if self.indexAnti then
        if self.allAntiToggle[self.indexAnti] then
            self.allAntiToggle[self.indexAnti]:Select(false)
        end
    end
    self.indexAnti = index
    if self.indexAnti then
        if self.allAntiToggle[self.indexAnti] then
            self.allAntiToggle[self.indexAnti]:Select(true)
        end
    end
    self:SetAnti(first, index)
    self._initSettingValue.AntiIndex = index
end
function UISetController:SetAnti(first, index)
    if not first then
        self._openAntialiasing = false
        local value = "close"
        if index == 1 then
            self._openAntialiasing = true
            value = "open"
        end
        LocalDB.SetString("CloseAntialiasing", value)
        Log.debug("###[UISetController] SetAnti value --> ", value)
        self:SetAntiSetting()
    end
end
function UISetController:SetAntiSetting()
    ---@type LODSetting
    local setting = LODManager.Instance.setting
    setting.IsOpenAntialiasing = self._openAntialiasing
    local currLevel = LODManager.Instance:GetLODLevel()
    Log.debug("###[UISetController] SetAnti currLevel --> ", currLevel)
    if currLevel == 2 then
        setting.isOpenImageProcess = self._openAntialiasing
    end

    Log.debug("###[UISetController] SetAnti IsOpenAntialiasing --> ", tostring(setting.IsOpenAntialiasing))
    Log.debug("###[UISetController] SetAnti isOpenImageProcess --> ", tostring(setting.isOpenImageProcess))

    Log.debug("###[UISetController] SetAnti set succ !")
end
function UISetController:SetPcSliderStatus()
    if IsPc() then
        self._mobileGraphicsChooseTips:SetActive(false)
        self._specialShapedScreenTabText:SetActive(false)
        self._systemScreenObj:SetActive(false)
    else
        self._mobileGraphicsChooseTips:SetActive(true)
        self._specialShapedScreenTabText:SetActive(true)
        self._systemScreenObj:SetActive(true)
    end
end

function UISetController:InitButtonOnPressEffect()
    self.btnLogout = self:GetUIComponent("Button", "btnLogout")
    self.btnLogoutSelect = self:GetGameObject("BtnLogoutSelect")
    local gv = HelperProxy:GetInstance():GetGameVersion()
    if IsPc() then
        self.btnLogout.gameObject:SetActive(false)
    else
        self.btnLogout.gameObject:SetActive(true)
    end
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.btnLogout.gameObject),
        UIEvent.Press,
        function(go)
            self.btnLogoutSelect:SetActive(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.btnLogout.gameObject),
        UIEvent.Release,
        function(go)
            self.btnLogoutSelect:SetActive(false)
        end
    )
end

---创建 开关和拖动条 设置声音
function UISetController:InitVolumeWindow()
    self.volumeRoot = self:GetUIComponent("UISelectObjectPath", "VolumeRoot")
    ---@type UISetControllerToggleSlider
    self.volumeRoot:SpawnObjects("UISetControllerToggleSlider", 3)
    self.volumeControllerList = self.volumeRoot:GetAllSpawnList()

    local sliderStrTitle = {"str_set_volume_music", "str_set_volume_sound", "str_set_volume_dialogue"}
    local sliderlocalDBKey = {"MusicVolumeKey", "SoundVolumeKey", "VoiceVolumeKey"}
    local togglelocalDBKey = {"MusicVolumeOnKey", "SoundVolumeOnKey", "VoiceVolumeOnKey"}

    for i, v in ipairs(self.volumeControllerList) do
        if i <= 3 then
            v:Init(
                i,
                sliderStrTitle[i],
                sliderlocalDBKey[i],
                togglelocalDBKey[i],
                self.OnToggleSliderComponentValueChanged,
                self
            )
        end
    end
end

function UISetController:OnToggleSliderComponentValueChanged(index, sliderValue, toggleValue)
    local newSliderValue = (toggleValue > 0) and sliderValue / 100 or 0
    if index == 1 then
        self._initSettingValue.bgmVolume = sliderValue
        self._initSettingValue.bgmMute = (toggleValue == 0) and true or false
        AudioHelperController.SetBgmVolume(newSliderValue * self.bgmGlobal)
    elseif index == 2 then
        self._initSettingValue.soundVolume = sliderValue
        self._initSettingValue.soundMute = (toggleValue == 0) and true or false
        AudioHelperController.SetSoundVolume(newSliderValue * self.voiceGlobal)
    elseif index == 3 then
        self._initSettingValue.voiceVolume = sliderValue
        self._initSettingValue.voiceMute = (toggleValue == 0) and true or false
        AudioHelperController.SetVoiceVolume(newSliderValue * self.soundGlobal)
    end
end

---设置画面等级和是否展示主动技能动画
function UISetController:InitToggleGraphicsAndSkillAnimation()
    self.tabGroupCount = 3
    --Graphics
    self.toggleGroupGraphics = self:GetUIComponent("ToggleGroup", "GroupGraphics")
    self.toggleGroupGraphicsPath = self:GetUIComponent("UISelectObjectPath", "GroupGraphics")
    ---@type UISetControllerSelectTabBtn
    self.toggleGroupGraphicsPath:SpawnObjects("UISetControllerSelectTabBtn", self.tabGroupCount)
    self.allGraphicsToggle = self.toggleGroupGraphicsPath:GetAllSpawnList()
    for i, v in ipairs(self.allGraphicsToggle) do
        if i <= self.tabGroupCount then
            v:Init(i, "str_set_graphics_setting_", self.toggleGroupGraphics, self.OnClickGraphicsTabBtn, self)
        end
    end
    self.lodLevel = self.tabGroupCount - LODManager.Instance:GetLODLevel()
    self:OnClickGraphicsTabBtn(self.lodLevel, true, true)

    --Skill
    self.toggleGroupSkill = self:GetUIComponent("ToggleGroup", "GroupSkill")
    self.toggleGroupSkillPath = self:GetUIComponent("UISelectObjectPath", "GroupSkill")
    self.toggleGroupSkillPath:SpawnObjects("UISetControllerSelectTabBtn", self.tabGroupCount)
    ---@type UISetControllerSelectTabBtn[]
    self.allSkillToggle = self.toggleGroupSkillPath:GetAllSpawnList()
    for i, v in ipairs(self.allSkillToggle) do
        if i <= self.tabGroupCount then
            v:Init(i, "str_set_skill_animation_setting_", self.toggleGroupSkill, self.OnClickSkillTabBtn, self)
        end
    end
    self.skillPermission = LocalDB.GetInt(self.localDBKey, SkillAnimationPermissionType.Open)
    self:OnClickSkillTabBtn(self.skillPermission, true, true)
end
--是否显示段位设置移到更换头像的界面了
function UISetController:InitToggleShowDan()
    --此处只是获取当前的段位设置并赋值，因为后续发消息不能少传参数，所以有这么一段
    local l_role_module = GameGlobal.GetModule(RoleModule)
    local curSwitch = l_role_module:GetBadgeSwitch()
    self._initSettingValue.danSwitch = curSwitch
    --Dan
    -- local setNum = 2

    -- self.toggleGroupDan = self:GetUIComponent("ToggleGroup", "GroupDan")
    -- self.toggleGroupDanPath = self:GetUIComponent("UISelectObjectPath", "GroupDan")
    -- ---@type UISetControllerSelectTabBtn
    -- self.toggleGroupDanPath:SpawnObjects("UISetControllerSelectTabBtn", setNum)
    -- self.allDanToggle = self.toggleGroupDanPath:GetAllSpawnList()
    -- for i, v in ipairs(self.allDanToggle) do
    --     if i <= setNum then
    --         v:Init(i, "str_set_dan_setting_", self.toggleGroupDan, self.OnClickDanTabBtn, self)
    --     end
    -- end
    -- local l_role_module = GameGlobal.GetModule(RoleModule)
    -- local curSwitch = l_role_module:GetBadgeSwitch()
    -- local curIndex
    -- if curSwitch then
    --     curIndex = 1
    -- else
    --     curIndex = 2
    -- end
    -- self:OnClickDanTabBtn(curIndex, true, true)
end
---点击设置是否显示段位
-- function UISetController:OnClickDanTabBtn(index, force, first)
--     if not force then
--         if self.indexDan == index then
--             return
--         end
--     end
--     if not self._initiating then
--         AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
--     end
--     if self.indexDan then
--         if self.allDanToggle[self.indexDan] then
--             self.allDanToggle[self.indexDan]:Select(false)
--         end
--     end
--     self.indexDan = index
--     if self.indexDan then
--         if self.allDanToggle[self.indexDan] then
--             self.allDanToggle[self.indexDan]:Select(true)
--         end
--     end
--     self:SetDan(first, index)
--     self._initSettingValue.danSwitch = (index == 1)
-- end
---设置是否显示段位
-- function UISetController:SetDan(first, index)
--     if not first then
--     end
-- end

---设置屏幕缩放黑边
function UISetController:InitResolutionBangWidth()
    local safeAreaExist = ResolutionManager.SafeAreaExist()
    local bangWidthPercent = 100

    if safeAreaExist then
        local key, registeredKey = ResolutionManager.BangWidthLocalDBKey()
        local isBangWidthRegistered = LocalDB.GetInt(registeredKey)
        if isBangWidthRegistered > 0 then
            bangWidthPercent = LocalDB.GetInt(key)
            if bangWidthPercent >100 then
                bangWidthPercent = 100
            end
        end
    end

    ---@type UnityEngine.UI.Image
    self.screenBangSliderBackgroundOn = self:GetUIComponent("Image", "BackgroundOn")
    self.screenBangSliderFillOn = self:GetUIComponent("Image", "FillOn")
    self.screenBangSliderImageOn = self:GetUIComponent("Image", "ImageOn")

    ---@type UnityEngine.UI.Slider
    self.comSlider = self:GetUIComponent("Slider", "Slider")
    self.comSlider.value = bangWidthPercent
    self:RefreshScreenBangSliderEnable(safeAreaExist)

    self.txt = self:GetUIComponent("Text", "info")
    self.txt.text = bangWidthPercent

    self._initSettingValue.BangWidth = bangWidthPercent

    self.sliderCB = function(value)
        local percent = math.floor(value)

        self.txt.text = percent
        self._initSettingValue.BangWidth = percent

        local width = math.ceil(ResolutionManager.GetBangCanvasPixelWidthByPercent(percent / 100))

        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIBangWidthChange, width)
        ResolutionManager.InvokeBangWidthChangedListeners(width)
        local key, registeredKey = ResolutionManager.BangWidthLocalDBKey()
        LocalDB.SetInt(registeredKey, 1)
        LocalDB.SetInt(key, percent)
    end
    self.comSlider.onValueChanged:AddListener(self.sliderCB)
end

function UISetController:RefreshScreenBangSliderEnable(enabled)
    self.comSlider.interactable = enabled
    if enabled then
        --self.screenBangSliderBackgroundOn.color = Color.white
        --self.screenBangSliderFillOn.color = Color.white
        --self.screenBangSliderImageOn.color = Color.white
    else
        --self.screenBangSliderBackgroundOn.color = Color.gray
        --self.screenBangSliderFillOn.color = Color.gray
        --self.screenBangSliderImageOn.color = Color.gray
    end
end

function UISetController:OnSetLocalDB()
    --[[local key, registeredKey = ResolutionManager.BangWidthLocalDBKey()
    
    LocalDB.SetInt(registeredKey, 1)
    if self.bangWidth then
        LocalDB.SetInt(key, self.bangWidth)
    end]]--
end

---点击设置画面
function UISetController:OnClickGraphicsTabBtn(index, force, first)
    if not force then
        if self.indexGraphics == index then
            return
        end
    end
    if not self._initiating then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    end
    if self.indexGraphics then
        if self.allGraphicsToggle[self.indexGraphics] then
            self.allGraphicsToggle[self.indexGraphics]:Select(false)
        end
    end
    self.indexGraphics = index
    if self.indexGraphics then
        if self.allGraphicsToggle[self.indexGraphics] then
            self.allGraphicsToggle[self.indexGraphics]:Select(true)
        end
    end
    self:SetGraphics(first, index)
    self._initSettingValue.GraphicsLevel = index
end

---设置画面
function UISetController:SetGraphics(first, index)
    if not first then
        LODManager.Instance:SetLODLevel(self.tabGroupCount - index)
        GameGlobal.SetTargetFrameRate()
        GameGlobal.SetQualityByLodLevel()
        if APPVER130 then
            self:SetAntiSetting()
        end
    end
end

---点击设置技能是否播放动画
function UISetController:OnClickSkillTabBtn(index, force, first)
    if not force then
        if self.indexSkill == index then
            return
        end
    end
    if not self._initiating then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    end
    if self.indexSkill then
        if self.allSkillToggle[self.indexSkill] then
            self.allSkillToggle[self.indexSkill]:Select(false)
        end
    end
    self.indexSkill = index
    if self.indexSkill then
        if self.allSkillToggle[self.indexSkill] then
            self.allSkillToggle[self.indexSkill]:Select(true)
        end
    end
    self:SetSkill(first, index)
    self._initSettingValue.skillAnmiIndex = index
end

---设置技能是否播放动画
function UISetController:SetSkill(first, index)
    if not first then
        LocalDB.SetInt(self.localDBKey, index)
    end
end

function UISetController:SetBangWidth(value)
    self._initSettingValue.BangWidth = value
    self.bangWidth = self.configBangWidth * value / 100

    local percentageInt = Mathf.Ceil(value)
    self.txt.text = percentageInt
    return self.bangWidth
end

function UISetController:GetWidthBlackOnce()
    self.widthBlack = Mathf.Floor(100 / 1920 * self.uiCanvasRect.sizeDelta.x)
end

function UISetController:OnHide()
    self.comSlider.onValueChanged:RemoveListener(self.sliderCB)
    self.btnSystem.onValueChanged:RemoveListener(self.btnSystemTabButtonValueChange)
    self.btnVoice.onValueChanged:RemoveListener(self.btnVoiceTabButtonValueChange)
    self.btnUser.onValueChanged:RemoveListener(self.btnUsermTabButtonValueChange)
    self:SendNewSettingTLog()
    self:DetachEvent(GameEventType.ColorBlindUpdate, self.FlushColorBlind)
    self:DetachEvent(GameEventType.ChangeBindBtnStatus, self.RefreshButtonStatus)

    --LI
    --防止打开用户中心失败，但是没有关闭canvas
    self:ActiveUILoginLIRoot(false)
end

function UISetController:SendNewSettingTLog()
    if self._settingTlogSended then
        return --发过了
    end
    local l_reportSvc = false
    for key, value in pairs(self._initSettingValue) do
        if self._enterSettingValue[key] ~= value then
            l_reportSvc = true
            break
        end
    end

    if l_reportSvc then
        local l_role_module = GameGlobal.GetModule(RoleModule)
        l_role_module:PushNewSettingTLog(self._initSettingValue)
        self._settingTlogSended = true
    end
end

function UISetController:BtnLogoutOnClick()
    self:OnSetLocalDB()
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_set_logout_describe"),
        function(param)
            self:Lock("LogoutTask")
            self:SendNewSettingTLog()                   --退出登录前手动发一次消息 避免在onhide中再发
            GameGlobal.TaskManager():StartTask(self.LogoutTask, self)
        end,
        nil,
        function(param)
            Log.debug("sale cancel. .")
        end,
        nil
    )
end
function UISetController:LogoutTask(TT)
    local loginmodule = GameGlobal.GetModule(LoginModule)
    loginmodule:Logout("setController logout")
    GameGlobal.GameLogic():BackToLogin(false, LoginModule, "player logout", false)
    self:UnLock("LogoutTask")
end
---@return boolean
function UISetController:NeedAdjustAnchorInfo(curBangWidth)
    local blackWidth = ResolutionManager.BlackWidth()

    --锚点的X值会受安全区的影响
    local bangWidth = nil
    if curBangWidth and curBangWidth >= 0 then
        bangWidth = curBangWidth
    --当前刘海宽
    end
    if bangWidth >= blackWidth then --用安全区锚
        return true
    end
    return false
end
function UISetController:ActiveUILoginLIRoot(active)
    Log.debug("###[lua LI] ActiveUILoginLIRoot active:",active)

    if self._m_UILoginLIRoot then
        self._m_UILoginLIRoot:SetActive(active)
    end
end
function UISetController:BtnUserCenterOnClick(go)
    --判断一下pc平台和版本号
    if _G.APPVER1190 and not IsPc() then
        self._m_UILoginLIRoot = UIHelper.GetGameObject("UILoginLIRoot.prefab")
        self._m_LI_UI_ROOT = self._m_UILoginLIRoot.transform:Find("m_LI_UI_Root").gameObject;
        self:ActiveUILoginLIRoot(true)
        Log.debug("###[lua LI] SetUIRoot!")
        SDKProxy:GetInstance():OpenAccountCenter(self._m_LI_UI_ROOT)
    end
end
function UISetController:BtnUrl1OnClick()
    local url = StringTable.Get("str_set_url_button_url_1")
    if SDKProxy:GetInstance():IsInternationalSDK() == true then
        url = StringTable.Get("str_set_url_button_url_jp_1")
    end
    SDKProxy:GetInstance():OpenUrl(url)
end

function UISetController:BtnUrl2OnClick()
    local url = StringTable.Get("str_set_url_button_url_2")
    if SDKProxy:GetInstance():IsInternationalSDK() == true then
        url = StringTable.Get("str_set_url_button_url_jp_2")
    end
    SDKProxy:GetInstance():OpenUrl(url)
end

function UISetController:BtnUrl3OnClick()
    local url = StringTable.Get("str_set_url_button_url_3")
    SDKProxy:GetInstance():OpenUrl(url)
end

function UISetController:BtnUrl4OnClick()
    local url = StringTable.Get("str_set_url_button_url_jp_5")
    SDKProxy:GetInstance():OpenUrl(url)
end

function UISetController:RefreshUserWindow()
    for i = 0, UISetUserInfoType.Max - 1 do
        if self:IsShowSetUserInfoItem(i) then
            local go = UnityEngine.GameObject.Instantiate(self._item, self._userWindowContent)
            go:SetActive(true)
            local com = self:GetUIComponentDynamic("UISelectObjectPath", go)
            ---@type UISetUserInfoItem
            local item = com:SpawnObject("UISetUserInfoItem")
            item:SetData(i)
        end
    end
end

---@param setUserInfoType UISetUserInfoType
function UISetController:IsShowSetUserInfoItem(setUserInfoType)
    if setUserInfoType == UISetUserInfoType.AgeConfirm then
        ---@type RoleModule
        local roleModule = GameGlobal.GetModule(RoleModule)
        return roleModule:IsJapanZone()
    end
    return true
end

function UISetController:RefreshButtonStatus()
    self:ShowLiUserCenter()
    Log.debug("###[lxs] check new app !")
    if self:IsLiNewApp() then
        self.btnBind:SetActive(true)
        self.btnChangePasswd:SetActive(false)
        return
    end

    --绑定账号 （游客） 修改密码（邮件登陆）
    self.btnChangePasswd:SetActive(false)
    self.btnBind:SetActive(false)
    if GetPlatformOS() ~= ClientRuntimeOS.CRO_PC then
        local gv = HelperProxy:GetInstance():GetGameVersion()
        local channelId = GameGlobal.GameLogic().ClientInfo.m_login_source
        local authModule = GameGlobal.GetModule(AuthInternationalModule)
        local queryUserInfoRet = authModule:GetQueryUserInfo()

        if APPVER125 and gv == GameVersionType.INTL then
            if channelId == MobileClientLoginChannel.MCLC_GUEST then
                self.btnBind:SetActive(true)
            else
                if queryUserInfoRet.RetCode == INTL.INTLErrorCode.SUCCESS and queryUserInfoRet.BindList then
                    local channelList = SDKProxy:GetInstance():GetBindChannel(queryUserInfoRet.BindList)
                    if channelList[MobileClientLoginChannel.MCLC_DMM] == true then
                        self.btnBind:SetActive(true)
                    end

                    if channelId == MobileClientLoginChannel.MCLC_TWITTER then
                        if channelList[EngineGameHelper.SAIchannelId()] == true or channelList[MobileClientLoginChannel.MCLC_DMM] == true then
                            self.btnBind:SetActive(true)
                        end
                    end

                else
                    --没数据在请求一次,避免循环请求
                    if self._hasRequestBtnStatus == false then
                        self._hasRequestBtnStatus = true
                        GameGlobal.TaskManager():StartTask(self.RefreshButtonStatusCoro, self)
                    end
                end
                if channelId == EngineGameHelper.SAIchannelId() then
                    self.btnChangePasswd:SetActive(true)
                end
            end
        else
            --非国际服只根据游客判断
            if channelId == EngineGameHelper.SAIchannelId() then
                self.btnChangePasswd:SetActive(true)
            elseif channelId == MobileClientLoginChannel.MCLC_GUEST then
                self.btnBind:SetActive(true)
            elseif channelId == MobileClientLoginChannel.MCLC_TWITTER then
                if queryUserInfoRet.RetCode == INTL.INTLErrorCode.SUCCESS and queryUserInfoRet.BindList then
                    local channelList = SDKProxy:GetInstance():GetBindChannel(queryUserInfoRet.BindList)
                    if channelList[EngineGameHelper.SAIchannelId()] == true or channelList[MobileClientLoginChannel.MCLC_DMM] == true then
                        self.btnBind:SetActive(true)
                    end
                end
            end
        end
    end
end
--显示LI用户中心
function UISetController:ShowLiUserCenter()
    local tex
    if self:IsLiNewApp() then
        tex = "str_set_bind_btn_name_LI"

    else
        tex = "str_set_bind_btn_name"
    end
    self.UserCenterText:SetText(StringTable.Get(tex))
end
function UISetController:IsLiNewApp()
    local new = false
    if _G.APPVER1190 and not IsPc() then
        new = true
    end
    if _G.APPVER1190 then
    Log.debug("###[lxs] check new app ! 1190")
        
    end
    if not IsPc() then
    Log.debug("###[lxs] check new app ! not pc")
        
    end
    return new
end
function UISetController:RefreshButtonStatusCoro(TT)
    local ret = SDKProxy:GetInstance():QueryUserInfo(TT)
end

function UISetController:HelpBtnOnClick()
    if IsPc() then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.Ok,
            "",
            StringTable.Get("str_set_pc_help_pop_tips")
        )
    else
        self:Lock("UISetController:HelpBtnOnClick")
        GameGlobal.TaskManager():StartTask(self.HelpBtnOnClickCoro, self)
    end
end

function UISetController:HelpBtnOnClickCoro(TT)
    SDKProxy:GetInstance():LaunchCustomerUI(TT)
    self:UnLock("UISetController:HelpBtnOnClick")
end

function UISetController:BtnChangePasswdOnClick()
    if SDKProxy:GetInstance():IsInternationalSDK() then
        self:ShowDialog("UISetChangePasswdController")
    end
end

function UISetController:BtnBindOnClick()
    if self:IsLiNewApp() then
        --LI
        self:BtnUserCenterOnClick()
        return
    end

    self:Lock("UISetController:BtnBindOnClick")
    local authModule = GameGlobal.GetModule(AuthInternationalModule)
    local queryUserInfoRet = authModule:GetQueryUserInfo()
    if queryUserInfoRet.RetCode == INTL.INTLErrorCode.SUCCESS then
        self:ShowBindChannelDialog(queryUserInfoRet)
    else
        GameGlobal.TaskManager():StartTask(self.BindBtnOnClickCoro, self)
    end
end

function UISetController:BindBtnOnClickCoro(TT)
    local ret = SDKProxy:GetInstance():QueryUserInfo(TT)
    if ret.RetCode == INTL.INTLErrorCode.SUCCESS then
        if ret.BindList then
            self:ShowBindChannelDialog(ret)
        else
            Log.error("异常情况")
        end
    else
        UICommonHelper:GetInstance():HandleLoginErrorCode(ret.RetCode, ret.ThirdCode)
    end
end

function UISetController:ShowBindChannelDialog(ret)
    local channelList = SDKProxy:GetInstance():GetBindChannel(ret.BindList)
    local channelId = GameGlobal.GameLogic().ClientInfo.m_login_source
    local gv = HelperProxy:GetInstance():GetGameVersion()
    if channelId ~= MobileClientLoginChannel.MCLC_GUEST then
        if gv == GameVersionType.INTL then
            --国际服非游客只显示DMM.....  加了推特这里变了
            if channelId == MobileClientLoginChannel.MCLC_TWITTER then
            else
                channelList = {}
                channelList[MobileClientLoginChannel.MCLC_DMM] = true
            end
        else
            --非国际服不显示DMM
            channelList[MobileClientLoginChannel.MCLC_DMM] = false
        end
    end
    self:ShowDialog("UISetBindChannelController", channelList)
    self:UnLock("UISetController:BtnBindOnClick")
end

--region 色盲模式
function UISetController:FlushColorBlind()
    local spriteNames = {
        "install_blind_icon3",
        "install_blind_icon2",
        "install_blind_icon1"
    }
    local colorBlindCode = UIPropertyHelper:GetInstance():GetColorBlindStyle()
    self.imgColorBlind.sprite = self.atlas:GetSprite(spriteNames[colorBlindCode])
    self.txtColorBlind:SetText(StringTable.Get("str_set_color_blind_" .. colorBlindCode))
end
function UISetController:btnColorBlindOnClick()
    self:ShowDialog("UIColorBlind")
end
--endregion

function UISetController:btnCreditsOnClick()
    self:ShowDialog("UICredits")
end

function UISetController:RefreshLanguage()
    --[[
        国内和港澳台不支持设置语言功能
        国际版可以设置语言,需要兼容老版本app,旧版本只支持英日韩三种语言,新版本支持全部8种语言
    ]]
    local enable = false
    local version = HelperProxy:GetInstance():GetGameVersion()
    if version == GameVersionType.USA then
        enable = true
    elseif version == GameVersionType.INTL then
        enable = true
    elseif version == GameVersionType.HMT then
    end
    if not enable then
        --国内版本不允许切换语言
        self._langTitle:SetActive(false)
        self._langRoot:SetActive(false)
        self._langOptGo:SetActive(false)
        self._langSystem:SetActive(false)
        Log.warn("当前版本屏蔽设置语言功能")
        return
    end

    local curLan = Localization.GetCurLanguage()
    local ls = {
        [1 << 0] = LanguageType.zh, --简体中文
        [1 << 1] = LanguageType.tw, --繁体中文
        [1 << 2] = LanguageType.us, --英文
        [1 << 3] = LanguageType.kr, --韩文
        [1 << 4] = LanguageType.jp, --日文
        [1 << 5] = LanguageType.pt, --葡萄牙语
        [1 << 6] = LanguageType.es, --西班牙语
        [1 << 7] = LanguageType.idn, --印尼语
        [1 << 8] = LanguageType.th --泰语
    }
    local cfgs = Cfg.cfg_language {}

    ---编辑器内支持设置为简体中文
    if EDITOR and not cfgs[1] then
        cfgs[1] = {ID = 1, Index = 1, Text = "str_set_language_cn", Sprite = "install_shezhi_zi1"}
    end
    ---end

    cfgs = table.toArray(cfgs)
    table.sort(
        cfgs,
        function(a, b)
            return a.Index < b.Index
        end
    )
    ---@type table<number, UISettingLanguageItem>
    local widgets = self._langItems:SpawnObjects("UISettingLanguageItem", #cfgs)
    local cur = -1
    for i, cfg in ipairs(cfgs) do
        widgets[i]:SetData(cfg, ls[cfg.ID], self.atlas:GetSprite(cfg.Sprite))
        widgets[i]:Refresh(curLan)
        if ls[cfg.ID] == curLan then
            cur = i
        end
    end

    local layouts =
        self._langFromAnchor.gameObject:GetComponentsInParent(
        typeof(UnityEngine.UI.HorizontalOrVerticalLayoutGroup),
        true
    )
    for i = 0, layouts.Length - 1 do
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(layouts[i].gameObject:GetComponent("RectTransform"))
    end

    local pos = self._langFromAnchor.position:Clone()
    self._langTargetAnchor.position = pos

    local sprite
    if cfgs[cur] then --编辑器里默认是简中,配置里没有
        sprite = self.atlas:GetSprite(cfgs[cur].Sprite)
    end
    if sprite then
        self._langImage.sprite = sprite
    end
    self._langWidgets = widgets
    self._langShow = false
    self._langWindow:SetActive(false)
    self._langBtnImage.sprite = self.atlas:GetSprite("install_shezhi_icon11")
end

function UISetController:LanguageBtnOnClick()
    self._langShow = not self._langShow
    if self._langShow then
        local curLan = Localization.GetCurLanguage()
        for _, w in pairs(self._langWidgets) do
            w:Refresh(curLan)
        end
        local pos = self._langFromAnchor.position:Clone()
        self._langTargetAnchor.position = pos
        self._langWindowAnchor.position = pos
        self._langWindow:SetActive(true)
        self._langBtnImage.sprite = self.atlas:GetSprite("install_shezhi_icon12")
    else
        self._langWindow:SetActive(false)
        self._langBtnImage.sprite = self.atlas:GetSprite("install_shezhi_icon11")
    end
end

function UISetController:lan_windowOnClick()
    self._langShow = false
    self._langWindow:SetActive(false)
    self._langBtnImage.sprite = self.atlas:GetSprite("install_shezhi_icon11")
end

--设置自动战斗连线策略
function UISetController:SetAutoFightLinkline()
    --控制值
    self._autoFightEnhanced = false
    local value = LocalDB.GetString("AutoFightLinkLine", "normal")
    if value == "enhanced" then
        self._autoFightEnhanced = true
    else
        self._autoFightEnhanced = false
    end
    self:InitAutoFightSettingGroup()
end
function UISetController:InitAutoFightSettingGroup()
    local count = 2
    self.toggleGroupAutoFight = self:GetUIComponent("ToggleGroup", "GroupAutoFight")
    self.toggleGroupAutoFightPath = self:GetUIComponent("UISelectObjectPath", "GroupAutoFight")
    self.toggleGroupAutoFightPath:SpawnObjects("UISetControllerSelectTabBtn", count)
    ---@type UISetControllerSelectTabBtn[]
    self.allAutoFightToggle = self.toggleGroupAutoFightPath:GetAllSpawnList()
    for i, v in ipairs(self.allAutoFightToggle) do
        if i <= count then
            v:Init(i, "str_set_auto_fight_", self.toggleGroupAutoFight, self.OnClickAutoFightTabBtn, self)
        end
    end
    local idx = 1
    if self._autoFightEnhanced then
        idx = 2
    end
    self:OnClickAutoFightTabBtn(idx, true)
end
function UISetController:OnClickAutoFightTabBtn(index, force)
    if not force then
        if self.indexAutoFight == index then
            return
        end
    end
    if not self._initiating then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    end

    if not force and index == 2 then
        --self:ShowDialog("UISetAutoFightEnhanceWarning")
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            StringTable.Get("str_set_auto_fight_warning_title"),
            StringTable.Get("str_set_auto_fight_warning"),
            function()
                self:SetAutoFight(2)
            end,
            nil,
            function()
                self:SetAutoFight(1)
            end
        )
    else
        self:SetAutoFight(index)
    end
end

function UISetController:SetAutoFight(index)
    if self.indexAutoFight then
        if self.allAutoFightToggle[self.indexAutoFight] then
            self.allAutoFightToggle[self.indexAutoFight]:Select(false)
        end
    end
    self.indexAutoFight = index
    if self.indexAutoFight then
        if self.allAutoFightToggle[self.indexAutoFight] then
            self.allAutoFightToggle[self.indexAutoFight]:Select(true)
        end
    end
    self._autoFightEnhanced = false
    local value = "normal"
    if index == 2 then
        self._autoFightEnhanced = true
        value = "enhanced"
    end
    LocalDB.SetString("AutoFightLinkLine", value)
    Log.debug("###[UISetController] SetAutoFight value --> ", value)
    BattleConst.AutoFightMoveEnhanced = self._autoFightEnhanced

    self._initSettingValue.AutoFightIndex = index
end
