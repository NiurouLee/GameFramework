--
---@class UIMedalCardDetailController : UIController
_class("UIMedalCardDetailController", UIController)
UIMedalCardDetailController = UIMedalCardDetailController

--初始化
function UIMedalCardDetailController:OnShow(uiParams)
    self:InitWidget()
    local visitData = uiParams[1]
    self:_SetData(visitData)
end

--获取ui组件
function UIMedalCardDetailController:InitWidget()
    self.btnEdit = self:GetGameObject("btnEdit")
    ---@type UICustomWidgetPool
    local cardPool = self:GetUIComponent("UISelectObjectPath", "card")
    self.card = cardPool:SpawnObject("UIMedalCardSimple")
end

function UIMedalCardDetailController:_SetData(visitData)
    local isVisit = nil
    if  visitData then
        self.btnEdit:SetActive(false)
        isVisit = true
    else
        self.btnEdit:SetActive(true)
        local medalMoule = GameGlobal.GetModule(MedalModule)
        visitData = medalMoule:GetPlacementInfo()
    end
    self.card:SetData(1800, visitData, isVisit)
end

--按钮点击
function UIMedalCardDetailController:BgOnClick(go)
    self:CloseDialog()
end

--按钮点击
function UIMedalCardDetailController:BtnBackOnClick(go)
    self:CloseDialog()
end

--按钮点击
function UIMedalCardDetailController:BtnEditOnClick(go)
    self:ShowDialog("UIN22MedalEdit")
end
