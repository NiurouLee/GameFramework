--[[-------------------------------------
    ActionIsHavePartner 校验是否有同伴（同组的其他ID是否还存活）
    2020-07-14 韩玉信
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsHavePartner : AINewNode
_class("ActionIsHavePartner", AINewNode)
ActionIsHavePartner = ActionIsHavePartner


function ActionIsHavePartner:OnUpdate()
    local listParnter = self:_FindMonsterByGroupOther(self.m_entityOwn)
    local nParnterCount = table.count(listParnter)
    if listParnter and nParnterCount > 0 then
        for key, value in ipairs(listParnter) do
            if AINewNode.IsEntityDead(value) then
                nParnterCount = nParnterCount - 1
            end
        end
    end
    self:PrintLog( "找到同组伙伴数量 = " ,nParnterCount )
    if nParnterCount > 0 then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
---@param entityOwn Entity
function ActionIsHavePartner:_GetMonsterGroupID(entityWork)
    ---@type MonsterIDComponent
    local cmptMonsterID = entityWork:MonsterID()
    if not cmptMonsterID then
        return  nil
    end
    return cmptMonsterID:GetMonsterGroupID()
end
---按照GroupID查找所有相同组号的其他Monster
---@param entityOwn Entity
function ActionIsHavePartner:_FindMonsterByGroupOther(entityOwn)
    local listTarget = {}
    local nGroupID = self:_GetMonsterGroupID(entityOwn)
    if not nGroupID then
        return listTarget
    end
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local entityList = group:GetEntities()

    ---@param value Entity
    for key, value in ipairs(entityList) do
        local nMonsterGroupID = self:_GetMonsterGroupID(value)
        if nMonsterGroupID == nGroupID and value ~= entityOwn then
            table.insert( listTarget, value )
        end
    end
    return listTarget
end
