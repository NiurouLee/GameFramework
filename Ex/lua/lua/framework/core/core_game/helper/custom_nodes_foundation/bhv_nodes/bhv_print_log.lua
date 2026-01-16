--PrintLogBhv 
require "abstract_bhv_finite_time"

--[[------------------------------------------------------------------------------------------
    静态配置节点：Check_PrintLogBhv
]]--------------------------------------------------------------------------------------------

---@param cfg table
function CustomNodeConfigStatic.Check_PrintLogBhv(cfg)
    if cfg.LogStr then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("PrintLogBhv", CustomNodeConfigStatic.Check_PrintLogBhv)



--[[------------------------------------------------------------------------------------------
    运行时节点： PrintLogBhv
]]--------------------------------------------------------------------------------------------

---@class PrintLogBhv:HasBeginBhv
_class( "PrintLogBhv", HasBeginBhv )
PrintLogBhv = PrintLogBhv

function PrintLogBhv:Constructor()
    self.logStr = 0
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function PrintLogBhv:InitializeNode(cfg, context)
    PrintLogBhv.super.InitializeNode(self, cfg, context)
    self.logStr = cfg.LogStr
end


function PrintLogBhv:OnBegin()
    Log.debug(self.logStr)
end