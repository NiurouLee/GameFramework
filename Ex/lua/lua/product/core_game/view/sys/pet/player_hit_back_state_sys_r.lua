--[[----------------------------------------------------------
    PlayerHitBackStateSystem_Render处理玩家对目标的击退
]] ------------------------------------------------------------
---@class PlayerHitBackStateSystem_Render:ReactiveSystem
_class("PlayerHitBackStateSystem_Render", ReactiveSystem)
PlayerHitBackStateSystem_Render = PlayerHitBackStateSystem_Render

---@param world World
function PlayerHitBackStateSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function PlayerHitBackStateSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.MoveFSM)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PlayerHitBackStateSystem_Render:Filter(entity)
    if not entity:HasMoveFSM() then

        return false
    end

    local move_fsm_cmpt = entity:MoveFSM()
    local cur_state_id = move_fsm_cmpt:GetMoveFSMCurStateID()
    if cur_state_id == PlayerActionStateID.PlayHitBack then
        return true
    end

    return false
end

function PlayerHitBackStateSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:HandleHitBack(entities[i])
    end
end

function PlayerHitBackStateSystem_Render:HandleHitBack(entity)
    TaskManager:GetInstance():CoreGameStartTask(self.PlayHitBackAnimation, self, {}, entity:GetID())
end

function PlayerHitBackStateSystem_Render:PlayHitBackAnimation(TT, hit_back_target_list, owner_entity_id)
    --结束玩家的状态
    self._world:EventDispatcher():Dispatch(GameEventType.PlayerHitBackFinish, 1, owner_entity_id)

end
