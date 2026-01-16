--[[------------------------------------------------------------------------------------------
   GMCommand gm
]] --------------------------------------------------------------------------------------------

---@class GMCommand:IEntityCommand
_class("GMCommand", IEntityCommand)
GMCommand = GMCommand

function GMCommand:Constructor()
    self._commandType = "GM"
    self._funcParam={}
end

function GMCommand:GetExecStateID()
    return GameStateID.WaitInput
end

function GMCommand:IsExecExcluded()
    return 0
end

function GMCommand:DependRoundCount()
    return false
end

function GMCommand:SetFuncName(funcName)
    self._funcName = funcName
end

function GMCommand:GetFuncName()
    return self._funcName
end

function GMCommand:GetCommandType()
    return self._commandType
end

-- param
--目前只支持number 且只有一个
function GMCommand:SetFuncParam(...)
    self._funcParam = {...}
end

-- param
--目前只支持number 且只有一个
function GMCommand:GetFuncParam()
    return self._funcParam
end

function GMCommand:ToNetMessage()
    ---@type CEventLuaCommand
    local msg = CEventLuaCommand:New()
    msg.cmd = echo(self)
    return msg
end

function GMCommand:FromNetMessage(msg)
    ---@type GMCommand
    local cmd = ohce(msg.cmd)
    self._funcName = cmd:GetFuncName()
    self._funcParam = cmd:GetFuncParam()
end
