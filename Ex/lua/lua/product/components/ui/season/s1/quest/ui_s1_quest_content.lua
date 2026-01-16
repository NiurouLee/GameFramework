---@class UIS1QuestContent : UICustomWidget
_class("UIS1QuestContent", UICustomWidget)
UIS1QuestContent = UIS1QuestContent

function UIS1QuestContent:OnShow(uiParams)
    --是否响应事件，一般不用
    self._responseEvent = true
    self._claimItems = {}

    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    self._seasonId = self._seasonModule:GetCurSeasonID()

    ---@type UISeasonObj
    self._seasonObj = self._seasonModule:GetCurSeasonObj()

    self._componentId = ECCampaignSeasonComponentID.QUEST
    --- @type CampaignQuestComponent
    self._component = self._seasonObj:GetComponent(self._componentId)

    self._tipsCallback = function(matid, pos)
        UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
    end

    self:_Attach()
end

function UIS1QuestContent:OnHide()
    self:_Detach()
end

function UIS1QuestContent:SetData(params)
    self._ownerName = params and params.ownerName
    self._closeCallback = params and params.closeCallback

    local type = (self._ownerName == "UISeasonQuestController") and 1 or 2
    local isZh = UIActivityZhHelper.IsZh() -- 国服
    type = isZh and type or 1 -- 国际服的任务界面不需要调整横向坐标
    self._type = type

    self:_SetScrollView_Bg()

    self:_Refresh(true)

    -- 设置滑动列表位置
    local first = self:_CalcFirstShowIndex()
    self:_SetScrollViewPosByIndex(first)

    self:_SetType(type)
    self:_PlayAnim(type)
    self:_CellListPlayAnim(first)
end

function UIS1QuestContent:_Refresh(isFirst)
    self:_SetCellList()
    self:_SetClaimAllBtn()
end

function UIS1QuestContent:_SetType(type)
    if type == 1 then
        return
    end

    local offset = 180
    UIWidgetHelper.SetAnchoredPosition(self, "ScrollView_Bg", offset, 0)
    UIWidgetHelper.SetAnchoredPosition(self, "_nextPageHint", offset, 0)
    UIWidgetHelper.SetAnchoredPosition(self, "ScrollView_Item", offset, 0)
    UIWidgetHelper.SetAnchoredPosition(self, "_desc", offset, 0)
end

function UIS1QuestContent:_PlayAnim(type, callback)
    local tb = {
        { animName = "uieffanim_UIS1QuestContent_in", duration = 1333 },
        { animName = "uieffanim_UIS1QuestContent_in2", duration = 1333 },
        { animName = "uieffanim_UIS1QuestContent_out", duration = 200 }
    }
    UIWidgetHelper.PlayAnimation(self, "_anim", tb[type].animName, tb[type].duration, callback, true)
end

function UIS1QuestContent:_SetClaimAllBtn()
    local isShow = self._component:HasQuestCanClaim(self._cellDatas)
    self:GetGameObject("ClaimAllBtn"):SetActive(isShow)
end

function UIS1QuestContent:_SetScrollView_Bg()
    local nextPageHint = self:GetGameObject("_nextPageHint")

    ---@type UnityEngine.UI.ScrollRect
    local svBg = self:GetUIComponent("ScrollRect", "ScrollView_Bg")
    ---@type UnityEngine.UI.ScrollRect
    local svItem = self:GetUIComponent("ScrollRect", "ScrollView_Item")

    svItem.onValueChanged:AddListener(
        function(value)
            local y = Mathf.Clamp(value.y, 0, 1)
            svBg.verticalNormalizedPosition = y

            local isShow = (y > 0.05) and true or false
            nextPageHint:SetActive(isShow)
        end
    )
end

function UIS1QuestContent:_SetCellListData()
    local filter = {
        [CampaignQuestStatus.CQS_NotStart] = false,
        [CampaignQuestStatus.CQS_Accepted] = true,
        [CampaignQuestStatus.CQS_Completed] = true,
        [CampaignQuestStatus.CQS_Taken] = true,
        [CampaignQuestStatus.CQS_Over] = true
    }
    self._cellDatas = self._component:GetQuestInfo_ByCampaignQuestStatus(filter)
    self._questStatus = self._component:GetCampaignQuestStatus(self._cellDatas)
end

function UIS1QuestContent:_SetCellList()
    self:_SetCellListData()

    ---@type UIS1QuestCell
    local objs = UIWidgetHelper.SpawnObjects(self, "Content", "UIS1QuestCell", #self._cellDatas)
    for i, v in ipairs(objs) do
        local quest = self._cellDatas[i]
        local state = self._questStatus[quest]
        v:SetData(self._type, i, self._component, quest, state,
            function(uiView, questInfo)
                self:_ClaimOneBtn(uiView, questInfo)
            end,
            self._tipsCallback
        )
    end
    self._cells = objs
end

function UIS1QuestContent:_CellListPlayAnim(first)
    local offset = 4
    local start = Mathf.Max(first - offset, 1)
    local stop = #self._cells
    for i = start, stop do
        local v = self._cells[i]
        if v then
            v:PlayAnimationInSequence(i - start + 1)
        end
    end
end

function UIS1QuestContent:_CalcFirstShowIndex()
    local count = #self._cellDatas
    local offset_center = -2 -- 调整至屏幕中央
    local offset_top = 0     -- 调整至屏幕上方

    local index
    -- 1. 可领取状态任务，显示在屏幕中央位置
    for i, v in ipairs(self._cellDatas) do
        if index then
            break
        end
        if self._questStatus[v] == CampaignQuestStatus.CQS_Completed then
            index = i + offset_center
        end
    end
    -- 2. 若无可领取任务，首个非已完成任务，显示在屏幕上方
    if not index then
        for i, v in ipairs(self._cellDatas) do
            if self._questStatus[v] ~= CampaignQuestStatus.CQS_Taken then
                index = i + offset_top
                break
            end
        end
    end

    return index or 1
end

function UIS1QuestContent:_SetScrollViewPosByIndex(index)
    local count = #self._cellDatas

    -- local _debug = true
    -- if _debug then
    --     local key = "UIS1QuestContent:_CalcFirstShowIndex_Debug"
    --     index = LocalDB.GetInt(key, 1)

    --     local next = (index == count) and 1 or (index + 1)
    --     LocalDB.SetInt(key, next)
    -- end

    local pos = Mathf.Clamp((count - index) / (count - 1), 0, 1)
    self:_SetScrollViewPos(false, pos)
end

function UIS1QuestContent:_SetScrollViewPos(hor, normalizedPos)
    ---@type UnityEngine.UI.ScrollRect
    local svItem = self:GetUIComponent("ScrollRect", "ScrollView_Item")
    if hor then
        svItem.horizontalNormalizedPosition = normalizedPos
    else
        svItem.verticalNormalizedPosition = normalizedPos
    end
end

--region Event

function UIS1QuestContent:ClaimAllBtnOnClick(go)
    self._claimItems = self._component:GetQuestCanClaim(self._cellDatas)
    self._component:Start_HandleOneKeyTakeQuest(function(res, rewards)
        self:_OnRecvRewards(res, rewards)
    end)
end

--endregion

---@param questInfo MobileQuestInfo
function UIS1QuestContent:_ClaimOneBtn(uiView, questInfo)
    self._claimItems = { questInfo.quest_id }
    self._component:Start_HandleQuestTake(questInfo.quest_id, function(res, rewards)
        self:_OnRecvRewards(res, rewards)
    end)
end

function UIS1QuestContent:_OnRecvRewards(res, rewards)
    if not self.view then
        return
    end

    if res and res:GetSucc() then
        UISeasonHelper.ShowUIGetRewards(rewards)
        self:DispatchEvent(GameEventType.OnSeasonQuestAwardCollected)
    else
        self._seasonModule:CheckErrorCode(res.m_result, self._seasonId, 
            function()
                self:_Refresh()
            end,
            function()
                if self._closeCallback then
                    self._closeCallback()
                end
            end
        )
    end
end

---------------------------------------------------
function UIS1QuestContent:_Attach()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIS1QuestContent:_Detach()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIS1QuestContent:OnUIGetItemCloseInQuest()
    if self._ownerName ~= "UISeasonQuestController" and not self._responseEvent then
        return
    end

    if table.count(self._claimItems) ~= 0 then
        self:ShowDialog("UISeasonQuestDetail", self._claimItems)
        self._claimItems = {}
    end
    self:_Refresh()
end

--是否响应获得物品界面关闭消息,任务界面用
function UIS1QuestContent:SetResponseEvent(val)
    self._responseEvent = val
end
