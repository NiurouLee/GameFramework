--
_class("UIFeatureScanTrapElement", UICustomWidget)
---@class UIFeatureScanTrapElement : UICustomWidget
UIFeatureScanTrapElement = UIFeatureScanTrapElement
--初始化
function UIFeatureScanTrapElement:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIFeatureScanTrapElement:InitWidget()
    --允许模拟输入
    self.enableFakeInput = true
    --generated--
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UnityEngine.UI.Image
    self.selected = self:GetGameObject("selected")
    --generated end--

    self.selected:SetActive(false)
end

--设置数据
function UIFeatureScanTrapElement:SetData(index, id, selected, replaceIcon)
    self._dataIndex = index
    self._dataTrapID = id

    ---@type CfgTrapScan
    local cfgTrapScan = Cfg.cfg_trap_scan[id]
    local iconPath = cfgTrapScan.Icon
    local petID = cfgTrapScan.PetID
    if petID then
        local matchPet = InnerGameHelperRender.GetLocalMatchPetByTemplateID(petID)
        if matchPet then
            iconPath = matchPet:GetPetHead(PetSkinEffectPath.HEAD_ICON_CHAIN_SKILL_PREVIEW)
        end
    end

    self.icon:LoadImage(iconPath)

    self.selected:SetActive(selected)
end
--白盒测试用
function UIFeatureScanTrapElement:AutoTestClick(index)
    if self._dataIndex == index then
        self:UIFeatureScanTrapElementOnClick(nil)
    end
end
--按钮点击
function UIFeatureScanTrapElement:UIFeatureScanTrapElementOnClick(go)
    self._callback(self._dataIndex)
end

function UIFeatureScanTrapElement:SetElementSelectedCallback(cb)
    self._callback = cb
end

function UIFeatureScanTrapElement:SetSelected(b)
    self.selected:SetActive(b)
end
