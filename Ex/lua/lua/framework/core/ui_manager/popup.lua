--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    每次请求弹出会创建一个 popup
    存储弹出信息、优先级
    依赖 UIMessageBox 负责UI的显示、关闭、点击逻辑
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
---@class Popup:Object
_class("Popup", Object)
Popup = Popup

function Popup:Constructor(uiMsgBoxName, priority, ...)
    self.uiMsgBoxName = uiMsgBoxName
    self.priority = priority or PopupPriority.Normal
    self.params = {...}
end

function Popup:Priority(value)
    if value then
        self.priority = value
    else
        return self.priority
    end
end

--region Private
---@private
function Popup:Open(TT)
    if not GameGlobal.UIStateManager() then
        Log.fatal("[UIPopup] Popup:Open UIStateManager is nil, return")
        return
    end
    local uiMsgBox = GameGlobal.UIStateManager():GetUIMessageBox(TT, self.uiMsgBoxName, true)
    if not uiMsgBox then
        Log.fatal("[UIPopup] Popup:Open cannot find uiMsgBox named ",self.uiMsgBoxName,", return")
        return
    end
    Log.debug("[UIPopup] Popup:Open,",self.uiMsgBoxName)
    uiMsgBox:Alert(self, self.params)
    uiMsgBox:SetShow(true)
end

---@private
---@param clearCallback 是否清理callback 默认是true
function Popup:Close(TT, clearCallback)
    clearCallback = clearCallback ~= false

    local uiMsgBox = GameGlobal.UIStateManager():GetUIMessageBox(TT, self.uiMsgBoxName, false)
    if not uiMsgBox then
        return
    end

    Log.debug("[UIPopup] Popup:Close,",self.uiMsgBoxName)
    if clearCallback then        
        Log.debug("[UIPopup] Popup:Close,",self.uiMsgBoxName,",clearCallback")
        -- 确定关闭
        uiMsgBox:ClearCallback()
    end
    -- 隐藏先压到列表;这里要处理隐藏，有的Close不一定是通过点击按钮触发的，比如通过PopupManager:SetPopupPriorityFilter
    uiMsgBox:SetShow(false)
end
--endregion
