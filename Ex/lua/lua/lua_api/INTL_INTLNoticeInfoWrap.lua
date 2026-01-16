---@class INTL.INTLNoticeInfo : INTL.JsonSerializable
---@field NoticeId int
---@field AppId string
---@field AppNoticeId string
---@field Status int
---@field StartTime int
---@field EndTime int
---@field UpdateTime int
---@field AreaList string
---@field PictureList table
---@field ContentList table
---@field ExtraData string
local m = {}
INTL = {}
INTL.INTLNoticeInfo = m
return m