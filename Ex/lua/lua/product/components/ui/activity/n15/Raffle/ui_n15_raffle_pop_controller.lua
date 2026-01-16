---@class UIN15RafflePopController : UIController
_class("UIN15RafflePopController", UIController)
UIN15RafflePopController = UIN15RafflePopController
function UIN15RafflePopController:OnShow(uiParams)
    self:_InitWidget()
    self._cb = uiParams[1]
    self:_RefView()
end

---@private
---初始化组件
function UIN15RafflePopController:_InitWidget()
    ---@type UILocalizedTMP
    self._tmp = self:GetUIComponent("UILocalizedTMP", "TMP")
end

---@private
---刷新显示
function UIN15RafflePopController:_RefView()
    self._materialReq = ResourceManager:GetInstance():SyncLoadAsset("N15Material_02.mat", LoadType.Mat)
    if self._materialReq and self._materialReq.Obj then
        self._material = self._materialReq.Obj
        local oldMaterial = self._tmp.fontMaterial
        self._tmp.fontMaterial = self._material
        self._tmp.fontMaterial:SetTexture("_MainTex", oldMaterial:GetTexture("_MainTex"))
    end
    self:StartTask(
        function(TT)
            YIELD(TT, 2000)
            self:CloseDialog()
            YIELD(TT, 100)
            self._cb()
        end
    )
end
