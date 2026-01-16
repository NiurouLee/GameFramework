---@class UIN31HardLevel : UIController
_class("UIN31HardLevel", UIController)
UIN31HardLevel = UIN31HardLevel

function UIN31HardLevel:LoadDataOnEnter(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N31,
        ECampaignN31ComponentID.ECAMPAIGN_N31_LINE_MISSION, -- 普通关线性关
        ECampaignN31ComponentID.ECAMPAIGN_N31_DIFFICULT_MISSION -- 困难关
    )
    
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    ---@type LineMissionComponent
    self._line_component = self._localProcess:GetComponent(ECampaignN31ComponentID.ECAMPAIGN_N31_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._line_info = self._localProcess:GetComponentInfo(ECampaignN31ComponentID.ECAMPAIGN_N31_LINE_MISSION)
    --困难线性关
    ---@type LineMissionComponent
    self._levelCpt = self._localProcess:GetComponent(ECampaignN31ComponentID.ECAMPAIGN_N31_DIFFICULT_MISSION)
    ---@type LineMissionComponentInfo
    self._levelCptInfo = self._localProcess:GetComponentInfo(ECampaignN31ComponentID.ECAMPAIGN_N31_DIFFICULT_MISSION)


    local openTime = self._levelCptInfo.m_unlock_time
    local closeTime = self._levelCptInfo.m_close_time
    local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
    --不在开放时段内
    if now < openTime then
        res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
        campaignModule:ShowErrorToast(res.m_result, true)
        return
    elseif now > closeTime then
        res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
        campaignModule:ShowErrorToast(res.m_result, true)
        return
    end
    if not self._line_info.m_b_unlock then --未通过 暂时屏蔽进入
        res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_UNLOCK

        local cfgv = Cfg.cfg_campaign_mission[self._line_info.m_need_mission_id]
        if cfgv then
            local lvName = StringTable.Get(cfgv.Name)
            local msg = StringTable.Get("str_activity_common_will_open_after_clearance", lvName) --通关{1}关后开启
            ToastManager.ShowToast(msg)
        end
        return
    end
end

function UIN31HardLevel:OnShow(uiParams)
    self._rootAni = self:GetUIComponent("Animation", "rootAni")
    self.rt = self:GetUIComponent("RawImage", "Eff")
    self._atlas = self:GetAsset("UIN31Main.spriteatlas", LoadType.SpriteAtlas)
    ---@type UILocalizationText
    self._time = self:GetUIComponent("UILocalizationText", "RemainTime")

    --是否退局
    local fromBattle = false
    local isWin = false
    if uiParams[1] then
        fromBattle = uiParams[1][1]
        isWin = uiParams[1][2]
    end
    self._mainShot = uiParams[2]

    self:InitWidget()
    self:InitCommonTopButton()
    self:InitLevelCfg()

    local spine, bgm = self:GetSpineAndBgm()
    if bgm then
        AudioHelperController.PlayBGM(bgm, AudioConstValue.BGMCrossFadeTime)
    end

    self:RefreshCurrentIndex()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local playerId = roleModule:GetPstId()
    local key = playerId.."UIN31HardLevel"
    local value = LocalDB.GetInt(key,2)
    if fromBattle and not self._showLevel1 and self._curIndex == 7 and value == 2 then
        LocalDB.SetInt(key, 1)
        self:DoLevelBtnSwitch(true)
        --self._isLevel2Lock = false
        self:Level2OnClick()
        --self:UnlockEvilAnimation()
    end

    self:RefreshTime()
    self:SetLevelBtns()
    self:_RefreshPoint()
    self._isShow = true
    --self._bg2loader.gameObject:SetActive(not self._showLevel1)
    if self._showLevel1 then
        if self._mainShot then
            self.rt.texture = self._mainShot
        else
            self.rt.gameObject:SetActive(false)
        end
        self._rootAni:Play("uieff_UIN31HardLevel_in")
    else
        if self._mainShot then
            self.rt.texture = self._mainShot
        else
            self.rt.gameObject:SetActive(false)
        end
        self._rootAni:Play("uieff_UIN31HardLevel_in02")
    end 
    
    if fromBattle and isWin then
        self:FadeInAnim()
    end

    -- if not fromBattle then
    --     if self._showLevel1 then
    --         if self._mainShot then
    --             self.rt.texture = self._mainShot
    --         end
    --         self._rootAni:Play("uieff_UIN31HardLevel_in")
    --     else
    --         if self._mainShot then
    --             self.rt.texture = self._mainShot
    --         end
    --         self._rootAni:Play("uieff_UIN31HardLevel_in02")
    --     end 
    -- end

end

function UIN31HardLevel:InitLevelCfg()
    UIN31HardLevel.LevelCfg =
    {
        [1] = {
            normal = "n31_kng_spot01",
            close = "n31_kng_spotmask01",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [2] = {
            normal = "n31_kng_spot02",
            close = "n31_kng_spotmask02",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [3] = {
            normal = "n31_kng_spot03",
            close = "n31_kng_spotmask03",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [4] = {
            normal = "n31_kng_spot04",
            close = "n31_kng_spotmask04",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [5] = {
            normal = "n31_kng_spot05",
            close = "n31_kng_spotmask05",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [6] = {
            normal = "n31_kng_spot06",
            close = "n31_kng_spotmask06",
            titleColor = Color(95/255,63/255,39/255),
            titleOutlineColor = Color(236/255,231/255,218/255),
            passTxtColor = Color(90/255,66/255,4/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [7] = {
            normal = "n31_kng_spot07",
            close = "n31_kng_spotmask01",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [8] = {
            normal = "n31_kng_spot08",
            close = "n31_kng_spotmask02",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [9] = {
            normal = "n31_kng_spot09",
            close = "n31_kng_spotmask03",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [10] = {
            normal = "n31_kng_spot010",
            close = "n31_kng_spotmask04",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [11] = {
            normal = "n31_kng_spot011",
            close = "n31_kng_spotmask05",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        [12] = {
            normal = "n31_kng_spot012",
            close = "n31_kng_spotmask06",
            titleColor = Color(255/255,252/255,254/255),
            titleOutlineColor = nil,
            passTxtColor = Color(112/255,86/255,128/255),
            lock = "n31_kng_lock01",
            passBg = "n31_kng_complete"
        },
        ["bghard"] = {
            ["Bg1"] = "n31_kng_bg001",
            ["Bg2"] = "n31_kng_bg01",
        },
        ["bgevil"] = {
            ["Bg1"] = "n31_kng_bg002",
            ["Bg2"] = "n31_kng_bg02",

        }
    }

    return self.LevelCfg
end

function UIN31HardLevel:InitCommonTopButton()
    ---@type UICommonTopButton
    self.topButtonWidget = self.topbuttons:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            --CutsceneManager.ExcuteCutsceneIn_Shot()
            -- ---@type CampaignModule
            -- local campaignModule = GameGlobal.GetModule(CampaignModule)
            -- campaignModule:CampaignSwitchState(
            --     true,
            --     UIStateType.UIActivityN31MainController,
            --     UIStateType.UIMain,
            --     nil,
            --     self._campaign._id
            -- )
            self:SwitchMainUI()
        end,
        nil,
        function()
            self:SwitchState(UIStateType.UIMain)
        end
    )
end


function UIN31HardLevel:SwitchMainUI()

    self._shot.OwnerCamera =
    GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local rt = self._shot:RefreshBlurTexture()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    self:StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            self:SwitchState(UIStateType.UIActivityN31MainController, cache_rt, true,true)
        end
    )

end 

function UIN31HardLevel:RefreshTime()
    local endTime = self._levelCptInfo.m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local remainTime = endTime - curTime
    remainTime = math.max(remainTime, 0)

    local timeStr = UIN31Line:GetFormatTimerStr(remainTime)--, "544C4C"

    if self._timeString ~= timeStr then
        self._time:SetText(timeStr)
        self._timeString = timeStr
    end
    if remainTime == 0 then
        self._time:SetText(StringTable.Get("str_activity_error_107"))
    end
end

function UIN31HardLevel:OnUpdate()
    self:RefreshTime()
end

--入场动画
function UIN31HardLevel:FadeInAnim()
    if self._curIndex == 7 then
        --self:UnlockEvilAnimation()
        self._levels[1]:Anim_Open()
        return  --第七关不需要播放前一关pass
    end
    local idx = (self._curIndex > 6) and (self._curIndex - 6) or self._curIndex
    if self._levels[idx] then
        self._levels[idx]:Anim_Open()
    end
    if self._levels[idx - 1] then
        self._levels[idx - 1]:Anim_Pass()
    end
end

function UIN31HardLevel:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN28ActivityMainRedStatusRefresh)
    UIN31HardLevel.LevelCfg = nil
    self._isShow = false
end

function UIN31HardLevel:InitWidget()
    ---@type UICustomWidgetPool
    self.topbuttons = self:GetUIComponent("UISelectObjectPath", "topbuttons")

    ---@type table<number,UIN31HardLevelItem>
    self._levels = {}
    for i = 1, 6 do
        self._levels[i] = UIN31HardLevelItem:New(self:GetUIComponent("UIView", "Level" .. i))
    end

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "BlurHelper")
    self._shotRect = self:GetUIComponent("RectTransform", "BlurHelper")
    self._width = self._shotRect.rect.width
    self._height = self._shotRect.rect.height
    self._shot.width = self._width
    self._shot.height = self._height
    self._shot.blurTimes = 0
    self._scale = 1.2


    -- self._level1pos1 = self:GetUIComponent("RectTransform", "level1pos1")
    -- self._level1pos2 = self:GetUIComponent("RectTransform", "level1pos2")
    -- self._level2pos1 = self:GetUIComponent("RectTransform", "level2pos1")
    -- self._level2pos2 = self:GetUIComponent("RectTransform", "level2pos2")
    self._level1 = self:GetUIComponent("RectTransform", "level1")
    self._level2 = self:GetUIComponent("RectTransform", "level2")
    self._level2OpenTip = self:GetGameObject("lv2OpenTip")
    self._level2OpenTip:SetActive(false)
    --self._tipAnim = self:GetUIComponent("Animation", "lv2OpenTip")

    self._bg2loader = self:GetUIComponent("RawImageLoader", "Bg2")
    self._bg1loader = self:GetUIComponent("RawImageLoader", "Bg1")
    ---@type ATransitionComponent
    --self._atc = self:GetUIComponent("ATransitionComponent","lv2OpenTip")
    self.rightBg = self:GetUIComponent("RawImageLoader", "RightBg")
    self.rightBg2 = self:GetUIComponent("RawImageLoader", "RightBg2")
    --self._atc.enabled = false
end

function UIN31HardLevel:CheckTime()
    local simpleCloseTime = self._levelCptInfo.m_close_time
    local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
    --线性关活动结束
    if now > simpleCloseTime then
        return false
    end
    return true
end

function UIN31HardLevel:_EnterLevel(idx)
    local open = self:CheckTime()
    if not open then
        local lockName = "UIN31HardLevel"
        self:StartTask(function(TT)
            self:Lock(lockName)
            ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
            YIELD(TT, 1000)
            self:UnLock(lockName)
            self:SwitchMainUI()
        end)
        return
    end
    if idx < 1 and idx > 6 then
        return
    end

    local levelIndex
    if self._showLevel1 then
        levelIndex = idx
    else
        levelIndex = idx + 6
    end

    local missionID = self._levelCfgs[levelIndex].CampaignMissionId
    if levelIndex > self._curIndex then
        ToastManager.ShowToast(StringTable.Get("str_activity_common_clear_mission_to_unlock"))
        return
    end

    -- self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    -- self._shot:CleanRenderTexture()

    local missionCfg = Cfg.cfg_campaign_mission[missionID]
    local autoFightShow = self:_CheckSerialAutoFightShow(missionCfg.Type, missionID)

    self:ShowDialog(
            "UIActivityLevelStageNew",
            missionID,
            self._levelCptInfo.m_pass_mission_info[missionID],
            self._levelCpt,
            autoFightShow,
            nil --行动点组件
    )

    --local localProcess = self._campaign:GetLocalProcess()
    --localProcess:HardLineMissionChallenge(missionID)
end

function UIN31HardLevel:_CheckSerialAutoFightShow(stageType, stageId)
    local autoFightShow = false
    if stageType == DiscoveryStageType.Plot then
        autoFightShow = false
    else
        local missionCfg = Cfg.cfg_campaign_mission[stageId]
        if missionCfg then
            local enableParam = missionCfg.EnableSerialAutoFight
            if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
                autoFightShow = false
            elseif enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE then
                autoFightShow = true
            elseif enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK then
                autoFightShow = true
            end
        end
    end

    return autoFightShow
end

function UIN31HardLevel:RefreshCurrentIndex()
    local cptID = self._levelCpt:GetComponentCfgId()
    local allMissions = Cfg.cfg_component_line_mission {ComponentID = cptID}
    table.sort(allMissions, function(a, b)
        return a.SortId < b.SortId
    end)

    if #allMissions ~= 12 then
        Log.exception("N28高难关的数量必须是12")
    end

    ---@type table<number, cam_mission_info> 完成的关卡数据<missionID, cam_mission_info>
    self._passInfo = self._levelCptInfo.m_pass_mission_info
    self._levelCfgs = allMissions
    local cur = 1
    for i, cfg in ipairs(allMissions) do
        if cfg.CampaignMissionId == self._levelCptInfo.m_cur_mission then
            cur = i + 1
        end
    end
    self._curIndex = cur
    --最难关是否锁定
    self._isLevel2Lock = self._curIndex <= 6
    --当前展示的是否为Level1的6个路点
    self._showLevel1 = self._isLevel2Lock
end

function UIN31HardLevel:Press1OnClick()
    self:_EnterLevel(1)
end
function UIN31HardLevel:Press2OnClick()
    self:_EnterLevel(2)
end
function UIN31HardLevel:Press3OnClick()
    self:_EnterLevel(3)
end
function UIN31HardLevel:Press4OnClick()
    self:_EnterLevel(4)
end
function UIN31HardLevel:Press5OnClick()
    self:_EnterLevel(5)
end
function UIN31HardLevel:Press6OnClick()
    self:_EnterLevel(6)
end

function UIN31HardLevel:SetLevelBtns()
    ---@type UIN31HardLevelBtn
    self.level1Btn = self:_SpawnObject("level1", "UIN31HardLevelBtn")

    ---@type UIN31HardLevelBtn
    self.level2Btn = self:_SpawnObject("level2", "UIN31HardLevelBtn")

    self.level1Btn:SetData(self._atlas, 1, function()
        self:ClickLevelBtn1()
    end)

    self.level2Btn:SetData(self._atlas, 2, function()
        self:ClickLevelBtn2()
    end)

    self:RefreshLevelBtnSelect()
end

function UIN31HardLevel:RefreshLevelBtnSelect()

    if self._showLevel1 then
        self.level1Btn:SetSelect(true,false, self._isLevel2Lock)
        self.level2Btn:SetSelect(false, true, self._isLevel2Lock)
    else
        self.level1Btn:SetSelect(false,false, self._isLevel2Lock)
        self.level2Btn:SetSelect(true, true, self._isLevel2Lock)
    end

end

function UIN31HardLevel:ClickLevelBtn1()
    
    if self._showLevel1 then
        return
    end
    self._level2:SetAsFirstSibling()
    self._showLevel1 = true
    self:DoLevelBtnSwitch(true)
    self:RefreshLevelBtnSelect()
end

function UIN31HardLevel:ClickLevelBtn2()
    
    if self._isLevel2Lock then
        local cfgv = Cfg.cfg_campaign_mission[self._levelCfgs[6].CampaignMissionId]
        local lvName = StringTable.Get(cfgv.Name)
        ToastManager.ShowToast(StringTable.Get("str_activity_common_will_open_after_clearance", lvName))
        return
    end

    if not self._showLevel1 then
        return
    end
    self._level1:SetAsFirstSibling()
    self._showLevel1 = false
    self:DoLevelBtnSwitch(false)
    self:RefreshLevelBtnSelect()
end

function UIN31HardLevel:UnlockEvilAnimation()
    local lockName = self:GetName().. ".EvilOpenAnim"
    self:StartTask(function(TT)
        self:Lock(lockName)
        --YIELD(TT, 500)
        self._level2OpenTip:SetActive(true)
        self._rootAni:Play("uieff_UIN31HardLevel_lv2OpenTip_show")
        -- self._atc.enabled = true
        -- self._atc:PlayEnterAnimation(true)
        YIELD(TT, 100)
        -- self._bg2loader.gameObject:SetActive(true)
        -- self._bg2loader.gameObject:SetActive(not self._showLevel1)
        self:UnLock(lockName)
    end)
end

function UIN31HardLevel:CloseTipBtnOnClick()
    local lockName = self:GetName().. ".EvilCloseAnim"
    self:StartTask(function(TT)
        self:Lock(lockName)
        -- self._atc:PlayLeaveAnimation(true)
        self._rootAni:Play("uieff_UIN31HardLevel_lv2OpenTip_hide")
        YIELD(TT, 600)
        self._level2OpenTip:SetActive(false)
        self:UnLock(lockName)
    end)
end

function UIN31HardLevel:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN31HardLevel:Level2OnClick()
    if self._isLevel2Lock then
        local cfgv = Cfg.cfg_campaign_mission[self._levelCfgs[6].CampaignMissionId]
        local lvName = StringTable.Get(cfgv.Name)
        ToastManager.ShowToast(StringTable.Get("str_activity_common_will_open_after_clearance", lvName))
        return
    end
    if not self._showLevel1 then
        return
    end
    self._showLevel1 = false

    --self:DoLevelBtnSwitch(false)
    if self._isShow then
        self:_RefreshPoint()
    end
end

function UIN31HardLevel:_RefreshPoint()
    --最难关已解锁
    for i = 1, 6 do
        local idx = i
        if not self._showLevel1 then
            idx = idx + 6
        end
        self._levels[i]:SetData(
                idx,
                self._levelCfgs[idx],
                self._passInfo[self._levelCfgs[idx].CampaignMissionId],
                self._curIndex,
                self._atlas
        )
        --self._levels[i]:Anim_In()
    end

    self.level2Btn:SetLockVisible(self._isLevel2Lock,true)
    -- local bgs = {}
    -- if self._showLevel1 then
    --     --bgs = UIN31HardLevel.LevelCfg["bghard"]
    --     self._bg1loader.gameObject:SetActive(true)
    --     self._bg2loader.gameObject:SetActive(false)

    --     self.rightBg.gameObject:SetActive(true)
    --     self.rightBg2.gameObject:SetActive(false)
    -- else
    --     --bgs = UIN31HardLevel.LevelCfg["bgevil"]
    --     self._bg2loader.gameObject:SetActive(true)
    --     self.rightBg2.gameObject:SetActive(true)
    -- end
    -- self._bg2loader:LoadImage(bgs["Bg2"])
    -- self.rightBg:LoadImage(bgs["Bg1"])
end

function UIN31HardLevel:DoLevelBtnSwitch(blevel1)
    self:StartTask(function(TT)
        self:Lock(self:GetName())

        --self._bg2loader.gameObject:SetActive(true)

        if self._showLevel1 then
            self._rootAni:Play("uieff_UIN31HardLevel_in_hard")
            YIELD(TT, 100)
            self:_RefreshPoint()
            YIELD(TT, 500)
        else
            self._rootAni:Play("uieff_UIN31HardLevel_in_highest")

            if blevel1 then
                YIELD(TT, 600)
                self:UnlockEvilAnimation()
            else
                YIELD(TT, 100)
                self:_RefreshPoint()
                YIELD(TT, 500)
            end
        end

        --self._bg2loader.gameObject:SetActive(not blevel1)

        self:UnLock(self:GetName())
    end)
end

---@return string, number
function UIN31HardLevel:GetSpineAndBgm()
    local cfg = Cfg.cfg_n25_const[1]
    if self._line_info and cfg then
        ---@type MissionModule
        local missionModule = GameGlobal.GetModule(MissionModule)
        ---@type cam_mission_info[]
        local passInfo = self._line_info.m_pass_mission_info
        for _, info in pairs(passInfo) do
            local storyId = missionModule:GetStoryByStageIdStoryType(info.mission_id, StoryTriggerType.Node)
            if storyId == cfg.StoryID then
                return cfg.Spine2, cfg.Bgm2
            end
        end
        return cfg.Spine1, cfg.Bgm1
    end
    return nil, nil
end
