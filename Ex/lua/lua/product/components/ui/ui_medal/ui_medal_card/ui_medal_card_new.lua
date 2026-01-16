--
---@class UIMedalCard_New : UICustomWidget
_class("UIMedalCard_New", UICustomWidget)
UIMedalCard_New = UIMedalCard_New


function UIMedalCard_New:Constructor()
    self.roleModule = GameGlobal.GetModule(RoleModule)
    self.visitData = nil
end

--初始化
function UIMedalCard_New:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIMedalCard_New:InitWidget()
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
function UIMedalCard_New:SetData(visitData, hideRightTop)
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


function UIMedalCard_New:_SetPlaceData(placeData, visit)
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
    self.card:SetData(672, placeData,visit, function ()
        self:_OnBgClicked()
    end)
end

function UIMedalCard_New:_OnBgClicked()
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
function UIMedalCard_New:ImgEditOnClick(go)
    self:ShowDialog("UIN22MedalEdit")
end

--按钮点击
function UIMedalCard_New:ImgDetailOnClick(go)
    self:ShowDetailDialog()
end

function UIMedalCard_New:ImgLockOnClick(go)
    ToastManager.ShowToast(StringTable.Get("str_function_lock_zidongzhandou_tips"))
end

function UIMedalCard_New:ShowDetailDialog()
    if self.visitData then
        self:ShowDialog("UIMedalCardDetailController", self.visitData)
    else
        self:ShowDialog("UIMedalCardDetailController")
    end
end
