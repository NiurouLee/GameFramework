--
---@class UIN32MultiLineOverTips : UIController
_class("UIN32MultiLineOverTips", UIController)
UIN32MultiLineOverTips = UIN32MultiLineOverTips

---@param res AsyncRequestRes
function UIN32MultiLineOverTips:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UIN32MultiLineOverTips:OnShow(uiParams)
    self:InitWidget()
    local unPassNum = uiParams[1]
    local roleModule = self:GetModule(RoleModule)
    local name = roleModule:GetName()
    self.desc:SetText(StringTable.Get("str_n32_multiline_branch_tips", name, unPassNum))
end

--获取ui组件
function UIN32MultiLineOverTips:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.desc = self:GetUIComponent("UILocalizationText", "desc")
    self.animation = self:GetUIComponent("Animation","animation")
    --generated end--
end


--按钮点击
function UIN32MultiLineOverTips:BtnConformOnClick(go)
    self:StartTask(function (TT)
        local lockName = "UIN32MultiLineOverTips:ExitAni"
        self:Lock(lockName)
        self.animation:Play("uieff_UIN32MultiLineOverTips_out")
        YIELD(TT, 200)
        self:CloseDialog()
        self:UnLock(lockName)
    end)
end
