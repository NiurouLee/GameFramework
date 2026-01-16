---@class INTL.INTLAuthResult : INTL.INTLBaseResult
---@field OpenId string
---@field Token string
---@field TokenExpire long
---@field FirstLogin int
---@field RegChannelDis string
---@field UserName string
---@field Gender int
---@field Birthdate string
---@field PictureUrl string
---@field Pf string
---@field PfKey string
---@field NeedRealNameAuth bool
---@field ChannelID int
---@field Channel string
---@field ChannelInfo string
---@field ConfirmCode string
---@field BindList string
---@field LegalDocumentsAcceptedVersion string
---@field DeleteAccountStatus int
---@field DeleteAccountInfo string
---@field DeleteLIAccountStatus int
---@field TransferCode string
---@field TransferCodeExpire long
---@field Email string
local m = {}
INTL = {}
INTL.INTLAuthResult = m
return m