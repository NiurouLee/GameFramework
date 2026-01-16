---@class BaseUtil.NetworkCfgInfoDc : object
---@field network_cfg_ver string
---@field max_wait_tick4_send int
---@field max_wait_tick4_recv int
---@field max_wait_tick4_connect int
---@field max_wait_tick4_calltimelong int
---@field resend_delay_cd int
---@field wait_tick4_report int
local m = {}
BaseUtil = {}
BaseUtil.NetworkCfgInfoDc = m
return m