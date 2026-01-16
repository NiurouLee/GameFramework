---@class UIComponent:Object
_class( "UIComponent", Object )

function UIComponent:Constructor()
    ---@type UIController
    self.uiController = nil
    self.registerInfo = nil
end

function UIComponent:Init(uiController, registerInfo)
    self.uiController = uiController
    self.registerInfo = registerInfo
end


---该阶段UI资源已经显示了
function UIComponent:Show(uiParams)
end
function UIComponent:AfterShow(TT)
end

function UIComponent:BeforeHide(TT)
end

---该阶段UI资源还没有隐藏
function UIComponent:Hide()
end