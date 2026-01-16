--[[******************************************************************************************
    定义EntityCommand：
    
--******************************************************************************************]] --

--[[------------------------------------------------------------------------------------------
   IEntityCommand
]] --------------------------------------------------------------------------------------------

---@class IEntityCommand:Object
_class("IEntityCommand", Object)
IEntityCommand = IEntityCommand

function IEntityCommand:Constructor()
    self.EntityID = nil
end

function IEntityCommand:GetEntityID()
    return self.EntityID
end

function IEntityCommand:GetCommandType()
end

--限定执行状态
function IEntityCommand:GetExecStateID()
    return 0
end

--限定状态下互斥执行
function IEntityCommand:IsExecExcluded()
    return 0
end

function IEntityCommand:DependRoundCount()
    return true
end

function IEntityCommand:ToNetMessage()
end

function IEntityCommand:FromNetMessage(msg)
end