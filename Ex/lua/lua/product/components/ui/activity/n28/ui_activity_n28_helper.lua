--- @class ActivityN28ComponentStatus
local ActivityN28ComponentStatus = {
    None        = 0,
    Open        = 1, --开启
    Close       = 2, --关闭
    TimeLock    = 3, --时间未到
    MissionLock = 4, --未通关关卡
    ActivityEnd = 5, --活动结束
}
_enum("ActivityN28ComponentStatus", ActivityN28ComponentStatus)

---@class UIActivityN28Helper : Object
_class("UIActivityN28Helper", Object)
UIActivityN28Helper = UIActivityN28Helper

function UIActivityN28Helper:Constructor()
end

---@param component ICampaignComponent
function UIActivityN28Helper.CheckComponentStatus(component)
    if not component then
        return ActivityN28ComponentStatus.Close, 0
    end
    
    ---@type ICampaignComponentInfo
    local info = component:GetComponentInfo()
    if not info then
        return ActivityN28ComponentStatus.Close, 0
    end

    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime >= info.m_close_time then
        return ActivityN28ComponentStatus.Close, 0
    end

    local opentTime = info.m_open_time
    local unLockTime = info.m_unlock_time
    local time = opentTime
    if unLockTime > time then
        time = unLockTime
    end

    if curTime > time then
        if not info.m_b_unlock then
            return ActivityN28ComponentStatus.MissionLock, 0
        end
        return ActivityN28ComponentStatus.Open, info.m_close_time - curTime
    end

    return ActivityN28ComponentStatus.TimeLock, time - curTime
end

function UIActivityN28Helper.GetTimeString(seconds)
    if seconds < 0 then
        seconds = 0
    end
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n28_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n28_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n28_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n28_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n28_less_one_minus")
        end
    end
    return timeStr
end

function UIActivityN28Helper.GetItemCountStr(byteCount, count, preColor, countColor)
    local dight = 0
    local tmpCount = count
    if tmpCount < 0 then
        tmpCount = -tmpCount
    end
    while tmpCount > 0 do
        tmpCount = math.floor(tmpCount / 10)
        dight = dight + 1
    end

    local pre = ""
    if count >= 0 then
        for i = 1, byteCount - dight do
            pre = pre .. "0"
        end
    else
        for i = 1, byteCount - dight - 1 do
            pre = pre .. "0"
        end
    end

    if count > 0 then
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    elseif count == 0 then
        return string.format("<color=" .. preColor .. ">%s</color>", pre)
    else
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    end
end

function UIActivityN28Helper.ShowRewards(rewards, callback)
    local petIdList = {}
    local mPet = GameGlobal.GetModule(PetModule)
    for _, reward in pairs(rewards) do
        if mPet:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                GameGlobal.UIStateManager():ShowDialog(
                    "UIGetItemController",
                    rewards,
                    function()
                        if callback then
                            callback()
                        end
                    end
                )
            end
        )
        return
    end
    GameGlobal.UIStateManager():ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            if callback then
                callback()
            end
        end
    )
end

function UIActivityN28Helper.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. id
    return key
end

function UIActivityN28Helper.GetNewFlagStatus(id)
    local key = UIActivityN28Helper.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN28Helper.SetNewFlagStatus(id, status)
    local key = UIActivityN28Helper.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

--28入口获取困难关状态，时间到了就返回open
---@param component ICampaignComponent
function UIActivityN28Helper.CheckHard(component)
    if not component then
        return ActivityN28ComponentStatus.Close, 0
    end
    
    ---@type ICampaignComponentInfo
    local info = component:GetComponentInfo()
    if not info then
        return ActivityN28ComponentStatus.Close, 0
    end

    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime >= info.m_close_time then
        return ActivityN28ComponentStatus.Close, 0
    end

    local opentTime = info.m_open_time
    local unLockTime = info.m_unlock_time
    local time = opentTime
    if unLockTime > time then
        time = unLockTime
    end

    if curTime > time then
        return ActivityN28ComponentStatus.Open, info.m_close_time - curTime
    end

    return ActivityN28ComponentStatus.TimeLock, time - curTime
end