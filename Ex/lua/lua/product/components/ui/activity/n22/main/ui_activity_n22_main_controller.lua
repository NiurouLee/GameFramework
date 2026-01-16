--- @class UIActivityN22MainController:UIController
_class("UIActivityN22MainController", UIController)
UIActivityN22MainController = UIActivityN22MainController

function UIActivityN22MainController:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIActivityN22MainController:_SetRemainingTime(widgetName, extraId, descId, endTime, customTimeStr)
    ---@type UIActivityCommonRemainingTime
    local obj = self:_SpawnObject(widgetName, "UIActivityCommonRemainingTime")
    if customTimeStr then
        obj:SetCustomTimeStr_Common_1()
    end
    -- obj:SetExtraRollingText()
    obj:SetExtraText("txtDesc", nil, extraId)
    obj:SetAdvanceText(descId)

    obj:SetData(
        endTime,
        nil,
        function()
            self:_UpdateRemainingTime()
        end
    )
end

function UIActivityN22MainController:_PlayAnim(widgetName, animName, time, callback)
    local anim = self:GetUIComponent("Animation", widgetName)

    self:Lock(animName)
    anim:Play(animName)
    self:StartTask(
        function(TT)
            YIELD(TT, time)
            self:UnLock(animName)
            if callback then
                callback()
            end
        end,
        self
    )
end

function UIActivityN22MainController:_InitWidget()
    self._mainBg = self:GetUIComponent("RawImageLoader", "_mainBg")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIMain)
        end,
        nil,
        nil,
        false,
        function()
            local  entermodel = "uieff_UIN22MainController_out"
            self:_PlayAnim(
                "_anim",
                entermodel,
                500,
                function()
                    self:HideBtnOnClick()
                end
            )
            --
        end
    )
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN22MainController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N22
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        self._campaignType,
        ECampaignN22ComponentID.ECAMPAIGN_N22_CUMULATIVE_LOGIN,
        ECampaignN22ComponentID.ECAMPAIGN_N22_FIRST_MEET,
        ECampaignN22ComponentID.ECAMPAIGN_N22_LINE_MISSION,
        ECampaignN22ComponentID.ECAMPAIGN_N22_DIFFICULT_MISSION,
        ECampaignN22ComponentID.ECAMPAIGN_N22_POWER2ITEM,
        ECampaignN22ComponentID.ECAMPAIGN_N22_SHOP,
        ECampaignN22ComponentID.ECAMPAIGN_N22_ENTRUST
    )
    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end
    -- 清除 new
    self._campaign:ClearCampaignNew(TT)
end

function UIActivityN22MainController:OnShow(uiParams)
    N22Data.SetPrefsMain()
    self:_AttachEvents()
    self._isOpen = true

    self._atlas = self:GetAsset("UIN22.spriteatlas", LoadType.SpriteAtlas)
    --- @type SvrTimeModule
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self:_InitWidget()
    self:_SetSpine()

    self:_UpdateRemainingTime()
    self:_Refresh()

    --------------------------------------------------------------------------------
    self.imgRT = uiParams[1] -- 传入底图，并决定是否播放动效
    local entermodel = "uieff_UIN22MainController_in"
    if self.imgRT ~= nil then
        ---@type UnityEngine.UI.RawImage
        -- local rt = self:GetUIComponent("RawImage", "rt")
        -- rt.texture = self.imgRT
        self:_PlayAnim(
            "_anim",
            entermodel,
            1667,
            function()
               self:_CheckGuide()
            end
        )
        CutsceneManager.ExcuteCutsceneOut()
    else
        self:_PlayAnim(
            "_anim",
            entermodel,
            1667,
            function()
                self:_CheckGuide()
            end
        )
    end 
end

function UIActivityN22MainController:OnHide()
    self:_DetachEvents()
    self._isOpen = false
end

function UIActivityN22MainController:_Refresh()
    self:_SetBattlePassBtn()
    self:_SetExchangeBtn()
    self:_SetLoginRewardBtn()
    self:_SetLineMissionBtn()
    self:_SetHardLevelBtn()
    self:_SetEntrustBtn()
end

function UIActivityN22MainController:_SetBg()
    local url = UIActivityHelper.GetCampaignMainBg(self._campaign, 1)
    if url then
        self._mainBg:LoadImage(url)
    end
end

function UIActivityN22MainController:_SetSpine()
    local obj = self:GetUIComponent("SpineLoader", "_spine")
   -- obj:LoadSpine("n22_kv_1_spine_idle")
end

function UIActivityN22MainController:_UpdateRemainingTime()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local lineComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_LINE_MISSION, 1)
    local endTime = lineComponent:GetComponentInfo().m_close_time
    local stamp = endTime - curTime
    if stamp > 0 then
        self:_SetRemainingTime("_remainingTimePool", "str_n22_activity_main_lasttime", nil, endTime, true)
        return
    end

    local exchangeItemComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_EXCHANGE_ITEM, 1)
    endTime = exchangeItemComponent:GetComponentInfo().m_close_time
    stamp = endTime - curTime
    if stamp > 0 then
        self:_SetRemainingTime("_remainingTimePool", "str_n22_exchange_lasttime_desc", nil, endTime)
        return
    end
end

--region EnterBtn
function UIActivityN22MainController:_SetBattlePassBtn()
    local campaignType = ECampaignType.CAMPAIGN_TYPE_BATTLEPASS
    local widgetName = "_battlePassBtn"
    local className = "UIActivityCommonCampaignEnter"
    local useStateUI = false

    -- 依赖
    -- 主菜单进入时调用的 campaignModule:GetLatestCampaignObj(TT) 中已经获取过活动信息
    -- 所以这里只需要取本地数据
    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    campaign:LoadCampaignInfo_Local(campaignType)

    -- 获取活动是否开启
    local open_sample = campaign:CheckCampaignOpen()

    -- 检查活动是否开启，决定是否显示
    if open_sample then
        ---@type UICustomWidgetPool
        local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
        local obj = pool:SpawnObject(className)
        obj:SetData(campaign, useStateUI)
    end

    local obj = self:GetGameObject(widgetName)
    obj:SetActive(open_sample)
end

function UIActivityN22MainController:_SetExchangeBtn()
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_SHOP

    self.exchangeobj = self:_SpawnObject("_exchangeBtn", "UIActivityCommonComponentEnter")

    self.exchangeobj:SetRed(
        "red",
        function()
            return self._campaign:CheckComponentOpen(componentId) and self._campaign:CheckComponentRed(componentId)
        end
    )

    ---@type ExchangeItemComponent
    local component = self._campaign:GetComponent(componentId)
    local icon, count = component:GetCostItemIconText()
    if icon then
        self.exchangeobj:SetIcon("icon", icon)
    end
    local preZero = UIActivityHelper.GetZeroStrFrontNum(7, count)
    local fmtStr = string.format("<color=#d4cdc8>%s</color><color=#f2d385>%s</color>", preZero, tostring(count))
    self.exchangeobj:SetText("text", fmtStr)

    self.exchangeobj:SetData(
        self._campaign,
        function()
            ClientCampaignShop.OpenCampaignShop(
                self._campaign._type,
                self._campaign._id,
                function()
                    self:SwitchState(UIStateType.UIActivityN22MainController)
                end
            )
        end
    )
end

function UIActivityN22MainController:_RefeshCount() 
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_SHOP
    local component = self._campaign:GetComponent(componentId)
    local icon, count = component:GetCostItemIconText()
    local preZero = UIActivityHelper.GetZeroStrFrontNum(7, count)
    local fmtStr = string.format("<color=#4c4c4c>%s</color><color=#d1b24c>%s</color>", preZero, tostring(count))
    self.exchangeobj:SetText("text", fmtStr)
end 

function UIActivityN22MainController:_SetLoginRewardBtn()
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_CUMULATIVE_LOGIN

    local obj = self:_SpawnObject("_loginRewardBtn", "UIActivityCommonComponentEnter")

    obj:SetRed(
        "red",
        function()
            return self._campaign:CheckComponentOpen(componentId) and self._campaign:CheckComponentRed(componentId)
        end
    )

    obj:SetData(
        self._campaign,
        function()
            self:ShowDialog("UIActivityTotalLoginAwardController", false, self._campaignType, componentId)
        end
    )
end

function UIActivityN22MainController:_SetLineMissionBtn()
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_LINE_MISSION
    local componentId2 = ECampaignN22ComponentID.ECAMPAIGN_N22_FIRST_MEET

    local component = self._campaign:GetComponent(componentId)

    local obj = self:_SpawnObject("_lineMissionBtn", "UIActivityCommonComponentEnterLock")

    obj:SetRed(
        "red",
        function()
            return self._campaign:CheckComponentOpen(componentId, componentId2) and
                self._campaign:CheckComponentRed(componentId, componentId2)
        end
    )
    local roleId = self:_GetRoleId()
    obj:SetNew(
        "new",
        function()
            local isNew =  component:ComponentIsOpen() and not LocalDB.HasKey("UIActivityN22lineMission" .. roleId)
            return isNew
        end
    )

    local unlockTime = component and component:ComponentUnLockTime() or 0
    obj:SetActivityCommonRemainingTime("_timePool_lock", nil, unlockTime, true)

    local tb = {
        {"time_lock"}, 
        {"state_lock"}, 
        {"state_unlock"}, 
        {"state_close"}}
    obj:SetWidgetNameGroup(tb)

    obj:SetData(
        self._campaign,
        componentId,
        function()
            self:SwitchState(UIStateType.UIActivityN22LineMissionController)
            LocalDB.SetInt("UIActivityN22lineMission"..roleId, 1)
            N22Data.SetPrefsMission()
        end
    )

end

function UIActivityN22MainController:_SetHardLevelBtn()
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_DIFFICULT_MISSION
    local component = self._campaign:GetComponent(componentId)

    local obj = self:_SpawnObject("_hardLevelBtn", "UIActivityCommonComponentEnterLock")

    local roleId = self:_GetRoleId()
    obj:SetNew(
        "new",
        function()
            return component:ComponentIsOpen() and not LocalDB.HasKey("UIActivityN22HardLevel" .. roleId)
        end
    )

    obj:SetRed(
        "red",
        function()
            return self._campaign:CheckComponentOpen(componentId) and self._campaign:CheckComponentRed(componentId)
        end
    )

    local unlockTime = component and component:ComponentUnLockTime() or 0
    obj:SetActivityCommonRemainingTime("_timePool_lock", nil, unlockTime, true)

    --local closeTime = component and component:GetComponentInfo().m_close_time or 0
    --obj:SetActivityCommonRemainingTime("_remainingTimePool_unlock", nil, closeTime, false)

    local tb = {
        {"time_lock"},
        {"state_lock"},
        {"state_unlock"},
        {"state_close"}
    }
    obj:SetWidgetNameGroup(tb)

    obj:SetData(
        self._campaign,
        componentId,
        function()
            N22Data.SetPrefsHard()
            self:SwitchState(UIStateType.UIActivtiyN22HardLevelController, {false, false, nil})
        end
    )
end

function UIActivityN22MainController:_SetEntrustBtn()
    local componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_ENTRUST
    local component = self._campaign:GetComponent(componentId)

    local obj = self:_SpawnObject("_subjectBtn", "UIActivityCommonComponentEnterLock")

    local roleId = self:_GetRoleId()
    obj:SetNew(
        "new",
        function()
            return component:HasNew()
        end
    )

    obj:SetRed(
        "red",
        function()
            return false
        end
    )

    local unlockTime = component and component:ComponentUnLockTime() or 0
    obj:SetActivityCommonRemainingTime("_timePool_lock", nil, unlockTime, true)

    -- local closeTime = component and component:GetComponentInfo().m_close_time or 0
    -- obj:SetActivityCommonRemainingTime("_remainingTimePool_unlock", nil, closeTime, false)

    local tb = {
        {"time_lock"},
        {"state_lock"},
        {"state_unlock"},
        {"state_close"}
    }
    obj:SetWidgetNameGroup(tb)

    obj:SetData(
        self._campaign,
        componentId,
        function()
            self:_SwitchEntrust()
        end
    )
end
--endregion

--region 显示隐藏UI
function UIActivityN22MainController:ShowBtnOnClick()
    local hideBtn = self:GetGameObject("_backBtns")
    hideBtn:SetActive(true)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(false)
    local uiElements = self:GetGameObject("_uiElements")
    uiElements:SetActive(true)
    local entermodel = "uieff_UIN22MainController_in2"
    self:_PlayAnim(
        "_anim",
        entermodel,
        500,
        function()
           
        end
    )
end

function UIActivityN22MainController:HideBtnOnClick()
    local hideBtn = self:GetGameObject("_backBtns")
    hideBtn:SetActive(false)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(true)
    local uiElements = self:GetGameObject("_uiElements")
    uiElements:SetActive(false)
end
--endregion

--region Event Callback
--活动说明
function UIActivityN22MainController:InfoBtnOnClick(go)
    UIActivityHelper.ShowActivityIntro("UIActivityN22MainController")
end
--endregion

--region AttachEvent
function UIActivityN22MainController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._RefeshCount)
end

function UIActivityN22MainController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._RefeshCount)
end

function UIActivityN22MainController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityN22MainController:_GetRoleId()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    return pstId
end
--endregion

--region Effect
function UIActivityN22MainController:_SetEffect()
    
end

function UIActivityN22MainController:_SetMainTex()
    local rawImage = self:GetUIComponent("RawImage", "TitleImg_RawImage")
    local obj = self:GetGameObject("TitleImg")
    local meshRender = obj:GetComponent(typeof(UnityEngine.MeshRenderer))
    meshRender.material:SetTexture("_MainTex", rawImage.material:GetTexture("_MainTex"))
end
--endregion

function UIActivityN22MainController:_SwitchEntrust()
    local screenShot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    screenShot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local rt = screenShot:RefreshBlurTexture()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    self:StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            self:SwitchState(UIStateType.UIN22EntrustStageController, cache_rt, true)
            N22Data.SetPrefsEntrust()
        end
    )
end

--N22 引导
function UIActivityN22MainController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIActivityN22MainController)
end

