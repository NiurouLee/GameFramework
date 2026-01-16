---@class UIHauteCoutureDrawChargeMainPLM:UIHauteCoutureDrawChargeBase
_class("UIHauteCoutureDrawChargeMainPLM", UIHauteCoutureDrawChargeBase)
UIHauteCoutureDrawChargeMainPLM = UIHauteCoutureDrawChargeMainPLM

function UIHauteCoutureDrawChargeMainPLM:Constructor()
end

function UIHauteCoutureDrawChargeMainPLM:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawChargeMainPLM:InitWidgets()
   --通用Widgets初始化
    --self:InitWidgetsBase()
    self.controller = self.uiOwner
    ---@type UIHauteCoutureDataBase
    self._ctx = self.controller._ctx

    local btns = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self:StartTask(
                function(TT)
                    self._anim:Play("UIHauteCoutureDrawChargeMainGL_out")
                    YIELD(TT, 450)
                    self.controller:CloseDialog()
                end
            )

        end,
        nil,
        nil,
        true
    )

    local currency = self:GetUIComponent("UISelectObjectPath", "currencyMenu")
    ---@type UICurrencyMenu
    self._topTips = currency:SpawnObject("UICurrencyMenu")
    self._topTips:SetData({HauteCouture:GetInstance().CostCoinId}, true)
    self._topTips:ShowHideTSFBtn(true)

    self._itemPool = self:GetUIComponent("UISelectObjectPath", "Content")
    --个性化Widgets初始化
    self._anim = self:GetUIComponent("Animation", "anim")
end

function UIHauteCoutureDrawChargeMainPLM:_OnValue()
    self:_OnValueBase()
    local itemPools = self._itemPool:GetAllSpawnList()
    for i = 1, #itemPools do
        local item = itemPools[i]
        item:PlayAnimIn(i)
    end
end


--子类实现
function UIHauteCoutureDrawChargeMainPLM:GetItemImpl()
    return "UIHauteCoutureDrawChargeItemPLM"
end
