--
---@class UIMedalCard : UICustomWidget
_class("UIMedalCard", UICustomWidget)
UIMedalCard = UIMedalCard


function UIMedalCard:Constructor()
    self.roleModule = GameGlobal.GetModule(RoleModule)
    self.visitData = nil
end

--初始化
function UIMedalCard:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIMedalCard:InitWidget()
    ---@type UnityEngine.GameObject
    self.root = self:GetGameObject("root")
    ---@type UnityEngine.GameObject
    self.imgLock = self:GetGameObject("imgLock")
    ---@type UnityEngine.GameObject
    self.imgEdit = self:GetGameObject("imgEdit")
    ---@type UnityEngine.GameObject
    self.imgDetail = self:GetGameObject( "imgDetail")
    ---@type UICustomWidgetPool
    self.cardPool = self:GetUIComponent("UISelectObjectPath", "card")
    self._rightTopGO = self:GetGameObject("rightTop")
end

--设置数据
--visitData nil 时，代表自己
function UIMedalCard:SetData(visitData, hideRightTop)
    if visitData then
        self.visitData = visitData
        self:_SetPlaceData(visitData, true)
        self.imgLock:SetActive(false)
        self.imgEdit:SetActive(false)
    else
        local medalMoule = GameGlobal.GetModule(MedalModule)
        local placeData = medalMoule:GetPlacementInfo()
        self:_SetPlaceData(placeData)

        local unLock = self.roleModule:CheckModuleUnlock(GameModuleID.MD_MEDAL)
        self.imgLock:SetActive(not unLock)
        self.imgEdit:SetActive(unLock)
        self.imgDetail:SetActive(unLock)
    end
    if hideRightTop then
        self._rightTopGO:SetActive(false)
    end
end


function UIMedalCard:_SetPlaceData(placeData, visit)
    if not self.visitData then
        local unLock = self.roleModule:CheckModuleUnlock(GameModuleID.MD_MEDAL)
        if not unLock then
            return
        end
    end

    if not self.card then
        ---@type UIMedalCardSimple
        self.card = self.cardPool:SpawnObject("UIMedalCardSimple")
    end
    self.card:SetData(1113, placeData,visit, function ()
        self:_OnBgClicked()
    end)
end

function UIMedalCard:_OnBgClicked()
    if not self.visitData then
        local unLock = self.roleModule:CheckModuleUnlock(GameModuleID.MD_MEDAL)
        if not unLock then
            ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
            return
        end
    end
    self:ShowDetailDialog()
end


--按钮点击
function UIMedalCard:ImgEditOnClick(go)
    self:ShowDialog("UIN22MedalEdit")
end

--按钮点击
function UIMedalCard:ImgDetailOnClick(go)
    self:ShowDetailDialog()
end

function UIMedalCard:ImgLockOnClick(go)
    ToastManager.ShowToast(StringTable.Get("str_function_lock_zidongzhandou_tips"))
end

function UIMedalCard:ShowDetailDialog()
    if self.visitData then
        self:ShowDialog("UIMedalCardDetailController", self.visitData)
    else
        self:ShowDialog("UIMedalCardDetailController")
    end
end
