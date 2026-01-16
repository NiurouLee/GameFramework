--[[
    设置entity与队伍同步移动（早苗 机关）
]]
_class("BuffViewSetMoveWithTeam", BuffViewBase)
---@class BuffViewSetMoveWithTeam:BuffViewBase
BuffViewSetMoveWithTeam = BuffViewSetMoveWithTeam

function BuffViewSetMoveWithTeam:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    local bSet = self._buffResult:IsSet()
    if bSet then
        local teamEntity = self._buffResult:GetTargetTeamEntity()
        entity:AddRenderSyncMoveWithTeam(teamEntity)
    else
        entity:RemoveRenderSyncMoveWithTeam()
    end
end
