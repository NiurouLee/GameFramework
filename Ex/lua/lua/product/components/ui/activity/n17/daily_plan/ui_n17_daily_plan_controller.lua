---@class UIN17DailyPlanController:UIController
_class("UIN17DailyPlanController", UIController)
UIN17DailyPlanController = UIN17DailyPlanController

--region help
--
function UIN17DailyPlanController:_SetRawImageBtn(widgetName, size, urlNormal, urlClick, callback)
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRawImageBtn")
    obj:SetData(size, urlNormal, urlClick, callback)
end

--endregion

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN17DailyPlanController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N17
    self._componentCycleQuestId = ECampaignN17ComponentID.ECAMPAIGN_N17_CYCLE_QUEST
    self._componentStoryId = ECampaignN17ComponentID.ECAMPAIGN_N17_STORY

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, self._componentCycleQuestId, self._componentStoryId)

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end
end

--
function UIN17DailyPlanController:OnShow(uiParams)
    self._inHome = uiParams[1]

    self:_SetTabBtns()
    self:_SetTabPages()
    self:_SetTabSelect(self._inHome and 2 or 1) -- 设置起始按钮，从家园进入显示 空谷清单

    self:_SetInHomeMode()
    -- self:_Refresh()

    self._campaign:GetLocalProcess():OnOpenPlanList()
end

--
function UIN17DailyPlanController:OnHide()
end

--
function UIN17DailyPlanController:_Refresh()
    local index = self._tabIndex
    local components = {
        self._campaign:GetComponent(self._componentStoryId),
        self._campaign:GetComponent(self._componentCycleQuestId)
    }

    ---@type UIN17DailyPlanTabExplore
    ---@type UIN17DailyPlanTabHome
    self._tabPages[index]:SetData(components[index], self._inHome, function()
        self:CloseDialog()
    end)
end

-- 设置家园内模式
function UIN17DailyPlanController:_SetInHomeMode()
    if self._inHome then
        self._tabBtns[1]:GetGameObject():SetActive(false)
    end
end

--region TabBtn TabPage

-- 设置 tab btn
function UIN17DailyPlanController:_SetTabBtns()
    local title = {
        "str_n17_daily_plan_tab_btn_explore",
        "str_n17_daily_plan_tab_btn_home"
    }

    ---@type UIHomelandShopTabBtn[]
    self._tabBtns = UIWidgetHelper.SpawnObjects(self, "_tabBtns", "UIActivityCommonTextTabBtn", #title)
    for i, v in ipairs(self._tabBtns) do
        v:SetData(
            i, -- 索引
            {
                indexWidgets = {}, -- 与索引相关的状态组
                onoffWidgets = { { "OnBtn" }, { "OffBtn" } }, -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = {}, --- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = { "txtTitle_off", "txtTitle_on" }, -- 标题列表组
                titleText = StringTable.Get(title[i]), -- 标题文字
                callback = function(index, isOffBtnClick) -- 点击按钮回调
                    if isOffBtnClick then
                        self:_SetTabSelect(index)
                    end
                end
            }
        )
    end
end

-- 刷新 tab
function UIN17DailyPlanController:_SetTabSelect(index)
    if self._tabIndex == index then
        return
    end

    self._tabIndex = index
    for i = 1, #self._tabBtns do
        self._tabBtns[i]:SetSelected(i == index)
        self._tabPages[i]:GetGameObject():SetActive(i == index)
    end

    self:_Refresh()
end

-- 设置 tab page
function UIN17DailyPlanController:_SetTabPages()
    self._tabPages = {}
    self._tabPages[1] = UIWidgetHelper.SpawnObject(self, "_tab_Explore", "UIN17DailyPlanTabExplore")
    self._tabPages[2] = UIWidgetHelper.SpawnObject(self, "_tab_Home", "UIN17DailyPlanTabHome")
end

--endregion

--region Event Callback

--
function UIN17DailyPlanController:CloseBtnOnClick(go)
    UIWidgetHelper.PlayAnimation(self,
        "_anim",
        "UIN17DailyPlanController_anim2",
        500,
        function()
            self:CloseDialog()
        end
    )
end

--
function UIN17DailyPlanController:AssistantOnClick(go)
end

--endregion
