--
---@class UISeasonActionPointTip : UIController
_class("UISeasonActionPointTip", UIController)
UISeasonActionPointTip = UISeasonActionPointTip

---@param res AsyncRequestRes
function UISeasonActionPointTip:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonActionPointTip:OnShow(uiParams)
    self:InitWidget()
    ---@type ActionPointComponent
    self._cpt = uiParams[1]
    local pos = uiParams[2]
    self.root.anchoredPosition = pos + Vector2(-3, 7)
    self._targetTime = self._cpt:GetRegainEndTime() + 1 --加1秒保证比服务器时间慢
    self._timer = GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:_Countdown()
        end
    )
    self:_Countdown()

    local itemID = self._cpt:GetItemId()
    local tipCfg = Cfg.cfg_top_tips[itemID]
    local atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self.icon.sprite = atlas:GetSprite(tipCfg.Icon)
    self.itemName:SetText(StringTable.Get(tipCfg.Title))
    self.desText:SetText(StringTable.Get(tipCfg.Intr))
end

function UISeasonActionPointTip:OnHide()
    if self._timer then
        GameGlobal.Timer():CancelEvent(self._timer)
        self._timer = nil
    end
end

--获取ui组件
function UISeasonActionPointTip:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "Icon")
    ---@type UILocalizationText
    self.itemName = self:GetUIComponent("UILocalizationText", "ItemName")
    ---@type UnityEngine.GameObject
    self.countdown = self:GetGameObject("Countdown")
    ---@type UILocalizationText
    self.desText = self:GetUIComponent("UILocalizationText", "DesText")
    ---@type UILocalizationText
    self.time = self:GetUIComponent("UILocalizationText", "Time")
    --generated end--
    self.root = self:GetUIComponent("RectTransform", "Root")
end

--按钮点击
function UISeasonActionPointTip:BgOnClick(go)
    self:CloseDialog()
end

function UISeasonActionPointTip:_Countdown()
    local now = GetSvrTimeNow()
    local time = self._targetTime - now
    local timeStr = HelperProxy:GetInstance():FormatTime(time)
    self.time:SetText(timeStr)
    if time <= 0 then
        self:StartTask(self._ReqFlush, self)
    end
end

function UISeasonActionPointTip:_ReqFlush(TT)
    local res = AsyncRequestRes:New()
    self._cpt:HandleActionPointData(TT, res)
    if res:GetSucc() then
        self:DispatchEvent(GameEventType.OnSeasonActionPointChanged)
    else
        GameGlobal.Timer():CancelEvent(self._timer) --失败了就不更新了
        self._timer = nil
        Log.exception("请求刷新行动点失败:", res:GetResult())
    end
end
