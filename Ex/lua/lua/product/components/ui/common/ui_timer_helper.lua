---@class UITimerHelper:Singleton
---@field GetInstance UITimerHelper
_class("UITimerHelper", Singleton)
UITimerHelper = UITimerHelper

function UITimerHelper:Constructor()
   
end

function UITimerHelper.GetTimeFormatByString(timeStr)
    if timeStr == nil  then
        Log.exception("UISideEnterItem_FixedTime.CheckOpen() time = nil",  debug.traceback())
        return false
    end

    local loginModule = GameGlobal.GetModule(LoginModule)
    local formatTime = loginModule:GetTimeStampByTimeStr(timeStr, Enum_DateTimeZoneType.E_ZoneType_GMT)
    return formatTime
end

function UITimerHelper.GetCurTime()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    return curTime
end 

function UITimerHelper.CheckTimeUnLock(cfgTime,compareTime)
    if not compareTime then 
        compareTime = UITimerHelper.GetCurTime()
    end  
    return cfgTime < compareTime
end 

function UITimerHelper.GetTimeString(seconds, dayStr, hourStr, minusStr, lessOneMinusStr)
    if seconds < 0 then
        seconds = 0
    end

    if not dayStr then
        dayStr = "str_common_day"
    end

    if not hourStr then
        hourStr = "str_common_hour"
    end

    if not minusStr then
        minusStr = "str_common_minus"
    end

    if not lessOneMinusStr then
        lessOneMinusStr = "str_common_less_one_minus"
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
            if minus then
                timeStr = timeStr .. StringTable.Get(minusStr, minus)
            end
        else
            timeStr = StringTable.Get(lessOneMinusStr)
        end
    end
    return timeStr
end



