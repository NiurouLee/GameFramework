--[[
    判定场上是否存在自己的幻象
]]
---@class ActionExistPhantom:AINewNode
_class("ActionExistPhantom", AINewNode)
ActionExistPhantom = ActionExistPhantom

function ActionExistPhantom:Constructor()
end

function ActionExistPhantom:OnUpdate()
    local phantoms = self._world:GetGroup(self._world.BW_WEMatchers.Phantom):GetEntities()
    if phantoms and #phantoms > 0 then
        for _, phantom in ipairs(phantoms) do
            if phantom:PhantomComponent():GetOwnerEntityID() == self.m_entityOwn:GetID() then
                if not phantom:HasDeadMark() then
                    return AINewNodeStatus.Success
                end
            end
        end
    end
    return AINewNodeStatus.Failure
end
