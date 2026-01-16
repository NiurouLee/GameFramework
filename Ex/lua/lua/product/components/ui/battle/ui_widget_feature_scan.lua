--
---@class UIWidgetFeatureScan : UICustomWidget
_class("UIWidgetFeatureScan", UICustomWidget)
UIWidgetFeatureScan = UIWidgetFeatureScan
--初始化
function UIWidgetFeatureScan:OnShow(uiParams)
    --允许模拟输入
    self.enableFakeInput = true
end

function UIWidgetFeatureScan:SetData()

end

function UIWidgetFeatureScan:UIWidgetFeatureScanButtonOnClick()
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    if coreGameStateID ~= GameStateID.WaitInput then
        return
    end

    local scanTrap = FeatureServiceHelper.FeatureScanGetScanTrapIDList()
    GameGlobal.UIStateManager():ShowDialog("UIFeatureScanController", scanTrap)
end
