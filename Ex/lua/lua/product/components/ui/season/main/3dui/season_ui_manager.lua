--场景中的UI，例如关卡信息、事件点头顶信息
---@class SeasonUIManager:Object
_class("SeasonUIManager", Object)
SeasonUIManager = SeasonUIManager

function SeasonUIManager:Constructor()
end

function SeasonUIManager:OnInit()
    ---@type SeasonUI
    self._ui = SeasonUI:New()
end

function SeasonUIManager:Update(deltaTime)
    self._ui:Update(deltaTime)
end

function SeasonUIManager:Dispose()
    self._ui:Dispose()
    self._ui = nil
end

function SeasonUIManager:Refresh()
    if self._ui then
        self._ui:Refresh()
    end
end

---@param diff UISeasonLevelDiff
function SeasonUIManager:SwitchDiff(diff)
    if self._ui then
        self._ui:SwitchDiff(diff)
    end
end

function SeasonUIManager:UI()
    return self._ui
end