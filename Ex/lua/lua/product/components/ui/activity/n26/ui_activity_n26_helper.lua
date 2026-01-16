---@class UIActivityN26Helper : Object
_class("UIActivityN26Helper", Object)
UIActivityN26Helper = UIActivityN26Helper

function UIActivityN26Helper:Constructor()
end

---@param component ICampaignComponent
function UIActivityN26Helper.CheckComponentStatus(component)
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

function UIActivityN26Helper.GetTimeString(seconds)
    if seconds < 0 then
        seconds = 0
    end
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n26_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n26_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n26_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n26_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n26_less_one_minus")
        end
    end
    return timeStr
end

function UIActivityN26Helper.GetItemCountStr(byteCount, count, preColor, countColor)
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

function UIActivityN26Helper.ShowRewards(rewards, callback)
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

function UIActivityN26Helper.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. id
    return key
end

function UIActivityN26Helper.GetNewFlagStatus(id)
    local key = UIActivityN26Helper.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN26Helper.SetNewFlagStatus(id, status)
    local key = UIActivityN26Helper.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

function UIActivityN26Helper.ShowOrNot()
    local Anonymousname={}
    local cfgAnonymousLetter = Cfg.cfg_homeland_anonymous_letter{}
    for k, v in ipairs(cfgAnonymousLetter) do  
        table.insert(Anonymousname,v.ID)
    end
    ---@type HomelandModule
    local homeModule = GameGlobal.GetModule(HomelandModule)
    local Anonymouslist = homeModule:GetAnonymousLetterRreward()

    if #Anonymouslist==0 then
        for _, v in ipairs(Anonymousname) do
            local sec = UIActivityN26Helper.GetAnonymousMovieTimeById(v)
            if sec > 0  then
                return true
            end
        end
    else
        --是否领过奖

        for k1, v1 in ipairs(Anonymousname) do
            for k2, v2 in ipairs(Anonymouslist) do
                --删除重复table数据
                for i=1,#Anonymouslist do
                if  v1 == v2 then         
                    table.remove(Anonymousname, k1)
                end
                end
            end
        end
        --是否到时间
        for _, v in ipairs(Anonymousname) do
            local sec=UIActivityN26Helper.GetAnonymousMovieTimeById(v)
            if sec > 0  then
                return true
            end
        end
    end
    return false
end

function UIActivityN26Helper.GetAnonymousMovieTimeById(id)
    local cfgAnonymousLetter = Cfg.cfg_homeland_anonymous_letter{}
    local unlockTime = cfgAnonymousLetter[id].UnlockTime--表中解锁时间

    local loginModule = GameGlobal.GetModule(LoginModule)
    local unlockTimeStr = loginModule:GetTimeStampByTimeStr(unlockTime,Enum_DateTimeZoneType.E_ZoneType_GMT)

    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = math.ceil(svrTimeModule:GetServerTime()*0.001)--服务器时间
    local sec = nowTime - unlockTimeStr
    return sec
end