--[[------------------------------------------------------------------------------------------
    玩家命令分发
]] --------------------------------------------------------------------------------------------

---@class PlayerCommandDispatcher:IEntityCommandDispatcher
_class("PlayerCommandDispatcher", IEntityCommandDispatcher)

function PlayerCommandDispatcher:Constructor(world)
    self._world = world
end

---@param cmd IEntityCommand
function PlayerCommandDispatcher:HandleCommand(cmd)
    ---@type PlayerCommandHandler
    local cmdHandler = self._world:GetPlayerCommandHandler()
    cmdHandler:AddCommand(cmd)
    --Log.debug("PlayerCommandDispatcher() add command ",cmd:GetCommandType())
    cmdHandler:HandleCommand()
end
