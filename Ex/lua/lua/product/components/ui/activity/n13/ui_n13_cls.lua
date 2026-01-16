---@class N13ToolFunctions
local N13ToolFunctions = {
    --获取剩余时间
    GetRemainTime = function(time)
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
    GetSakuragariNew = function()
        local dbStr = "SakuragariNew"
        local roleModule = GameGlobal.GetModule(RoleModule)
        local pstid = roleModule:GetPstId()
        dbStr = dbStr .. pstid
        return dbStr
    end
}
_enum("N13ToolFunctions", N13ToolFunctions)
