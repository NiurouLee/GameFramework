--[[
    木牌弹窗
]]
_class("UITreasureBoard", UIController)
UITreasureBoard = UITreasureBoard

function UITreasureBoard:Constructor()
end

function UITreasureBoard:OnShow(uiParams)
    --文本
    local tipsid = uiParams[1]
    local cfg = Cfg.cfg_homeland_treasure_board_tips[tipsid]
    local txt = StringTable.Get(cfg.Text)
    self._txtInfo = self:GetUIComponent("UILocalizationText", "info")
    self._txtInfo:SetText(txt)
end

--close self关闭
function UITreasureBoard:CloseOnClick()
    self:CloseDialog()
end
