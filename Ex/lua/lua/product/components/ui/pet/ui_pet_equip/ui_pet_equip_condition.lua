--
---@class UIPetEquipCondition : UICustomWidget
_class("UIPetEquipCondition", UICustomWidget)
UIPetEquipCondition = UIPetEquipCondition

--初始化
function UIPetEquipCondition:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIPetEquipCondition:InitWidget()
    ---@type UnityEngine.GameObject
    self.imgEnoughGo = self:GetGameObject("imgEnough")

     ---@type UnityEngine.GameObject
     self.imgNoneEnoughGo = self:GetGameObject("imgNoneEnough")

    ---@type UILocalizationText
    self.txtCondition = self:GetUIComponent("UILocalizationText", "txtCondition")

    ---@type UILocalizationText
    self.txtValue = self:GetUIComponent("UILocalizationText", "txtValue")
end

--设置数据
function UIPetEquipCondition:SetData(isEnough, conditionStr, valueStr)
    self.imgEnoughGo:SetActive(isEnough)
    self.imgNoneEnoughGo:SetActive(not isEnough)
    if isEnough then
        self.txtCondition:SetText("<color=#1fecd6>"..conditionStr.."</color>")
        self.txtValue:SetText("<color=#1fecd6>"..valueStr.."</color>")
    else
        self.txtCondition:SetText(conditionStr)
        self.txtValue:SetText(valueStr)
    end
end
