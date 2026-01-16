--[[

]]
_class("BuffViewSetMapForFirstChainPath", BuffViewBase)
---@class BuffViewSetMapForFirstChainPath : BuffViewBase
BuffViewSetMapForFirstChainPath = BuffViewSetMapForFirstChainPath

function BuffViewSetMapForFirstChainPath:PlayView(TT)
    ---@type BuffResultSetMapForFirstChainPath
    local result = self._buffResult
    local effectID = result:GetEffectID()
    local effectOutAnim = result:GetEffectOutAnim()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    renderBoardCmpt:SetMapPieceFirstChainPathEffectID(effectID)
    renderBoardCmpt:SetMapPieceFirstChainPathEffectOutAnim(effectOutAnim)
end

--是否匹配参数
function BuffViewSetMapForFirstChainPath:IsNotifyMatch(notify)
    return true
end
