---在ui_register的component中注册 例:
---["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
---@class UISetParamOnShowComponent:UIComponent
_class( "UISetParamOnShowComponent", UIComponent )

function UISetParamOnShowComponent:Show()
    if self.registerInfo then
        for key, value in pairs(self.registerInfo) do
            self.uiController:SetComponentSharedParam(key, value)
        end
    end
end