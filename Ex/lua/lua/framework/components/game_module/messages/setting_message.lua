--region dc define
require "message_def"

local settingMessageDef ={
    --region setting
    CLSID_CEventUpdateSetting = 25000,
    CLSID_CEventUpdateSettingResult = 25001,
    --endregion
}
table.append(MessageDef, settingMessageDef)

-- 更新设置数据
--region CEventUpdateSetting define
---@class CEventUpdateSetting:CCallRequestEvent
_class("CEventUpdateSetting",CCallRequestEvent)
CEventUpdateSetting = CEventUpdateSetting

 function CEventUpdateSetting:Constructor()
    self.m_info = setting_info:New()
end
---@private
CEventUpdateSetting._proto = {
    [1] = {"m_info", "setting_info"},
}
--endregion

--region CEventUpdateSettingResult define
---@class CEventUpdateSettingResult:CCallReplyEvent
_class("CEventUpdateSettingResult",CCallReplyEvent)
CEventUpdateSettingResult = CEventUpdateSettingResult

 function CEventUpdateSettingResult:Constructor()
    self.m_ret = 0
end
---@private
CEventUpdateSettingResult._proto = {
    [1] = {"m_ret", "int"},
}
--endregion

--endregion dc define
