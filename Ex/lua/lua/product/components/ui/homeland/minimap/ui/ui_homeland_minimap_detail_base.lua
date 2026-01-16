---@class UIHomelandMinimapDetailBase:UICustomWidget
_class("UIHomelandMinimapDetailBase", UICustomWidget)
UIHomelandMinimapDetailBase = UIHomelandMinimapDetailBase

---@param iconData UIHomelandMinimapIconData
function UIHomelandMinimapDetailBase:InternalInitialize(iconData)
    self.anim = self:GetUIComponent("Animation", "Anim")
    ---@type UIHomelandMinimapIconData
    self._iconData = iconData
    self:OnInitDone()
end

---@return UIHomelandMinimapIconData
function UIHomelandMinimapDetailBase:GetIconData()
    return self._iconData
end

--初始化完成回调
function UIHomelandMinimapDetailBase:OnInitDone()
end

--切换显示UI的时候的前面一个界面的关闭回调
function UIHomelandMinimapDetailBase:OnClose()
    local animation = self:GetAnimation()
    if not animation then
        self:GetGameObject():SetActive(false)
    else
        local animName = self:GetCloseAnimtionName()
        if animName ~= nil and animName ~= "" then
            animation:Play(animName)
        else
            self:GetGameObject():SetActive(false)
        end
    end
end

function UIHomelandMinimapDetailBase:GetAnimation()
    return self.anim
end

function UIHomelandMinimapDetailBase:GetCloseAnimtionName()
    return ""
end
