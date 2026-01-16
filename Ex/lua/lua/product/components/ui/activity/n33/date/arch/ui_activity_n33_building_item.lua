--
---@class UIActivityN33BuildingItem : UICustomWidget
_class("UIActivityN33BuildingItem", UICustomWidget)
UIActivityN33BuildingItem = UIActivityN33BuildingItem
local ARCH_LEVEL_MIN_CONST = 1
local ARCH_LEVEL_MAX_CONST = 4
--初始化
function UIActivityN33BuildingItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIActivityN33BuildingItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    ---@type RawImageLoader
    self.icon_item_3000328Loader = self:GetUIComponent("RawImageLoader", "icon_item_3000328")
    ---@type UnityEngine.GameObject
    self.bubbleNode = self:GetGameObject("BubbleNode")
    ---@type UILocalizationText
    self.coinNumTextMax = self:GetUIComponent("UILocalizationText", "CoinNumTextMax")
    ---@type UILocalizedTMP
    self.coinNumText = self:GetUIComponent("UILocalizedTMP", "CoinNumText")
    ---@type UnityEngine.GameObject
    self.starNode = self:GetGameObject("StarNode")
    ---@type UnityEngine.UI.Image
    self.starNode_1 = self:GetUIComponent("Image", "StarNode_1")
    ---@type UnityEngine.UI.Image
    self.starNode_2 = self:GetUIComponent("Image", "StarNode_2")
    ---@type UnityEngine.UI.Image
    self.starNode_3 = self:GetUIComponent("Image", "StarNode_3")
    ---@type UnityEngine.UI.Image
    self.starNode_4 = self:GetUIComponent("Image", "StarNode_4")
    ---@type UnityEngine.GameObject
    self.infoNode = self:GetGameObject("InfoNode")
    ---@type UnityEngine.GameObject
    self.lvUpNode = self:GetGameObject("LvUpNode")
    ---@type UILocalizationText
    self.nameText = self:GetUIComponent("UILocalizationText", "NameText")
    ---@type UILocalizationText
    self.nameText2 = self:GetUIComponent("UILocalizationText", "NameText2")
    ---@type UnityEngine.GameObject
    self.receiveCDNode = self:GetGameObject("ReceiveCDNode")
    ---@type UnityEngine.UI.Image
    self.receiveCDImage = self:GetUIComponent("Image", "ReceiveCDImage")
    ---@type UILocalizationText
    self.fullCoinTipsText = self:GetUIComponent("UILocalizationText", "FullCoinTipsText")
    ---@type UILocalizationText
    self.coinFullMarkText = self:GetUIComponent("UILocalizationText", "CoinFullMarkText")
    ---@type UnityEngine.UI.Image
    self.bubbleBG1 = self:GetUIComponent("Image", "BubbleBG1")
    ---@type UnityEngine.UI.Image
    self.bubbleBG2 = self:GetUIComponent("Image", "BubbleBG2")
    ---@type UnityEngine.GameObject
    self.effNode = self:GetGameObject("eff")
    self._atlas = self:GetAsset("UIN33Date.spriteatlas", LoadType.SpriteAtlas)

    self.rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self.nameRectTransform = self.infoNode:GetComponent("RectTransform")
    self.bubbleRectTransform = self.bubbleNode:GetComponent("RectTransform")
    self.receiveRectTransform = self.receiveCDNode:GetComponent("RectTransform")
    self.starNumMax = 4
    self.v2_0_5 = Vector2(0.5, 0.5)
    self.allLvBuildingCfg = nil
    self.nextReceiveTime = 0
    self.receiveCoinCD = 0
    self.serverData = nil
    self.currArchID = 0
    self._currentTimeEvent = 
        GameGlobal.RealTimer():AddEventTimes(1000, TimerTriggerCount.Infinite, self.OnOneMinusUpdate, self)

    self:AttachEvent(GameEventType.OnDateFilterClick, self._OnDateFilterClick)
    ---@type ArchInfo
    self.currArchServerData = nil
    self.isAllArchFullLv = false
    self._anim = self:GetGameObject():GetComponent("Animation")
    --generated end--
end
--设置数据
---@param archID number
---@param serverData ArchInfo[]
---@param archCfg ComponentSimulationBuildingInfo[]
---@param activityConst UIActivityN33DateData
function UIActivityN33BuildingItem:SetData(archID, serverData, archCfg, isAllArchFullLv, activityConst)
    self.activityConst = activityConst
    self.currArchID = archID
    self.allLvBuildingCfg = archCfg
    self.isAllArchFullLv = isAllArchFullLv
    self:_RefreshShow(archID, serverData, true)
    self.fullCoinTipsText.gameObject:SetActive(false)
end
---@param serverData ArchInfo[]
function UIActivityN33BuildingItem:RefreshData(serverData, isAllArchFullLv)
    self.isAllArchFullLv = isAllArchFullLv
    self:_RefreshShow(self.currArchID, serverData, false)
end
---@param archID number
---@param serverData ArchInfo[]
function UIActivityN33BuildingItem:_RefreshShow(archID, serverData, isInit)
    self.serverData = serverData
    local currArchServerData = nil
    for key, value in pairs(serverData) do
        if value.arch_id == archID then
            currArchServerData = value
            break
        end
    end
    self.currArchServerData = currArchServerData
    local conf = self.allLvBuildingCfg[currArchServerData.level]
    if not self.iconLoader then
        return
    end
    self.iconLoader:LoadImage(conf.Icon)
    self.icon_item_3000328Loader:LoadImage("icon_item_3000328")
    self.nameText:SetText(StringTable.Get(conf.MapName))
    self.nameText2:SetText(StringTable.Get(conf.MapName))
    for i = 1, self.starNumMax do
        if not self["starNode_"..i] then
            return
        end
        self["starNode_"..i].gameObject:SetActive(i == conf.Level)
    end
    if isInit then
        local mapPos = conf.MapPos
        if not mapPos then
            mapPos = self.allLvBuildingCfg[1].MapPos
        end
        self.rectTransform.anchorMax = self.v2_0_5
        self.rectTransform.anchorMin = self.v2_0_5
        self.rectTransform.sizeDelta = Vector2.zero
        self.rectTransform.anchoredPosition = mapPos
        self:SetVisible(true)

        -- 气泡是否反转
        local isReverse = conf.BubbleReverse
        if not isReverse then
            isReverse = self.allLvBuildingCfg[1].BubbleReverse
        end
        self.bubbleBG1.gameObject:SetActive(not isReverse)
        self.bubbleBG2.gameObject:SetActive(isReverse)
        local NamePos = conf.NamePos
        if not NamePos then
            NamePos = self.allLvBuildingCfg[1].NamePos
        end
        self.nameRectTransform.anchoredPosition = NamePos
        local BubbleNodePos = conf.BubbleNodePos
        if not BubbleNodePos then
            BubbleNodePos = self.allLvBuildingCfg[1].BubbleNodePos
        end
        self.bubbleRectTransform.anchoredPosition = BubbleNodePos
        self.receiveRectTransform.anchoredPosition = BubbleNodePos
    end

    if self.isAllArchFullLv then
        self:AllArchFullLvRefreshUI()
    else
        local  all_coin = currArchServerData.coin_num + currArchServerData.default_coin
        self:_RefreshReceiveCD(currArchServerData.cd)
        self.coinNumText:SetText(tostring(all_coin))
        self.coinNumTextMax:SetText(all_coin)
        self:_RefreshUpState(currArchServerData.level)
        local isMax = all_coin >= conf.LimitNum
        self.coinNumText.gameObject:SetActive(not isMax)
        self.coinNumTextMax.gameObject:SetActive(isMax)
        -- self.coinFullMarkText.gameObject:SetActive(isMax)
        self:RefreshFullCoinTips(all_coin, conf.LimitNum, conf.Rate)
    end
end
---@param nextReceiveTime number
function UIActivityN33BuildingItem:_RefreshReceiveCD(nextReceiveTime)
    self.nextReceiveTime = nextReceiveTime
    self.receiveCoinCD = Cfg.cfg_global["simulation_operation_pickup_cd"].IntValue
    self:_OneMinusUpdateReceiveCD()
end
function UIActivityN33BuildingItem:RefreshFullCoinTips(currCoinNum, CoinMax, rate)
    if currCoinNum >= CoinMax then
        self.fullCoinTipsText:SetText(StringTable.Get("str_n33_date_arch_info_key12"))
        return
    end
    local t = (CoinMax - currCoinNum) / rate
    self.fullCoinTipsText:SetText(self:GetFormatTimerStr(t))
end

function UIActivityN33BuildingItem:_RefreshUpState(archLv)
    self.lvUpNode:SetActive(false)
    self.nameText.gameObject:SetActive(true)
    local isCanUp = archLv < ARCH_LEVEL_MAX_CONST
    if not isCanUp then
        return
    end
    local itemModule = GameGlobal.GetModule(ItemModule)
    local coinCount = itemModule:GetItemCount(RoleAssetID.RoleAssetSimulationOperationCoin)
    local conf = self.allLvBuildingCfg[archLv]
    isCanUp = coinCount >= conf.UpgradeCost
    if not isCanUp then
        return
    end
    for key, value in pairs(conf.PreCondition) do
        local isPreOk = self:CheckUpPreCond(value)
        if not isPreOk then
            return
        end
    end
    self.nameText.gameObject:SetActive(false)
    self.lvUpNode:SetActive(true)
end
function UIActivityN33BuildingItem:CheckUpPreCond(condition)
    local archID = condition[1]
    local archLv = condition[2]
    for key, value in pairs(self.serverData) do
        if value.arch_id == archID then
            return value.level >= archLv
        end
    end
    return false
end
function UIActivityN33BuildingItem:_OneMinusUpdateReceiveCD()
    local mSvrTime = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = mSvrTime:GetServerTime() / 1000 --当前时间戳
    local cd = self.nextReceiveTime - nowTime
    local isShowCD = cd > 0
    self.receiveCDNode:SetActive(false)
    self.bubbleNode:SetActive(not isShowCD)
    if not isShowCD then
        return
    end
    self.receiveCDImage.fillAmount = (self.receiveCoinCD - cd) / self.receiveCoinCD
end
--按钮点击
function UIActivityN33BuildingItem:OpenInfoBtnOnClick(go)
    if self.activityConst:CheckSimulationOperationIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        self:SwitchState(UIStateType.UIActivityN33MainController)
        return
    end
    local key = "UIActivityN33BuildingItem_InfoBtnOnClick"
    self:StartTask(function(TT)
        self:Lock(key)
        self._anim:Play("uieffanim_UIActivityN33BuildingItem_click_Build")
        YIELD(TT, 500)
        self:UnLock(key)
        ---@type UnityEngine.RectTransform
        local rect = self:GetGameObject():GetComponent(typeof(UnityEngine.RectTransform))
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN33FocusTag, rect.anchoredPosition)
        self:ShowDialog(UIStateType.UIActivityN33BuildingInfo, self.activityConst, self.currArchID, self.serverData, self.allLvBuildingCfg, self.isAllArchFullLv, function()
            self.fullCoinTipsText.gameObject:SetActive(false)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN33FocusTag)
        end)
    end, self)
end
function UIActivityN33BuildingItem:ReceiveCoinBtnOnClick(go)
    if self.activityConst:CheckSimulationOperationIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        self:SwitchState(UIStateType.UIActivityN33MainController)
        return
    end
    self.effNode:SetActive(true)
    local key = "UIActivityN33BuildingItem_InfoBtnOnClick"
    self:StartTask(function(TT)
        self:Lock(key)
        self._anim:Play("uieffanim_UIActivityN33BuildingItem_gather")
        YIELD(TT, 500)
        self:UnLock(key)
        self.effNode:SetActive(false)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN33PickUpCoin, self.currArchServerData.arch_id)
    end, self)

end

function UIActivityN33BuildingItem:SetVisible(status)
    self:GetGameObject():SetActive(status)
end

function UIActivityN33BuildingItem:OnOneMinusUpdate()
    if not self.isAllArchFullLv then
        self:_OneMinusUpdateReceiveCD()
    end
end
---@param type UIActivityN33DateMainFilterType
function UIActivityN33BuildingItem:_OnDateFilterClick(type)
    if type == UIActivityN33DateMainFilterType.Pet then
        --- 置灰

    else

    end
end
function UIActivityN33BuildingItem:AllArchFullLvRefreshUI()
    self.bubbleNode:SetActive(false)
    self.receiveCDNode:SetActive(false)
    self.lvUpNode:SetActive(false)
    self.lvUpNode:SetActive(false)
    self.nameText.gameObject:SetActive(true)
end
function UIActivityN33BuildingItem:GetFormatTimerStr(time, id)
    local default_id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }
    id = id or default_id

    local timeStr = StringTable.Get(id.over)
    if time < 0 then
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        timeStr = day .. StringTable.Get(id.day) .. hour .. StringTable.Get(id.hour)
    elseif hour > 0 then
        timeStr = hour .. StringTable.Get(id.hour) .. min .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = min .. StringTable.Get(id.min)
    else
        timeStr = StringTable.Get(id.zero)
    end
    return StringTable.Get("str_n33_date_arch_info_key11", timeStr)
    -- return string.format("预计%s后到达存储上限", timeStr)
end
function UIActivityN33BuildingItem:PlayAnim(isIn)
    if isIn then
        self:StartTask(
            function(TT)
                self._anim:Play("uieffanim_UIActivityN33BuildingItem_in_01")
            end,
            self
        )
    else
        self:StartTask(
            function(TT)
                self._anim:Play("uieffanim_UIActivityN33BuildingItem_out_02")
            end,
            self
        )
    end
end

function UIActivityN33BuildingItem:PlayAnim_InfoBubble(isShow)
    if isShow then
        self:StartTask(function(TT)
            self._anim:Play("uieffanim_UIActivityN33BuildingItem_in_02")
        end, self)
    else
        self:StartTask(function(TT)
            self._anim:Play("uieffanim_UIActivityN33BuildingItem_out_01")
        end, self)
    end
end





function UIActivityN33BuildingItem:OnHide()
    if self._currentTimeEvent then
        GameGlobal.RealTimer():CancelEvent(self._currentTimeEvent)
        self._currentTimeEvent = nil
    end
    self:DetachEvent(GameEventType.OnDateFilterClick, self._OnDateFilterClick)

end

--返回打开建筑按钮
function UIActivityN33BuildingItem:GetOpenInfoBtn()
    return self:GetGameObject("OpenInfoBtn")
end

--返回收集金币按钮
function UIActivityN33BuildingItem:GetReceiveCoinBtn()
    return self:GetGameObject("ReceiveCoinBtn")
end



---@class ArchAnimType
---@field TypeIn int
---@field TypeOut int
---@field TypeOutIn int
local ArchAnimType = {
    TypeIn = 1,
    TypeOut = 2,
    TypeOutIn = 3,
}
_enum("ArchAnimType", ArchAnimType)
ArchAnimType = ArchAnimType
