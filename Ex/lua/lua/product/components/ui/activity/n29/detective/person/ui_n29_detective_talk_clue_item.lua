---@class UIN29DetectiveTalkClueItem : UICustomWidget
_class("UIN29DetectiveTalkClueItem", UICustomWidget)
UIN29DetectiveTalkClueItem = UIN29DetectiveTalkClueItem
--初始化
function UIN29DetectiveTalkClueItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIN29DetectiveTalkClueItem:InitWidget()
    ---@type UnityEngine.GameObject
    self._select = self:GetGameObject("select")
    self._clue = self:GetUIComponent("RawImageLoader","Clue")
end

--设置数据
function UIN29DetectiveTalkClueItem:SetData(clueId,callback)
    self.clueId = clueId
    self.callback = callback
    local cfg = Cfg.cfg_component_detective_item[self.clueId]
    self._clue:LoadImage(cfg.Icon)
end

function UIN29DetectiveTalkClueItem:SetSelected(isSelected)
    self._select:SetActive(isSelected)
end
------------------------------onclick--------------------------------

function UIN29DetectiveTalkClueItem:ClueOnClick()
    -- if self._select.SetActive() then
    --     self._select:SetActive(false)
    -- else
    --     self._select:SetActive(true)
    -- end
    if self.callback then
        self.callback(self)
        Log.fatal("点击线索"..self.clueId)
    end
end

function UIN29DetectiveTalkClueItem:GetClue()
    return self.clueId
end



