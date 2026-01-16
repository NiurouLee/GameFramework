--
---@class UIActivityValentineSideEnter : UICustomWidget
_class("UIActivityValentineSideEnter", UICustomWidget)
UIActivityValentineSideEnter = UIActivityValentineSideEnter

function UIActivityValentineSideEnter:Constructor()
end

--初始化
function UIActivityValentineSideEnter:OnShow(uiParams)
    self:_GetComponents()
end

function UIActivityValentineSideEnter:OnHide()
    self._activityData = nil

    if self._timer then
        GameGlobal.Timer():CancelEvent(self._timer)
        self._timer = nil
    end
end

--获取ui组件
function UIActivityValentineSideEnter:_GetComponents()
    self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    self._red = self:GetGameObject("red")
    self._new = self:GetGameObject("new")
end

--设置数据
function UIActivityValentineSideEnter:SetData()
    
end

--按钮点击
function UIActivityValentineSideEnter:BtnOnClick(go)
    local isOver = self._activityData:CheckTaskIsOver()
    local isMailOver = self._activityData:CheckMailIsOver()
    self._activityData:CancelEntryNew()
    self._activityData:ClearTaskGroupRed()
    
    if isMailOver then
        self._setShowCallback(not isMailOver)
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_offline"))
        return
    end
    
    if isOver then
        self:ShowDialog("UIActivityValentineEndController")
    else
        self:ShowDialog("UIActivityValentineMainController")
    end
end

function UIActivityValentineSideEnter:OnSideEnterLoad(TT, setShowCallback, setNewRedCallback)
    self._setShowCallback = setShowCallback
    self._setNewRedCallback = setNewRedCallback
    self:Lock("UIActivityValentineSideEnter")

    local res = AsyncRequestRes:New()
    ---@type ActivityValentineData
    self._activityData = ActivityValentineData:New()
    self._activityData:LoadData(TT, res)

    self:UnLock("UIActivityValentineSideEnter")
    self._campain = self._activityData:GetCampaign()
    local isOpen = self._campain:CheckCampaignOpen()
    if not isOpen then
        self._setShowCallback(false)
        return
    end
    self._setShowCallback(true)

    if self._timer then
        GameGlobal.Timer():CancelEvent(self._timer)
        self._timer = nil
    end
    self:_CheckRedPoint()
    self._timer = GameGlobal.Timer():AddEventTimes(1000,TimerTriggerCount.Infinite,function()
        self:_CheckRedPoint()
    end)
    -- GameGlobal.TaskManager():StartTask(self._CheckRedPoint,self)
end

-- 需要提供入口图片
---@return string
function UIActivityValentineSideEnter:GetSideEnterRawImage()
    local campainId = self._activityData:GetCampaignID()
    local cfg = Cfg.cfg_campaign[campainId]
    return cfg and cfg.SideEnterIcon
end

function UIActivityValentineSideEnter:_CheckRedPoint()
    -- --一秒检查一次
    -- while true do
    --     if not self._activityData then
    --         return
    --     end
    --     local showNew =  self._activityData:GetEntryNew()
    --     local showRed = self._activityData:GetEntryRed()
    --     self._red:SetActive(showRed)
    --     self._new:SetActive(showNew)

    --     self._setNewRedCallback(showNew, showRed)
    --     YIELD(TT,1000)
    -- end

    --MSG56634	【偶现】（测试_王琦）n27通行证购买豪华版获得名饰，装扮后，手动退出游戏，报错，附截图/log	1	新缺陷	王怀冬, 252	01/31/2023	
    -- @lixuesen 攜程沒關,把成用計時器，方便卸載
    if not self._activityData then
        return
    end

    if not GameGlobal.GameLogic():Inited() then
        Log.error("###[UIActivityValentineSideEnter] _CheckRedPoint ,but logic is Reset !")
        return
    end
    Log.debug("###[UIActivityValentineSideEnter] _CheckRedPoint !")

    local showNew =  self._activityData:GetEntryNew()
    local showRed = self._activityData:GetEntryRed()
    self._red:SetActive(showRed)
    self._new:SetActive(showNew)

    self._setNewRedCallback(showNew, showRed)
end