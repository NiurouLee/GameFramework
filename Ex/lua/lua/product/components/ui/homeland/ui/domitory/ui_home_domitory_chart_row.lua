---@class UIHomeDomitoryChartRow : UICustomWidget
_class("UIHomeDomitoryChartRow", UICustomWidget)
UIHomeDomitoryChartRow = UIHomeDomitoryChartRow
--这是注释
function UIHomeDomitoryChartRow:OnShow(uiParams)
    self:InitWidget()
end
--这是注释
function UIHomeDomitoryChartRow:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UILocalizationText
    self.text1 = self:GetUIComponent("UILocalizationText", "text1")
    ---@type UILocalizationText
    self.text2 = self:GetUIComponent("UILocalizationText", "text2")
    --generated end--
end
--这是注释
function UIHomeDomitoryChartRow:SetData(idx, text1, cfg)
    if idx % 2 == 1 then
        self.bg.color = Color.white
    else
        self.bg.color = Color(237 / 255, 235 / 255, 234 / 255)
    end

    self.text1:SetText(text1)
    self.text2:SetText(cfg.SinglePetAddValue)
end
