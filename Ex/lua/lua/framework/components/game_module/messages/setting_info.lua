--region dc define

--- @class SETTING_OPTION
local SETTING_OPTION = {
    SETTING_OPTION_UNKONW = 0,
    SETTING_OPTION_MUSIC = 1,
    SETTING_OPTION_CHAT_PRIVATE = 100,
}
_enum("SETTING_OPTION", SETTING_OPTION)

-- 设置数据
--region setting_info define
---@class setting_info:Object
_class("setting_info",Object)
setting_info = setting_info

 function setting_info:Constructor()
    self.option = {}
    self.music_volume = 0.0
end
--region dc custom setting_info
--endregion dc custom setting_info
---@private
setting_info._proto = {
    [1] = {"option", "map<int,bool>"},
    [2] = {"music_volume", "float"},
}
--endregion

-- 客戶端本地的设置数据
--region local_setting_info define
---@class local_setting_info:Object
_class("local_setting_info",Object)
local_setting_info = local_setting_info

 function local_setting_info:Constructor()
    self.info = setting_info:New()
    self.account = ""
end
--region dc custom local_setting_info
--endregion dc custom local_setting_info
---@private
local_setting_info._proto = {
    [1] = {"info", "setting_info"},
    [2] = {"account", "string"},
}
--endregion

--endregion dc define
