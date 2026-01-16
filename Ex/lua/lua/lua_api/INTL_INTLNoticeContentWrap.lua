---@class INTL.INTLNoticeContent : INTL.JsonSerializable
---@field ContentId int
---@field AppContentId string
---@field Title string
---@field Content string
---@field Language string
---@field UpdateTime int
---@field ExtraData string
---@field PictureList table
local m = {}
INTL = {}
INTL.INTLNoticeContent = m
return m