---@class UITacticDiffBtn : UICustomWidget
_class("UITacticDiffBtn", UICustomWidget)
UITacticDiffBtn = UITacticDiffBtn
function UITacticDiffBtn:OnShow(uiParams)
    self:InitWidget()
end
function UITacticDiffBtn:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.text = self:GetUIComponent("UILocalizationText", "Text")
    ---@type UnityEngine.UI.Button
    self.btn = self:GetUIComponent("Button", "btn")
    --generated end--
end
function UITacticDiffBtn:SetData(diff, onSelect)
    local texts = {
        "str_aircraft_tactic_difficulty1",
        "str_aircraft_tactic_difficulty2",
        "str_aircraft_tactic_difficulty3"
    }
    self.text:SetText(StringTable.Get(texts[diff]))
    self._onClick = onSelect
    self._diff = diff
    self:OnSelect(false)
end

function UITacticDiffBtn:OnSelect(select)
    self.btn.interactable = select
    if select then
        self.text.color = Color.black
    else
        self.text.color = Color(141 / 255, 146 / 255, 156 / 255)
    end
end

function UITacticDiffBtn:btnOnClick()
    self._onClick(self._diff)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N8DefaultClick)
end
