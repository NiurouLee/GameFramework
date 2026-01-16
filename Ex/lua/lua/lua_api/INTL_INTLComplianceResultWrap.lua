---@class INTL.INTLComplianceResult : INTL.INTLBaseResult
---@field AdultStatus int
---@field ParentCertificateStatus int
---@field ParentCertificateStatusExpiration string
---@field EUUserAgreeStatus int
---@field CountryCode string
---@field AdultAge int
---@field GameGrade int
---@field CertificateType int
---@field AdultStatusExpiration string
---@field TS string
---@field IsEEA bool
---@field Region string
---@field Email string
---@field RealNameAuthStatus int
---@field NeedRealNameAuth int
---@field NeedLICert bool
local m = {}
INTL = {}
INTL.INTLComplianceResult = m
return m