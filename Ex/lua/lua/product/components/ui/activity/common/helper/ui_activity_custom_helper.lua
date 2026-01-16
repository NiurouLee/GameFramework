--- @class ActivityComponentStatus
local ActivityComponentStatus = {
    None        = 0,
    Open        = 1, --开启
    Close       = 2, --关闭
    TimeLock    = 3, --时间未到
    MissionLock = 4, --未通关关卡
    ActivityEnd = 5, --活动结束
}
_enum("ActivityComponentStatus", ActivityComponentStatus)

---@class UIActivityCustomHelper : Object
_class("UIActivityCustomHelper", Object)
UIActivityCustomHelper = UIActivityCustomHelper

function UIActivityCustomHelper:Constructor()
end

---@param component ICampaignComponent
function UIActivityCustomHelper.CheckComponentStatus(component)
    if not component then
        return ActivityComponentStatus.Close, 0
    end
    
    ---@type ICampaignComponentInfo
    local info = component:GetComponentInfo()
    if not info then
        return ActivityComponentStatus.Close, 0
    end

    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime >= info.m_close_time then
        return ActivityComponentStatus.Close, 0
    end

    local opentTime = info.m_open_time
    local unLockTime = info.m_unlock_time
    local time = opentTime
    if unLockTime > time then
        time = unLockTime
    end

    if curTime > time then
        if not info.m_b_unlock then
            return ActivityComponentStatus.MissionLock, 0
        end
        return ActivityComponentStatus.Open, info.m_close_time - curTime
    end

    return ActivityComponentStatus.TimeLock, time - curTime
end

function UIActivityCustomHelper.GetTimeString(seconds, dayStr, hourStr, minusStr, lessOneMinusStr)
    if seconds < 0 then
        seconds = 0
    end

    if not dayStr then
        dayStr = "str_activity_day"
    end

    if not hourStr then
        hourStr = "str_activity_hour"
    end

    if not minusStr then
        minusStr = "str_activity_minus"
    end

    if not lessOneMinusStr then
        lessOneMinusStr = "str_activity_less_one_minus"
    end

    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get(dayStr, day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get(hourStr, hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get(hourStr, hour)
            end
            local minus = math.floor(seconds / 60)
            if minus > 0 then
                timeStr = timeStr .. StringTable.Get(minusStr, minus)
            end
        else
            timeStr = StringTable.Get(lessOneMinusStr)
        end
    end
    return timeStr
end

function UIActivityCustomHelper.GetItemCountStr(byteCount, count, preColor, countColor)
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

function UIActivityCustomHelper.ShowRewards(rewards, callback)
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

function UIActivityCustomHelper.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. id
    return key
end

function UIActivityCustomHelper.GetNewFlagStatus(id)
    local key = UIActivityCustomHelper.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityCustomHelper.SetNewFlagStatus(id, status)
    local key = UIActivityCustomHelper.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end
