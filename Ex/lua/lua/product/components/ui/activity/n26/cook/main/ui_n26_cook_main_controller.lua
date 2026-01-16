--
---@class UIN26CookMainController : UIController
_class("UIN26CookMainController", UIController)
UIN26CookMainController = UIN26CookMainController

---@param res AsyncRequestRes
function UIN26CookMainController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
    self._cookData = UIN26CookData.New()
    self._cookData:LoadData(TT,res)
    local state = self._cookData:GetCookState()
    if state == UISummerOneEnterBtnState.NotOpen then
        return
    elseif state == UISummerOneEnterBtnState.Closed then
        return
    end
    local com, comInfo = self._cookData:GetComponnet()
    self._componentInfo = comInfo
end

function UIN26CookMainController:ReloadData(TT,res)
    self._cookData:LoadData(TT,res)
    local com, comInfo = self._cookData:GetComponnet()
    self._componentInfo = comInfo
end

--初始化
function UIN26CookMainController:OnShow(uiParams)
    self:InitWidget()
    self:Refresh(true)
    self:PlayEnterAni()
    self._eventMakeSucc = GameHelper:GetInstance():CreateCallback(self.OnMakeSucc, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnN26CookMakeSucc, self._eventMakeSucc)
    
    local firstStoryId = self._cookData:GetFirstPlayStoryID()
    if firstStoryId then
        self:ShowDialog("UIStoryController", firstStoryId)
    end
end

function UIN26CookMainController:PlayEnterAni()
    self:StartTask(function (TT)
        local lockName = "UIN26CookMainController:PlayEnterAni"
        self:Lock(lockName)
        local delay = 20
        for i, v in ipairs(self._items) do
            YIELD(TT,delay)
            v:SetVisible(true)
            v:PlayEnterAni()
            delay = delay + 20
        end
        self:UnLock(lockName)
    end)
end

function UIN26CookMainController:OnHide()
    if self._eventMakeSucc then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnN26CookMakeSucc, self._eventMakeSucc)
        self._eventMakeSucc = nil
    end
end

function UIN26CookMainController:OnMakeSucc()
    self:StartTask(function (TT)
        self:Refresh()
    end)
end


function UIN26CookMainController:Refresh(hide)
    self:InitCollectList()
    self:RefreshCollectList(hide)
    self.requireRed:SetActive(UIN26CookData.CheckRed_MatRequire(self._componentInfo))
    local cookNew = UIN26CookData.CheckNew_CookBook(self._componentInfo)
    self.cookNew:SetActive(cookNew)
    self.cookRed:SetActive(not cookNew and UIN26CookData.CheckRed_CookBook(self._componentInfo))
    if self._cookData:IsCookedAll() then
        self.bg:LoadImage("n26_xyx_bg07")
    end
end

function UIN26CookMainController:RefreshRequireRed()
    self.requireRed:SetActive(UIN26CookData.CheckRed_MatRequire(self._componentInfo))
end

function UIN26CookMainController:InitCollectList()
    self._collectData = {}
    local componnetId = self._cookData:GetComponentId()
    local cfgs = Cfg.cfg_component_newyear_dinner_collect{ComponentID = componnetId}
    if not cfgs then
        Log.error("cfg_component_newyear_dinner_collect no data with ComponnetID = " .. componnetId)
        return
    end
    
    for i, v in ipairs(cfgs) do
        local collectId = v.CollectID
        local collectData = {}
        collectData.cfg = v
        ---@type NewYearDinner_Status
        collectData.status = self._cookData:GetCollectStatus(collectId)
        --self._collectData[i] = collectData
        table.insert(self._collectData, collectData)
    end

    --sort
    table.sort(self._collectData, function (a, b)
        local sA = a.status
        local sB = b.status
        if sA == sB then
            return a.cfg.CollectID < b.cfg.CollectID
        end

        if sA == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
            return true
        end
        
        if sA == NewYearDinner_Status.E_NewYearDinner_Status_RECVED then
            return false
        end

        if sB == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
            return false
        end
        return true
    end)
end

function UIN26CookMainController:RefreshCollectList(hide)
    local count = 0
    local len = #self._collectData
    local items = self.list:SpawnObjects("UIN26CookMainCollectItem",len)
    self._items = items
    for i, v in ipairs(items) do
        local subCollectData = self._collectData[i]
        local cCount = subCollectData.cfg.Count
        if cCount > count then
            count = cCount
        end
        v:SetData(subCollectData, function (collectId)
            self:_RequestReceive(collectId)
        end, 
        function (tplId, pos)
            self:OnItemClicked(tplId, pos)
        end)
        if hide then
            v:SetVisible(false)
        end
    end

    local collectCount = self._cookData:GetMakeFoodNum()
    self.collectNum:SetText("<color=#ffffff><size=35>"..collectCount.."</size></color>/"..count)
end

function UIN26CookMainController:_RequestReceive(collectId)
    self:StartTask(
        function(TT)
            local lockName = "UIN26CookMainController_RequestReceive"
            self:Lock(lockName)
            local res, rewards = self._cookData:RequestReceiveReward(TT, NewYearDinner_Reward_Type.E_NewYearDinner_Reward_Collect, collectId)
            if  res and res:GetSucc() then
                self:ShowDialog("UIGetItemController", rewards)
                local res = AsyncRequestRes:New()
                res:SetSucc(true)
                --self._cookData:LoadData(TT,res)
                self:ReloadData(TT, res)
                self:Refresh()
            end
            self:UnLock(lockName)
        end,
        self
    )
end
--获取ui组件
function UIN26CookMainController:InitWidget()
    ---@type UILocalizationText
    self.remaindTime = self:GetUIComponent("UILocalizationText", "remaindTime")

    ---@type UILocalizationText
    self.collectNum = self:GetUIComponent("UILocalizationText", "collectNum")

    ---@type UICustomWidgetPool
    self.list = self:GetUIComponent("UISelectObjectPath", "list")

    self.requireRed = self:GetGameObject("requireRed")
    self.cookRed = self:GetGameObject("cookRed")
    self.cookNew = self:GetGameObject("new")

    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")
    self.bg = self:GetUIComponent("RawImageLoader","bg")
    self.animation = self:GetUIComponent("Animation","animation")

    local btns = self:GetUIComponent("UISelectObjectPath", "topBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            GameGlobal.TaskManager():StartTask(self.CloseCoro, self)
        end,
        nil,
        nil
    )
end

function UIN26CookMainController:CloseCoro(TT)
    self:Lock("UIN26CookMainController_CloseCoro")
    self.animation:Play("uieff_N26_CookMainController_out")
    YIELD(TT,400)
    self:SwitchState(UIStateType.UIActivityN26MainController)
    self:UnLock("UIN26CookMainController_CloseCoro")
end

function UIN26CookMainController:OnUpdate()
    self:RefreshTime()
end

function UIN26CookMainController:RefreshTime()
    if not self._componentInfo then
        return
    end

    local endTime = self._componentInfo.m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local str = self:GetFormatTimerStr(endTime - curTime)
    local timeStr = StringTable.Get("str_n26_activity_remain_time", str)
    
    self.remaindTime:SetText(timeStr)

    if curTime > endTime and not self.lineEnd then
        self.lineEnd = true
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        local campain = self._cookData:GetCampaign()
        campaignModule:CampaignSwitchState(true, UIStateType.UIActivityN26MainController, UIStateType.UIMain, nil, campain._id)
    end
end

function UIN26CookMainController:GetFormatTimerStr(time)
    local id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }

    local timeStr = StringTable.Get(id.over)
    if time < 0 then
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        if hour > 0 then
            timeStr =
            "<color=#fabf4f>" ..
            day ..
                "</color>" ..
                    StringTable.Get(id.day) .. "<color=#fabf4f>" .. hour .. "</color>" .. StringTable.Get(id.hour).. "<color=#fabf4f>" .. min .. "</color>" .. StringTable.Get(id.min)

        else
            timeStr =
            "<color=#fabf4f>" ..
            day ..
                "</color>" ..
                    StringTable.Get(id.day).. "<color=#fabf4f>" .. min .. "</color>" .. StringTable.Get(id.min)

        end
            elseif hour > 0 then
        timeStr =
            "<color=#fabf4f>" ..
            hour ..
                "</color>" ..
                    StringTable.Get(id.hour) .. "<color=#fabf4f>" .. min .. "</color>" .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = "<color=#fabf4f>" .. min .. "</color>" .. StringTable.Get(id.min)
    else
        timeStr = "<color=#fabf4f>" .. StringTable.Get(id.zero) .. "</color>"
    end
    return timeStr
end

--按钮点击
function UIN26CookMainController:InfroBtnOnClick(go)
    self:ShowDialog("UIIntroLoader", "UIN26CookIntro", MaskType.MT_BlurMask)
end

--按钮点击
function UIN26CookMainController:RequireBtnOnClick(go)
    self:ShowDialog("UIN26CookMatRequireController")
end

--按钮点击
function UIN26CookMainController:CookBtnOnClick(go)
    self:StartTask(function (TT)
        local lockName = "UIN26CookMainController_CookBtnOnClick"
        self:Lock(lockName)
        self.animation:Play("uieff_N26_CookMainController_getinto")
        YIELD(TT,300)
        self:ShowDialog("UIN26CookBookController", function ()
            self:OnCookBookClose()
        end)
        UIN26CookData.ClearNew_CookBook(self._componentInfo)
        self:UnLock(lockName)
    end)
end

function UIN26CookMainController:OnCookBookClose()
    self:StartTask(function (TT)
        local lockName = "UIN26CookMainController_OnCookBookClose"
        self:Lock(lockName)
        local res = AsyncRequestRes:New()
        self:ReloadData(TT,res)
        self:Refresh()
        YIELD(TT,400)
        self.animation:Play("uieff_N26_CookMainController_return")
        YIELD(TT,300)
        self:UnLock(lockName)
    end)
end

function UIN26CookMainController:OnItemClicked(matid, pos)
    self._selectInfo:SetData(matid, pos)
end