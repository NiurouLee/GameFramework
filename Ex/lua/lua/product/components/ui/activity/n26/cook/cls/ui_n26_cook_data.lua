---@class UIN26CookData : Object
_class("UIN26CookData", Object)
UIN26CookData = UIN26CookData

---@param res AsyncRequestRes
function UIN26CookData:LoadData(TT, res)
    -- ---@type SvrTimeModule
    -- self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    -- local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign =  UIActivityCampaign.New()
    
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N26,
        ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER
    )

    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN26
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --获取组件
    --新年物业饭组件
    ---@type NewYearDinnerMiniGameComponent
    self._cookComp = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER)
    ---@type NewYearDinnerComponentInfo
    self._cookCompInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER)

    self._componentId  = self._cookCompInfo.m_campaign_id * 100000 + self._cookCompInfo.m_component_type * 100 + self._cookCompInfo.m_component_id
end

---@return UIActivityCampaign
function UIN26CookData:GetCampaign()
    return self._campaign
end

function UIN26CookData:GetComponnet()
    return self._cookComp, self._cookCompInfo
end

function UIN26CookData:GetFirstPlayStoryID()
    local key = "N26CookFistStory"
    if UIN26CookData.HasKey(key) then
        return nil
    end
    UIN26CookData.SetKey(key)
   local storyID = self._cookCompInfo.m_first_story_id
   return storyID
end

function UIN26CookData:GetMakeFoodNum()
    local data_info = self._cookCompInfo.data_info
    local food_list = data_info.food_list
    local count = 0
    if food_list then
        for k, v in pairs(food_list) do
            if v >= NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
                count = count + 1
            end
        end
    end
    return count
end

--检查食材获取红点 
function UIN26CookData.CheckRed_MatRequire(compInfo)
    local task_list = compInfo.task_list
    for k, v in pairs(task_list) do
        if v.status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
            return true
        end
    end
    return false
end

--检查收集是否可以领取
function UIN26CookData.CheckRed_Collect(compInfo)
    local data_info = compInfo.data_info
    local collect_list = data_info.collect_list
    for k, v in pairs(collect_list) do
        if v == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
            return true
        end
    end
    return false
end

--检查图鉴红点
---@param compInfo  NewYearDinnerComponentInfo
function UIN26CookData.CheckRed_CookBook(compInfo)
    local itemModule = GameGlobal.GetModule(ItemModule)
    local data_info = compInfo.data_info
    local food_list = data_info.food_list

    local componnetId  = compInfo.m_campaign_id * 100000 + compInfo.m_component_type * 100 + compInfo.m_component_id
    local cfgs = Cfg.cfg_component_newyear_dinner_food {ComponentID = componnetId}
    if not cfgs then
        return false
    end
    for k, v in pairs(cfgs) do
        local foodId = v.FoodID
        local costItem = v.CostItem
        local itemCount = itemModule:GetItemCount(costItem[1])
        local costNum = costItem[2]
        if itemCount >= costNum then
            local status = food_list[foodId]
            if status and status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
                return true
            end
        end
    end
end

--所有美食制作完成
function UIN26CookData:IsCookedAll()
    local componnetId  = self._cookCompInfo.m_campaign_id * 100000 + self._cookCompInfo.m_component_type * 100 + self._cookCompInfo.m_component_id
    local cfgs = Cfg.cfg_component_newyear_dinner_food {ComponentID = componnetId}

    local data_info = self._cookCompInfo.data_info
    local food_list = data_info.food_list

    if #food_list ~= #cfgs then
        return false
    end
    for k, v in pairs(food_list) do
        if v <= NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            return false
        end
    end
    return true
end

--检查图鉴New
---@param compInfo  NewYearDinnerComponentInfo
function UIN26CookData.CheckNew_CookBook(compInfo)
    local data_info = compInfo.data_info
    for i, v in ipairs(data_info.food_list) do
        if v == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            if not UIN26CookData.HasKey(i) then
                return true
            end
        end
    end
    return false
end

function UIN26CookData.ClearNew_CookBook(compInfo)
    local data_info = compInfo.data_info
    for i, v in ipairs(data_info.food_list) do
        if v == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            if not UIN26CookData.HasKey(i) then
               UIN26CookData.SetKey(i)
            end
        end
    end
end

function UIN26CookData.GetTimeString(seconds)
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n25_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n25_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n25_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n25_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n25_less_one_minus")
        end
    end
    return timeStr
end

---@return UISummerOneEnterBtnState
function UIN26CookData:GetCookState()
    if self._cookCompInfo then
        return self:GetState(self._cookCompInfo)
    end
    return UISummerOneEnterBtnState.NotOpen
end

---@return UISummerOneEnterBtnState
function UIN26CookData:GetState(cInfo)
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < cInfo.m_unlock_time then --未开启
        return UISummerOneEnterBtnState.NotOpen
    elseif nowTimestamp > cInfo.m_close_time then --已关闭
        return UISummerOneEnterBtnState.Closed
    else --进行中
        if cInfo.m_b_unlock then --是否已解锁，可能有关卡条件
            return UISummerOneEnterBtnState.Normal
        else
            local cfgv = Cfg.cfg_campaign_mission[cInfo.m_need_mission_id]
            if cfgv then
                return UISummerOneEnterBtnState.Locked
            else
                return UISummerOneEnterBtnState.Normal
            end
        end
    end
end

---@return NewYearDinner_Status
function UIN26CookData:GetCollectStatus(collectId)
    if not self._cookCompInfo then
        return NewYearDinner_Status.E_NewYearDinner_Status_LOCK
    end
    ---@type NewYearDinnerInfo
    local data_info = self._cookCompInfo.data_info
    local collect_list = data_info.collect_list
    local status = collect_list[collectId]
    if status then
        return status
    end
    return NewYearDinner_Status.E_NewYearDinner_Status_LOCK
end

---@return NewYearDinner_Status
function UIN26CookData:GetFoodStatus(foodId)
    if not self._cookCompInfo then
        return NewYearDinner_Status.E_NewYearDinner_Status_LOCK
    end
    ---@type NewYearDinnerInfo
    local data_info = self._cookCompInfo.data_info
    local collect_list = data_info.food_list
    local status = collect_list[foodId]
    if status then
        return status
    end
    return NewYearDinner_Status.E_NewYearDinner_Status_LOCK
end


function UIN26CookData:GetComponentId()
    return self._componentId
end

---@param reward_type  NewYearDinner_Reward_Type
---@return AsyncRequestRes
function UIN26CookData:RequestReceiveReward(TT,reward_type, req_id)
    local res = AsyncRequestRes:New()
   local result, rewards = self._cookComp:HandleNewYearDinnerReward(TT, res, reward_type, req_id)
    return res, rewards
end

---@return AsyncRequestRes
function UIN26CookData:RequestMakeFood(TT,food_id)
    local res = AsyncRequestRes:New()
    self._cookComp:HandleNewYearDinnerMakeFood(TT, res, food_id)
    return res
    
    -- local request = NetMessageFactory:GetInstance():CreateMessage(NewYearDinnerMakeFoodReq)
    -- request.food_id = tonumber(food_id)

    -- local game_module = GameGlobal.GetModule(LoginModule)
    -- local reply = game_module:Call(TT, request)
    -- if reply.res ~= CallResultType.Normal then
    --     AsyncRes:SetResult(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_FAILURE)
    --     return AsyncRes
    -- end
    -- ---@type NewYearDinnerMakeFoodRep
    -- local reply_msg = reply.msg
    -- AsyncRes:SetSucc(true)
    -- return AsyncRes, reply_msg.data_info
end


function UIN26CookData:GetCostId()
    return 3000301
end


function UIN26CookData:GetWrongTimes(tid)
    local key = UIN26CookData.GetPrefsKey(tid)
    local times = UnityEngine.PlayerPrefs.GetInt(key, 0)
    return times
end

function UIN26CookData:SetWrongTimes(tid, times)
    local key = UIN26CookData.GetPrefsKey(tid)
    local times = UnityEngine.PlayerPrefs.SetInt(key, times)
end

function UIN26CookData.GetPrefsKey(str)
    local playerPrefsKey = UIN26CookData.GetPstId() .. str
    return playerPrefsKey
end

function UIN26CookData.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end

function UIN26CookData.HasKey(k)
    local key = UIN26CookData.GetPrefsKey(k)
    return UnityEngine.PlayerPrefs.HasKey(key)
end

function UIN26CookData.SetKey(k)
    local key = UIN26CookData.GetPrefsKey(k)
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end
