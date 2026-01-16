-- 操作类型
--- @class UIChooseAssistantType
local UIChooseAssistantType = {
    Change2Cg = 1,
    Change2Bg = 2,
    Cg2MainLobby = 11,
    Bg2MainLobby = 22
}
_enum("UIChooseAssistantType", UIChooseAssistantType)
-- 操作状态
--- @class UIChooseAssistantState
local UIChooseAssistantState = {
    Save = 1,
    Cancel = 2,
    Default = 3
}
_enum("UIChooseAssistantState", UIChooseAssistantState)
-- 背景类型
--- @class UIChooseAssistantBgType
local UIChooseAssistantBgType = {
    Normal = 1,
    Cg = 2
}
_enum("UIChooseAssistantBgType", UIChooseAssistantBgType)