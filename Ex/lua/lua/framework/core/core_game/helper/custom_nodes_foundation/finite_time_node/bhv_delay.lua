--DelayBhv 
require "abstract_bhv_finite_time"

--[[------------------------------------------------------------------------------------------
    静态配置节点：CheckValid
]]--------------------------------------------------------------------------------------------

---@param cfg table
function CustomNodeConfigStatic.Check_DelayBhv(cfg)
    if cfg.TimeLen then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("DelayBhv", CustomNodeConfigStatic.Check_DelayBhv)


--[[------------------------------------------------------------------------------------------
    运行时节点： DelayBhv
]]--------------------------------------------------------------------------------------------

---@class DelayBhv:FiniteTimeBhv
_class( "DelayBhv", FiniteTimeBhv )
DelayBhv = DelayBhv

function DelayBhv:Constructor()
    self.delayTime = 0
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function DelayBhv:InitializeNode(cfg, context)
    DelayBhv.super.InitializeNode(self, cfg, context)
    self.delayTime = self:Parse(cfg.TimeLen)
    self:InitDuration(self.delayTime)
end


function DelayBhv:Reset()
    DelayBhv.super.Reset(self)
    self:InitDuration(self.delayTime)
end