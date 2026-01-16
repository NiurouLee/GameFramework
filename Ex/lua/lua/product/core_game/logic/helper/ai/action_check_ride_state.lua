--[[-------------------------------------
    ActionCheckRideState 检测骑乘状态
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckRideState : AINewNode
_class("ActionCheckRideState", AINewNode)
ActionCheckRideState = ActionCheckRideState

function ActionCheckRideState:OnUpdate()
    ---@type Entity
    local entity = self.m_entityOwn
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()

    if not entity:HasRide() then
        return AINewNodeStatus.Other + AIRideStateType.NoRide
    end

    ---@type RideComponent
    local rideCmpt = entity:Ride()
    if entity:GetID() == rideCmpt:GetMountID() then
        return AINewNodeStatus.Other + AIRideStateType.BeRide
    end

    ---@type Entity
    local mountEntity = self._world:GetEntityByID(rideCmpt:GetMountID())
    if not mountEntity then
        return AINewNodeStatus.Other + AIRideStateType.NoRide
    end

    if mountEntity:HasTrap() then
        return AINewNodeStatus.Other + AIRideStateType.RideOnTrap
    end

    if mountEntity:HasMonsterID() then
        return AINewNodeStatus.Other + AIRideStateType.RideOnMonster
    end

    return AINewNodeStatus.Other + AIRideStateType.NoRide
end
