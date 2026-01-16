--- @class UIActivityN8MainController_Review:UIController
_class("UIActivityN8MainController_Review", UIController)
UIActivityN8MainController_Review = UIActivityN8MainController_Review

--region help
function UIActivityN8MainController_Review:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

-- function UIActivityN8MainController_Review:_SetRemainingTime(widgetName, descId, endTime)
--     local obj = self:_SpawnObject(widgetName, "UIActivityCommonRemainingTime")

--     obj:SetCustomTimeStr_Common_1()
--     obj:SetExtraRollingText()
--     -- obj:SetAdvanceText(descId)
--     obj:SetExtraText("txtDesc", nil, descId)

--     obj:SetData(
--         endTime,
--         nil,
--         -- function()
--         --     self:_UpdateRemainingTime()
--         -- end
--     )
-- end

function UIActivityN8MainController_Review:_PlayAnim(widgetName, animName, time, callback)
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

--endregion

function UIActivityN8MainController_Review:_InitWidget()
    self._anim = self:GetUIComponent("Animation", "_anim")

    self._mainBg = self:GetUIComponent("RawImageLoader", "_mainBg")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            GameGlobal.TaskManager():StartTask(self.CloseCoro, self)
        end,
        nil,
        nil,
        false,
        function()
            self:HideBtnOnClick()
        end
    )

    self._showBtn = self:GetGameObject("_showBtn")
end

function UIActivityN8MainController_Review:CloseCoro(TT)
    self:Lock("UIActivityN8MainController_Review_CloseCoro")
    self:SwitchState(UIStateType.UIActivityReview)
    self:UnLock("UIActivityN8MainController_Review_CloseCoro")
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN8MainController_Review:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_REVIEW_N8

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        self._campaignType,
        ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION

    )

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end

    -- 清除 new
    self._campaign:ClearCampaignNew(TT)
end

function UIActivityN8MainController_Review:OnShow(uiParams)
    self._isOpen = true
    self:_AttachEvents()

    self:_InitWidget()
    self:_SetSpine()
    self:_SetEffect()
    --self:_UpdateRemainingTime()
    self:_Refresh()
    
    -- self._shot = self:GetUIComponent("RawImage","rt")

    -- self._rt = uiParams[1]
    -- self._shot.gameObject:SetActive(self._rt~=nil)
    -- if self._rt then
    --     self._shot.texture = self._rt
    -- end
    
    --------------------------------------------------------------------------------
    -- self:_PlayAnim(
    --     "_anim",
    --     "UIActivityN8MainController_Review_in",
    --     1000,
    --     function()
    --         self:_CheckGuide()
    --     end
    -- )

    self.imgRT = uiParams[1] -- 传入底图，并决定是否播放动效

    if self.imgRT ~= nil then
        ---@type UnityEngine.UI.RawImage
        local rt = self:GetUIComponent("RawImage", "rt")
        rt.texture = self.imgRT

        self:_PlayAnim(
            "_anim",
            "UIActivityN8MainController_Review_in",
            1000,
            function()
                self:_CheckGuide()
            end
        )
    else
        self:_CheckGuide()
    end
    
    -- self.imgRT = uiParams[1] -- 传入底图，并决定是否播放动效

    -- if self.imgRT ~= nil then
    --     ---@type UnityEngine.UI.RawImage
    --     local rt = self:GetUIComponent("RawImage", "rt")
    --     rt.texture = self.imgRT

    --     self:_PlayAnim(
    --         "_anim",
    --         "UIActivityN8MainController_Review_in",
    --         1000,
    --         function()
    --             self:_CheckGuide()
    --         end
    --     )
    -- else
    --     self:_CheckGuide()
    -- end

end

function UIActivityN8MainController_Review:OnHide()
    if self.imgRT then
        self.imgRT:Release()
        self.imgRT = nil
    end

    self:_DetachEvents()
    self._isOpen = false
end

function UIActivityN8MainController_Review:Destroy()
    self._lineMatReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._lineMatReq)
    self._personMatReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._personMatReq)
    self._bpMatReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._bpMatReq)
    self._loginMatReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._loginMatReq)
    self._battleMatReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._battleMatReq)
end

function UIActivityN8MainController_Review:_Refresh()
    self:_SetLineMissionBtn()
    --self:_SetPersonProgressBtn()
    --self:_SetBattlePassBtn()
    --self:_SetLoginRewardBtn()
    --self:_SetBattleSimulatorBtn()
end

function UIActivityN8MainController_Review:_SetBg()
    local url = UIActivityHelper.GetCampaignMainBg(self._campaign, 1)
    if url then
        self._mainBg:LoadImage(url)
    end
end

function UIActivityN8MainController_Review:_SetSpine()
    local obj = self:GetUIComponent("SpineLoader", "_spine")
    obj:LoadSpine("n8_kv_spine_idle")
end

-- function UIActivityN8MainController_Review:_UpdateRemainingTime()
--     --- @type SvrTimeModule
--     local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
--     local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

--     local lineComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_LINE_MISSION, 1)
--     local endTime = lineComponent:GetComponentInfo().m_close_time
--     local stamp = endTime - curTime
--     if stamp > 0 then
--         -- self:_SetRemainingTime("_remainingTimePool", "str_activity_n8_main_time_desc", endTime)
--         -- return
--     end

--     local personProgressComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_PERSON_PROGESS, 1)
--     endTime = personProgressComponent:GetComponentInfo().m_close_time
--     stamp = endTime - curTime
--     if stamp > 0 then
--         -- self:_SetRemainingTime("_remainingTimePool", "str_activity_n8_main_time_reward_desc", endTime)
--         -- return
--     end
-- end

--region EnterBtn
function UIActivityN8MainController_Review:_SetLineMissionBtn()
    local componentId = ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION
    --local componentId2 = ECampaignN8ComponentID.ECAMPAIGN_N8_LINE_MISSION_FIXTEAM

    local obj = self:_SpawnObject("_lineMissionBtn", "UIActivityCommonComponentEnterLock")

    --obj:SetRed_RedDotModule("red", RedDotType.RDT_N8_LINEMISSION)

    self._lineMatReq = UIWidgetHelper.SetLocalizedTMPMaterial(obj, "titleText", "N8Material_02.mat", self._lineMatReq)

    local tb = { { "bg_lock" }, { "bg_lock" }, { "bg_unlock" }, { "bg_lock" } }
    obj:SetWidgetNameGroup(tb)

    obj:SetData(
        self._campaign,
        componentId,
        function()
            self:SwitchState(UIStateType.UIActivityN8LineMissionController_Review)
        end
    )
end

-- function UIActivityN8MainController_Review:_SetPersonProgressBtn()
--     local componentId = ECampaignN8ComponentID.ECAMPAIGN_N8_PERSON_PROGRESS

--     local obj = self:_SpawnObject("_personProgressBtn", "UIActivityCommonComponentEnterLock")

--     obj:SetRed_RedDotModule("red", RedDotType.RDT_N8_SIMULATOR_PRESTIGE)

--     self._personMatReq = UIWidgetHelper.SetLocalizedTMPMaterial(obj, "titleText", "N8Material_02.mat", self._personMatReq)

--     local tb = { { "bg_lock" }, { "bg_lock" }, { "bg_unlock" }, { "bg_lock" } }
--     obj:SetWidgetNameGroup(tb)

--     obj:SetData(
--         self._campaign,
--         componentId,
--         function()
--             self:ShowDialog("UIActivityN8PersonProgressController")
--         end
--     )

--     -- 从按钮中分离，在主界面右上角显示
--     local iconText = self:_SpawnObject("_personProgressIconTextPool", "UIActivityN8PersonProgressIconText")
--     iconText:SetData(self._campaign, "_icon")
-- end

-- function UIActivityN8MainController_Review:_SetBattlePassBtn()
--     local campaignType = ECampaignType.CAMPAIGN_TYPE_BATTLEPASS
--     local widgetName = "_battlePassBtn"
--     local className = "UIActivityCommonCampaignEnter"
--     local useStateUI = false

--     -- 依赖
--     -- 主菜单进入时调用的 campaignModule:GetLatestCampaignObj(TT) 中已经获取过活动信息
--     -- 所以这里只需要取本地数据
--     ---@type UIActivityCampaign
--     local campaign = UIActivityCampaign:New()
--     campaign:LoadCampaignInfo_Local(campaignType)

--     -- 获取活动是否开启
--     local open_sample = campaign:CheckCampaignOpen()

--     -- 检查活动是否开启，决定是否显示
--     if open_sample then
--         ---@type UICustomWidgetPool
--         local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
--         local obj = pool:SpawnObject(className)

--         self._bpMatReq = UIWidgetHelper.SetLocalizedTMPMaterial(obj, "titleText", "N8Material_02.mat", self._bpMatReq)
--         obj:SetData(campaign, useStateUI)
--     end

--     local obj = self:GetGameObject(widgetName)
--     obj:SetActive(open_sample)
-- end

-- function UIActivityN8MainController_Review:_SetLoginRewardBtn()
--     local componentId = ECampaignN8ComponentID.ECAMPAIGN_N8_CUMULATIVE_LOGIN

--     local obj = self:_SpawnObject("_loginRewardBtn", "UIActivityCommonComponentEnterLock")

--     obj:SetRed_RedDotModule("red", RedDotType.RDT_N8_LOGIN_AWARD)

--     self._loginMatReq = UIWidgetHelper.SetLocalizedTMPMaterial(obj, "titleText", "N8Material_02.mat", self._loginMatReq)

--     local tb = { { "bg_lock" }, { "bg_lock" }, { "bg_unlock" }, { "bg_lock" } }
--     obj:SetWidgetNameGroup(tb)

--     obj:SetData(
--         self._campaign,
--         componentId,
--         function()
--             self:ShowDialog("UIActivityTotalLoginAwardController", false, self._campaignType, componentId)
--         end
--     )
-- end

-- function UIActivityN8MainController_Review:_SetBattleSimulatorBtn()
--     local componentId = ECampaignN8ComponentID.ECAMPAIGN_N8_COMBAT_SIMULATOR

--     local obj = self:_SpawnObject("_battleSimulatorBtn", "UIActivityCommonComponentEnterLock")

--     obj:SetRed_RedDotModule("red", RedDotType.RDT_N8_SIMULATOR_FUNCTION)

--     self._battleMatReq = UIWidgetHelper.SetLocalizedTMPMaterial(obj, "titleText", "N8Material_01.mat", self._battleMatReq)

--     local component = self._campaign:GetComponent(componentId)
--     local unlockTime = component and component:ComponentUnLockTime() or 0
--     obj:SetActivityCommonRemainingTime("remainingTimePool", nil, unlockTime, true)

--     local tb = { { "closed", "lock", "lockWitchTime" }, { "closed", "lock" }, {}, { "closed" } }
--     obj:SetWidgetNameGroup(tb)

--     obj:SetData(
--         self._campaign,
--         componentId,
--         function()
--             self:SwitchState(UIStateType.UIActivityN8BattleSimulatorController)
--         end
--     )
-- end

--endregion

--region 显示隐藏UI
function UIActivityN8MainController_Review:ShowBtnOnClick()
    local hideBtn = self:GetGameObject("_backBtns")
    hideBtn:SetActive(true)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(false)
    self._anim:Play("uieff_N8_Main_Show")
end

function UIActivityN8MainController_Review:HideBtnOnClick()
    local hideBtn = self:GetGameObject("_backBtns")
    hideBtn:SetActive(false)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(true)
    self._anim:Play("uieff_N8_Main_Hide")
end

--endregion

--region Event Callback
--活动说明
function UIActivityN8MainController_Review:InfoBtnOnClick(go)
    self:ShowDialog("UIActivityIntroController", "UIActivityN8MainController_Review")
end

--endregion

--region AttachEvent
function UIActivityN8MainController_Review:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIActivityN8MainController_Review:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIActivityN8MainController_Review:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end


function UIActivityN8MainController_Review:_SetEffect()
    self:_SetSpineEffect("_spine")
end

--endregion

--region Effect
-- function UIActivityN8MainController_Review:_SetEffect()
--     self:_SetMask()
--     self:_HandelRawImageMaterial("_effect_Image")
--     self:_HandelRawImageMaterial("_effect_TitleImg")
--     self:_SetSpineEffect("_spine")
-- end

-- function UIActivityN8MainController_Review:_SetMask()
--     local scr = self:GetUIComponent("RectTransform", "_effect_SafeArea")
--     local obj = self:GetUIComponent("RectTransform", "_effect_Mask")
--     obj.localScale = Vector2(scr.rect.size.x, scr.rect.size.y)
-- end



function UIActivityN8MainController_Review:_SetSpineEffect(widgetName)
    local obj = self:GetGameObject(widgetName)

    ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
    local spineSkeMultipleTex = obj:GetComponentInChildren(typeof(Spine.Unity.Modules.SkeletonGraphicMultiObject))

    spineSkeMultipleTex.UseInstanceMaterials = true

    spineSkeMultipleTex.OnInstanceMaterialCreated = function(material)
        self:_HandelSpineMaterial(material)
    end

    spineSkeMultipleTex:UpdateMesh()
end

function UIActivityN8MainController_Review:_HandelSpineMaterial(material)
    material:SetFloat("_StencilComp", 3)
    --material:SetFloat("_StencilRef", 10)
end

-- function UIActivityN8MainController_Review:_HandelRawImageMaterial(widgetName)
--     local obj = self:GetUIComponent("RawImage", widgetName)
--     if obj.material ~= obj.defaultGraphicMaterial then -- 防止图片丢失时修改 default
--         obj.material:SetFloat("_StencilComp", 3)
--         obj.material:SetFloat("_Stencil", 10)
--     end
-- end

--endregion

function UIActivityN8MainController_Review:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIActivityN8MainController_Review)
end
