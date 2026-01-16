---@class INTL.AccountProfile : INTL.JsonSerializable
---@field UserName string
---@field Birthday string
---@field IsReceiveEmail int
---@field Region string
---@field LangType string
---@field ExtraJson string
---@field Email string
---@field Phone string
---@field PhoneAreaCode string
---@field AccountType int
---@field NickName string
---@field BirthdayYear int
---@field BirthdayMonth int
---@field BirthdayDay int
local m = {}
INTL = {}
INTL.AccountProfile = m
return m