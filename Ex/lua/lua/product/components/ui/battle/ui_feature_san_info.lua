---@class UIFeatureSanInfo : UIController
_class("UIFeatureSanInfo", UIController)
UIFeatureSanInfo = UIFeatureSanInfo
function UIFeatureSanInfo:OnShow(uiParams)
    ---@type FeatureEffectParamSan
    self._sanInitData = uiParams[1]
    self._curVal = uiParams[2]
    self:InitWidget()
    self:_RefreshContent()
end
function UIFeatureSanInfo:InitWidget()
    --generated--
    ---@type UILocalizationText
    self._titleText = self:GetUIComponent("UILocalizationText", "TitleText")
    ---@type UILocalizationText
    self._content = self:GetUIComponent("UILocalizationText", "Content")
    --generated end--
end
function UIFeatureSanInfo:DotBGOnClick()
    self:CloseDialog()
end
function UIFeatureSanInfo:_RefreshContent()
    if self._sanInitData then
        local param = self._sanInitData:GetSanityParam()
        local validColorStrFormat = "<color=#E2C017>%s</color>"
        if param then
            local paramCount = #param
            local contentStr = ""
            for i,v in ipairs(param) do
                local descStr
                local rangeTb = v.range
                if rangeTb then
                    local rangeMin = rangeTb[1]
                    local rangeMax = rangeTb[2]
                    --descStr = StringTable.Get(v.descStr,rangeMin,rangeMax)
                    descStr = StringTable.Get(v.descStr)--数值也包括在文本中
                    if self._curVal <= rangeMax then--生效区间变色
                        descStr = string.format(validColorStrFormat,descStr)
                    end
                else
                    descStr = StringTable.Get(v.descStr)
                end
                if paramCount == i then
                    contentStr = contentStr .. descStr
                else
                    contentStr = contentStr .. descStr .. "\n"
                end
            end
            self._content:SetText(contentStr)
        end
    end
end
