--
---@class UIN26CookBookController : UIController
_class("UIN26CookBookController", UIController)
UIN26CookBookController = UIN26CookBookController

---@param res AsyncRequestRes
function UIN26CookBookController:LoadDataOnEnter(TT, res)
    self._cookData = UIN26CookData.New()
    self._cookData:LoadData(TT,res)
    local state = self._cookData:GetCookState()
    if state == UISummerOneEnterBtnState.NotOpen then
        return
    elseif state == UISummerOneEnterBtnState.Closed then
        return
    end
    local com, comInfo = self._cookData:GetComponnet()
    self._foodData = comInfo
end

--初始化
function UIN26CookBookController:OnShow(uiParams)
    self._closeCallback = uiParams[1]
    self._unlockNum = 0  --解锁数量
    ---@type NewYearDinnerInfo
    self._foodStatusTb = {}  --美食列表状态
    self._foodCfgTb = Cfg.cfg_component_newyear_dinner_food {}
    self._curFoodWidget = nil  --当前选中的食物
    self._foodWidgets = {}
    self._rewardWidgets = {}
    self._atlas = self:GetAsset("UIN26Cook.spriteatlas", LoadType.SpriteAtlas)
    self._isFirst = true

    self:InitWidget()
    self:_SetFirstSelect()
    self:AddListener()
end

function UIN26CookBookController:OnHide()
    self:RemoveListener()
end

function UIN26CookBookController:AddListener()
    self:AttachEvent(GameEventType.OnN26CookMakeSucc, self.CookSuccess)
end

function UIN26CookBookController:RemoveListener()
    self:DetachEvent(GameEventType.OnN26CookMakeSucc, self.CookSuccess)
end

--获取ui组件
function UIN26CookBookController:InitWidget()
    self._foodContent = self:GetUIComponent("UISelectObjectPath", "foodContent")
    self._selfNumTxt = self:GetUIComponent("UILocalizationText","selfNum")
    self._foodName = self:GetUIComponent("UILocalizedTMP","foodName")
    self._foodPic = self:GetUIComponent("RawImageLoader","foodPic")
    self._rewardContent = self:GetUIComponent("UISelectObjectPath","rewardContent")
    self._createBtnBg = self:GetUIComponent("Image","createBtnBg")
    self._createBtnTxtObj = self:GetGameObject("createBtnTxt")
    self._timeObj = self:GetGameObject("timeBg")
    self._foodInfo = self:GetUIComponent("UILocalizationText","foodInfo")
    self._isDoneObj = self:GetGameObject("isDone")
    self._createBtnObj = self:GetGameObject("CreateBtn")
    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")
    self._panelAnim = self:GetUIComponent("Animation","panelAnim")
    self._leftAnim = self:GetUIComponent("Animation","leftAnim")

    self:InitFoodList()

    self._req = ResourceManager:GetInstance():SyncLoadAsset("ui_n26_foodbook.mat", LoadType.Mat)
    if self._req and self._req.Obj then
        self.material = self._req.Obj
        local oldMaterial = self._foodName.fontMaterial
        self._foodName.fontMaterial = self.material
        self._foodName.fontMaterial:SetTexture("_MainTex",oldMaterial:GetTexture("_MainTex"))
    end
end

--初始化食物列表
function UIN26CookBookController:InitFoodList()
    if self._foodData then
        self._foodStatusTb = self._foodData.data_info.food_list
    end
    self._unlockNum = 0

    self._foodWidgets = self._foodContent:SpawnObjects("UIN26CookBookItem",#self._foodCfgTb)
    for i, v in pairs(self._foodWidgets) do
        local cfg = self._foodCfgTb[i]
        local status = self._foodStatusTb[cfg.ID]
        if status then
            self._unlockNum = self._unlockNum + 1
        else
            status = NewYearDinner_Status.E_NewYearDinner_Status_LOCK
        end
        v:SetData(cfg,status,function(widget)
                if self._curFoodWidget == widget then
                    return
                end
                self:RefreshFoodInfo(widget)
            end,i)

        if not self._curFoodWidget then
            v:ItemBtnOnClick()
        end
    end

    self._selfNumTxt:SetText(self._unlockNum.."/"..#self._foodCfgTb)
end

--刷新食物详情
---@type UIN26CookMatRequireItem
function UIN26CookBookController:RefreshFoodInfo(widget)
    if self._curFoodWidget then
        self._curFoodWidget:SetSelect(false)
    end

    GameGlobal.TaskManager():StartTask(function(TT)
        if self._isFirst then
            self._isFirst = false
        else
            self:Lock("UIN26CookBookController_Switch")
            self._leftAnim:Play("uieff_N26_CookBookController_left_out")
            local time = self._leftAnim:GetClip("uieff_N26_CookBookController_left_out").length
            YIELD(TT, time * 1000)
            self._leftAnim:Play("uieff_N26_CookBookController_left_in")
            self:UnLock("UIN26CookBookController_Switch")
        end

        local curFood = widget:GetInfo()
        self._curFoodWidget = widget
    
        self._foodPic:LoadImage(curFood.BigTu)
        self._foodName:SetText(StringTable.Get(curFood.Name))
        self._foodInfo:SetText(StringTable.Get(curFood.Description))
        local status = widget:GetStatus()
        if status == NewYearDinner_Status.E_NewYearDinner_Status_LOCK then
            self._createBtnBg.sprite = self._atlas:GetSprite("n26_food_btn03")
            self._isDoneObj:SetActive(false)
            self._createBtnObj:SetActive(true)
            --状态为锁定
            self._createBtnTxtObj:SetActive(false)
            self._timeObj:SetActive(true)
            --设置解锁时间
            local loginModule = GameGlobal.GetModule(LoginModule)
            local descId = "str_n26_foodbook_remainTime"
            local time = curFood.UnlockTime
            local timer = loginModule:GetTimeStampByTimeStr(time,Enum_DateTimeZoneType.E_ZoneType_GMT)
            self:_SetRemainingTime("remainingTimePool", descId, timer)
        elseif status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            self._createBtnBg.sprite = self._atlas:GetSprite("n26_food_btn02")
            self._createBtnTxtObj:SetActive(true)
            self._timeObj:SetActive(false)
            self._isDoneObj:SetActive(false)
            self._createBtnObj:SetActive(true)
        else
            self._createBtnTxtObj:SetActive(false)
            self._timeObj:SetActive(false)
            self._isDoneObj:SetActive(true)
            self._createBtnObj:SetActive(false)
        end
        --初始化奖励列表
        local rewards = curFood.Reward
        local rewardWidget = self._rewardContent:SpawnObject("UIN26CookRewardItem")
        local id = rewards[1][1]
        local num = rewards[1][2]
        rewardWidget:SetData(id,num,function(tplId, pos)
            self:OnItemClicked(tplId, pos)
        end,
        function (tplId, pos)
            self.OnItemClicked(tplId, pos)
        end)
        end,self)
end

--显示解锁时间
function UIN26CookBookController:_SetRemainingTime(widgetName, descId, endTime)
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", widgetName)
    ---@type UIActivityCommonRemainingTime
    local obj = sop:SpawnObject("UIActivityCommonRemainingTime")

    -- 设置自定义时间文字
    obj:SetCustomTimeStr(
        {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_n26_foodbook_remainTime_End" -- 超时后还显示小于 1 分钟
        }
    )
    obj:SetAdvanceText(descId)
    obj:SetData(endTime, nil,nil)
end

--选中第一个已解锁但未激活的图鉴
function UIN26CookBookController:_SetFirstSelect()
    for _,v in pairs(self._foodWidgets) do
        if v:GetStatus() == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            v:ItemBtnOnClick()
            return
        end
    end
end

--烹饪成功
function UIN26CookBookController:CookSuccess()
    self._createBtnTxtObj:SetActive(false)
    self._timeObj:SetActive(false)
    self._isDoneObj:SetActive(true)
    self._createBtnObj:SetActive(false)
    self._curFoodWidget:SetDone()
end

function UIN26CookBookController:OnItemClicked(matid, pos)
    self._selectInfo:SetData(matid, pos)
end

function UIN26CookBookController:_CloseFunc(TT)
    self:Lock("UIN26CookBookController_Close")
    self._panelAnim:Play("uieff_N26_CookBookController_out")
    local time = self._panelAnim:GetClip("uieff_N26_CookBookController_out").length
    YIELD(TT, time * 1000)
    self:UnLock("UIN26CookBookController_Close")
    self:CloseDialog()
end

--按钮点击
function UIN26CookBookController:CloseBtnOnClick()
    if self._closeCallback then
        self._closeCallback()
    end
    GameGlobal.TaskManager():StartTask(self._CloseFunc,self)
end

function UIN26CookBookController:CreateBtnOnClick()
    if self._curFoodWidget then
        local status = self._curFoodWidget:GetStatus()
        if status == NewYearDinner_Status.E_NewYearDinner_Status_LOCK then
            return
        end
        self:ShowDialog("UIN26CookMakeController",self._curFoodWidget:GetID())
    end
end