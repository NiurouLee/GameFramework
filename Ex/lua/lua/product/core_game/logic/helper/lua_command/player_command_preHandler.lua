--[[------------------------------------------------------------------------------------------
    玩家命令本地提前处理
]]--------------------------------------------------------------------------------------------

---@class PlayerCommandPreHandler:IEntityCommandPreHandler
_class( "PlayerCommandPreHandler", IEntityCommandPreHandler )

function PlayerCommandPreHandler:BindOwner(owner) 
    self.owner = owner
end

function PlayerCommandPreHandler:UnBindOwner() 
    self.owner = nil
end

function PlayerCommandPreHandler:PreHandleCommand(cmd) 
    --Log.fatal("cmd type " .. cmd.CommandType)
end