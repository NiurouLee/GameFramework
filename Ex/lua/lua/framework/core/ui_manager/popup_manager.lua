--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    Popup窗口管理器
    管理带优先级的 MessageBox 窗口。
    MessageBox窗口：系统消息提示框。用于消息提示、确认消息和提交内容。适合展示较为简单的内容。

    1、MessageBox 窗口属于顶层窗口，在所有窗口之上，包括UILock，有专有的层级depth_message_box。
    2、目前的 MessageBox 窗口不支持请求网络。
    3、MessageBox请求可以有多个，但是同时只会处理一个，后面的请求会等待前面的请求处理完再处理
    4、MessageBox分为两大类：
    普通类（业务逻辑弹框），在UI切换过程中不允许弹出，切完再处理，同Dialog。见UIStateManager说明
    高优先级、可以打断现有逻辑类（弱网弹框，退出游戏弹框等），这种的弹框任何时候可以弹出并打断现有逻辑，像弱网还需要清理干净现有逻辑。
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
---popup优先级
---@class PopupPriority
local _PopupPriority = {
    Invalid = 0,
    Normal = 1,
    Guide = 2,
    --新手强制引导的优先级，谨慎修改，在断线重连（优先级是NetWork）的弹出框下面，在其他所有弹出框的上面,新加入优先级一般小于Guide
    Network = 3,
    --比如弱网(>=该优先级都属于高优先级、可以打断现有逻辑的MessageBox)
    System = 4
    --比如退出游戏的系统提示
}
_enum("PopupPriority", _PopupPriority)
PopupPriority = PopupPriority

---@class PopupManager:Singleton
---@field GetInstance PopupManager
_class("PopupManager", Singleton)
PopupManager = PopupManager
local PrefabSuffix = ".prefab"
local SHALLOW_COPY = table.shallowcopy

--region 初始化/销毁
function PopupManager:Constructor()
    ---优先级高的元素在List前面
    self.popupList = ArrayList:New()
    ---@type Popup
    self.curPopup = nil
    self.priorityFilter = PopupPriority.Normal
    ---@type table<string, UIMessageBox>
    self.name2MsgBox = {}
    self.switchLock = false
end

function PopupManager:Dispose()
    if self.name2MsgBox then
        ---@type table<string, UIMessageBox>
        local name2MsgBox = SHALLOW_COPY(self.name2MsgBox)
        for k, v in pairs(name2MsgBox) do
            v:UnLoad()
            v:Dispose()
        end
    end
end
--end

--region 对外接口

---弹出Popup，
---@param uiMsgBoxName string
---@param priority PopupPriority
---@param ... 不定参由具体的UIMessageBox.Alert解析
function PopupManager.Alert(uiMsgBoxName, priority, ...)
    if(GameGlobal:GetInstance():IsDisposing()) then
        Log.debug("[UIPopup] PopupManager.Alert return,cause game disposing,",uiMsgBoxName,debug.traceback())
        return
    else
        Log.debug("[UIPopup] PopupManager.Alert,",uiMsgBoxName,debug.traceback())
    end
    local popup = Popup:New(uiMsgBoxName, priority, ...)
    GameGlobal.UIStateManager():ShowPopup(popup)
    return popup
end

--endregion

--region 业务层不用关心！
---@private
function PopupManager:GetSwitchLock()
    return self.switchLock
end
---@private
function PopupManager:SetSwitchLock(value)
    Log.debug("[UIPopup] PopupManager:SetSwitchLock,", value)
    self.switchLock = value
end

---@private
---@param value PopupPriority
---@param bOnlyFilter boolean 是否仅过滤掉popup不重置优先级过滤器的值
function PopupManager:SetPopupPriorityFilter(TT, value, bOnlyFilter)
    if value then
        if not bOnlyFilter then
            self.priorityFilter = value
        end

        ---@type Popup[]
        local deletePopup = {}
        for i = 1, self.popupList:Size() do
            local popup = self.popupList:GetAt(i)
            if popup:Priority() < value then
                deletePopup[#deletePopup + 1] = popup
            end
        end

        for i = 1, #deletePopup do
            local popup = deletePopup[i]
            self:ClosePopup(TT, popup)
        end
    end
end

---@private
---@return PopupPriority
function PopupManager:GetPriorityFilter()
    return self.priorityFilter
end

---@private
---@param popup Popup
function PopupManager:OpenPopup(TT, popup)
    if not popup then
        Log.fatal("[UIPopup] PopupManager:OpenPopup, popup is nil,return")
        return
    end
    if popup:Priority() < self.priorityFilter then
        Log.fatal(
            "[UIPopup] PopupManager:OpenPopup, priority=",
            popup:Priority(),
            " is lower than filter=",
            self.priorityFilter,
            ",return"
        )
        return
    end

    -- 检测重复弹出
    local index = self.popupList:Find(popup)
    if index ~= -1 then
        Log.fatal("[UIPopup] PopupManager:OpenPopup, popup had open,return")
        return
    end

    if not self.curPopup or popup:Priority() > self.curPopup:Priority() then
        Log.debug("[UIPopup] PopupManager:OpenPopup,", popup.uiMsgBoxName, ", open and add to popuplist")
        -- 弹新的Popup
        if self.curPopup then
            self.curPopup:Close(TT, false)
        end
        self.curPopup = popup
        self.curPopup:Open(TT)
    else
        --这里把下面两句注释掉了，虽然是历史代码，但是找不到留下来的理由，性能上有损耗，而且逻辑上也不太合理。
        --被动关闭popup
        -- popup:Close(TT, false)
        --这里有个tricky,ugly for messagebox，如果上面这句代码添加了，则必须添加下面这句。
        --ugly原因：当请求的新的popup优先级<=当前popup，可能导致当前popup Open多次。
        --下面这句和上面的代码必须同时出现的原因在于：同名的MessageBox用的是同一份资源，而请求弹出新popup的时候，如果和正在显示的popup是同一个MessageBox，
        --在上句关闭新popup时，会隐藏资源，这时候必须触发当前Popup重新显示。
        -- self.curPopup:Open()
        Log.debug("[UIPopup] PopupManager:OpenPopup,", popup.uiMsgBoxName, ", just add to popuplist")
    end

    -- 按优先级插入
    local index = -1
    for i = 1, self.popupList:Size() do
        local p = self.popupList:GetAt(i)
        if popup:Priority() > p:Priority() then
            index = i
            break
        end
    end
    if index < 0 then
        self.popupList:PushBack(popup)
    else
        self.popupList:Insert(popup, index)
    end
end

---@private
---主动关闭popup（通常是当前正在显示的popup；强引导也是popup，所以会可能主动关闭popup，并且可能不在显示）
---@param popup Popup
function PopupManager:ClosePopup(TT, popup)
    if not popup then
        Log.fatal("[UIPopup] PopupManager:ClosePopup, popup is nil,return")
        return
    end

    local oldSize = self.popupList:Size()
    local index = self.popupList:Remove(popup)
    if self.curPopup == popup then
        Log.debug(
            "[UIPopup] PopupManager:ClosePopup ",
            popup.uiMsgBoxName,
            " which is curPopup, close and remove from popuplist"
        )
        popup:Close(TT)
        if self.popupList:Size() > 0 then
            self.curPopup = self.popupList:GetAt(1)
            Log.debug("[UIPopup] PopupManager:ClosePopup, open popup ", self.curPopup.uiMsgBoxName, " from popupList")
            self.curPopup:Open(TT)
        else
            self.curPopup = nil
        end
    else
        if oldSize == 0 then
            Log.debug(
                "[UIPopup] PopupManager:ClosePopup ",
                popup.uiMsgBoxName,
                " which isn't curPopup, and popuplist is empty"
            )
        elseif index == -1 then
            Log.debug(
                "[UIPopup] PopupManager:ClosePopup ",
                popup.uiMsgBoxName,
                " which isn't curPopup, not in popuplist"
            )
        else
            Log.debug(
                "[UIPopup] PopupManager:ClosePopup ",
                popup.uiMsgBoxName,
                " which isn't curPopup, just remove from popuplist"
            )
        end
    end
end

---@private
---@param uiMsgBoxName string
---@return UIMessageBox
function PopupManager:GetUIMessageBox(TT, uiMsgBoxName)
    local uiMsgBox = self.name2MsgBox[uiMsgBoxName]
    if uiMsgBox then
        return true, uiMsgBox
    else
        -- 创建脚本
        local uiMsgBox = self:CreateUIMessageBox(uiMsgBoxName)
        if not uiMsgBox then
            return
        end
        uiMsgBox:SetName(uiMsgBoxName)

        -- 加载资源
        local uiView, resRequest = UIResourceManager.GetViewAsync(TT, uiMsgBoxName, uiMsgBoxName .. PrefabSuffix)
        if not uiView then
            Log.fatal("[UI] PopupManager:GetUIMessageBox Error, View is Null, ", uiMsgBoxName)
            return
        end

        return false, uiMsgBox, uiView, resRequest
    end
end
---@private
---@param uiMsgBox UIMessageBox
function PopupManager:SetUIMessageBox(uiMsgBoxName, uiMsgBox, uiView, resRequest)
    if uiMsgBox == nil or uiView == nil then
        return
    end
    -- 设置Load Show
    uiMsgBox:Load(uiView, resRequest)
    self.name2MsgBox[uiMsgBoxName] = uiMsgBox
end

---@private
function PopupManager:Clear(TT)
    if self.curPopup then
        self.curPopup:Close(TT)
        self.curPopup = nil
    end
    self.popupList:Clear()
end

---@private
function PopupManager:GetCurShowingPriority()
    if not self.curPopup then
        return PopupPriority.Invalid
    end
    return self.curPopup:Priority()
end

---@private
function PopupManager:HasPopup()
    return self.popupList:Size() > 0
end

---@private
function PopupManager:CreateUIMessageBox(uiMsgBoxName)
    -- 然后创建实例
    local uiMsgBox = _createInstance(uiMsgBoxName)
    if not uiMsgBox then
        Log.fatal("[UI] PopupManager:CreateUIMessageBox Error, No UIMessageBox of name = ", uiMsgBoxName)
    end
    if not uiMsgBox:IsChildOf("UIMessageBox") then
        Log.fatal("[UI] PopupManager:CreateUIMessageBox Fail, ", uiMsgBoxName, " is not inherited from UIMessageBox!")
        return
    end
    return uiMsgBox
end
--endregion