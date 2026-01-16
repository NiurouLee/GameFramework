---@class UIMainLobbyController:UIController
_class("UIMainLobbyController", UIController)
UIMainLobbyController = UIMainLobbyController

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIMainLobbyController:LoadDataOnEnter(TT, res, uiParams)
    --拉取最新活动数据更新主界面活动信息
    self.mCampaign = self:GetModule(CampaignModule)
    self._latestCampObj = self.mCampaign:GetLatestCampaignObj(TT)
    self.grassData = self.mCampaign:GetGraveRobberData()
    self.grassData:RequestCampaign(TT)
    self:RequestCampaignSummer1(TT, self._latestCampObj)
    --每次打开主界面都更新体力 --靳策添加
    ---@type RoleModule
    local roleModule = self:GetModule(RoleModule)
    if roleModule ~= nil then
        roleModule:GetRecoverData(TT, 0)
    end
    ---@type TalePetModule
    local talePetModule = GameGlobal.GetModule(TalePetModule)
    local ret = talePetModule:RequestTrailLevelData(TT)

    local petModule = GameGlobal.GetModule(PetModule)
    petModule:ClearAllPetSortInfo()

    -----------------------------------------------------------------------------
    -- 侧边入口 数据提前下载
    if not self._sideEnter then
        ---@type UISideEnterMain
        self._sideEnter = UIWidgetHelper.SpawnObject(self, "SideEnter", "UISideEnterMain")
        self._sideEnter:_LoadDataAndRefresh(TT)
    end

    -- 如果在主界面onShow前离线或者被顶号，onShow会出错，如果已不在登陆状态则不继续打开主界面
    res:SetSucc(self:GetModule(LoginModule):IsLogin())
end

---@param uiParams table<number, any> 参数1:true不播放欢迎语音,nil或false播放语音|
function UIMainLobbyController:OnShow(uiParams)
    -- 侧边入口 显示 UI （在 UIStateType.UIMain 时，再进行 switch state 到 UIStateType.UIMain 时，会析构 Spawn 出来的 Object，必须在 OnShow 中重新 Spawn）
    ---@type UISideEnterMain
    self._sideEnter = UIWidgetHelper.SpawnObject(self, "SideEnter", "UISideEnterMain")
    self._sideEnter:_Refresh()

    --关闭多点触控，之前在login�??
    UnityEngine.Input.multiTouchEnabled = false
    self._playEnterSpine=false
    self._enterSpineName=nil
    self._enterSpineSubGoName=nil
    --轮播数量
    self._count = 0
    --文本框消失时�??
    self._fadeTime = 1
    --文本框消失等待时�??
    self._waitFadeTime = 1

    self._freeTime = 0
    self._maxFreeTime = Cfg.cfg_global["MainUIFreeTime"].IntValue * 1000

    -- 返回主界面上�??
    GameGlobal.UAReportForceGuideEvent("MainUIEnter", {}, true)

    ---@type TalePetModule
    self._talePetModule = GameGlobal.GetModule(TalePetModule)

    self:_GetComponents()
    self:PlayMatsTween()

    self._playWelcome = false
    if not uiParams[1] then --true表示不播放语音
        local oldType = self:Manager():GetLastStateType()
        if oldType == UIStateType.Login or oldType == UIStateType.LoginEmpty or 
           oldType == UIStateType.UIAircraft or oldType == UIStateType.UIDiscovery then
            self._playWelcome = true
        end
    end

    ---@type RoleModule
    self._roleModule = self:GetModule(RoleModule)
    ---@type MissionModule
    self._missionModule = GameGlobal.GetModule(MissionModule)
    ---@type SvrTimeModule
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type QuestModule
    self._questModule = self:GetModule(QuestModule)
    self._shopModule = GameGlobal.GetModule(ShopModule)
    --公共图集，动态静�??
    self._atlas = self:GetAsset("UIMainLobby.spriteatlas", LoadType.SpriteAtlas)

    ---@type SignInModule
    self._signInModule = self:GetModule(SignInModule)
    ---@type LoginModule
    self._loginModule = self:GetModule(LoginModule)

    self._petAudioModule = self:GetModule(PetAudioModule)

    self:_OnValue()
    self:AddListener()
    self:GetCurrentPhyTimer()

    --这里解锁一下成就弹窗，以防某处忘记解锁
    --锁住成就弹窗�??
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)

    self:_RefreshFriendRedStatus()
    Log.prof("UIMainLobbyController Show")

    local memoryCount = math.floor(collectgarbage("count") / 1024)
    Log.prof("[luamem] mainlobbyui current memory: ", memoryCount, " MB")

    AudioHelperController.RequestUISound(CriAudioIDConst.AircraftBtnClick)

    --播放主界面背景音
    UIBgmHelper.PlayMainBgm()

    --按钮事件注册
    self:SetButtonAnim()
    self:PlayEnterAnim()
    --[[
    local www = "https://www.tencent.com/"
    www = SDKProxy:GetInstance():AddUrlParam(www)
    Log.debug(www)

    local www = "https://www.tencent.com"
    www = SDKProxy:GetInstance():AddUrlParam(www)
    Log.debug(www)

    local www = "https://www.tencent.com/?ssss=dddd"
    www = SDKProxy:GetInstance():AddUrlParam(www)
    Log.debug(www)

    local www = "www.tencent.com"
    www = SDKProxy:GetInstance():AddUrlParam(www)
    Log.debug(www)
    ]]
    self.showTestFuncEntry = true

    self:CheckFixedStatus()
    self._roleModule:LoginCompleteEvent()
    self:ResetBtnclickImage()
end
function UIMainLobbyController:CheckFixedStatus()
    ---@type RoleModule
    local roleModule = self:GetModule(RoleModule)
    if not roleModule:GetIsFix() then
        return
    end

    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal,
            PopupMsgBoxType.Ok,
            StringTable.Get("str_shop_resourceerror_title"),
            StringTable.Get("str_shop_resourceerror_desc"),
            function(param)
                Log.error("huidiaoddddd")
                roleModule:SetIsFixItem(false)
            end
        )
end
function UIMainLobbyController:_CheckCutSceneOut()
    CutsceneManager.ExcuteCutsceneOut()
end
function UIMainLobbyController:RequestCampaignSummer1(TT, latestCampObj) --如果夏活1开了就请求夏活1数据
    if latestCampObj then
        local sampleInfo = latestCampObj:GetSampleInfo()
        if sampleInfo and sampleInfo.camp_type == ECampaignType.CAMPAIGN_TYPE_SUMMER_I then
            local summer1Data = self.mCampaign:GetSummer1Data()
            if summer1Data then
                summer1Data:RequestCampaign(TT)
            end
        end
    end
end

function UIMainLobbyController:ResetBtnclickImage()
    self:GetUIComponent("RawImage","missionClickLight").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
    self:GetUIComponent("RawImage","QuestBtnClick").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
    self:GetUIComponent("RawImage","QuestJumpBtnClick").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
    self:GetUIComponent("RawImage","BaseBtnClick").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
    self:GetUIComponent("RawImage","SummonBtnClick").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
    self:GetUIComponent("RawImage","HomeBtnClick").color = Color.New(255/255, 255/255, 255/ 255, 0/255)
end

function UIMainLobbyController:SetButtonAnim()
    self:RegisterBtnClick("missionBtn", "mission", "missionClickLight")
    self:RegisterBtnClick("missionLeftBtn", "mission", "missionClickLight")
    self:RegisterBtnClick("questBtn", "questLeft", "QuestBtnClick")
    self:RegisterBtnClick("questJumpBtn", "questRight", "QuestJumpBtnClick")
    self:RegisterBtnClick("baseBtn", "base", "BaseBtnClick")
    self:RegisterBtnClick("sumBtn", "sum", "SummonBtnClick")
    self:RegisterBtnClick("homeBtn", "home", "HomeBtnClick")
end

function UIMainLobbyController:RegisterBtnClick(btnName, animGoName, imgName)
    local btnGo = self:GetGameObject(btnName)
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(btnGo),
        UIEvent.Press,
        function(go)
            self:PlayBtnPressAnim(animGoName, "uieff_mainlobby_btnClick", imgName)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(btnGo),
        UIEvent.Release,
        function(go)
            self:PlayBtnUpAnim(animGoName, "uieff_mainlobby_btnClickFade", imgName)
        end
    )
end

function UIMainLobbyController:PlayBtnPressAnim(btnGo, animName, imageGo)
    self._btnPressAnimTask = self:StartTask(self.PlayBtnPressAnimCoro, self, btnGo, animName, imageGo)
end

function UIMainLobbyController:PlayBtnPressAnimCoro(TT, btnGo, animName, imageGo)
    local anim = self:GetUIComponent("Animation", btnGo)
    anim:Play(animName)
    local rawImg = self:GetUIComponent("RawImage", imageGo)
    local rawMat = rawImg.material
    rawMat:SetTextureScale("_MaskTex", Vector2(1, 1))

    local speed = 1 / 0.1667
    local timer = 0
    local length = 0.1667
    local value = 1

    while true do
        local deltaTime = UnityEngine.Time.deltaTime
        timer = timer + deltaTime
        value = value - deltaTime * speed
        if value < 0 then
            value = 0
        end
        rawMat:SetTextureScale("_MaskTex", Vector2(value, 1))
        if timer >= length then
            rawMat:SetTextureScale("_MaskTex", Vector2(0, 1))
            break
        end
        YIELD(TT)
    end
    self._btnPressAnimTask = nil
end

function UIMainLobbyController:PlayBtnUpAnim(btnGo, animName, imageGo)
    self._btnUpAnimTask = self:StartTask(self.PlayBtnUpAnimCoro, self, btnGo, animName, imageGo)
end

function UIMainLobbyController:PlayBtnUpAnimCoro(TT, btnGo, animName, imageGo)
    if self._btnPressAnimTask then
        if self._btnPressAnimTask then
            GameGlobal.TaskManager():KillTask(self._btnPressAnimTask)
            self._btnPressAnimTask = nil
        end
    end
    local anim = self:GetUIComponent("Animation", btnGo)
    anim:Play(animName)
    local rawImg = self:GetUIComponent("RawImage", imageGo)
    local rawMat = rawImg.material
    rawMat:SetTextureScale("_MaskTex", Vector2(0, 1))
    YIELD(TT, 500)
    rawMat:SetTextureScale("_MaskTex", Vector2(1, 1))
    self._btnUpAnimTask = nil
end

function UIMainLobbyController:PlayEnterAnim()
    self:Lock("UIMainLobbyController_PlayEnterAnim")
    self:StartTask(self.PlayEnterAnimCoro, self)
end

function UIMainLobbyController:PlayEnterAnimCoro(TT)
    local anim = self:GetUIComponent("Animation", "uianim")
    local anim2 = self:GetUIComponent("Animation", "FullScreenArea")
    local anim3 = self:GetUIComponent("Animation", "FullScreenArea2")
    local bgImg = self:GetUIComponent("Image", "bottomBg")
    local outlineImg = self:GetUIComponent("Image", "bottomOutline")
    local bgMat = bgImg.material
    local outlineMat = outlineImg.material

    anim:Play("uieff_mainlobby_in")
    anim2:Play("uieff_mainlobby_in2")
    anim3:Play("uieff_mainlobby_in3")
    bgMat:SetFloat("_DissolveValue", 1)
    outlineMat:SetFloat("_OutLineValue", 1)

    YIELD(TT, 100)

    local bgSpeed = 1 / 0.6
    local outSpeed = 1 / 0.633
    local timer = 0
    local length = 0.633
    local bgValue = 1
    local outlineValue = 1

    while true do
        local deltaTime = UnityEngine.Time.deltaTime
        timer = timer + deltaTime

        bgValue = bgValue - deltaTime * bgSpeed
        if bgValue < 0 then
            bgValue = 0
        end

        outlineValue = outlineValue - deltaTime * outSpeed
        if outlineValue < 0 then
            outlineValue = 0
        end

        bgMat:SetFloat("_DissolveValue", bgValue)
        outlineMat:SetFloat("_OutLineValue", outlineValue)

        if timer >= length then
            bgMat:SetFloat("_DissolveValue", 0)
            outlineMat:SetFloat("_OutLineValue", 0)
            break
        end
        YIELD(TT)
    end
    self:UnLock("UIMainLobbyController_PlayEnterAnim")
end

function UIMainLobbyController:SwitchTestFuncEntry(show)
    if self._testFunc ~= nil then
        self._testFunc:Switch(show)
    end
end

function UIMainLobbyController:_GetComponents()
    ---region 测试功能
    if EngineGameHelper.IsDevelopmentBuild() or HelperProxy:GetInstance():GetConfig("EnableTestFunc", "false") == "true" then
        ---@type UICustomWidgetPool
        local testFuncPool = self:GetUIComponent("UISelectObjectPath", "TestFunc")
        if testFuncPool then
            ---@type UIMainLobbyTestFunc
            self._testFunc = testFuncPool:SpawnObject("UIMainLobbyTestFunc")
        end
    end
    ---region end 测试功能

    self._canvasGroupUiAnim = self:GetUIComponent("CanvasGroup", "uianim")
    self._changePetPosAndScaleRoot = self:GetUIComponent("RectTransform", "posAndScale")
    self._cgSpineGo = self:GetGameObject("posAndScale")

    ---@type UILocalizationText
    self._discoveryGuideGO = self:GetGameObject("discoveryGuideGO")
    self._goldText = self:GetUIComponent("UILocalizationText", "GoldText")
    self._toptips = self:GetUIComponent("UISelectObjectPath", "toptips")
    self._toptipsInfo = self._toptips:SpawnObject("UITopTipsContext")
    self._goldIcon = self:GetUIComponent("Image", "goldIcon")
    self._powerIcon = self:GetUIComponent("Image", "powerIcon")
    self._diamondIcon = self:GetUIComponent("Image", "diamondIcon")

    -----------------------------------------------------------------------------
    self._phyPowerText = self:GetUIComponent("UILocalizationText", "PhyPowerText")
    self._diamondText = self:GetUIComponent("UILocalizationText", "DiamondText")
    ---@type UILocalizationText
    self._playerNameText = self:GetUIComponent("UILocalizationText", "PlayerName")
    self._playerIDText = self:GetUIComponent("UILocalizationText", "PlayerID")
    self._levelText = self:GetUIComponent("UILocalizationText", "Level")
    self._dynamicText = self:GetUIComponent("UILocalizationText", "dynamicText")
    self._staticText = self:GetUIComponent("UILocalizationText", "staticText")
    self._staticRect = self:GetUIComponent("RectTransform", "static")
    self._dynamicRect = self:GetUIComponent("RectTransform", "dynamic")
    ---@type UnityEngine.RectTransform
    self._staticAndDynamicImg = self:GetUIComponent("RectTransform", "dsbar")
    -----------------------------------------------------------------------------
    self._missionName = self:GetUIComponent("RollingText", "missionName")
    self._missionName1 = self:GetUIComponent("RollingText", "missionName1")
    self._missionLockTex = self:GetUIComponent("UILocalizationText", "missionLockTex")
    self._taskTipText = self:GetUIComponent("UILocalizationText", "TaskTip")
    self._missionOneBtnMode = self:GetGameObject("missionOneBtnMode")
    self._missionTwoBtnMode = self:GetGameObject("missionTwoBtnMode")
    self._oneBtnModeLeftTextGo = self:GetGameObject("oneBtnModeLeftText")

    self._twoBtnModeMissionName = self:GetUIComponent("UILocalizationText", "twoBtnModeMissionName")
    self._twoBtnModeMissionName1 = self:GetUIComponent("UILocalizationText", "twoBtnModeMissionName1")
    -----------------------------------------------------------------------------
    self._questNew = self:GetGameObject("questNew")
    self._questRed = self:GetGameObject("questRed")
    self._questNumber = self:GetUIComponent("UILocalizationText", "questNumber")
    self._cardNew = self:GetGameObject("cardNew")
    self._noticeRed = self:GetGameObject("NoticeRed")
    self._noticeRed:SetActive(false)
    -----------------------------------------------------------------------------
    self._voiceTex = self:GetUIComponent("UILocalizationText", "voiceTex")
    -----------------------------------------------------------------------------
    self._questFinishImg = self:GetUIComponent("Image", "finishImg")
    self._questFinishImg2 = self:GetGameObject("finish2Img")
    self._goMask = self:GetGameObject("mask")
    self._questDescTex = self:GetUIComponent("RollingText", "storyQuestDesc")
    self._questDescTexBottom = self:GetUIComponent("RollingText", "storyQuestDescBottom")

    ------------------------------------------------------------------------------------------
    self._aircraftAwardCountGo = self:GetGameObject("aircraftAwardGo")
    self._aircraftAwardCountText = self:GetUIComponent("UILocalizationText", "aircraftAwardCountTex")
    ----------------------
    self._homeAwardCountGo = self:GetGameObject("homeAwardGo")
    self._homeAwardCountText = self:GetUIComponent("UILocalizationText", "homeAwardCountTex")
    ------------------------------------------------------------------------------------------
    self._gambleIcon = self:GetUIComponent("RawImageLoader", "gambleIcon")
    self._gambleNew = self:GetGameObject("gambleNew")
    -- self._gambleRed = self:GetGameObject("gambleRed")
    self._gambleFreeMul = self:GetGameObject("gambleFreeMul")
    self._gambleFreeSin = self:GetGameObject("gambleFreeSin")
    ------------------------------------------------------------------------------------------
    ---@type UnityEngine.CanvasGroup
    self._voiceCanvasGroup = self:GetUIComponent("CanvasGroup", "VOICE")
    self._voiceGo = self:GetGameObject("VOICE")

    self._staticDynamicGo = self:GetGameObject("Btns")

    --获取功能解锁需要的组件
    self._photoNameEnLabel = self:GetUIComponent("UILocalizationText", "PhotoNameEn")
    self._photoNameChLabel = self:GetUIComponent("UILocalizationText", "PhotoNameCh")
    self._laborNameEnLabel = self:GetUIComponent("UILocalizationText", "LaborNameEn")
    self._laborNameChLabel = self:GetUIComponent("UILocalizationText", "LaborNameCh")
    ---------------------------------------------------
    self._phyTime = self:GetGameObject("phyTime")
    self._phyTimeCanvasGroup = self:GetUIComponent("CanvasGroup", "phyTime")
    self._nextTime = self:GetUIComponent("UILocalizationText", "nextTime")
    self._allTime = self:GetUIComponent("UILocalizationText", "allTime")
    ---------------------------------------------------
    ---@type UnityEngine.Animation
    self._voiceAnim = self:GetUIComponent("Animation", "VOICE")
    self._backPackRedGO = self:GetGameObject("backpack_red")
    self._photoRedGO = self:GetGameObject("photoRed")

    --head
    self._head_bg = self:GetUIComponent("UICircleMaskLoader", "headbg")
    self._head_icon = self:GetUIComponent("RawImageLoader", "head")
    self._head_icon_rect = self:GetUIComponent("RectTransform", "head")
    self._head_frame_rect = self:GetUIComponent("RectTransform", "headFrame")
    self._head_frame = self:GetUIComponent("RawImageLoader", "headFrame")
    self._head_bg_rect = self:GetUIComponent("RectTransform", "headbg")
    self._head_root_rect = self:GetUIComponent("RectTransform", "headRoot")
    self._head_bg_mask_rect = self:GetUIComponent("RectTransform", "headbgmask")
    self._head_dan_badge_gen = self:GetUIComponent("UISelectObjectPath", "DanBadgeSimpleGen")
    self._head_dan_badge_gen_go = self:GetGameObject("DanBadgeSimpleGen")
    self._head_dan_badge_gen_rect = self:GetUIComponent("RectTransform", "DanBadgeSimpleGen")
    --称号&纹饰
    self._title_icon = self:GetUIComponent("RawImageLoader", "title")
    self._playerInfoRedPoint = self:GetGameObject("playerInfoRedPoint")

    self._weChatRedGO = self:GetGameObject("weChatRed")
    self._weChatCountGO = self:GetGameObject("weChatCount")
    self._weChatCountTxt = self:GetUIComponent("UILocalizationText", "weChatCountTxt")
    self._weChatTalkGO = self:GetGameObject("wechattalk")
    self._weChatTalkTxt = self:GetUIComponent("UILocalizationText", "wechattalktxt")
    self._weChatTalkAni = self:GetUIComponent("Animation", "wechattalk")
    self._weChatMainIcon = self:GetUIComponent("RawImageLoader", "wechatmainicon")

    self._friendRedGo = self:GetGameObject("friendRed")

    self._questGo = self:GetGameObject("questGo")
    self._questNoGo = self:GetGameObject("questNoGo")

    self._signInRed = self:GetGameObject("signInRed")

    self._playerInfoAnim = self:GetUIComponent("Animation", "playerInfoAnim")

    ---@type UnityEngine.UI.Image
    self._img11 = self:GetUIComponent("Image", "img11")
    ---@type UnityEngine.UI.Image
    self._img12 = self:GetUIComponent("Image", "img12")
    ---@type UnityEngine.UI.Image
    self._img13 = self:GetUIComponent("Image", "img13")
    ---@type UnityEngine.UI.Image
    self._img14 = self:GetUIComponent("Image", "img14")
    ---@type UnityEngine.UI.Image
    self._img21 = self:GetUIComponent("Image", "img21")
    ---@type UnityEngine.UI.Image
    self._img22 = self:GetUIComponent("Image", "img22")

    self._mainBg = self:GetUIComponent("RawImageLoader", "bg")
    self._mainBgRect = self:GetUIComponent("RectTransform", "bg")
    self._mainBg2Rect = self:GetUIComponent("RectTransform", "bg2")
    self._mainBgAlpha1 = self:GetUIComponent("CanvasGroup", "bg")
    self._mainBg2 = self:GetUIComponent("RawImageLoader", "bg2")
    self._mainBgAlpha2 = self:GetUIComponent("CanvasGroup", "bg2")
    self._bgRoot = self:GetUIComponent("RectTransform", "bgRoot")

    local shopPool = self:GetUIComponent("UISelectObjectPath", "shop")
    ---@type UIMainLobbyBtnShop
    self.shop = shopPool:SpawnObject("UIMainLobbyBtnShop")

    --world boss red point
    self._oneBtnRedPoint = self:GetGameObject("OneBtnRedPoint")
    self._twoBtnRedPoint = self:GetGameObject("TwoBtnRedPoint")
    ---------------------------------------------------------------cg spine
    self._cgGo = self:GetGameObject("cg")
    self._cg = self:GetUIComponent("RawImageLoader", "cg")
    self._spineGo = self:GetGameObject("spine")
    self._spine = self:GetUIComponent("SpineLoader", "spine")

    self._enterSpineGo = self:GetGameObject("enter_spine")
    self._enterSpine = self:GetUIComponent("SpineLoader", "enter_spine")
    self._enterSpineSubGoGen = self:GetUIComponent("UISelectObjectPath", "enterSpineSubGo")
    self._enterSpineSubGo = self:GetGameObject("enterSpineSubGo")
    self._enterSpineGoShowFinish = true
    
    ---------------------------------------------------传说光灵
    self.talePetRedPoint = self:GetGameObject("talePetRedPoint")
    self.canConvene = self:GetGameObject("canConvene")
    self.canConceneImg = self:GetUIComponent("RawImageLoader", "canConvene")
    self.talePetImg = self:GetUIComponent("Image", "talePetImg")
    self.btnTalePetName = self:GetUIComponent("UILocalizationText", "btnTaleName")
    self.btnTalePet = self:GetUIComponent("Button", "btnTalePet")
    self._screenShot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_TalePet)
    if isLock == false then
        local IsCanDo = self._talePetModule:IsCanDo()
        if IsCanDo then
            GameGlobal.TaskManager():StartTask(self.RefreshCanConvene, self)
        end
    end

    self:TalePetRedPointController()

    --顶部和banner的灯�??
    -- local topLight = self:GetUIComponent("UISelectObjectPath", "topLight")
    -- topLight:SpawnObject("UIMainLobbyLightTop")
    -- local bannerLight = self:GetUIComponent("UISelectObjectPath", "bannerLight")
    -- bannerLight:SpawnObject("UIMainLobbyLightBanner")

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        self._homeObj = self:GetGameObject("home")
        self._homeObj:SetActive(false)
        self._questLeft = self:GetUIComponent("RectTransform", "questLeft")
        self._questLeft.anchoredPosition = Vector2(0, 0)
    end

    self:SetMainLightUI()
end
function UIMainLobbyController:SetMainLightUI()
    local showLight = Cfg.cfg_global["ShowMainLightUI"].IntValue
    if not showLight then
        return
    end
    ---@type UISelectObjectPath
    local light_1 = self:GetUIComponent("UISelectObjectPath","light03_1")
    light_1:SpawnObject("UIMainLobbyLight03CommonTop")
    local light_2 = self:GetUIComponent("UISelectObjectPath","light03_2")
    light_2:SpawnObject("UIMainLobbyLight03Common")
    local light_3 = self:GetUIComponent("UISelectObjectPath","light03_3")
    light_3:SpawnObject("UIMainLobbyLight03Common")
    local light_4 = self:GetUIComponent("UISelectObjectPath","light03_4")
    light_4:SpawnObject("UIMainLobbyLight03Common")
    local light_5 = self:GetUIComponent("UISelectObjectPath","light03_5")
    light_5:SpawnObject("UIMainLobbyLight03Common")
    local light_6 = self:GetUIComponent("UISelectObjectPath","light03_6")
    light_6:SpawnObject("UIMainLobbyLight03Common")
    local light_7 = self:GetUIComponent("UISelectObjectPath","light03_7")
    light_7:SpawnObject("UIMainLobbyLight03Common")
    local light_8 = self:GetUIComponent("UISelectObjectPath","light03_8")
    light_8:SpawnObject("UIMainLobbyLight03Common")
    local light_9 = self:GetUIComponent("UISelectObjectPath","light03_9")
    light_9:SpawnObject("UIMainLobbyLight03CommonDown")
end
function UIMainLobbyController:PlayMatsTween()
    ---@type UnityEngine.Material[]
    local mats = {
        self._img11.material,
        self._img12.material,
        self._img13.material,
        self._img14.material,
        self._img21.material,
        self._img22.material
    }
    for i, mat in ipairs(mats) do
        local y = mat:GetTextureOffset("_EmissionTex").y
        mat:SetTextureOffset("_EmissionTex", Vector2(0, y))
        if i == 4 then
            mat:SetColor("_EmissionColor", Color(1, 1, 1, 1))
        else
            mat:SetColor("_EmissionColor", Color(1, 1, 1, 0.5))
        end
        local sequence = DG.Tweening.DOTween.Sequence()
        sequence:PrependInterval(0.1)
        sequence:Append(mat:DOOffset(Vector2(0.18, y), "_EmissionTex", 0.66))
        ---@type DG.Tweening.Tweener
        local t = mat:DOFade(0, "_EmissionColor", 0.4):SetDelay(0.17)
        sequence:Join(t)
    end
end

function UIMainLobbyController:_RefreshFriendRedStatus()
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    if socialModule:HaveNewMsg() or socialModule:HaveNewInvitation() then
        self._friendRedGo:SetActive(true)
    else
        self._friendRedGo:SetActive(false)
    end
end

function UIMainLobbyController:_OnValue()
    --主界面背�??
    self:ShowMainBg()

    self:BtnOnPress()
    --解锁
    self:_RefreshFunctionLockStatus()

    --检查光灵按钮红点
    self:CheckPetRed()

    --公告红点
    self:CheckNewNotice()
    --任务new
    self:CheckQuestNew()
    --任务红点
    self:CheckQuestRed()
    --检查邮件状�??
    self:_CheckMailStatus()
    --顶条,等级
    self:OnItemCountChange()

    --引导
    self:CheckGuideShow()
    self:_CheckGuide()

    --签到
    self:CheckSignIn()

    --当前助理
    self:ShowCurrentAssistant()

    --播放欢迎语音
    if self._playWelcome == true then
        self:WelcomeAudio()
    end

    --探索按钮模式
    self:ExploreMode()
    --关卡信息
    self:MissionInfo()

    --轮播
    self:InitScrollView()

    --任务
    self:QuestInfo()

    --风船红点
    self:CheckAircraftRed()
    --家园红点
    self:CheckHomeRed()
    --名片红点
    self:CheckPlayerInfoNew()
    --情报红点
    self:CheckPhotoNew()
    --抽卡红点
    self._gamebleBtn =
        UIMainLobbyBtnGamble:New(self._gambleIcon, self._gambleFreeMul, self._gambleFreeSin, self._gambleNew)
    --终端红点
    self:OnUpdateWeChatRed()
    self:OnUpdateWeChatMainTalk() -- 轮播

    self:SetBtnsSpacing()
    self:HideEnText()
    self:_CheckCutSceneOut()
    --world boss red point
    self:_CheckWoldBossRedPoint()
end

--主界面背�??
function UIMainLobbyController:ShowMainBg()
    self._mainBgID = self._roleModule:UI_GetMainBgID()
    if not Cfg.cfg_main_bg[self._mainBgID] then
        self._mainBgID = 1
    end
    local cfg_mainBg = Cfg.cfg_main_bg[self._mainBgID]
    if cfg_mainBg then
        local size = Vector2(2539, 1439)
        if cfg_mainBg.Size then
            size = Vector2(cfg_mainBg.Size[1], cfg_mainBg.Size[2])
        end
        self._bgRoot.sizeDelta = size

        self._mainBg:LoadImage(cfg_mainBg.BG)
    else
        Log.error("###[UIMainLobbyController] cfg_mainBg is nil ! id --> ", self._mainBgID)
    end
end
function UIMainLobbyController:OnMainLobbyHideAssistant(hideAs)
    self._staticDynamicGo:SetActive(not hideAs)
    self._cgSpineGo:SetActive(not hideAs)
    self._voiceGo:SetActive(not hideAs)
end
function UIMainLobbyController:SetAsActive(changeAsHide)
    if changeAsHide then
        --重新获取一�?
        local petid = self._roleModule:GetResId()
        self._assistantNull = false
        if petid and petid ~= 0 then
            if petid == -1 then
                self._assistantNull = true
            end
        end
        self._staticDynamicGo:SetActive(not self._assistantNull)
        self._cgSpineGo:SetActive(not self._assistantNull)
        self._voiceGo:SetActive(not self._assistantNull)
    end
end
--暂存主界面背�??
function UIMainLobbyController:SetMainBg(id, anim, isSaveBtn, save, changeAsHide)
    local cfg_mainBg
    local _id
    if id then
        _id = id
    else
        -- self._mainBgID
        _id = self._roleModule:UI_GetMainBgID()
    end
    cfg_mainBg = Cfg.cfg_main_bg[_id]
    if not cfg_mainBg then
        _id = 1
        cfg_mainBg = Cfg.cfg_main_bg[_id]
    end
    if cfg_mainBg then
        local realWidth = ResolutionManager.RealWidth()
        local realHeight = ResolutionManager.RealHeight()
        local safeArea = Vector2(realWidth, realHeight)
        self._bg_posOffset = Vector2(0, 0)
        self._bg_scaleOffset = 1

        self:SetAsActive(changeAsHide)
        if isSaveBtn then
            if save then
                -- 保存当前
                local open_id = GameGlobal.GameLogic():GetOpenId()
                local title = "MAIN_BG_OFFSET_"
                local key = title .. open_id .. "_" .. _id

                local value = self._deltaBgPos.x .. "|" .. self._deltaBgPos.y .. "|" .. self._deltaBgScale
                self._bg_posOffset = self._deltaBgPos
                self._bg_scaleOffset = self._deltaBgScale
                LocalDB.SetString(key, value)

                Log.debug("###[UIMainLobbyController] bgroot save change key[" .. key .. "],value[" .. value .. "].")
            end
        end
        --只有CG背景才
        if cfg_mainBg.Type == UIChooseAssistantBgType.Cg then
            --每选择一个背景，都要获取一下偏�?
            local open_id = GameGlobal.GameLogic():GetOpenId()
            local title = "MAIN_BG_OFFSET_"
            local key = title .. open_id .. "_" .. _id
            local pos_offset_str = LocalDB.GetString(key, "null")
            if pos_offset_str == "null" then
            else
                local strs = string.split(pos_offset_str, "|")
                local _x = tonumber(strs[1])
                local _y = tonumber(strs[2])
                self._bg_posOffset = Vector2(_x, _y)
                self._bg_scaleOffset = tonumber(strs[3])
            end
        end

        local size = Vector2(2539, 1439)
        if cfg_mainBg.Size then
            size = Vector2(size[1], size[2])
        end
        --如果size小于屏幕分辨率，则设为分辨率
        local rate_x = 1
        local rate_y = 1

        if size.x * self._bg_scaleOffset < safeArea.x then
            rate_x = size.x * self._bg_scaleOffset / safeArea.x
        end
        if size.y * self._bg_scaleOffset < safeArea.y then
            rate_y = size.y * self._bg_scaleOffset / safeArea.y
        end

        if rate_x < 1 or rate_y < 1 then
            local changex = true
            if rate_x < rate_y then
                changex = true
            else
                changex = false
            end
            if changex then
                self._bg_scaleOffset = self._bg_scaleOffset / rate_x
            else
                self._bg_scaleOffset = self._bg_scaleOffset / rate_y
            end
        end
        self._deltaBgPos = self._bg_posOffset
        self._deltaBgScale = self._bg_scaleOffset
        self._bgRoot.anchoredPosition = self._bg_posOffset
        self._bgRoot.localScale = Vector3(self._bg_scaleOffset, self._bg_scaleOffset, self._bg_scaleOffset)

        if anim then
            self:Lock("UIMainLobbyController:SetMainBg")
            self._mainBg2:LoadImage(cfg_mainBg.BG)
            self._mainBgAlpha1.alpha = 1
            self._mainBgAlpha2.alpha = 0
            self._mainBgAlpha1:DOFade(0, 0.25)
            self._mainBgAlpha2:DOFade(1, 0.25):OnComplete(
                function()
                    self._mainBg:LoadImage(cfg_mainBg.BG)
                    self._mainBgAlpha1.alpha = 1
                    self._mainBgAlpha2.alpha = 0
                    self:UnLock("UIMainLobbyController:SetMainBg")
                end
            )
        else
            -- if id then
            --     self._mainBgID = id
            -- end
            self._mainBg:LoadImage(cfg_mainBg.BG)
            self._mainBgAlpha1.alpha = 1
            self._mainBgAlpha2.alpha = 0
        end
    else
        Log.error("###[UIMainLobbyController] cfg_mainBg is nil ! id --> ", _id)
    end
end

--调整下方按钮间隔,字号变化在text�??
function UIMainLobbyController:SetBtnsSpacing()
    ---@type UnityEngine.UI.HorizontalLayoutGroup
    local btnLayout = self:GetUIComponent("HorizontalLayoutGroup", "btnLayout")
    local type = Localization.GetCurLanguage()
    local spacing = 59.66
    local right = 40
    if type == LanguageType.us then
        spacing = 0
        right = 12
    elseif type == LanguageType.kr then
        spacing = 45
        right = 15
    elseif type == LanguageType.pt or type == LanguageType.es or type == LanguageType.idn then
        spacing = 15
        right = -30
    elseif type == LanguageType.th then
        spacing = 45
        right = 40
    end
    btnLayout.spacing = spacing
    btnLayout.padding.right = right
end

--英文版本隐藏文本
function UIMainLobbyController:HideEnText()
    local eng = HelperProxy:GetInstance():IsInEnglish()
    if eng then
        local explorer_en_text = self:GetGameObject("explorer_en_text")
        local summon_en_text = self:GetGameObject("summon_en_text")
        local base_en_text = self:GetGameObject("base_en_text")
        local quest_en_text = self:GetGameObject("quest_en_text")

        explorer_en_text:SetActive(false)
        summon_en_text:SetActive(false)
        base_en_text:SetActive(false)
        quest_en_text:SetActive(false)
    end
end
--轮播
function UIMainLobbyController:InitScrollView()
    self._isDarging = false

    self._isScrollReady = false

    self._currIdx = 1

    self:_CreateScrollData()
    self:_CreateScrollItem()
    self:_CreateScrollEvent()

    self._isScrollReady = true
end
--
function UIMainLobbyController:_CreateScrollData()
    self._cfg_main_carousel = {}
    self._carouselTab = {}
    local tmp_cfg_main_carousel = {}
    local max = Cfg.cfg_global["MainBannerMaxCount"].IntValue or 6
    local cfg_main_c_all = Cfg.cfg_main_caroursel {}
    local _cfg_main_c_all = {}
    for key, value in pairs(cfg_main_c_all) do
        table.insert(_cfg_main_c_all, value)
    end
    table.sort(
        _cfg_main_c_all,
        function(a, b)
            return a.Order < b.Order
        end
    )

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        table.insert(self._cfg_main_carousel, Cfg.cfg_main_caroursel[101])
    else
        for i = 1, table.count(_cfg_main_c_all) do
            local info = _cfg_main_c_all[i]
            if not info.Minimum then
                local closeTime = info.CloseTime
                if info.IsResident then
                    closeTime = HelperProxy:GetInstance():ResidentTimeString()
                end

                if
                    self:_CheckMainCarourseEventIsOpen(
                        info.ModuleID,
                        info.OpenType,
                        info.OpenParam,
                        info.OpenTime,
                        closeTime,
                        info.PrivateZoneID
                    )
                 then
                    table.insert(tmp_cfg_main_carousel, info)
                end
            end
        end
    end

    --MSG39769	(QA_王忠智）N17_商店QA_banner增加显示上限20220412	5	QA-开发制作中	李学森, 1958	04/15/2022
    local insertCount
    if max > #tmp_cfg_main_carousel then
        insertCount = #tmp_cfg_main_carousel
    else
        insertCount = max
    end
    for i = 1, insertCount do
        local data = tmp_cfg_main_carousel[i]
        table.insert(self._cfg_main_carousel, data)
    end

    local count = table.count(self._cfg_main_carousel)
    if count == 0 then
        Log.debug("###[UIMainLobbyController] _cfg_main_carousel count == 0 ! minimum start !")
        --有保�??
        local minimumCfg = Cfg.cfg_main_caroursel {Minimum = 1}
        if minimumCfg and table.count(minimumCfg) > 0 then
            table.insert(self._cfg_main_carousel, minimumCfg[1])
        end
    end

    count = table.count(self._cfg_main_carousel)

    if count == 0 then
        Log.error("###mainlobby cfg_main_caroursel count == 0")
    end

    self._count = count

    local cfg_item_left = {}
    cfg_item_left.idx = 1
    cfg_item_left.data = self._cfg_main_carousel[self._count]

    table.insert(self._carouselTab, cfg_item_left)

    for i = 1, self._count do
        local cfg_item_middle = {}
        cfg_item_middle.idx = i + 1
        cfg_item_middle.data = self._cfg_main_carousel[i]

        table.insert(self._carouselTab, cfg_item_middle)
    end

    local cfg_item_right = {}
    cfg_item_right.idx = self._count + 1
    cfg_item_right.data = self._cfg_main_carousel[1]

    table.insert(self._carouselTab, cfg_item_right)
end

function UIMainLobbyController:_CreateScrollItem()
    --idxUI----------------
    self._grid = self:GetUIComponent("UISelectObjectPath", "grid")
    self._grid:SpawnObjects("UIIdxItem", self._count)
    ---@type UIIdxItem[]
    self._idxItems = self._grid:GetAllSpawnList()
    for i = 1, #self._idxItems do
        self._idxItems[i]:SetData(i, self._currIdx)
    end
    ------------------------------------------------------------------------------------------
    --轮播view的初始位置（首位+1�??
    --首尾分别设置了数据的最后一个和第一个，循环�??
    --当滑到首位（数据的最后一个）时，修改content的位置到末尾前一位（数据的最后一个）
    --当滑到末尾（数据的第一个）时，修改content的位置到首位的后一位（数据的第一个）
    --形成循环，不适用scrollrect，scrollrect会控制content的位�??

    self._content = self:GetUIComponent("RectTransform", "Content")
    self._scroll = self:GetGameObject("scroll")
    self._width = 579 --593
    self._targetPosX = self._currIdx * self._width * -1

    ---------------------------------------------------
    if self._spRequest ~= nil then
        self._spRequest:Dispose()
        self._spRequest = nil
    end
    self._spRequest = ShopPriceRequest:New()
    local itemPool = self:GetUIComponent("UISelectObjectPath", "Content")
    itemPool:ClearWidgets()
    itemPool:SpawnObjects("UIScrollItem", #self._carouselTab)
    ---@type UIScrollItem[]
    local items = itemPool:GetAllSpawnList()
    for i = 1, #self._carouselTab do
        items[i]:SetData(
            self._carouselTab[i],
            function(idx)
                GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_Advertising_" .. idx}, true)
                local jumpType = self._carouselTab[idx].data.JumpType
                local jumpParam = self._carouselTab[idx].data.JumpParam
                if jumpType then
                    ---@type UIJumpModule
                    local jumpModule = self._questModule.uiModule
                    jumpModule:SetJumpUIData(jumpType, jumpParam)
                    jumpModule:Jump()
                end
            end,
            function(eventData)
                if self._count <= 1 then
                    return
                end
                self._bDragPosX = eventData.position.x
                self._isDarging = true
                if self._scrollEvent then
                    -- Log.error(" cancel")
                    --拖拽中不计时
                    GameGlobal.Timer():CancelEvent(self._scrollEvent)
                    self._scrollEvent = nil
                end

                self._tmpContentPosX = self._content.anchoredPosition.x
            end,
            function(eventData)
                if self._count <= 1 then
                    return
                end
                local _x = eventData.delta.x
                self._content.anchoredPosition = Vector2(self._content.anchoredPosition.x + _x, 0)
                if self._content.anchoredPosition.x > self._width * -0.5 then
                    self._content.anchoredPosition =
                        Vector2(self._content.anchoredPosition.x - self._count * self._width, 0)
                end

                if self._content.anchoredPosition.x <= -(self._count * self._width + self._width * 0.5) then
                    self._content.anchoredPosition =
                        Vector2(self._content.anchoredPosition.x + self._count * self._width, 0)
                end
            end,
            function(eventData)
                if self._count <= 1 then
                    return
                end
                local posx = math.abs(self._content.anchoredPosition.x)
                local c, d = math.modf(posx / self._width)

                local tmpIdx = self._currIdx
                self._eDragPosX = eventData.position.x

                if self._eDragPosX < self._bDragPosX then
                    --左滑超过1/5
                    if d > 0.1 then
                        tmpIdx = c + 1
                    else
                        tmpIdx = c
                    end
                else
                    --右滑超过1/5
                    if d < 0.9 then
                        tmpIdx = c
                    else
                        tmpIdx = c + 1
                    end
                end

                if tmpIdx > self._count then
                    self._currIdx = tmpIdx % self._count
                elseif tmpIdx <= 0 then
                    self._currIdx = self._count
                else
                    self._currIdx = tmpIdx
                end

                for i = 1, #self._idxItems do
                    self._idxItems[i]:Flush(self._currIdx)
                end

                self._targetPosX = self:_CalcPosX(tmpIdx)
                self._isDarging = false
                self:_CreateScrollEvent()
            end
        )

        items[i]:BookPrice(self._spRequest)
    end
end

function UIMainLobbyController:_CreateScrollEvent()
    local deltaTime = 5000
    --方向,�??
    local dir = 1

    if self._scrollEvent then
        Log.debug("###main -- the scrollEvent is has attach ! ")
        GameGlobal.Timer():CancelEvent(self._scrollEvent)
        self._scrollEvent = nil
    end

    if self._count > 1 then
        Log.debug("###main - attach")
        self._scrollEvent =
            GameGlobal.Timer():AddEventTimes(
            deltaTime,
            TimerTriggerCount.Infinite,
            function()
                if not self._isDarging then
                    local idx = self._currIdx
                    if dir == 1 then
                        idx = self._currIdx + 1
                    else
                        idx = self._currIdx - 1
                    end
                    if idx < 1 then
                        idx = self._count
                    elseif idx > self._count then
                        idx = 1
                    end
                    self._currIdx = idx

                    for i = 1, #self._idxItems do
                        self._idxItems[i]:Flush(self._currIdx)
                    end

                    self._targetPosX = self:_CalcPosX(self._currIdx)
                end
            end
        )
    end
end
function UIMainLobbyController:_CalcPosX(idx)
    local posx = 0
    if not idx or self._count <= 1 then
        return posx
    end
    posx = idx * self._width
    return -posx
end

function UIMainLobbyController:BtnOnPress()
    self._backpackImg = self:GetUIComponent("Image", "backpackImg")
    self._laborImg = self:GetUIComponent("Image", "laborImg")
    self._photoImg = self:GetUIComponent("Image", "photoImg")
    self._teamImg = self:GetUIComponent("Image", "teamImg")
    self._heartImg = self:GetUIComponent("Image", "heartImg")

    self._backpackBtn = self:GetUIComponent("Button", "backpackBtn")
    self._laborBtn = self:GetUIComponent("Button", "laborBtn")
    self._photoBtn = self:GetUIComponent("Button", "photoBtn")
    self._teamBtn = self:GetUIComponent("Button", "teamBtn")
    self._heartBtn = self:GetUIComponent("Button", "heartBtn")
    ------------------------------------------------------------------------------------------
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._backpackBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._backpackImg.sprite = self._atlas:GetSprite("main_zjm_icon17")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._backpackBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._backpackImg.sprite = self._atlas:GetSprite("main_zjm_icon16")
        end
    )
    ------------------------------------------------------------------------------------------
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._laborBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._laborImg.sprite = self._atlas:GetSprite("main_zjm_icon19")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._laborBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._laborImg.sprite = self._atlas:GetSprite("main_zjm_icon18")
        end
    )
    ------------------------------------------------------------------------------------------
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._photoBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._photoImg.sprite = self._atlas:GetSprite("main_zjm_icon21")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._photoBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._photoImg.sprite = self._atlas:GetSprite("main_zjm_icon20")
        end
    )
    ------------------------------------------------------------------------------------------
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._teamBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._teamImg.sprite = self._atlas:GetSprite("main_zjm_icon23")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._teamBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._teamImg.sprite = self._atlas:GetSprite("main_zjm_icon22")
        end
    )
    ------------------------------------------------------------------------------------------
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._heartBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._heartImg.sprite = self._atlas:GetSprite("main_zjm_icon25")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._heartBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._heartImg.sprite = self._atlas:GetSprite("main_zjm_icon24")
        end
    )
end

--探索按钮模式 单按�?? 双按�??
function UIMainLobbyController:ExploreMode()
    local oneBtnMode = true
    if self._latestCampObj then
        ---@type UICustomWidgetPool
        local sop = self:GetUIComponent("UISelectObjectPath", "missionRight")
        ---@type UIMainLobbyCampaignEnter
        local pool = sop:SpawnObject("UIMainLobbyCampaignEnter")
        oneBtnMode = pool:Flush(self, self._latestCampObj)
    end

    self._missionOneBtnMode:SetActive(oneBtnMode)
    self._missionTwoBtnMode:SetActive(not oneBtnMode)
    self._oneBtnModeLeftTextGo:SetActive(oneBtnMode)
end

--关卡信息
function UIMainLobbyController:MissionInfo()
    local discoveryData = self._missionModule:GetDiscoveryData()
    if not discoveryData then
        Log.fatal("### DiscoveryData nil.")
        return
    end
    local _, canPlayNode = discoveryData:GetCanPlayChapterNode()
    if not canPlayNode then --敬请期待
        local count = 0
        if EngineGameHelper.EnableAppleVerifyBulletin() then
            -- 审核服环境
            count = 2
        else
            --统计所有主线章节数
            for _, chapter in pairs(discoveryData.chapters) do
                local section = discoveryData:GetDiscoverySectionByChapterId(chapter.id)
                if not section.isBetween then
                    count = count + 1
                end
            end
        end
        local str = StringTable.Get("str_main_lobby_finish", count + 1)
        self._missionName:RefreshText(str)
        self._missionName1:RefreshText(str)
        --双按钮模�?? 文本暂时同步设置
        self._twoBtnModeMissionName:SetText(str)
        self._twoBtnModeMissionName1:SetText(str)
        self._missionLockTex.gameObject:SetActive(false)
    else
        local canPlayStages = canPlayNode:GetCanPlayStages()
        local currentMissionID = canPlayStages[1].id
        local missionName = "1-1"
        local cfg_mission = Cfg.cfg_mission[currentMissionID]
        if cfg_mission then
            missionName = StringTable.Get(cfg_mission.Name)
        end
        local missionIndex = DiscoveryStage.GetStageIndexString(currentMissionID)
        local strMissionName = missionIndex .. " " .. missionName
        self._missionName:RefreshText(strMissionName)
        self._missionName1:RefreshText(strMissionName)

        local twoModeStr = strMissionName
        local twoModeBackStr = strMissionName
        local lvU = cfg_mission.NeedLevel
        local lvN = self._roleModule:GetLevel()
        if lvU > lvN then
            self._missionLockTex.gameObject:SetActive(true)
            local lockStr = "[" .. lvU .. StringTable.Get("str_main_lobby_mission_lock") .. "]"
            self._missionLockTex:SetText(lockStr)
            twoModeStr = twoModeStr .. "<color=#feee1a>" .. lockStr .. "</color>"
            twoModeBackStr = twoModeBackStr .. lockStr
        else
            self._missionLockTex.gameObject:SetActive(false)
        end

        --双按钮模�?? 文本暂时同步设置
        self._twoBtnModeMissionName:SetText(twoModeStr)
        self._twoBtnModeMissionName1:SetText(twoModeBackStr)
    end
end

--任务信息
function UIMainLobbyController:QuestInfo()
    if self._questLock then
        return
    end

    self:CheckQuestNew()
    self:CheckQuestRed()

    local currChapter = self._questModule:GetMainQuestChapterID()

    self._questGo:SetActive(currChapter ~= nil)
    self._questNoGo:SetActive(currChapter == nil)

    if currChapter == nil then
        return
    end
    local questList = self._questModule:GetChapterQuests(currChapter)
    ---@type MobileQuestInfo
    self._quest = nil
    for i = 1, table.count(questList) do
        local qtemp = questList[i]:QuestInfo()
        if qtemp.status == QuestStatus.QUEST_NotStart then
            break
        end
        self._quest = qtemp
        if self._quest.status ~= QuestStatus.QUEST_Taken then
            break
        end
    end
    self._questGo:SetActive(self._quest ~= nil)
    self._questNoGo:SetActive(self._quest == nil)

    if self._quest == nil then
        return
    end
    if self._quest.status == QuestStatus.QUEST_Completed then
        self._questFinishImg.sprite = self._atlas:GetSprite("main_zjm_icon32")
        self._questFinishImg2:SetActive(true)
    elseif self._quest.status == QuestStatus.QUEST_Accepted then
        self._questFinishImg.sprite = self._atlas:GetSprite("main_zjm_icon31")
        self._questFinishImg2:SetActive(false)
    end
    self._goMask:SetActive(false)
    local strQuestDesc = StringTable.Get(self._quest.CondDesc)
    self._questDescTex:RefreshText(strQuestDesc)
    self._questDescTexBottom:RefreshText(strQuestDesc)
    self._goMask:SetActive(true)
end

--等级,经验,Name
function UIMainLobbyController:PlayerInfo()
    local nPlayerLevel = 0
    local nPlayerExp = self._roleModule:GetRoleExp()
    nPlayerLevel = HelperProxy:GetInstance():GetLvByExp(nPlayerExp)
    self._levelText:SetText(nPlayerLevel)
    local expPercent = 0
    if nPlayerLevel == HelperProxy:GetInstance():GetMaxLevel() then
        expPercent = 1
    else
        local curLvExp = HelperProxy:GetInstance():GetLevelExp(nPlayerLevel)
        local nextLvExp = HelperProxy:GetInstance():GetLevelExp(nPlayerLevel + 1)
        local deltaExp = nextLvExp - curLvExp
        if deltaExp > 0 then
            expPercent = (nPlayerExp - curLvExp) / deltaExp
        end
    end
    ---@type ArtFont
    local txtFilling = self._levelText.gameObject:GetComponent("ArtFont")
    txtFilling.Division = expPercent

    local len = HelperProxy:GetInstance():GetCharLength(self._roleModule:GetName())
    local size = 32
    if len > 10 then
        size = 31
    else
        size = 40
    end
    self._playerNameText.fontSize = size
    self._playerNameText:SetText(self._roleModule:GetName())
    local showid = self._loginModule:GetRoleShowID()
    if not showid then
        return
    end
    self._playerIDText:SetText("ID:" .. showid)

    self:PlayerHeader()
    self:PlayerTitle()
end

function UIMainLobbyController:PlayerTitle()
    -- local playerInfo = self._roleModule:UI_GetPlayerInfo()
    -- self._title_icon
end

function UIMainLobbyController:PlayerHeader()
    local playerInfo = self._roleModule:UI_GetPlayerInfo()
    local headIcon = playerInfo.m_nHeadImageID
    local cfg_header = Cfg.cfg_role_head_image[headIcon]
    if cfg_header then
        self._head_icon:LoadImage(cfg_header.Icon)
        HelperProxy:GetInstance():GetHeadIconSizeWithTag(self._head_icon_rect, cfg_header.Tag)
    else
        Log.fatal("###main - cfg_header is nil ! id - ", headIcon)
    end

    local headFrame = playerInfo.m_nHeadFrameID
    if not headFrame or headFrame == 0 then
        headFrame = HelperProxy:GetInstance():GetHeadFrameDefaultID()
    end
    local cfg_head_frame = Cfg.cfg_role_head_frame[headFrame]
    self._head_frame:LoadImage(cfg_head_frame.Icon)

    HelperProxy:GetInstance():GetHeadBgSizeWithTag(self._head_bg_rect)
    HelperProxy:GetInstance():GetHeadBgMaskSizeWithTag(self._head_bg_mask_rect)
    HelperProxy:GetInstance():GetHeadFrameSizeWithTag(self._head_frame_rect)
    HelperProxy:GetInstance():GetHeadRootSizeWithTag(self._head_root_rect, RoleHeadFrameSizeType.Size2)

    local headBg = playerInfo.m_nHeadColorID
    local cfg_head_bg = Cfg.cfg_player_head_bg[headBg]
    if not cfg_head_bg then
        cfg_head_bg = Cfg.cfg_player_head_bg[1]
    end
    self._head_bg:LoadImage(cfg_head_bg.Icon)

    --世界boss段位徽章
    UIWorldBossHelper.InitSelfDanBadgeSimple(
        self._head_dan_badge_gen,
        self._head_dan_badge_gen_go,
        self._head_dan_badge_gen_rect
    )
end

--检查新公告
function UIMainLobbyController:CheckNewNotice()
    if SDKProxy:GetInstance():IsInternationalSDK() then
        if NoNoticeOut then
            local noticeGo = self:GetGameObject("noticeGo")
            noticeGo:SetActive(false)
            return
        end
    end
    local state = self._roleModule:CheckModuleUnlock(GameModuleID.MD_Notify)
    if state == false then
        self._noticeRed:SetActive(false)
        return
    end

    ---@type NoticeData
    self._noticeData = self._loginModule:GetNoticeData()
    if self._noticeData == nil then
        Log.fatal("###main notice data is nil !")
        return
    end

    self:CheckNoticeRed()
end
function UIMainLobbyController:CheckNoticeRed()
    if self._noticeData == nil then
        return
    end
    local systemState = self._noticeData:GetNoticeNewStateWithGroup(NoticeType.System)
    local activeState = self._noticeData:GetNoticeNewStateWithGroup(NoticeType.Active)
    self._noticeRed:SetActive(systemState or activeState)
end

--显示当前助理
function UIMainLobbyController:ShowCurrentAssistant()
    self:SetBgRootPosAndScale()

    --(pet_grade,skin_id)
    local petid = self._roleModule:GetResId()

    local old_pet_id = self._defaultPetID
    --看板娘为�??
    self._assistantNull = false
    self._defaultPetID = 0
    local grade
    local skin
    local asid
    if petid and petid ~= 0 then
        self._defaultPetID = petid
        if petid == -1 then
            self._assistantNull = true
        end
        grade = self._roleModule.m_choose_painting.pet_grade
        skin = self._roleModule.m_choose_painting.skin_id
        asid = self._roleModule.m_choose_painting.board_pet
    else
        --获取spine设置
        self._defaultPetID = Cfg.cfg_global["main_default_spine_pet_id"].IntValue
        grade = 0
        skin = 0
        asid = 0
    end
    self._assistantGrade = grade
    self._assistantSkinID = skin
    self._assistantAsID = asid

    self._staticDynamicGo:SetActive(not self._assistantNull)
    self._cgSpineGo:SetActive(not self._assistantNull)
    self._voiceGo:SetActive(not self._assistantNull)
    if self._assistantNull then
        --如果是空，直接隐�??
        return
    end

    if old_pet_id ~= self._defaultPetID then
        local playPetID

        if old_pet_id and old_pet_id ~= 0 then
            playPetID = old_pet_id
        else
            playPetID = self._defaultPetID
        end
        -- self._petAudioModule:RequestAdx2VoiceCueSheetByAnyAudioId("MainLobbyInteract", playPetID)
        self:PlayPetAudio("MainLobbyInteract")
    end

    local petModule = self:GetModule(PetModule)
    local cfg_pet
    if grade > 0 then
        cfg_pet = Cfg.cfg_pet_grade {PetID = self._defaultPetID, Grade = grade}[1]
    else
        cfg_pet = Cfg.cfg_pet[self._defaultPetID]
    end

    ---@type MatchPet
    if cfg_pet then
        --看板娘qa
        --如果有看板娘的话显示看板�??
        if asid and asid ~= 0 then
            local cfg_as = Cfg.cfg_only_assistant[asid]
            if not cfg_as then
                Log.error("###[UIMainLobbyController] cfg_as is nil ! id --> ", asid)
            end
            self._dynamicSpineSettings = cfg_as.Spine
            self._staticSpineSettings = cfg_as.CG
        else
            --时装还没应用
            self._dynamicSpineSettings = nil
            self._dynamicSpineSettings =
                HelperProxy:GetInstance():GetMainLobbySpine(
                self._defaultPetID,
                grade,
                skin,
                PetSkinEffectPath.NO_EFFECT
            )
            self._enterSpineName = HelperProxy:GetInstance():GetMainLobbyEnterSpine(
                self._defaultPetID,
                grade,
                skin,
                PetSkinEffectPath.NO_EFFECT
            )
            Log.debug("[lobbyspine] _enterSpineName ",self._enterSpineName)
            self._enterSpineSubGoName = HelperProxy:GetInstance():GetMainLobbyEnterSpineSubGo(
                self._defaultPetID,
                grade,
                skin,
                PetSkinEffectPath.NO_EFFECT
            )
            if not self._dynamicSpineSettings then
                self._dynamicSpineSettings =
                    HelperProxy:GetInstance():GetPetSpine(self._defaultPetID, grade, skin, PetSkinEffectPath.NO_EFFECT)
            end

            --时装还没应用
            self._staticSpineSettings = nil
            self._staticSpineSettings =
                HelperProxy:GetInstance():GetMainLobbyStaticBody(
                self._defaultPetID,
                grade,
                skin,
                PetSkinEffectPath.NO_EFFECT
            )
            if not self._staticSpineSettings then
                self._staticSpineSettings =
                    HelperProxy:GetInstance():GetPetStaticBody(
                    self._defaultPetID,
                    grade,
                    skin,
                    PetSkinEffectPath.NO_EFFECT
                )
            end
        end
    else
        Log.fatal("cfg_pet is nil!")
        self._dynamicSpineSettings = self._defaultPetID .. "_spine_idle"
        self._staticSpineSettings = self._defaultPetID .. "_cg"
    end

    --获取设置，设置bg
    local flagValue = self._roleModule:GetExtFlag(CharExtFlag.CEFT_MAIN_UI_SHOW_SPINE)
    --默认false
    if flagValue then
        self._cgState = DynamicAndStaticState.Static
    else
        self._cgState = DynamicAndStaticState.Dynamic
    end
    self:ChangeDynamicAndStatic(self._cgState)
    self:SetRootPosAndScale()
end

--玩家自定义偏�??
function UIMainLobbyController:SetRootPosAndScale()
    --获取玩家设置的偏�??
    self._posOffset = Vector2(0, 0)
    self._scaleOffset = 1

    local open_id = GameGlobal.GameLogic():GetOpenId()
    local title = "MAIN_OFFSET_"
    local key = title .. open_id .. "_" .. self._staticSpineSettings

    local pos_offset_str = LocalDB.GetString(key, "null")
    if pos_offset_str == "null" then
    else
        local strs = string.split(pos_offset_str, "|")
        local _x = tonumber(strs[1])
        local _y = tonumber(strs[2])
        self._posOffset = Vector2(_x, _y)
        self._scaleOffset = tonumber(strs[3])
    end
    local size = Vector2(2048, 2048)
    if self._assistantSkinID and self._assistantSkinID > 0 then
        local cfg = Cfg.cfg_pet_skin[self._assistantSkinID]
        if cfg then
            local mainSize = cfg.MainLobbySize
            if mainSize then
                size = Vector2(mainSize[1], mainSize[2])

                local realWidth = ResolutionManager.RealWidth()
                local realHeight = ResolutionManager.RealHeight()
                local safeArea = Vector2(realWidth, realHeight)

                --如果size小于屏幕分辨率，则设为分辨率
                local rate_x = 1
                local rate_y = 1

                if size.x * self._scaleOffset < safeArea.x then
                    rate_x = size.x * self._scaleOffset / safeArea.x
                end
                if size.y * self._scaleOffset < safeArea.y then
                    rate_y = size.y * self._scaleOffset / safeArea.y
                end

                if rate_x < 1 or rate_y < 1 then
                    local changex = true
                    if rate_x < rate_y then
                        changex = true
                    else
                        changex = false
                    end
                    if changex then
                        self._scaleOffset = self._scaleOffset / rate_x
                    else
                        self._scaleOffset = self._scaleOffset / rate_y
                    end
                end
            end
        end
    end

    Log.debug("###[UIMainLobbyController] cgroot -- " .. self._staticSpineSettings .. "|" .. pos_offset_str)

    self._changePetPosAndScaleRoot.anchoredPosition = self._posOffset
    self._changePetPosAndScaleRoot.localScale = Vector3(self._scaleOffset, self._scaleOffset, self._scaleOffset)
    self._changePetPosAndScaleRoot.sizeDelta = size
    self._deltaPos = self._posOffset
    self._deltaScale = self._scaleOffset
end
function UIMainLobbyController:SetBgRootPosAndScale()
    -----------------------------------------------------------------------------bg
    self._bg_posOffset = Vector2(0, 0)
    self._bg_scaleOffset = 1
    self._currentMainBgID = self._roleModule:UI_GetMainBgID()
    local cfg_mainBg = Cfg.cfg_main_bg[self._currentMainBgID]
    if not cfg_mainBg then
        cfg_mainBg = Cfg.cfg_main_bg[1]
    end
    local size = Vector2(2539, 1439)
    if cfg_mainBg.Size then
        size = Vector2(size[1], size[2])
    end
    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()
    local safeArea = Vector2(realWidth, realHeight)

    --只有CG背景才
    if cfg_mainBg.Type == UIChooseAssistantBgType.Cg then
        local open_id = GameGlobal.GameLogic():GetOpenId()
        local title = "MAIN_BG_OFFSET_"
        local key = title .. open_id .. "_" .. self._currentMainBgID
        local pos_offset_str = LocalDB.GetString(key, "null")
        if pos_offset_str == "null" then
        else
            local strs = string.split(pos_offset_str, "|")
            local _x = tonumber(strs[1])
            local _y = tonumber(strs[2])
            self._bg_posOffset = Vector2(_x, _y)
            self._bg_scaleOffset = tonumber(strs[3])
        end
    end

    local rate_x = 1
    local rate_y = 1

    if size.x * self._bg_scaleOffset < safeArea.x then
        rate_x = size.x * self._bg_scaleOffset / safeArea.x
    end
    if size.y * self._bg_scaleOffset < safeArea.y then
        rate_y = size.y * self._bg_scaleOffset / safeArea.y
    end

    if rate_x < 1 or rate_y < 1 then
        local changex = true
        if rate_x < rate_y then
            changex = true
        else
            changex = false
        end
        if changex then
            self._bg_scaleOffset = self._bg_scaleOffset / rate_x
        else
            self._bg_scaleOffset = self._bg_scaleOffset / rate_y
        end
    end

    self._bgRoot.anchoredPosition = self._bg_posOffset
    self._bgRoot.localScale = Vector3(self._bg_scaleOffset, self._bg_scaleOffset, self._bg_scaleOffset)
    self._deltaBgPos = self._bg_posOffset
    self._deltaBgScale = self._bg_scaleOffset
    self._bgRoot.sizeDelta = size
end
function UIMainLobbyController:ChangeCgRootPos(type, pos)
    if type == UIChooseAssistantType.Bg2MainLobby then
        -- 改背�?(不保存，等待保存事件)
        self._deltaBgPos = pos
        self._bgRoot.anchoredPosition = self._deltaBgPos
    elseif type == UIChooseAssistantType.Cg2MainLobby then
        -- 改立�?(直接保存)
        self._deltaPos = pos
        self._changePetPosAndScaleRoot.anchoredPosition = self._deltaPos
    end
end
function UIMainLobbyController:ChangeCgRootScale(type, scale)
    if type == UIChooseAssistantType.Bg2MainLobby then
        -- 改背�?(不保存，等待保存事件)
        self._deltaBgScale = scale
        self._bgRoot.localScale = Vector3(self._deltaBgScale, self._deltaBgScale, self._deltaBgScale)
    elseif type == UIChooseAssistantType.Cg2MainLobby then
        -- 改立�?(直接保存)
        self._deltaScale = scale
        self._changePetPosAndScaleRoot.localScale = Vector3(self._deltaScale, self._deltaScale, self._deltaScale)
    end
end
function UIMainLobbyController:OnShowChangeMainCg(show)
    if show then
        self._canvasGroupUiAnim.alpha = 0.5
    else
        self._canvasGroupUiAnim.alpha = 1
    end
end
function UIMainLobbyController:SaveCancelChangeCgRoot(type, saveOrCancel)
    if type == UIChooseAssistantType.Bg2MainLobby then
        -- 改背�?(不保存，等待保存事件)
    elseif type == UIChooseAssistantType.Cg2MainLobby then
        -- 改立�?(直接保存)
        if saveOrCancel == UIChooseAssistantState.Save then
            -- 保存当前
            self._posOffset = self._deltaPos
            self._scaleOffset = self._deltaScale

            local open_id = GameGlobal.GameLogic():GetOpenId()
            local title = "MAIN_OFFSET_"
            local key = title .. open_id .. "_" .. self._staticSpineSettings

            local value = self._posOffset.x .. "|" .. self._posOffset.y .. "|" .. self._scaleOffset
            LocalDB.SetString(key, value)

            Log.debug("###[UIMainLobbyController] cgroot save change key[" .. key .. "],value[" .. value .. "].")
        elseif saveOrCancel == UIChooseAssistantState.Cancel then
            -- 回到上次保存
            Log.debug("###[UIMainLobbyController] cgroot cancel change !")
            self:SetRootPosAndScale()
        elseif saveOrCancel == UIChooseAssistantState.Default then
            -- 回到默认
            self._deltaPos = Vector2(0, 0)
            self._deltaScale = 1

            self._changePetPosAndScaleRoot.anchoredPosition = self._deltaPos
            self._changePetPosAndScaleRoot.localScale = Vector3(self._deltaScale, self._deltaScale, self._deltaScale)
        end
    end
end

--更换助理
function UIMainLobbyController:chooseAssistantBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_ChooseAssistantController"}, true)
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_CHANGE_ASSISTANT)
        end
    )
    self:ShowDialog("UIChooseAssistantController")
end

--引导
function UIMainLobbyController:CheckGuideShow()
    local module = self:GetModule(MissionModule)
    local discoveryData = module:GetDiscoveryData()
    local chapters = discoveryData:GetVisibleChapters()
    local needChapter = Cfg.cfg_guide_const["guide_discovery_btn_chapter"].IntValue
    if chapters and table.count(chapters) < needChapter then
        if not GuideHelper.GuideInProgress() then
            if self._discoveryGuideGO then
                self._discoveryGuideGO:SetActive(true)
            end
        else
            if self._discoveryGuideGO then
                self._discoveryGuideGO:SetActive(false)
            end
        end
    else
        if self._discoveryGuideGO then
            self._discoveryGuideGO:SetActive(false)
        end
    end
end

function UIMainLobbyController:ShowGuideStep(param)
    self._discoveryGuideGO:SetActive(false)
end

function UIMainLobbyController:GuideDone()
    self:CheckGuideShow()
end

function UIMainLobbyController:UIClose()
    self:CheckGuideShow()
end

--弹出签到
function UIMainLobbyController:CheckSignIn()
    --签到红点
    ---累计登录奖励
    local showRed = self._signInModule:HaveTotalLoginReward()
    ---补签
    if not showRed then
        showRed = self._signInModule:IsReSignInToday()
    end

    self._signInRed:SetActive(showRed)
end

--刷新顶条数量
function UIMainLobbyController:OnItemCountChange()
    --[[
    直接拖上去了，没有用公共图集的资源，直接可以用主界面的图�??
        -- MSG8480 主界面右上货币使用单独icon --不用了现�??
        local uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
        self._goldIcon.sprite = uiCommonAtlas:GetSprite("toptoon_3000002")
        self._powerIcon.sprite = uiCommonAtlas:GetSprite("toptoon_3000001")
        self._diamondIcon.sprite = uiCommonAtlas:GetSprite("toptoon_3000003")
        ]]
    --灯盏
    self._diamondText:SetText(self._roleModule:GetGlow())

    self:ShowPhyPoint()
    --gold
    local count = self._roleModule:GetGold()
    self._goldText:SetText(HelperProxy:GetInstance():FormatGold(count))

    --等级,经验,Name
    self:PlayerInfo()

    --检查光灵按钮红点
    self:CheckPetRed()

    --成就点现在放在这个事件里
    self:QuestInfo()
    --背包红点
    self:CheckBackPackNew()
    --情报红点
    self:CheckPhotoNew()
end

--体力
function UIMainLobbyController:ShowPhyPoint()
    local currentPhyPower = self._roleModule:GetHealthPoint()
    if currentPhyPower == nil then
        currentPhyPower = 0
    end
    local currentPhysicalPowerUpper = self._roleModule:GetHpLevelMax()
    if currentPhysicalPowerUpper == nil then
        currentPhysicalPowerUpper = 0
    end

    local moreThan = false
    if currentPhyPower > currentPhysicalPowerUpper then
        moreThan = true
    end
    if currentPhyPower > 999 then
        currentPhyPower = "999+"
    end
    if moreThan then
        currentPhyPower = "<color=#00ffea>" .. currentPhyPower .. "</color>"
    end
    self._phyPowerText:SetText(currentPhyPower .. "/" .. currentPhysicalPowerUpper)
end

function UIMainLobbyController:AddListener()
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:AttachEvent(GameEventType.RolePropertyChanged, self.OnItemCountChange)
    self:AttachEvent(GameEventType.QuestUpdate, self.QuestInfo)
    self:AttachEvent(GameEventType.AircraftRedPoint, self.CheckAircraftRed)
    self:AttachEvent(GameEventType.CheckCardNew, self.CheckCardNew)
    self:AttachEvent(GameEventType.CheckCardAwakeRedPoint, self.OnItemCountChange)
    self:AttachEvent(GameEventType.RefreshMailStatus, self._CheckMailStatus)
    self:AttachEvent(GameEventType.ModuleMailNotifyNewMail, self._CheckMailStatus)
    self:AttachEvent(GameEventType.OnAssistantChanged, self.OnAssistantChanged)
    --self:AttachEvent(GameEventType.CheckNoticeNew, self.CheckNewNotice)
    self:AttachEvent(GameEventType.ShowGuideStep, self.ShowGuideStep)
    self:AttachEvent(GameEventType.GuideDone, self.GuideDone)
    self:AttachEvent(GameEventType.UIClose, self.UIClose)
    self:AttachEvent(GameEventType.OnUIPetObtainCloseInMain, self.OnUIPetObtainCloseInMain)
    self:AttachEvent(GameEventType.ClosePetAudio, self.ClosePetAudio)
    self:AttachEvent(GameEventType.OnNoticeDataCheckNew, self.CheckNoticeRed)
    self:AttachEvent(GameEventType.NoticeBackPackRed, self.CheckBackPackNew)
    --self:AttachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.OnChapcterInfoChanged, self.PlayerInfo)
    self:AttachEvent(GameEventType.OnPlayerHeadInfoChanged, self.PlayerHeader)
    self:AttachEvent(GameEventType.OnPlayerChangeHeadBadgeClick, self.PlayerHeader)
    self:AttachEvent(GameEventType.OnPlayerTitleInfoChanged, self.PlayerTitle)
    self:AttachEvent(GameEventType.OnPlayerInfoOpen, self.OnPlayerInfoOpen)
    self:AttachEvent(GameEventType.UpdateWeChatRed, self.OnUpdateWeChatRed)
    self:AttachEvent(GameEventType.UpdateWeChatMainTalk, self.OnUpdateWeChatMainTalk)

    self:AttachEvent(GameEventType.ModuleFriendNotifyNewMsg, self._RefreshFriendRedStatus)
    self:AttachEvent(GameEventType.UpdateFriendInvitation, self._RefreshFriendRedStatus)
    self:AttachEvent(GameEventType.ChangeMainBg, self.SetMainBg)

    self:AttachEvent(GameEventType.OnMainLobbyHideAssistant, self.OnMainLobbyHideAssistant)

    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnAfterUILayerChanged)
    self:AttachEvent(GameEventType.TalePetRedStatusChange, self.TalePetRedPointController)
    self:AttachEvent(GameEventType.TalePetInfoDataChange, self.ChangeTaleInfo)

    self:AttachEvent(GameEventType.MainLobbyAutoOpenTryFail, self.OnAutoOpenListFail)

    self:AttachEvent(GameEventType.OnMainCgChangePos, self.ChangeCgRootPos)
    self:AttachEvent(GameEventType.OnMainCgChangeScale, self.ChangeCgRootScale)
    self:AttachEvent(GameEventType.OnMainCgChangeSave, self.SaveCancelChangeCgRoot)
    self:AttachEvent(GameEventType.OnShowChangeMainCg, self.OnShowChangeMainCg)

    self:AttachEvent(GameEventType.RefreshPlayerInfoRedPoint, self.CheckPlayerInfoNew)
    self:AttachEvent(GameEventType.WatchPetSkinStory, self.OnItemCountChange)
    
    self:AttachEvent(GameEventType.OnSeasonQuestRedUpdate, self.QuestInfo)
end

function UIMainLobbyController:OnAfterUILayerChanged()
    local topui = GameGlobal.UIStateManager():IsTopUI(self:GetName())
    if topui then
        self:InitScrollView()
        --引导不弹窗暂�??
        if GuideHelper.GuideInProgress() then
            return
        end

        self:ShowOpenList()

        self:CheckSignIn()

        --显示终端解锁的音�?
        self:ShowChatUnLockBGM()

        if self._spRequest ~= nil then
            self._spRequest:Request()
        end
    end
end
function UIMainLobbyController:ShowChatUnLockBGM()
    ---@type UIMainModule
    local uiMainModule = self:GetUIModule(SignInModule)
    local unlockBGMs = uiMainModule:GetUnLockBGMs()
    if unlockBGMs and next(unlockBGMs) then
        local bgm = unlockBGMs[1]
        uiMainModule:RemoveBGM1()
        local title = ""
        local title_en = ""
        local cfg = Cfg.cfg_role_music[bgm]
        if not cfg then
            Log.error("###[UIMainLobbyController] cfg is nil ! id --> ", bgm)
        else
            title = StringTable.Get("str_main_lobby_un_lock_music_tips", StringTable.Get(cfg.Name))
        end
        self:ShowDialog("UIAircraftUnlockFileController", title, title_en, true)
    end
end
function UIMainLobbyController:CheckShowAutoPop()
    local topui = GameGlobal.UIStateManager():IsTopUI(self:GetName())
    if topui then
        --引导不弹窗暂�??
        if GuideHelper.GuideInProgress() then
            return
        end
        self:ShowOpenList()
    end
end
function UIMainLobbyController:ShowOpenList()
    ---@type UIMainModule
    local uiMainModule = self:GetUIModule(SignInModule)
    local openList = uiMainModule:GetOpenList()
    if not openList or table.count(openList) <= 0 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.MainLobbyOpenListFinish)
        return
    end

    if table.count(openList) > 1 then
        table.sort(
            openList,
            function(a, b)
                local a_order = 0
                local b_order = 0
                local cgf_a = Cfg.cfg_main_open_list {UIType = a.ID}
                if cgf_a then
                    a_order = cgf_a[1].Order
                end
                local cgf_b = Cfg.cfg_main_open_list {UIType = b.ID}
                if cgf_b then
                    b_order = cgf_b[1].Order
                end
                return a_order > b_order
            end
        )
    end

    local idx = 0
    while idx < #openList do
        idx = idx + 1
        local openData = openList[idx]
        local open = false

        if openData.OpenState == UIMainOpenState.DayOnce then
            local dayOpen, open_id, svr_time = self:CheckDayOnceOpen(openData.ID)
            if dayOpen then
                open = openData.CheckFunc()
                if open then
                    LocalDB.SetString("ui_main_login_time_" .. open_id .. "_" .. openData.ID, tostring(svr_time))
                end
            end
        elseif openData.OpenState == UIMainOpenState.Once then
            if openData.OpenTimes == 0 then
                open = openData.CheckFunc()
                if open then
                    openData.OpenTimes = 1
                end
            end
        elseif openData.OpenState == UIMainOpenState.Times then
            open = openData.CheckFunc()
        end

        if open then
            return
        end
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.MainLobbyOpenListFinish)
end

function UIMainLobbyController:OnAutoOpenListFail()
    Log.debug("#OpenList# OnAutoOpenListFail")
    if self._delayCheckAutoPopEvent ~= nil then
        GameGlobal.Timer():CancelEvent(self._delayCheckAutoPopEvent)
        self._delayCheckAutoPopEvent = nil
    end
    self._delayCheckAutoPopEvent =
        GameGlobal.RealTimer():AddEvent(
        1,
        function()
            self:CheckShowAutoPop()
        end
    )
end
function UIMainLobbyController:CheckDayOnceOpen(dataid)
    local hourOffset = 5
    --检查跨�??
    --local next_zero_time = 1619020800
    local cfg_open_list = Cfg.cfg_main_open_list {UIType = dataid}
    local isZeroTime = false
    if cfg_open_list then
        if cfg_open_list[1].IsZeroTime then
            isZeroTime = true
        end
        hourOffset = cfg_open_list[1].TimeOffset
    end
    local next_zero_time
    if isZeroTime then
        -- Log.error("###[UIMainLobbyController] next_zero_time = self._loginModule:GetGMTNextZeroTime() !!!")
        --next_zero_time = self._loginModule:GetNextZeroTime()
        --------------------------------------------------------------------
        next_zero_time = self._loginModule:GetGMTNextZeroTime()
    else
        next_zero_time = self._loginModule:GetNextZeroTime()
    end

    --5写在lua里，后面修改频繁再改为读配置
    next_zero_time = next_zero_time + (hourOffset - 24) * 60 * 60
    local svr_time = math.modf(self._svrTimeModule:GetServerTime() * 0.001)
    local open_id = GameGlobal.GameLogic():GetOpenId()
    local db_value = LocalDB.GetString("ui_main_login_time_" .. open_id .. "_" .. dataid, "empty")
    if db_value == "empty" then
        --LocalDB.SetString("ui_main_login_time_" .. open_id .. "_" .. dataid, tostring(svr_time))
        return true, open_id, svr_time
    else
        local last_time = tonumber(db_value)
        if svr_time > next_zero_time then
            if last_time < next_zero_time then
                --LocalDB.SetString("ui_main_login_time_" .. open_id .. "_" .. dataid, tostring(svr_time))
                return true, open_id, svr_time
            else
                return false
            end
        else
            if svr_time - last_time >= 86400 then
                return true, open_id, svr_time
            end
        end
    end
end

function UIMainLobbyController:CheckQuestRedPoint()
    self:QuestInfo()
end

function UIMainLobbyController:RemoveListener()
    --[[底层已经处理
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:DetachEvent(GameEventType.CheckCardNew, self.CheckCardNew)
    self:DetachEvent(GameEventType.RolePropertyChanged, self.OnItemCountChange)
    self:DetachEvent(GameEventType.RefreshMailStatus, self._CheckMailStatus)
    self:DetachEvent(GameEventType.ModuleMailNotifyNewMail, self._CheckMailStatus)
    self:DetachEvent(GameEventType.OnAssistantChanged, self.OnAssistantChanged)
    self:DetachEvent(GameEventType.AircraftRedPoint, self.CheckAircraftRed)
    self:DetachEvent(GameEventType.CheckNoticeNew, self.CheckNewNotice)
    self:DetachEvent(GameEventType.ShowGuideStep, self.ShowGuideStep)
    self:DetachEvent(GameEventType.GuideDone, self.GuideDone)
    self:DetachEvent(GameEventType.UIClose, self.UIClose)
    --]]
end

function UIMainLobbyController:OnHide()
    if self._btnUpAnimTask then
        if self._btnUpAnimTask then
            GameGlobal.TaskManager():KillTask(self._btnUpAnimTask)
            self._btnUpAnimTask = nil
        end
    end
    if self._startPhyTimerEvent ~= nil then
        GameGlobal.RealTimer():CancelEvent(self._startPhyTimerEvent)
        self._startPhyTimerEvent = nil
    end

    if self._startPhyTimerLoopEvent ~= nil then
        GameGlobal.RealTimer():CancelEvent(self._startPhyTimerLoopEvent)
        self._startPhyTimerLoopEvent = nil
    end

    self:RemoveListener()

    if self._showTimeEvent then
        GameGlobal.RealTimer():CancelEvent(self._showTimeEvent)
        self._showTimeEvent = nil
    end

    if self._phyEvent then
        GameGlobal.RealTimer():CancelEvent(self._phyEvent)
        self._phyEvent = nil
    end

    Log.debug("###main - OnHide")
    if self._scrollEvent then
        Log.debug("###main - cancel")

        GameGlobal.Timer():CancelEvent(self._scrollEvent)
        self._scrollEvent = nil
    end

    if self._voiceTween then
        self._voiceTween:Kill()
    end
    self._voiceTween = nil
    self._audioPlayID = nil
    self._content = nil
    if self._event then
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end
    self:StopWeChatTalkTimer() --停止终端轮播说话
    AudioHelperController.ReleaseUISoundById(CriAudioIDConst.AircraftBtnClick)
    if self._defaultPetID and self._defaultPetID ~= 0 then
        self._petAudioModule:ReleaseAdx2VoiceCueSheetByAnyAudioId("MainLobbyInteract", self._defaultPetID)
    end

    if self.conveneDelay then
        GameGlobal.RealTimer():CancelEvent(self.conveneDelay)
        self.conveneDelay = nil
    end
    if self._monthcardRefreshEvent ~= nil then
        GameGlobal.Timer():CancelEvent(self._monthcardRefreshEvent)
        self._monthcardRefreshEvent = nil
    end
    if self._delayCheckAutoPopEvent ~= nil then
        GameGlobal.Timer():CancelEvent(self._delayCheckAutoPopEvent)
        self._delayCheckAutoPopEvent = nil
    end

    if self._spineEvent then
        GameGlobal.Timer():CancelEvent(self._spineEvent)
        self._spineEvent = nil
    end
    if self._enterSpineSubGoCloseEvent then
        GameGlobal.Timer():CancelEvent(self._enterSpineSubGoCloseEvent)
        self._enterSpineSubGoCloseEvent = nil
    end

    if self._spRequest ~= nil then
        self._spRequest:Dispose()
        self._spRequest = nil
    end

    self:ClosePhyTimer()
end

--更换助理
function UIMainLobbyController:OnAssistantChanged(petid, grade, skin, as)
    self._spineLoaded = false
    self._cgLoaded = false
    self._enterSpine:DestroyCurrentSpine()
    self:ShowCurrentAssistant()

    --播放语音功能从助理界面移动到这里
    --另外添加显示语音文本
    self._audioPlayID = self:PlayPetAudio("Appointment")
    if self._audioPlayID == nil then
        return
    end
    self._voiceAnim:Play("uieff_mainlobby_voice")
    local cfg_audio = AudioHelperController.GetCfgAudio(self._audioPlayID)
    if cfg_audio then
        self._voiceTex:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(cfg_audio.Content)))
    end
end

--检查邮件状�??
function UIMainLobbyController:_CheckMailStatus()
    local mailUnReadGo = self:GetGameObject("MailUnRead")
    local mailModule = GameGlobal.GetModule(MailModule)
    local hasNewMail = mailModule:HaveNewMail()
    mailUnReadGo:SetActive(hasNewMail)
end

--新卡
function UIMainLobbyController:CheckCardNew()
    local active = false
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    active = petModule:CheckNewPetForMainUI() or petModule:CheckRefineRedForMainUI()
    self._cardNew:SetActive(active)
end

function UIMainLobbyController:CheckPetRed()
    local isShow = false
    --检查新卡
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    isShow = petModule:CheckNewPetForMainUI() or petModule:CheckRefineRedForMainUI()
    if not isShow then
        --检查觉醒和皮肤
        local pets = petModule:GetPets()
        for _,pet in pairs(pets) do
            -- local isAweak = pet:IsShowRedPoint()
            local isSkin = pet:IsShowSkinRedPoint()
            local isRed = isSkin
            if isRed then
                isShow = true
                break
            end
        end
    end
    self._cardNew:SetActive(isShow)
end

--任务new
function UIMainLobbyController:CheckQuestNew()
    ---@type QuestModule
    local questModule = GameGlobal.GetModule(QuestModule)
    local new = questModule:GetNewPoint()
    self._questNew:SetActive(new)
end

--任务红点
function UIMainLobbyController:CheckQuestRed()
    if self._questUnLock == false then
        self._questRed:SetActive(false)
    else
        ---@type QuestModule
        local questModule = GameGlobal.GetModule(QuestModule)

        local questNumber = questModule:GetRedPointNum()

        if questNumber and questNumber > 0 then
            self._questRed:SetActive(true)
            self._questNumber:SetText(questNumber)
        else
            self._questRed:SetActive(false)
        end
    end
end

--风船红点状�?
function UIMainLobbyController:CheckAircraftRed()
    local aircraftModule = self:GetModule(AircraftModule)
    local count = aircraftModule:GetCollectTypeCount()
    self._aircraftAwardCountGo:SetActive(count > 0)
    if count > 0 then
        self._aircraftAwardCountText:SetText(count)
    end
end
--家园红点
function UIMainLobbyController:CheckHomeRed()
    local homeModule = self:GetModule(HomelandModule)
    local count = homeModule:GetMainRedCount()
    self._homeAwardCountGo:SetActive(count > 0)
    if count > 0 then
        self._homeAwardCountText:SetText(count)
    end
end
--新卡
function UIMainLobbyController:CheckBackPackNew()
    local itemModule = self:GetModule(ItemModule)
    local hasNew = itemModule:HasNew()
    self._backPackRedGO:SetActive(hasNew)
end

function UIMainLobbyController:CheckPhotoNew()
    -- local uiMedalModule = self:GetModule(MedalModule):GetUIModule()
    -- local hasNew = uiMedalModule:IsMedalNew() or uiMedalModule:IsMedalBoardNew()
    self._photoRedGO:SetActive(false)
end

--角色名片红点
function UIMainLobbyController:CheckPlayerInfoNew()
    local itemModule = self:GetModule(ItemModule)
    local hasNew = itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Title, true) and itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Fifure, true)
    self._playerInfoRedPoint:SetActive(hasNew)
end

--解锁
function UIMainLobbyController:_RefreshFunctionLockStatus()
    self.shop:FlushLockStatus() --商店
    --家园
    local s = self:GetUIComponent("UISelectObjectPath", "homeLock")
    ---@type UIFunctionLockButton
    local homeButtonFunction = s:SpawnObject("UIFunctionLockButton")
    homeButtonFunction:SetFunctionType(GameModuleID.MD_HomeLand, ButtonLockType.MaskAndTips, nil, MaskShowType.Big)
    --风船
    local s = self:GetUIComponent("UISelectObjectPath", "BaseFunctionLock")
    ---@type UIFunctionLockButton
    local baseButtonFunction = s:SpawnObject("UIFunctionLockButton")
    baseButtonFunction:SetFunctionType(GameModuleID.MD_Aircraft, ButtonLockType.MaskAndTips, nil, MaskShowType.Big)
    --公告
    local s = self:GetUIComponent("UISelectObjectPath", "NoticeBtn")
    local expressionButtonFunction = s:SpawnObject("UIFunctionLockButton")
    expressionButtonFunction:SetFunctionType(GameModuleID.MD_Notify, ButtonLockType.OnlyTips)
    --邮件
    local s = self:GetUIComponent("UISelectObjectPath", "MailBtn")
    local mailButtonFunction = s:SpawnObject("UIFunctionLockButton")
    mailButtonFunction:SetFunctionType(GameModuleID.MD_Mail, ButtonLockType.OnlyTips)
    --工会
    local s = self:GetUIComponent("UISelectObjectPath", "LaborFunctionLock")
    local mailButtonFunction = s:SpawnObject("UIFunctionLockButton")
    mailButtonFunction:SetFunctionType(
        GameModuleID.MD_Guild,
        ButtonLockType.MaskAndTips,
        nil,
        MaskShowType.Small,
        function()
            --lock
            self._laborNameEnLabel.color = Color(1, 1, 1, 0.08)
            self._laborNameChLabel.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
            self._laborImg.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
        end,
        function()
            --unlock
            self._laborNameEnLabel.color = Color(1, 1, 1, 55 / 255)
            self._laborNameChLabel.color = Color(1, 1, 1, 1)
            self._laborImg.color = Color(1, 1, 1, 1)
        end
    )
    --图鉴
    local s = self:GetUIComponent("UISelectObjectPath", "PhotoFunctionLock")
    local mailButtonFunction = s:SpawnObject("UIFunctionLockButton")
    mailButtonFunction:SetFunctionType(
        GameModuleID.MD_HandBook,
        ButtonLockType.MaskAndTips,
        nil,
        MaskShowType.Small,
        function()
            --lock
            self._photoNameEnLabel.color = Color(1, 1, 1, 0.08)
            self._photoNameChLabel.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
            self._photoImg.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
        end,
        function()
            --unlock
            self._photoNameEnLabel.color = Color(1, 1, 1, 55 / 255)
            self._photoNameChLabel.color = Color(1, 1, 1, 1)
            self._photoImg.color = Color(1, 1, 1, 1)
        end
    )
    --任务
    local s = self:GetUIComponent("UISelectObjectPath", "QuestFunctionLock")
    local mailButtonFunction = s:SpawnObject("UIFunctionLockButton")
    mailButtonFunction:SetFunctionType(GameModuleID.MD_QuestEntry, ButtonLockType.MaskAndTips, nil, MaskShowType.Big)
    --召唤
    local s = self:GetUIComponent("UISelectObjectPath", "SummonFunctionLock")
    local mailButtonFunction = s:SpawnObject("UIFunctionLockButton")
    mailButtonFunction:SetFunctionType(GameModuleID.MD_Gamble, ButtonLockType.MaskAndTips, nil, MaskShowType.Big)
    --任务
    self:_CheckQuestLock()
    --终端系统
    --邮件
    local s = self:GetUIComponent("UISelectObjectPath", "weChatBtn")
    local weChatBtnFunction = s:SpawnObject("UIFunctionLockButton")
    weChatBtnFunction:SetFunctionType(GameModuleID.MD_WeChat, ButtonLockType.OnlyTips)

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        local talepet = self.btnTalePet.transform.parent
        UIHelper.SetActive(talepet, false)
        return
    end

    --传说光灵
    local s = self:GetUIComponent("UISelectObjectPath", "btnTalePet")
    local talePetButtonFunction = s:SpawnObject("UIFunctionLockButton")
    local talePetImg = self:GetUIComponent("Image", "talePetImg")
    local btnTaleNameEnLabel = self:GetUIComponent("UILocalizationText", "btnTaleNameEn")
    local btnTaleNameLabel = self:GetUIComponent("UILocalizationText", "btnTaleName")
    talePetButtonFunction:SetFunctionType(
        GameModuleID.MD_TalePet,
        ButtonLockType.MaskAndTips,
        nil,
        MaskShowType.Small,
        function()
            --lock
            btnTaleNameEnLabel.color = Color(1, 1, 1, 0.08)
            btnTaleNameLabel.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
            talePetImg.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
        end,
        function()
            --unlock
            btnTaleNameEnLabel.color = Color(1, 1, 1, 55 / 255)
            btnTaleNameLabel.color = Color(1, 1, 1, 1)
            talePetImg.color = Color(1, 1, 1, 1)
        end
    )
end

--动态静�??
function UIMainLobbyController:ChangeDynamicAndStatic(state)
    if self._dsTween then
        self._dsTween:Kill()
    end
    if state == DynamicAndStaticState.Dynamic then
        self:ShowDynamicSpine()
    else
        self:ShowStaticCG()
    end
end
function UIMainLobbyController:ShowStaticCG()
    
    local pos = self._staticRect.anchoredPosition
    self._dsTween = self._staticAndDynamicImg:DOAnchorPos(pos, 0.3):SetEase(DG.Tweening.Ease.InOutCubic)

    self._staticText.color = Color.black
    self._dynamicText.color = Color(99 / 255, 99 / 255, 99 / 255, 1)

    if not self._cgLoaded then
        local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue
        self._cgGo:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        self._cg:LoadImage(self._staticSpineSettings)
        local uicg = true
        local mainSize = nil
        if self._assistantSkinID and self._assistantSkinID > 0 then
            local cfg = Cfg.cfg_pet_skin[self._assistantSkinID]
            if cfg then
                mainSize = cfg.MainLobbySize
                if mainSize then
                    uicg = false
                end
            end
        end
            ---@type UnityEngine.RectTransform
        local cgRect = self._cgGo:GetComponent(typeof(UnityEngine.RectTransform))
        if uicg then
            local size = Vector2(2048, 2048)
            -- cgRect.anchorMin = Vector2(0.5,0.5)
            -- cgRect.anchorMax = Vector2(0.5,0.5)
            cgRect.sizeDelta = size
            UICG.SetTransform(self._cgGo.transform, self:GetName(), self._staticSpineSettings)
        else
            --锚在四周
            -- cgRect.anchorMin = Vector2(0,0)
            -- cgRect.anchorMax = Vector2(1,1)
            -- cgRect.sizeDelta = Vector2(0,0)
            --忘了为啥猫在四周了，改为设置大小为size，缩放为1
            local setSize
            if not mainSize then
                setSize = Vector2(2539, 1439)
            else
                setSize = Vector2(mainSize[1], mainSize[2])
            end
            cgRect.sizeDelta = setSize
            cgRect.anchoredPosition = Vector2(0, 0)
            cgRect.localScale = Vector3(1, 1, 1)
        end
        self._cgLoaded = true
    end

    self._cgGo:SetActive(true)
    self._spineGo:SetActive(false)
    self._enterSpineGo:SetActive(false)
    self._enterSpineSubGo:SetActive(false)
end
function UIMainLobbyController:ShowDynamicSpine()
    local pos = self._dynamicRect.anchoredPosition
    self._dsTween = self._staticAndDynamicImg:DOAnchorPos(pos, 0.3):SetEase(DG.Tweening.Ease.InOutCubic)

    self._dynamicText.color = Color.black
    self._staticText.color = Color(99 / 255, 99 / 255, 99 / 255, 1)

    if not self._spineLoaded then
        self._spine:LoadSpine(self._dynamicSpineSettings)
        if(self._enterSpineName ~= nil) then
            self._enterSpine:LoadSpine(self._enterSpineName)
            -- if self._enterSpineSubGoName ~= nil then
            --     if self._enterSpineSubGoGen then
            --         self._enterSpineSubGoGen.dynamicInfoOfEngine:SetObjectName(self._enterSpineSubGoName)
            --         self._enterSpineSubGoGen:SpawnObject("UIMainLobbyEnterSpineSubGo")
            --     end
            -- end
        end
        local uicg = true
        if self._assistantSkinID and self._assistantSkinID > 0 then
            local cfg = Cfg.cfg_pet_skin[self._assistantSkinID]
            if cfg then
                local mainSize = cfg.MainLobbySize
                if mainSize then
                    uicg = false
                end
            end
        end
        if uicg then
            UICG.SetTransform(self._spineGo.transform, self:GetName(), self._dynamicSpineSettings)
            if(self._enterSpineName ~= nil) then
                UICG.SetTransform(self._enterSpineGo.transform, self:GetName(), self._enterSpineName)
            end
        else
            self._spineGo.transform.localPosition = Vector3(0, 0, 0)
            self._spineGo.transform.localScale = Vector3(1, 1, 1)
            self._enterSpineGo.transform.localPosition = Vector3(0, 0, 0)
            self._enterSpineGo.transform.localScale = Vector3(1, 1, 1)
            
        end
        self._spineLoaded = true
    end
   

    self._spineGo:SetActive(true)
    self._cgGo:SetActive(false)

    --在这里处理高级时装的特殊spine动画，入场和切换动态静�?
    self:ShowLobbyEnterSpine()
end
function UIMainLobbyController:PlayNoLoopSpineWithCallBack(spineSke,spinename,spineAnim,func)
    local entry
    local playAniSpineFunc = function()
        spineSke:Initialize(true)
        entry = spineSke.AnimationState:SetAnimation(0, spineAnim, false)
    end
    local succ = pcall(playAniSpineFunc)
    if not succ then
        Log.error(
            "###[UIMainLobbyController] set spine anim fail ! spine[",
            spinename,
            "] anim[",
            spineAnim,
            "]"
        )
        return
    end
    if not entry then
        Log.error(
            "###[UIMainLobbyController] entry is nil ! spine[",
            spinename,
            "] anim[",
            spineAnim,
            "]"
        )
        return
    end
    local anim = entry.Animation
    local duration = anim.Duration
    local yieldTime = math.floor(duration * 1000)
    
    if self._spineEvent then
        GameGlobal.Timer():CancelEvent(self._spineEvent)
        self._spineEvent = nil
    end
    self._spineEvent =
        GameGlobal.Timer():AddEvent(
        yieldTime,
        func
    )
end
function UIMainLobbyController:ShowLobbyEnterSpine() 
    
    self._enterSpineGo:SetActive(false)
    self._enterSpineSubGo:SetActive(false)
     ---@type Spine.Unity.SkeletonGraphic
     self._spineSke = self._spine.CurrentSkeleton
     if not self._spineSke then
         ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
         self._spineSke = self._spine.CurrentMultiSkeleton
     end

     if not self._spineSke then
        Log.debug(
            "###[UIMainLobbyController] not self._spineSke spine --> ",
            self._dynamicSpineSettings
        )
        return
    end
    self._enterSpineSke = nil
    if(self._enterSpineName ~= nil) then
        self._enterSpineSke = self._enterSpine.CurrentSkeleton
        if not self._enterSpineSke then
         ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
         self._enterSpineSke = self._enterSpine.CurrentMultiSkeleton
        end

        if not self._enterSpineSke then
            Log.debug(
                "###[UIMainLobbyController] not self._enterSpineSke spine --> ",
                self._enterSpineName
            )
            return
        end
    end
    
    local skinid = self._assistantSkinID
    if(skinid == 0 or skinid == nil) then
        return 
    end
    local skin_cfg = Cfg.cfg_pet_skin[skinid]
    if(skin_cfg == nil) then
        return 
    end
    local spineAnim = skin_cfg.EnterAnim
    if spineAnim == nil then
        
        return 
    end

    self._playSpineAnim = true

    local loopSpinePlayFunc = function()
        self._playSpineAnim = false
        --默认的spine的动画必须叫idle
        local animationName = "idle"
        self._spineSke.AnimationState:SetAnimation(0, animationName, true)
    end

    local dynamicSpineSettings = self._dynamicSpineSettings
    
    local idleSpinePlayFunc = function()
        self._enterSpineGo:SetActive(false)
        self:_DelayHideEnterSpineSubGo()--特效晚一会儿关闭
        if(dynamicSpineSettings == self._dynamicSpineSettings) then
            self:PlayNoLoopSpineWithCallBack(self._spineSke,self._dynamicSpineSettings,spineAnim,loopSpinePlayFunc)
        end
    end

    if self._enterSpineSke ~= nil then
        self._enterSpineGo:SetActive(true)
        self._enterSpineGoShowFinish = false
        self:PlayNoLoopSpineWithCallBack(self._enterSpineSke,self._enterSpineName,spineAnim,idleSpinePlayFunc)
        self._spineSke.startingAnimation = spineAnim
        local bShowSubGo = (self._enterSpineSubGoName ~= nil)
        if bShowSubGo then
            if self._enterSpineSubGoGen then
                if self._enterSpineSubGoName~=self._oldEnterSpineSubGoName and self._oldEnterSpineSubGoName~=nil then
                    --dispose
                    self._enterSpineSubGoGen:ClearWidgets()
                end
                self._enterSpineSubGoGen.dynamicInfoOfEngine:SetObjectName(self._enterSpineSubGoName)
                self._enterSpineSubGoGen:SpawnObject("UIMainLobbyEnterSpineSubGo")
                self._oldEnterSpineSubGoName = self._enterSpineSubGoName
            end
        end
        self._enterSpineSubGo:SetActive(bShowSubGo)
    else
        idleSpinePlayFunc()
    end
  
end
--配合高级时装入场spine的特效，可能会比入场动画稍微长一点，晚一点关
function UIMainLobbyController:_DelayHideEnterSpineSubGo()
    if self._enterSpineSubGoCloseEvent then
        GameGlobal.Timer():CancelEvent(self._enterSpineSubGoCloseEvent)
        self._enterSpineSubGoCloseEvent = nil
    end
    self._enterSpineSubGoCloseEvent =
        GameGlobal.Timer():AddEvent(
        1000,
        function()
            self._enterSpineSubGo:SetActive(false)
        end
    )
    self._enterSpineGoShowFinish = true
end
    
function UIMainLobbyController:OnGetExtData(TT, state)
    local roleModule = GameGlobal.GetModule(RoleModule)
    local flagValue = false
    if state == DynamicAndStaticState.Static then
        flagValue = true
    else
        flagValue = false
    end
    roleModule:SetExtFlag(TT, CharExtFlag.CEFT_MAIN_UI_SHOW_SPINE, flagValue)
end
--Add体力
function UIMainLobbyController:PhyPowerAddOnClick(go)
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_ADD_PHY)
        end
    )
    self:ShowDialog("UIGetPhyPointController")
end

function UIMainLobbyController:DiamondAddOnClick()
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_ADD_DIAMOND)
        end
    )
    GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", 0)
end

--tips
function UIMainLobbyController:GoldOnClick()
    local gold = self:GetGameObject("Gold")
    self._toptipsInfo:SetData(RoleAssetID.RoleAssetGold, gold)
end
function UIMainLobbyController:PhyPowerOnClick()
    local power = self:GetGameObject("PhyPower")
    self._toptipsInfo:SetData(RoleAssetID.RoleAssetPhyPoint, power)
end
function UIMainLobbyController:DiamondOnClick()
    local count = self._roleModule:GetGlow()
    if count<0 then
        PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal,
            PopupMsgBoxType.Ok,
            StringTable.Get("str_shop_resourceerror_title"),
            StringTable.Get("str_shop_resourceerror_desc"),
            function(param)
            end
        )
    else
        local diamond = self:GetGameObject("Diamond")
        self._toptipsInfo:SetData(RoleAssetID.RoleAssetGlow, diamond)
    end
end

--动态静态结果存储服务器
function UIMainLobbyController:staticAndDynamicOnClick()
    if self._cgState == DynamicAndStaticState.Static then
        self._cgState = DynamicAndStaticState.Dynamic
        GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_Dynamic"}, true)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlideDynamic)
    else
        self._cgState = DynamicAndStaticState.Static
        GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_Static"}, true)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlide)
    end

    self:ChangeDynamicAndStatic(self._cgState)
    GameGlobal.TaskManager():StartTask(self.OnGetExtData, self, self._cgState)
    --播放切换音效
    --AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSlide)
end

--音乐
function UIMainLobbyController:musicBgOnClick()
    ToastManager.ShowLockTip()
end

--图鉴
function UIMainLobbyController:PicButtonOnClick()
    -- TaskManager:GetInstance():StartTask(
    --     function(TT)
    --         GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_PICTURE)
    --     end
    -- )
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_BookEntryController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_HandBook)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    self:ShowDialog("UIBookEntryController")
end

--公会
function UIMainLobbyController:laborBtnOnClick()
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_GUILD)
        end
    )
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Guild)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    ToastManager.ShowLockTip()
end

--探索
function UIMainLobbyController:ExplorerOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_Discovery"}, true)

    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_EXPLORE)
        end
    )

    self.grassData = GameGlobal.GetModule(CampaignModule):GetGraveRobberData()
    if self.grassData:IsOpenGraveRobber() and self.grassData:HasCanPlayNode() then
        DiscoveryData.EnterStateUIDiscovery(7, nil)
    else
        DiscoveryData.EnterStateUIDiscovery(1)
    end

    --播放探索音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIExplore)
end

--探索 左侧按钮
function UIMainLobbyController:ExplorerLeftOnClick(go)
    self:ExplorerOnClick()
end

--任务
function UIMainLobbyController:taskBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_QuestController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_QuestEntry)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_TASK)
        end
    )
    if self._questUnLock == false then
    else
        self:ShowDialog("UIQuestController")
    end
end
function UIMainLobbyController:_CheckQuestLock()
    local questLockImg = self:GetGameObject("questLock")
    local QuestModule = GameGlobal.GetModule(QuestModule)
    local cfg_type = Cfg.cfg_quest_main_type {}
    local type_open_state = {}
    for i = 1, table.count(cfg_type) do
        if QuestModule:CheckQuestTypeUnlock(cfg_type[i].ClientType) then
            table.insert(type_open_state, cfg_type[i])
        end
    end
    if table.count(type_open_state) > 0 then
        self._questUnLock = true
    else
        self._questUnLock = false
    end
    --questLockImg:SetActive(not self._questUnLock)
end
--任务快捷操作
function UIMainLobbyController:questJumpBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_QuickQuest"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_QuestEntry)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    if self._quest then
        if self._quest.status == QuestStatus.QUEST_Completed then
            self:Lock("UIQuestGet")
            GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
            self:StartTask(self._OnGetQuestAwards, self)
        elseif self._quest.status == QuestStatus.QUEST_Accepted then
            ---@type UIJumpModule
            local jumpModule = self._questModule.uiModule
            local jumpType = self._quest.JumpID
            local jumpParam = self._quest.JumpParam

            jumpModule:SetJumpUIData(jumpType, jumpParam)
            jumpModule:Jump()
        else
            ToastManager.ShowToast("###quest -- the quest status is finish �??")
        end
    end
end
function UIMainLobbyController:_OnGetQuestAwards(TT)
    --领奖一秒内不接受任务事件，会刷新有无任务显�??
    self._questLock = true
    local res, msg = self._questModule:TakeQuestReward(TT, self._quest.quest_id)
    self:UnLock("UIQuestGet")
    if res:GetSucc() then
        --刷新红点
        local tempPets = {}
        local pets = msg.rewards
        self._petObtainRewards = msg.rewards
        if #pets > 0 then
            for i = 1, #pets do
                local ispet = GameGlobal.GetModule(PetModule):IsPetID(pets[i].assetid)
                if ispet then
                    table.insert(tempPets, pets[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIPetObtainCloseInMain)
                end
            )
        else
            if msg.rewards then
                self:ShowDialog(
                    "UIGetItemController",
                    msg.rewards,
                    function()
                        self._questLock = false
                        self:QuestInfo()
                    end
                )
            end
        end
    else
        self._questLock = false
        local result = res:GetResult()
        Log.error("###[UIMainLobbyController] TakeQuestReward fail ! result --> ", result)
    end
end
function UIMainLobbyController:OnUIPetObtainCloseInMain()
    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
    if self._petObtainRewards then
        self:ShowDialog(
            "UIGetItemController",
            self._petObtainRewards,
            function()
                self._questLock = false
                self:QuestInfo()
            end
        )
    end
end
--设置
function UIMainLobbyController:SetupBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"UISetController"}, true)
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_SETTING)
        end
    )
    self:ShowDialog("UISetController")
end
--邮件
function UIMainLobbyController:MailBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_MailController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Mail)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_MAIL)
        end
    )
    self:ShowDialog("UIMailController")
end
--好友
function UIMainLobbyController:ExpressionBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_ChatController"}, true)
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_FRIEND)
        end
    )
    self:ShowDialog("UIChatController")
end

function UIMainLobbyController:weChatBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_WeChatController"}, true)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.WeChatBtnClick)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_WeChat)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    self:ShowDialog("UIWeChatController")
end
--公告
function UIMainLobbyController:NoticeBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"UINoticeController"}, true)
    if SDKProxy:GetInstance():IsInternationalSDK() then
        if NoNoticeOut then
            return
        end
    end
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Notify)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_NOTICE)
        end
    )

    local openType = NoticeType.Active
    if self._noticeData == nil then
        self._noticeData = self._loginModule:GetNoticeData()
    end
    if self._noticeData then
        local systemState = self._noticeData:GetNoticeNewStateWithGroup(NoticeType.System)
        if systemState then
            openType = NoticeType.System
        end
    end
    self:ShowDialog("UINoticeController", openType)
end
--签到按钮
function UIMainLobbyController:signInBtnOnClick(go)
    self:ShowDialog("UISignInController")
end
--个人信息
function UIMainLobbyController:PlayerInfoOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_PlayerInfoController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Role)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_PLAYER_INFO)
        end
    )

    self:ShowDialog("UIPlayerInfoController", PlayerInfoFrom.MainLobby)
end
function UIMainLobbyController:OnPlayerInfoOpen(open)
    self._scroll:SetActive(not open)

    if self._cgState == DynamicAndStaticState.Static then
        self._cgGo:SetActive(not open)
    else
        self._spineGo:SetActive(not open)
        self._enterSpineGo:SetActive(not open and not self._enterSpineGoShowFinish)
        local bShowSubGo = (not open and not self._enterSpineGoShowFinish and (self._enterSpineSubGoName ~= nil))
        if bShowSubGo then
            if self._enterSpineSubGoGen then
                if self._enterSpineSubGoName~=self._oldEnterSpineSubGoName and self._oldEnterSpineSubGoName~=nil then
                    --dispose
                    self._enterSpineSubGoGen:ClearWidgets()
                end
                self._enterSpineSubGoGen.dynamicInfoOfEngine:SetObjectName(self._enterSpineSubGoName)
                self._enterSpineSubGoGen:SpawnObject("UIMainLobbyEnterSpineSubGo")
                self._oldEnterSpineSubGoName = self._enterSpineSubGoName
            end
        end
        self._enterSpineSubGo:SetActive(bShowSubGo)
    end

    if open then
        self._playerInfoAnim:Play("uieff_mainlobby_ToPlayerInfo")
    else
        self._playerInfoAnim:Play("uieff_mainlobby_BackFromPlayerInfo")
    end
end
--编队
function UIMainLobbyController:TeamMemberOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_Teams"}, true)
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_TEAM)
        end
    )
    GameGlobal.GetModule(MissionModule):TeamCtx():Init(TeamOpenerType.Main, 0)
    self:ShowDialog("UITeams")
end
--人物
function UIMainLobbyController:CharacterOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_HeartSpiritController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Pet)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_PET)
        end
    )
    self:ShowDialog("UIHeartSpiritController")
end
--召唤
function UIMainLobbyController:UnlockAndSummonOnClick(go)
    self._gamebleBtn:OnClicked()
end
--风船
function UIMainLobbyController:BaseOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_AircraftBtn"}, true)

    AudioHelperController.PlayRequestedUISound(CriAudioIDConst.AircraftBtnClick)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Aircraft)

    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_AIRCRAFT)
        end
    )
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Enter, "fc_ui")
end
--家园
function UIMainLobbyController:HomeBtnOnClick(go)
    GameGlobal.GetModule(HomelandModule):GetUIModule():LoadHomeland()
end
--仓库
function UIMainLobbyController:WarehouseOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_BackPackController"}, true)

    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Item)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_STORE)
        end
    )
    self:ShowDialog("UIBackPackController")
end

--修改文本播放语音
function UIMainLobbyController:bgOnClick()
    if not self._assistantNull then
        GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_ChangeGuider"}, true)
        local voiceSkinID
        if self._assistantAsID and self._assistantAsID ~= 0 then
            -- 用普通的
            voiceSkinID = nil
        else
            --检查皮�?
            if self._assistantSkinID == 0 then
                if self._assistantGrade == 0 then
                    local gradeCfg = Cfg.cfg_pet[self._defaultPetID]
                    if not gradeCfg then
                        Log.fatal(
                            "###[UIMainLobbyController] pet cfg is nil ! id --> ",
                            self._defaultPetID,
                            "| grade --> ",
                            self._assistantGrade
                        )
                        return
                    end
                    voiceSkinID = gradeCfg.SkinId
                else
                    local gradeCfg = Cfg.cfg_pet_grade {PetID = self._defaultPetID, Grade = self._assistantGrade}[1]
                    if not gradeCfg then
                        Log.fatal(
                            "###[UIMainLobbyController] grade cfg is nil ! id --> ",
                            self._defaultPetID,
                            "| grade --> ",
                            self._assistantGrade
                        )
                        return
                    end
                    voiceSkinID = gradeCfg.SkinId
                end
            else
                voiceSkinID = self._assistantSkinID
            end
        end
        self:PlayPetAudio("MainLobbyInteract")
        --spine动画
        self:PlaySpineAnim(voiceSkinID)
    end
end
function UIMainLobbyController:PlaySpineAnim(skinid)
    if self._cgState == DynamicAndStaticState.Dynamic then
        if self._spineSke then
            --正在�?
            if self._playSpineAnim then
                return
            end
            local cfg_pet_skin = Cfg.cfg_pet_skin[skinid]
            if not cfg_pet_skin then
                Log.error("###[UIMainLobbyController] cfg_pet_skin is nil ! id --> ", skinid)
                return
            end
            local spineAnims = cfg_pet_skin.MainLobbySpineAnim
            if not spineAnims then
                return
            end
            local animList = {}
            for i = 1, #spineAnims do
                local spineAnim = spineAnims[i]
                table.insert(animList, spineAnim)
            end
            if #animList == 0 then
                Log.error("###[UIMainLobbyController] animList is nil ! skinid --> ", skinid)
                return
            end
            local randomVal = math.random(#animList)
            local anim = animList[randomVal]

            local animationName = anim

            if not self._spineSke then
                Log.debug("###[UIMainLobbyController] not self._spineSke spine --> ", self._dynamicSpineSettings)
                return
            end
            ---@type Spine.TrackEntry
            local entry = self._spineSke.AnimationState:SetAnimation(0, animationName, false)
            if not entry then
                return
            end
            local anim = entry.Animation
            local duration = anim.Duration
            local yieldTime = math.floor(duration * 1000)
            self._playSpineAnim = true
            if self._spineEvent then
                GameGlobal.Timer():CancelEvent(self._spineEvent)
                self._spineEvent = nil
            end
            self._spineEvent =
                GameGlobal.Timer():AddEvent(
                yieldTime,
                function()
                    self._playSpineAnim = false
                    --默认的spine的动画必须叫idle
                    local animationName = "idle"
                    self._spineSke.AnimationState:SetAnimation(0, animationName, true)
                end
            )
            Log.debug("###[UIMainLobbyController] spine 动画名字[", animationName, "] 动画时长[", duration, "]")
        --ToastManager.ShowToast(animationName.."|"..duration)
        end
    end
end

--播放欢迎语音
function UIMainLobbyController:WelcomeAudio()
    self:StartTask(
        function(TT)
            YIELD(TT)
            self:PlayPetAudio("MainLobbyWelcome")
        end
    )
end

function UIMainLobbyController:PlayPetAudio(filed)
    local voiceSkinID
    if self._assistantAsID and self._assistantAsID ~= 0 then
        -- 用普通的
        voiceSkinID = nil
    else
        --检查皮�?
        if self._assistantSkinID == 0 then
            if self._assistantGrade == 0 then
                local gradeCfg = Cfg.cfg_pet[self._defaultPetID]
                if not gradeCfg then
                    Log.fatal(
                        "###[UIMainLobbyController] pet cfg is nil ! id --> ",
                        self._defaultPetID,
                        "| grade --> ",
                        self._assistantGrade
                    )
                    return
                end
                voiceSkinID = gradeCfg.SkinId
            else
                local gradeCfg = Cfg.cfg_pet_grade {PetID = self._defaultPetID, Grade = self._assistantGrade}[1]
                if not gradeCfg then
                    Log.fatal(
                        "###[UIMainLobbyController] grade cfg is nil ! id --> ",
                        self._defaultPetID,
                        "| grade --> ",
                        self._assistantGrade
                    )
                    return
                end
                voiceSkinID = gradeCfg.SkinId
            end
        else
            voiceSkinID = self._assistantSkinID
        end
    end
    if filed == "MainLobbyWelcome" and self._roleModule:TodayIsFirstLogin() then
        self._audioPlayID =
            self._petAudioModule:PlayPetAudio("FirstMainLobbyWelcome", self._defaultPetID, false, false, voiceSkinID)
        if self._audioPlayID == nil then
            self._audioPlayID = self._petAudioModule:PlayPetAudio(filed, self._defaultPetID, false, false, voiceSkinID)
        end
    else
        self._audioPlayID = self._petAudioModule:PlayPetAudio(filed, self._defaultPetID, false, false, voiceSkinID)
    end

    if self._audioPlayID == nil then
        return
    end
    self._voiceAnim:Play("uieff_mainlobby_voice")

    local cfg_audio = AudioHelperController.GetCfgAudio(self._audioPlayID)
    if cfg_audio then
        self._voiceTex:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(cfg_audio.Content)))
    end
end

function UIMainLobbyController:ClosePetAudio(normalClose)
    if self._audioPlayID == nil then
        return
    end
    if normalClose then
        self:OnAudioEndPlay()
    else
        self._voiceCanvasGroup.alpha = 0
        if self._audioPlayID then
            self._audioPlayID = nil
        end
    end
end

--播放结束
function UIMainLobbyController:OnAudioEndPlay()
    if self._audioPlayID then
        self._voiceAnim:Play("uieff_mainlobby_voicefade")
        self._audioPlayID = nil
    end
    --[[
    self._event =
        GameGlobal.Timer():AddEvent(
        self._waitFadeTime * 1000,
        function()
            self._voiceAnim:Play("uieff_mainlobby_voicefade")
    old
        self._voiceTween = self._voiceCanvasGroup:DOFade(0, self._fadeTime)
    end
    )
    ]]
end

function UIMainLobbyController:OnUpdate(deltaTimeMS)
    if (IsPc() or IsUnityEditor()) and GameGlobal.EngineInput().GetKeyDown(UnityEngine.KeyCode.BackQuote) then
        self.showTestFuncEntry = not self.showTestFuncEntry
        self:SwitchTestFuncEntry(self.showTestFuncEntry)
    end

    if self._isScrollReady then
        if self._count <= 1 then
            return
        end
        if not self._isDarging then
            if math.abs(math.abs(self._content.anchoredPosition.x) - math.abs(self._targetPosX)) > 1 then
                self._content.anchoredPosition =
                    Vector2(Mathf.Lerp(self._content.anchoredPosition.x, self._targetPosX, 0.5), 0)

                if self._content.anchoredPosition.x > self._width * -0.5 then
                    self._content.anchoredPosition =
                        Vector2(self._content.anchoredPosition.x - self._count * self._width, 0)

                    self._targetPosX = self._targetPosX - self._count * self._width
                end

                if self._content.anchoredPosition.x <= -(self._count * self._width + self._width * 0.5) then
                    self._content.anchoredPosition =
                        Vector2(self._content.anchoredPosition.x + self._count * self._width, 0)

                    self._targetPosX = self._targetPosX + self._count * self._width
                end
            else
                self._content.anchoredPosition = Vector2(self._targetPosX, self._content.anchoredPosition.y)
            end
        end
    end

    if not self._assistantNull then
        local cc =
            UnityEngine.Input.GetMouseButtonDown(0) or UnityEngine.Input.GetMouseButton(0) or
            UnityEngine.Input.GetMouseButtonUp(0) or
            not self:Manager():IsTopUI(self.name)

        if cc == true then
            self._freeTime = 0
        else
            if self._freeTime then
                self._freeTime = self._freeTime + deltaTimeMS
            else
                self._freeTime = 0
            end
        end

        if self._freeTime and self._maxFreeTime then
            if self._freeTime > self._maxFreeTime then
                self:PlayPetAudio("Leisure")
                self._freeTime = 0
            end
        end
    end
end

--主界面体力刷�??
function UIMainLobbyController:GetCurrentPhyTimer()
    self:Lock("UIMainLobbyController:GetCurrentPhyTimer")
    GameGlobal.TaskManager():StartTask(self.OnGetCurrentPhyTimer, self)
end
function UIMainLobbyController:OnGetCurrentPhyTimer(TT)
    local res, startTime, intervalRecoverTime, leftRecoverTime, allRecoverTime = self._roleModule:GetRecoverData(TT, 0)
    self:UnLock("UIMainLobbyController:GetCurrentPhyTimer")

    if not res:GetSucc() then
        Log.fatal("###OnGetCurrentPhyTimer false !")
        return
    end

    local gapTimeNum = intervalRecoverTime * 1000
    local nextTimeNum = leftRecoverTime * 1000

    if self._startPhyTimerEvent then
        GameGlobal.RealTimer():CancelEvent(self._startPhyTimerEvent)
        self._startPhyTimerEvent = nil
    end

    if self._roleModule:GetHealthPoint() >= self._roleModule:GetHpLevelMax() then
        return
    end

    self._startPhyTimerEvent =
        GameGlobal.RealTimer():AddEvent(
        nextTimeNum,
        function(gapTimeNum)
            self:StartPhyTimer(gapTimeNum)
        end,
        gapTimeNum
    )
end
function UIMainLobbyController:StartPhyTimer(gapTime)
    if self._startPhyTimerLoopEvent then
        GameGlobal.RealTimer():CancelEvent(self._startPhyTimerLoopEvent)
        self._startPhyTimerLoopEvent = nil
    end
    self:StartPhyTimerLoop()

    self._startPhyTimerLoopEvent =
        GameGlobal.RealTimer():AddEventTimes(
        gapTime,
        TimerTriggerCount.Infinite,
        function()
            self:StartPhyTimerLoop()
        end
    )
end
function UIMainLobbyController:StartPhyTimerLoop()
    self:Lock("UIMainLobbyController:StartPhyTimerLoop")
    GameGlobal.TaskManager():StartTask(self.OnStartPhyTimerLoop, self)
end

function UIMainLobbyController:OnStartPhyTimerLoop(TT)
    local res = self._roleModule:GetRecoverData(TT, 0)
    self:UnLock("UIMainLobbyController:StartPhyTimerLoop")
    if res:GetSucc() then
        self:ShowPhyPoint()
    else
        Log.fatal("###GetRecoverData false --> result --> ", res:GetResult())
    end
end

--体力
function UIMainLobbyController:PhyPowerTextOnClick()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_PhyPoint"}, true)
    if not self._phyPanelIsOpen then
        --打开体力计时
        self:ShowPhyPoint()
        self:OpenPhyTimer()
    end
end
function UIMainLobbyController:OpenPhyTimer()
    self:Lock("GetRecoverData")
    self:StartTask(self.OnOpenPhyTimer, self)
end
function UIMainLobbyController:OnOpenPhyTimer(TT)
    local res, startTime, intervalRecoverTime, leftRecoverTime, allRecoverTime = self._roleModule:GetRecoverData(TT, 0)
    self:UnLock("GetRecoverData")
    if not res:GetSucc() then
        Log.fatal("### request fail -- self._roleModule:GetRecoverData !")
        return
    end

    self._gapTimeNum = intervalRecoverTime
    self._nextTimeNum = leftRecoverTime
    self._allTimeNum = allRecoverTime
    self._phyPanelIsOpen = true

    if self._phyEvent then
        GameGlobal.RealTimer():CancelEvent(self._phyEvent)
        self._phyEvent = nil
    end
    self._phyEvent =
        GameGlobal.RealTimer():AddEvent(
        2000,
        function()
            self:ClosePhyTimer()
        end
    )

    self._phyTime:SetActive(true)
    self._nextTime:SetText(self:Time2Str(self._nextTimeNum))
    self._allTime:SetText(self:Time2Str(self._allTimeNum))

    if self._showTimeEvent then
        GameGlobal.RealTimer():CancelEvent(self._showTimeEvent)
        self._showTimeEvent = nil
    end
    self._showTimeEvent = GameGlobal.RealTimer():AddEventTimes(1000, TimerTriggerCount.Infinite, self.ShowTime, self)
end

function UIMainLobbyController:ClosePhyTimer()
    self._phyTime:SetActive(false)
    if self._showTimeEvent then
        GameGlobal.RealTimer():CancelEvent(self._showTimeEvent)
        self._showTimeEvent = nil
    end
    if self._phyEvent then
        GameGlobal.RealTimer():CancelEvent(self._phyEvent)
        self._phyEvent = nil
    end
    self._phyPanelIsOpen = false
end

function UIMainLobbyController:ShowTime()
    self._nextTimeNum = self._nextTimeNum - 1
    self._allTimeNum = self._allTimeNum - 1
    if self._nextTimeNum < 0 then
        self._nextTimeNum = self._gapTimeNum - 1
        self:OnItemCountChange()
    end
    if self._allTimeNum < 0 then
        self._allTimeNum = 0

        if self._showTimeEvent then
            GameGlobal.RealTimer():CancelEvent(self._showTimeEvent)
            self._showTimeEvent = nil
        end
        return
    end
    self._nextTime:SetText(self:Time2Str(self._nextTimeNum))
    self._allTime:SetText(self:Time2Str(self._allTimeNum))
end
function UIMainLobbyController:Time2Str(time)
    local str = ""
    local timeTab = self:ChangeSecondToTime(time)
    str = self:ChangeTimeTableToStr(timeTab)
    return str
end
--把一个timeTable转化为字符串
---@param timeTable table<string,number> 时间�?? table = {["hour"]=小时数，["min"]=分钟�??,["sec"]=秒数}
---@return timeStr string
function UIMainLobbyController:ChangeTimeTableToStr(timeTable)
    local hourStr
    local minStr
    local secStr

    if timeTable["hour"] > 9 then
        hourStr = timeTable["hour"]
    else
        hourStr = "0" .. timeTable["hour"]
    end

    if timeTable["min"] > 9 then
        minStr = timeTable["min"]
    else
        minStr = "0" .. timeTable["min"]
    end

    if timeTable["sec"] > 9 then
        secStr = timeTable["sec"]
    else
        secStr = "0" .. timeTable["sec"]
    end

    return hourStr .. ":" .. minStr .. ":" .. secStr
end
-- 把秒转换为时间格�??,参数为秒数，返回一个table = {"hour" = 小时�??,"min" = 分钟�??,"sec" = 秒数}
---@param second number 秒数
---@return timeTable table<string,number>
function UIMainLobbyController:ChangeSecondToTime(second)
    local timeTable = {["hour"] = 0, ["min"] = 0, ["sec"] = 0}

    if second == 0 then
        return timeTable
    end

    local sec = math.modf(second % 60)
    local minAll = math.modf((second - sec) / 60)
    local min = math.modf(minAll % 60)
    local hour = math.modf((minAll - min) / 60)

    timeTable["hour"] = hour
    timeTable["min"] = min
    timeTable["sec"] = sec

    return timeTable
end

function UIMainLobbyController:OnUpdateWeChatRed()
    local state = self._roleModule:CheckModuleUnlock(GameModuleID.MD_WeChat)
    if state == false then
        self._weChatRedGO:SetActive(false)
        self._weChatCountGO:SetActive(false)
        return
    end
    if self._weChatRedGO then
        local module = self:GetModule(QuestChatModule)
        local chats = module:GetWeChatProxy():GetUnReadChats()
        local count = #chats
        if count > 0 then
            self._weChatRedGO:SetActive(false)
            self._weChatCountGO:SetActive(true)
            self._weChatCountTxt:SetText(count)
        else
            self._weChatCountGO:SetActive(false)
            self._weChatRedGO:SetActive(module:GetWeChatProxy():HasRed())
        end
    end
end

-- 刷新轮播
function UIMainLobbyController:OnUpdateWeChatMainTalk()
    local state = self._roleModule:CheckModuleUnlock(GameModuleID.MD_WeChat)
    if state == false then
        self._weChatTalkGO:SetActive(false)
        return
    end
    local module = self:GetModule(QuestChatModule)
    self.weChatTalkTxts = module:GetWeChatProxy():GetRandomUnReadChats()
    local isConstructor = module:GetWeChatProxy():IsConstructor()
    self:StopWeChatTalkTimer()
    if self.weChatTalkTxts and #self.weChatTalkTxts > 0 then
        if #self.weChatTalkTxts >= 1 then
            if isConstructor then
                local trigger =
                    UICommonHelper:GetInstance():TrggerLocalRecordTime(self._roleModule:GetPstId() .. "WeChatMainTalk")
                if trigger then
                    self._weChatTalkGO:SetActive(true)
                    self.maxWeChatTalkCount = #self.weChatTalkTxts
                    self:AddWeChatTalkTimer()
                    module:GetWeChatProxy():SetIsConstructor(false)
                else
                    self._weChatTalkGO:SetActive(false)
                    module:GetWeChatProxy():SetIsConstructor(false)
                end
            else
                self._weChatTalkGO:SetActive(true)
                self.maxWeChatTalkCount = #self.weChatTalkTxts
                self:AddWeChatTalkTimer()
            end
        else
            self._weChatTalkGO:SetActive(false)
        end
    else
        self._weChatTalkGO:SetActive(false)
        module:GetWeChatProxy():SetIsConstructor(false)
    end
end

function UIMainLobbyController:AddWeChatTalkTimer()
    self.weChatTalkIndex = 1
    self.weChatTalkTimer =
        GameGlobal.Timer():AddEventTimes(1500, TimerTriggerCount.Infinite, self.OnWeChatTalkLoop, self)
    self:OnWeChatTalkLoop()
end

function UIMainLobbyController:OnWeChatTalkLoop()
    if self.weChatTalkIndex <= self.maxWeChatTalkCount then
        if self._weChatTalkTxt then
            self._weChatTalkAni:Play()
            -- self._weChatTalkTxt:SetText(self.weChatTalkTxts[self.weChatTalkIndex])
            self._weChatMainIcon:LoadImage(self.weChatTalkTxts[self.weChatTalkIndex])
        end
        self.weChatTalkIndex = self.weChatTalkIndex + 1
    else
        self:StopWeChatTalkTimer()
        self._weChatTalkGO:SetActive(false)
    end
end
function UIMainLobbyController:StopWeChatTalkTimer()
    if self.weChatTalkTimer then
        GameGlobal.Timer():CancelEvent(self.weChatTalkTimer)
        self.weChatTalkTimer = nil
    end
end

---------------------------------------------------传说光灵
function UIMainLobbyController:btnTalePetOnClick()
    self:Lock("UIMainLobbyController:OnClickTale")
    GameGlobal.TaskManager():StartTask(self.OnClickTale, self)
end

function UIMainLobbyController:OnClickTale(TT)
    --请求光灵数据
    ---@type AsyncRequestRes
    local res = self._talePetModule:ReqTalePet(TT)
    if res:GetSucc() then
        local isFirstEnter = self._talePetModule:IsFirstEnter()
        if isFirstEnter == false then
            --解锁传说光灵功能第一次进�??
            local res = self._talePetModule:ReqTaleFirst(TT, TaleFirstType.TFT_Enter)
            if res:GetSucc() then
                local storyId = self._talePetModule:GetEnterTalePetStoryIds()
                self:ShowDialog(
                    "UIStoryController",
                    storyId,
                    function()
                        self:ShowDialog("UITalePetList")
                        if GameGlobal.UIStateManager():IsShow("UIStoryController") then
                            GameGlobal.UIStateManager():CloseDialog("UIStoryController")
                        end
                    end,
                    false
                )
            else
                ToastManager.ShowToast(res:GetResult())
            end
        else
            local callState = self._talePetModule:SelectPetCfgId()
            if callState ~= 0 then
                --有正在召集中的光�??
                self:ShowDialog("UITalePetMissionController", callState)
            else
                --非首次进入，但是没有正在召集中的光灵
                self:ShowDialog("UITalePetList")
            end
        end
    else
        ToastManager.ShowToast(res.m_result)
    end
    self:UnLock("UIMainLobbyController:OnClickTale")
end

function UIMainLobbyController:TalePetRedPointController()
    --光灵可领取但未领取时显示
    local state1 = self._talePetModule:IsCanCall()
    --有任务奖励可领取时显�??
    local state2 = self._talePetModule:IsAllGetReward()
    local state3 = self._talePetModule:IsShowRewardRed()
    local state4 = self._talePetModule:IsShowTrailFinalLevelRed()

    if state1 or state2 or state3 or state4 then
        self.talePetRedPoint:SetActive(true)
    else
        self.talePetRedPoint:SetActive(false)
    end
end

function UIMainLobbyController:RefreshCanConvene(TT)
    local list = {}
    self.canConvene:SetActive(false)
    local cfg = Cfg.cfg_tale_pet {}
    if cfg == nil then
        return
    end
    for key, value in pairs(cfg) do
        local info = self._talePetModule:GetPetInfo(value.ID)
        if info == nil then
            table.insert(list, value)
        end
    end
    if #list <= 0 then
        return
    end
    self.canConvene:SetActive(true)
    local rand = math.random(1, #list)
    self.canConceneImg:LoadImage(list[rand].TurnIcon)

    --延迟5秒之后消�??
    if self.conveneDelay then
        GameGlobal.Timer():CancelEvent(self.conveneDelay)
    end
    self.conveneDelay =
        GameGlobal.Timer():AddEvent(
        5000,
        function()
            self.canConvene:SetActive(false)
            self.conveneDelay = nil
        end
    )
end

function UIMainLobbyController:ChangeTaleInfo()
    self.canConvene:SetActive(false)
    local IsCanDo = self._talePetModule:IsCanDo()
    if IsCanDo then
        GameGlobal.TaskManager():StartTask(self.RefreshCanConvene, self)
    end
    self:TalePetRedPointController()
end

---------------------------------------------------end

--region MainCarourseEvent
-- 主界面轮�?? cfg_main_caroursel.xlsx
-- 配置中条目的解锁 Type
--- @class UIMainCarourselType
local UIMainCarourselType = {
    None = 0,
    Mission = 1,
    ExtMission = 2,
    DrawCardNewPool = 3,
    Activity = 4,
    Gift = 5,
    TempSignIn = 6,
    Skin = 7
}
_enum("UIMainCarourselType", UIMainCarourselType)

function UIMainLobbyController:_CheckMainCarourseEventIsOpen(
    ModuleID,
    OpenType,
    OpenParam,
    OpenTime,
    CloseTime,
    PrivateZoneID)
    if PrivateZoneID and next(PrivateZoneID) then
        local have = false
        for i = 1, #PrivateZoneID do
            if PrivateZoneID[i] == self._roleModule:GetZoneIdType() then
                have = true
            end
        end
        if not have then
            return false
        end
    end

    if ModuleID ~= nil then
        --成长任务特殊处理
        if ModuleID == GameModuleID.MD_QuestGrowth then
            local questModule = self:GetModule(QuestModule)
            return questModule:IsGrowthVisible()
        else
            local state = self._roleModule:CheckModuleUnlock(ModuleID)
            if not state then
                return false
            end
        end
    end
    if OpenType ~= nil then
        if OpenType == UIMainCarourselType.Mission then
            --检查是否通关该关�??
            local pass = self._missionModule:IsPassMissionID(OpenParam[1])
            if not pass then
                return false
            end
        elseif OpenType == UIMainCarourselType.DrawCardNewPool then
            --改为通过卡池id，判断开�??
            local poolid = OpenParam[1]
            local gambleModule = self:GetModule(GambleModule)
            local pools = gambleModule:GetPrizePools()
            local have = false
            for i = 1, #pools do
                local pool = pools[i]
                if pool.prize_pool_id == poolid then
                    have = true
                    break
                end
            end
            if not have then
                return false
            end
        elseif OpenType == UIMainCarourselType.Activity then
            --检查活动是否开�??
            local id = OpenParam[1]
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            local sample = campaignModule.m_campaign_manager:GetSampleByID(id)
            if not sample then
                return false
            end
        elseif OpenType == UIMainCarourselType.Gift then
            --礼包,用礼包id查该礼包还有没有，有的话显示呢，没有不显示，（首充礼包）
            local ids = OpenParam
            local giftInfo, giftCfg = self._shopModule:GetGiftMarketData()
            local giftList = giftInfo.goods

            local have = false
            for i = 1, #ids do
                local id = ids[i]
                for _, v in pairs(giftList) do
                    if v.gift_id == id then
                        local id_giftCfg = giftCfg[id]
                        local maxTimes = tonumber(id_giftCfg[ConfigKey.ConfigKey_SaleNum])
                        if v.selled_num < maxTimes then
                            have = true
                            break
                        end
                    end
                end
                if have == true then
                    break
                end
            end
            if have == false then
                return false
            end
        elseif OpenType == UIMainCarourselType.TempSignIn then
            return false -- 新手签到已转移至活动中心
        elseif OpenType == UIMainCarourselType.Skin then
            if OpenParam then
                --时装,用id查该时装还有没有，有的话显示呢，没有不显�??
                local ids = OpenParam
                local skinsInfo, skinsCfg = self._shopModule:GetSkinsMarketData()
                local skinsList = skinsInfo
                local svrTime = self._svrTimeModule:GetServerTime() / 1000
                local have = false
                for i = 1, #ids do
                    local id = ids[i]
                    for _, v in pairs(skinsList) do
                        if v.goodid == id then
                            if svrTime < v.endtime then
                                have = true
                                break
                            end
                        end
                    end
                    if have == true then
                        break
                    end
                end
                if have == false then
                    return false
                end
            end
        end
    end

    if OpenTime ~= nil and CloseTime ~= nil then
        local openTimeTable = HelperProxy:GetInstance():GetTimeTable(OpenTime)
        local closeTimeTable = HelperProxy:GetInstance():GetTimeTable(CloseTime)

        local localOpenTime = _utc2Local(openTimeTable)
        local localCloseTime = _utc2Local(closeTimeTable)

        local open = HelperProxy:GetInstance():FormatDateTime(localOpenTime)
        local close = HelperProxy:GetInstance():FormatDateTime(localCloseTime)
        --检查时�??
        local svrTime = self._svrTimeModule:GetServerTime() / 1000
        if svrTime < open or svrTime > close then
            return false
        end
    end

    return true
end
--endregion
function UIMainLobbyController:_CheckWoldBossRedPoint()
    local show = false
    local worldBossModule = self:GetModule(WorldBossModule)
    local redPointData = worldBossModule:GetWorldBossRedPoint()
    show = redPointData:MainLobbyHaveRedPoint()
    self._oneBtnRedPoint:SetActive(show)
    self._twoBtnRedPoint:SetActive(show)
end

function UIMainLobbyController:ShowAutoTestLogs()
    if EDITOR then
        self:ShowDialog("UIBattleAutoTest")
    end
end

function UIMainLobbyController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.HomelandUnlock)
end
function UIMainLobbyController:GoldAddOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    self:ShowDialog("UIItemGetPathController", RoleAssetID.RoleAssetGold)
end