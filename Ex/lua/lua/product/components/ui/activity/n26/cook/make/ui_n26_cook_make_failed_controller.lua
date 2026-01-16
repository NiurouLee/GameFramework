--
---@class UIN26CookMakeFailedController : UIController
_class("UIN26CookMakeFailedController", UIController)
UIN26CookMakeFailedController = UIN26CookMakeFailedController

---@param res AsyncRequestRes
function UIN26CookMakeFailedController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UIN26CookMakeFailedController:OnShow(uiParams)
    self:InitWidget()
    local name = uiParams[1]
    local tips = uiParams[2]
    local petIcon = uiParams[3]
    self.name1:SetText(StringTable.Get(name))
    self.tips:SetText(StringTable.Get("str_n26_food_false_tishi",tips))
    self.head:LoadImage(petIcon)
end

--获取ui组件
function UIN26CookMakeFailedController:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.name1 = self:GetUIComponent("UILocalizationText", "name1")
    ---@type UILocalizationText
    self.tips = self:GetUIComponent("UILocalizationText", "tips")
    self.head = self:GetUIComponent("RawImageLoader","head")
    self.animation = self:GetUIComponent("Animation","animation")
    --generated end--
end

--按钮点击
function UIN26CookMakeFailedController:MaskOnClick(go)
    self:StartTask(function (TT)
        local lockName = "UIN26CookMakeFailedController:MaskOnClick"
        self:Lock(lockName)
        self.animation:Play("uieff_N26_CookMakeFailedController_out")
        YIELD(TT, 160)
        self:CloseDialog()
        self:UnLock(lockName)
    end)
end
