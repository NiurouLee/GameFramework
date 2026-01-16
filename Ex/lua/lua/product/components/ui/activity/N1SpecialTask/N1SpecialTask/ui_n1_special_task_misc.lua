
---@class UIN1SpecialTaskToolFunctions
local UIN1SpecialTaskToolFunctions =
{
    --获取剩余时间
    GetRemainTime = function (time)
        local day, hour, minute
        day = math.floor(time / 86400)
        hour = math.floor(time / 3600) % 24
        minute = math.floor(time / 60) % 60
        local timestring = ""
        if day > 0 then
            timestring = day .. StringTable.Get("str_activity_common_day")
            if hour > 0 then
                timestring = timestring .. hour .. StringTable.Get("str_activity_common_hour")
            end
        elseif hour > 0 then
            timestring = hour .. StringTable.Get("str_activity_common_hour")
            if minute > 0 then
                timestring = timestring .. minute .. StringTable.Get("str_activity_common_minute")
            end
        elseif minute > 0 then
            timestring = minute .. StringTable.Get("str_activity_common_minute")
        else
            timestring = StringTable.Get("str_activity_common_less_minute")
        end
        return timestring
    end,
    --获取本地记录
    GetLocalDBInt = function (key, defaultValue)
        local loginModule = GameGlobal.GetModule(LoginModule)
        return LocalDB.GetInt(key..loginModule:GetRoleShowID(), defaultValue)
    end,
    --设置本地记录
    SetLocalDBInt = function (key, value)
        local loginModule = GameGlobal.GetModule(LoginModule)
        return LocalDB.SetInt(key..loginModule:GetRoleShowID(), value)
    end,
}
_enum("UIN1SpecialTaskToolFunctions", UIN1SpecialTaskToolFunctions)

---@class N24SpecialTaskKey
local N24SpecialTaskKey =
{
    Opened = "Opened",
}
_enum("N24SpecialTaskKey", N24SpecialTaskKey)

