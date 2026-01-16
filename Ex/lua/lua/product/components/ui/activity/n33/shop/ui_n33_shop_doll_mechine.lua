---@class UIN33ShopDollMechineState
local UIN33ShopDollMechineState = 
{
    Lock = 1, -- 锁定
    Empty = 2, -- 抽空
    CanDraw = 3, -- 可以抽（其他状态都是播spine）
}
_enum("UIN33ShopDollMechineState", UIN33ShopDollMechineState)
UIN33ShopDollMechineState = UIN33ShopDollMechineState


---@class UIN33ShopDollMechine : Object
_class("UIN33ShopDollMechine", Object)
UIN33ShopDollMechine = UIN33ShopDollMechine

---@param owner UIN33ShopController
function UIN33ShopDollMechine:Constructor(uiView, owner)
    self._uiView = uiView
    self._owner = owner
    self._gameObject = self._uiView.gameObject
    self:OnInit()
end

function UIN33ShopDollMechine:OnInit()
    local view = self._uiView
    self._bgPic = view:GetUIComponent("RawImageLoader", "BgPic")
    self._goDollParent = view:GetGameObject("Dolls")
    self._rawImageDolls = {}
    self._rawImageDolls[1] = view:GetUIComponent("RawImageLoader", "Doll (3)")
    self._rawImageDolls[2] = view:GetUIComponent("RawImageLoader", "Doll (2)")
    self._rawImageDolls[3] = view:GetUIComponent("RawImageLoader", "Doll (1)")
    self._rawImageDolls[4] = view:GetUIComponent("RawImageLoader", "Doll")
    self._goBgMask = view:GetGameObject("BgMask")
    self._goBoLi = view:GetGameObject("BoLi")
end

function UIN33ShopDollMechine:RefreshState(state, pageIndex)
    if state == UIN33ShopDollMechineState.CanDraw then
        self._gameObject:SetActive(false)
        return
    end

    self._gameObject:SetActive(true)

    -- 未解锁显示娃娃堆和玻璃盒子
    self._goDollParent:SetActive(state == UIN33ShopDollMechineState.Lock)
    self._goBoLi:SetActive(state == UIN33ShopDollMechineState.Lock)
    -- 抽空显示遮罩
    self._goBgMask:SetActive(state == UIN33ShopDollMechineState.Empty)

    local uiCfg = Cfg.cfg_n33_shop_ui[pageIndex]
    if not uiCfg then
        return
    end
    if state == UIN33ShopDollMechineState.Lock then
        self._rawImageDolls[1]:LoadImage(uiCfg.DollMechineLockNormalDoll)
        self._rawImageDolls[2]:LoadImage(uiCfg.DollMechineLockSpecialDoll)
        self._rawImageDolls[3]:LoadImage(uiCfg.DollMechineLockNormalDoll)
        self._rawImageDolls[4]:LoadImage(uiCfg.DollMechineLockNormalDoll)
        self._bgPic:LoadImage(uiCfg.DollMechineLockBG)
    else
        self._bgPic:LoadImage(uiCfg.DollMechineBG)
    end
end
