--- @class UIActivityN16ReviewMainController:UIController
_class("UIActivityN16ReviewMainController", UIController)
UIActivityN16ReviewMainController = UIActivityN16ReviewMainController

--region help
function UIActivityN16ReviewMainController:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIActivityN16ReviewMainController:_PlayAnim(widgetName, animName, time, callback)
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

function UIActivityN16ReviewMainController:_InitWidget()
    self._mainBg = self:GetUIComponent("RawImageLoader", "_mainBg")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIActivityReview)
        end,
        nil,
        nil,
        false,
        function()
            self:HideBtnOnClick()
        end
    )

    ---@type UIReviewProgress
    local progress = UIReviewProgressConst.SpawnObject(self, "_progress", self._reviewData)
end

function UIActivityN16ReviewMainController:_SetProgressData(TT, res)
    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    ---@type UIReviewActivityN16
    self._reviewData = uiModule:GetReviewData():GetActivityByType(ECampaignType.CAMPAIGN_TYPE_REVIEW_N16)
    self._reviewData:ReqDetailInfo(TT, res)
end
--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN16ReviewMainController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_REVIEW_N16

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        self._campaignType,
        ECampaignReviewN16ComponentID.ECAMPAIGN_REVIEW_ReviewN16_LINE_MISSION,
        ECampaignReviewN16ComponentID.ECAMPAIGN_REVIEW_ReviewN16_POINT_PROGRESS
    )

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end

    self:_SetProgressData(TT,res)
end

function UIActivityN16ReviewMainController:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN16.spriteatlas", LoadType.SpriteAtlas)

    self._isOpen = true

    self:_InitWidget()
    self:_SetSpine()

    self:_Refresh()

    --------------------------------------------------------------------------------
    self.imgRT = uiParams[1] -- 传入底图，并决定是否播放动效
    local entermodel = "uieffanim_N16_main_show"
    if self.imgRT ~= nil then
        ---@type UnityEngine.UI.RawImage
        local rt = self:GetUIComponent("RawImage", "rt")
        rt.texture = self.imgRT
        entermodel = "uieffanim_N16_main_show"
        self:_PlayAnim(
            "_anim",
            entermodel,
            1667
        )
        CutsceneManager.ExcuteCutsceneOut()
    else
        entermodel = "uieffanim_N16_main_in"
        self:_PlayAnim(
            "_anim",
            entermodel,
            1667
        )
    end
   
end

function UIActivityN16ReviewMainController:OnHide()
    self._isOpen = false
end

function UIActivityN16ReviewMainController:_Refresh()
    self:_SetLineMissionBtn()
end

function UIActivityN16ReviewMainController:_SetBg()
    local url = UIActivityHelper.GetCampaignMainBg(self._campaign, 1)
    if url then
        self._mainBg:LoadImage(url)
    end
end

function UIActivityN16ReviewMainController:_SetSpine()
    local obj = self:GetUIComponent("SpineLoader", "_spine")
    obj:LoadSpine("n16_kv_1_spine_idle")
end
--region EnterBtn

function UIActivityN16ReviewMainController:_SetLineMissionBtn()
    local componentId = ECampaignReviewN16ComponentID.ECAMPAIGN_REVIEW_ReviewN16_LINE_MISSION

    local obj = self:_SpawnObject("_lineMissionBtn", "UIActivityCommonComponentEnterLock")

    local tb = {{"state_lock"}, {"state_lock"}, {"state_unlock"}, {"state_close"}}
    obj:SetWidgetNameGroup(tb)

    obj:SetData(
        self._campaign,
        componentId,
        function()
            self:SwitchState(UIStateType.UIActivityN16ReviewLineMissionController)
        end
    )
    local img =  obj.view:GetUIComponent("Image", "bgstate")
    img.sprite = self._atlas:GetSprite("n16_zjm_di2")
    local text =  obj.view:GetUIComponent("UILocalizationText", "txt")
    text.transform:GetComponent("Outline").enabled = true
    text.color = Color.New(203/ 255, 176 / 255, 90 / 255)
end
--endregion

--region 显示隐藏UI
function UIActivityN16ReviewMainController:ShowBtnOnClick()
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(false)
    self:_PlayAnim("_anim","uieffanim_UIActivityN16ReviewMainController_show",500)
end

function UIActivityN16ReviewMainController:HideBtnOnClick()
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(true)
    self:_PlayAnim("_anim","uieffanim_UIActivityN16ReviewMainController_hide",500)
end
--endregion

function UIActivityN16ReviewMainController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityN16ReviewMainController:_GetRoleId()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    return pstId
end
--endregion

--region Effect
function UIActivityN16ReviewMainController:_SetMainTex()
    local rawImage = self:GetUIComponent("RawImage", "TitleImg_RawImage")
    local obj = self:GetGameObject("TitleImg")
    local meshRender = obj:GetComponent(typeof(UnityEngine.MeshRenderer))
    meshRender.material:SetTexture("_MainTex", rawImage.material:GetTexture("_MainTex"))
end
--endregion