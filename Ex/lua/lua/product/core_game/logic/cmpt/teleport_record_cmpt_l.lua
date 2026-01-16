---记录这个单位一生中发生过的所有有效瞬移
_class("TeleportRecordComponent", Object)
---@class TeleportRecordComponent : Object
TeleportRecordComponent = TeleportRecordComponent

function TeleportRecordComponent:Constructor()
    ---@type table<number, TeleportRecord[]>
    self._recordsByRound = {}
end

---@class TeleportRecord
---@field beginPos Vector2
---@field finalPos Vector2
---@field casterID number

function TeleportRecordComponent:AddSingleTeleportRecord(round, beginPos, finalPos, casterID)
    if not self._recordsByRound[round] then
        self._recordsByRound[round] = {}
    end
    table.insert(self._recordsByRound[round], {
        beginPos = beginPos,
        finalPos = finalPos,
        casterID = casterID
    })
end

function TeleportRecordComponent:GetAllTeleportRecordByRound(round)
    return self._recordsByRound[round] or {}
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return TeleportRecordComponent|nil
function Entity:TeleportRecord()
    return self:GetComponent(self.WEComponentsEnum.TeleportRecord)
end

function Entity:HasTeleportRecord()
    return self:HasComponent(self.WEComponentsEnum.TeleportRecord)
end

---@return TeleportRecordComponent
function Entity:AddTeleportRecord()
    local index = self.WEComponentsEnum.TeleportRecord
    local component = TeleportRecordComponent:New()
    self:AddComponent(index, component)
    return component
end

function Entity:ReplaceTeleportRecord()
    local index = self.WEComponentsEnum.TeleportRecord
    local component = TeleportRecordComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveTeleportRecord()
    if self:HasActiveSkill() then
        self:RemoveComponent(self.WEComponentsEnum.TeleportRecord)
    end
end
