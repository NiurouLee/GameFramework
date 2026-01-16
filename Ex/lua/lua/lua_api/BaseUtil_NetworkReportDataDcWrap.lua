---@class BaseUtil.NetworkReportDataDc : object
---@field avgDelay float
---@field minDelay uint
---@field maxDelay uint
---@field totalSize float
---@field sendSize float
---@field recvSize float
---@field totalCount float
---@field sendCount float
---@field recvCount float
---@field resendCount uint
---@field maxResendWaitTick uint
---@field repeatCount uint
---@field lostCount uint
---@field connFailedCount uint
---@field rangeCount uint
---@field conflictCount uint
---@field aliveRto float
---@field connectTimeoutCount uint
---@field recvTimeoutCount uint
---@field callTimeoutCount uint
local m = {}
BaseUtil = {}
BaseUtil.NetworkReportDataDc = m
return m