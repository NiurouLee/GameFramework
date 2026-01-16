---@class LuaUIView:Object
_class( "LuaUIView", Object )
LuaUIView = LuaUIView
---@class UIEvent
local UIEvent = {
    Guide = 0,                          --新手引导点击
    Click = 1,                          --按钮单击
    DoubleClick = 2,                    --双击
    Press = 3,                          --按钮鼠标按下
    Release = 4,                        --按钮鼠标抬起
    Hovered = 5,                        --鼠标悬到按钮
    Unhovered = 6,                      --鼠标悬过按钮
    Select = 7,                         --选中事件
    UpdateSelect = 8,                   --更新
    BeginDrag = 9,                      --开始拖拽
    Drag = 10,                          --拖拽中
    EndDrag = 11,                       --结束拖拽
    Scroll = 12,                        --滚动事件
    ApplicationFocus = 13,              --得到焦点
    LongClick = 14,                     --长按按钮点击
    LongPress = 15,                     --长按按钮按下
    ToggleChanged = 16,                 --Toggle状态变化
    SliderChanged = 17,                 --Slider变化
    DropdownChanged = 18,               --DropDown变化
    ScrollRectChanged = 19,             --ScrollRect变化
    InputFieldChanged = 20,             --InputField变化
    InputFieldEndEdit = 21,             --InputField结束输入
    InputFieldValidate = 22,            --InputField Validate 
}
_enum("UIEvent", UIEvent)

--绑定的lua方法名字，unity里控件的事件的名字, LuaUIView里定义的绑定事件的方法名字
local UIEventFuncs = {
    {"OnClick", "onClick", "AddClickListener"},                               --（方法命名：按钮名字+OnClick）
    {"OnDoubleClick", "onDoubleClick", "AddDoubleClickListener"},             --（方法命名：按钮名字+OnDoubleClick）
    {"OnPressed", "onDown", "AddPressListener"},                              --（方法命名：按钮名字+OnPressed）
    {"OnReleased", "onUp", "AddReleaseListener"},                             --（方法命名：按钮名字+OnReleased）
    {"OnHovered", "onEnter", "AddHoveredListener"},                           --（方法命名：按钮名字+OnHovered）
    {"OnUnhovered", "onExit", "AddUnhoveredListener"},                        --（方法命名：按钮名字+OnUnhovered）
    {"OnSelect", "onSelect", "AddSelectListener"},                            --（方法命名：按钮名字+OnSelect
    {"OnUpdateSelect", "onUpdateSelect", "AddUpdateSelectListener"},          --（方法命名：按钮名字+OnUpdateSelect
    {"OnBeginDrag", "onBeginDrag", "AddBeginDragListener"},                   --（方法命名：按钮名字+OnBeginDrag
    {"OnDrag", "onDrag", "AddDragListener"},                                  --（方法命名：按钮名字+OnDrag
    {"OnEndDrag", "onEndDrag", "AddEndDragListener"},                         --（方法命名：按钮名字+OnEndDrag
    {"OnScroll", "onScroll", "AddScrollListener"},                            --（方法命名：组件名字+OnScroll）
    {"OnApplicationFocus", "onApplicationFocus", "AddFocusListener"},         --（方法命名：组件名字+OnScroll）

    {"OnLongClick", "onClick", "AddLongClickListener"},                       --（方法命名：长按按钮名字+OnLongClick
    {"OnLongPress", "onLongPress", "AddLongPressListener"},                   --（方法命名：长按按钮名字+OnLongPress

    {"OnValueChanged", "onValueChanged", "AddToggleListener"},                --（方法命名：Toggle名字+OnValueChanged）
    {"OnValueChanged", "onValueChanged", "AddSliderListener"},                --（方法命名：Slider名字+OnValueChanged）
    {"OnValueChanged", "onValueChanged", "AddDropDownListener"},              --（方法命名：DropDown名字+OnValueChanged）
    {"OnValueChanged", "onValueChanged", "AddScrollRectListener"},            --（方法命名：ScrollRect名字+OnValueChanged）
    {"OnValueChanged", "onValueChanged", "AddInputFieldListener"},            --（方法命名：InputField名字+OnValueChanged）
    {"OnEndEdit", "onEndEdit", "AddInputFieldEndEdit"},                       --（方法命名：InputField名字+OnEndEdit
    {"OnValidateInput", "onValidateInput", "AddInputFieldValidate"},          --（方法命名：InputField名字+OnValidateInput
}
--region 初始化/销毁
function LuaUIView:Constructor()
    --点击事件响应
	---@type table<UIEvent, table<UIListener>>
    self.uiEventListeners = {}
end

function LuaUIView:Dispose()
end
--endregion

function LuaUIView:SetShow(bShow, ui)
    if self.isShow == bShow then
        return
    end
    self.isShow = bShow
    if bShow then
        self:OnShow(ui)
    else
        self:OnHide()
    end
end

function LuaUIView:OnShow(ui)
    self.ui = ui
    self:AddUIListeners()
end

function LuaUIView:OnHide()
    self:RemoveUIListeners()
end

--region UI控件事件注册
---@param uiEventType UIEvent
---@param widget UnityEngine.GameObject
function LuaUIView:AddUIEvent(uiEventType, widget, name)
    self[UIEventFuncs[uiEventType][3]](self, widget, name)
end

---绑定按钮单击事件
function LuaUIView:AddClickListener(widget, name)
    name = name or widget.name
    local listener = UIClickListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Click]
    if not listeners then
        self.uiEventListeners[UIEvent.Click] = {}
        listeners = self.uiEventListeners[UIEvent.Click]
    end
    listeners[name] = listener
end

---绑定按钮双击事件
function LuaUIView:AddDoubleClickListener(widget, name)
    name = name or widget.name
    local listener = UIDoubleClickListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.DoubleClick]
    if not listeners then
        self.uiEventListeners[UIEvent.DoubleClick] = {}
        listeners = self.uiEventListeners[UIEvent.DoubleClick]
    end
    listeners[name] = listener
end

---绑定按钮鼠标按下事件
function LuaUIView:AddPressListener(widget, name)
    name = name or widget.name
    local listener = UIPressedListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Press]
    if not listeners then
        self.uiEventListeners[UIEvent.Press] = {}
        listeners = self.uiEventListeners[UIEvent.Press]
    end
    listeners[name] = listener
end

---绑定按钮鼠标抬起事件
function LuaUIView:AddReleaseListener(widget, name)
    name = name or widget.name
    local listener = UIReleaseListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Release]
    if not listeners then
        self.uiEventListeners[UIEvent.Release] = {}
        listeners = self.uiEventListeners[UIEvent.Release]
    end
    listeners[name] = listener
end

---绑定鼠标悬到事件
function LuaUIView:AddHoveredListener(widget, name)
    name = name or widget.name
    local listener = UIHoveredListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Hovered]
    if not listeners then
        self.uiEventListeners[UIEvent.Hovered] = {}
        listeners = self.uiEventListeners[UIEvent.Hovered]
    end
    listeners[name] = listener
end

---绑定鼠标悬过事件
function LuaUIView:AddUnhoveredListener(widget, name)
    name = name or widget.name
    local listener = UIUnHoveredListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Unhovered]
    if not listeners then
        self.uiEventListeners[UIEvent.Unhovered] = {}
        listeners = self.uiEventListeners[UIEvent.Unhovered]
    end
    listeners[name] = listener
end

---绑定选中事件
function LuaUIView:AddSelectListener(widget, name)
    name = name or widget.name
    local listener = UISelectListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Select]
    if not listeners then
        self.uiEventListeners[UIEvent.Select] = {}
        listeners = self.uiEventListeners[UIEvent.Select]
    end
    listeners[name] = listener
end

---绑定更新事件
function LuaUIView:AddUpdateSelectListener(widget, name)
    name = name or widget.name
    local listener = UIUpdateSelectListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.UpdateSelect]
    if not listeners then
        self.uiEventListeners[UIEvent.UpdateSelect] = {}
        listeners = self.uiEventListeners[UIEvent.UpdateSelect]
    end
    listeners[name] = listener
end

---绑定开始拖拽事件
function LuaUIView:AddBeginDragListener(widget, name)
    name = name or widget.name
    local listener = UIBeginDragListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.BeginDrag]
    if not listeners then
        self.uiEventListeners[UIEvent.BeginDrag] = {}
        listeners = self.uiEventListeners[UIEvent.BeginDrag]
    end
    listeners[name] = listener
end

---绑定拖拽事件
function LuaUIView:AddDragListener(widget, name)
    name = name or widget.name
    local listener = UIDragListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Drag]
    if not listeners then
        self.uiEventListeners[UIEvent.Drag] = {}
        listeners = self.uiEventListeners[UIEvent.Drag]
    end
    listeners[name] = listener
end

---绑定结束拖拽事件
function LuaUIView:AddEndDragListener(widget, name)
    name = name or widget.name
    local listener = UIEndDragListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.EndDrag]
    if not listeners then
        self.uiEventListeners[UIEvent.EndDrag] = {}
        listeners = self.uiEventListeners[UIEvent.EndDrag]
    end
    listeners[name] = listener
end

---绑定滚动事件
function LuaUIView:AddScrollListener(widget, name)
    name = name or widget.name
    local listener = UIScrollListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.Scroll]
    if not listeners then
        self.uiEventListeners[UIEvent.Scroll] = {}
        listeners = self.uiEventListeners[UIEvent.Scroll]
    end
    listeners[name] = listener
end

---绑定获得焦点事件
function LuaUIView:AddFocusListener(widget, name)
    name = name or widget.name
    local listener = UIFocusListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.ApplicationFocus]
    if not listeners then
        self.uiEventListeners[UIEvent.ApplicationFocus] = {}
        listeners = self.uiEventListeners[UIEvent.ApplicationFocus]
    end
    listeners[name] = listener
end

---长按按钮点击事件
function LuaUIView:AddLongClickListener(widget, name)
    name = name or widget.name
    local listener = LongClickListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.LongClick]
    if not listeners then
        self.uiEventListeners[UIEvent.LongClick] = {}
        listeners = self.uiEventListeners[UIEvent.LongClick]
    end
    listeners[name] = listener
end

---长按按钮按下事件
function LuaUIView:AddLongPressListener(widget, name)
    name = name or widget.name
    local listener = LongPressListener:New(self.ui, name, widget)
    if not listener:IsSucceed() then
        return
    end
    local listeners = self.uiEventListeners[UIEvent.LongPress]
    if not listeners then
        self.uiEventListeners[UIEvent.LongPress] = {}
        listeners = self.uiEventListeners[UIEvent.LongPress]
    end
    listeners[name] = listener
end

---绑定Toggle状态改变事件
function LuaUIView:AddToggleListener(widget, name)
    name = name or widget.name
    local listener = ToggleListener:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.ToggleChanged]
    if not listeners then
        self.uiEventListeners[UIEvent.ToggleChanged] = {}
        listeners = self.uiEventListeners[UIEvent.ToggleChanged]
    end
    listeners[name] = listener
end

---绑定Slider状态改变事件
function LuaUIView:AddSliderListener(widget, name)
    name = name or widget.name
    local listener = SliderListener:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.SliderChanged]
    if not listeners then
        self.uiEventListeners[UIEvent.SliderChanged] = {}
        listeners = self.uiEventListeners[UIEvent.SliderChanged]
    end
    listeners[name] = listener
end

---绑定DropDown状态改变事件
function LuaUIView:AddDropDownListener(widget, name)
    name = name or widget.name
    local listener = DropDownListener:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.DropdownChanged]
    if not listeners then
        self.uiEventListeners[UIEvent.DropdownChanged] = {}
        listeners = self.uiEventListeners[UIEvent.DropdownChanged]
    end
    listeners[name] = listener
end

---绑定ScrollRect状态改变事件
function LuaUIView:AddScrollRectListener(widget, name)
    name = name or widget.name
    local listener = ScrollRectListener:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.ScrollRectChanged]
    if not listeners then
        self.uiEventListeners[UIEvent.ScrollRectChanged] = {}
        listeners = self.uiEventListeners[UIEvent.ScrollRectChanged]
    end
    listeners[name] = listener
end

---绑定InputField状态改变事件
function LuaUIView:AddInputFieldListener(widget, name)
    name = name or widget.name
    local listener = InputFieldListener:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.InputFieldChanged]
    if not listeners then
        self.uiEventListeners[UIEvent.InputFieldChanged] = {}
        listeners = self.uiEventListeners[UIEvent.InputFieldChanged]
    end
    listeners[name] = listener
end

---绑定InputField结束编辑事件
function LuaUIView:AddInputFieldEndEdit(widget, name)
    name = name or widget.name
    local listener = InputFieldEndEdit:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.InputFieldEndEdit]
    if not listeners then
        self.uiEventListeners[UIEvent.InputFieldEndEdit] = {}
        listeners = self.uiEventListeners[UIEvent.InputFieldEndEdit]
    end
    listeners[name] = listener
end

---绑定InputField Validate事件
function LuaUIView:AddInputFieldValidate(widget, name)
    name = name or widget.name
    local listener = InputFieldValidata:New(self.ui, name, widget)
    local listeners = self.uiEventListeners[UIEvent.InputFieldValidate]
    if not listeners then
        self.uiEventListeners[UIEvent.InputFieldValidate] = {}
        listeners = self.uiEventListeners[UIEvent.InputFieldValidate]
    end
    listeners[name] = listener
end

function LuaUIView:AddUIListeners()
    --界面打开的时候主动绑定ui事件，OnClick已在C#做了绑定，其他需要框架主动绑定可以在这里加扩展
end

function LuaUIView:RemoveUIListeners()
    for _, listeners in next, self.uiEventListeners do
        for _, v in next, listeners do
            v:RemoveListener()
            v:Dispose()
        end
    end
    table.clear(self.uiEventListeners)
end
--endregion

--region UI事件
--region UI事件绑定基类
---@class UIListener:Object
_class( "UIListener", Object )
UIListener = UIListener

local widgets = {}

function UIListener:Constructor(target, name, widget)
    ---@type UnityEngine.Component
    self.widget = widget
    self.name = name
    self.target = target
end

function UIListener:IsSucceed()
    return self.handler ~= nil
end

function UIListener:AddEvent()
    local methodName = self.name .. UIEventFuncs[self.kind][1] --需规范
    self.handler = self:CreateVoidEventHandler(self.target, methodName)
    if self.handler then
        self:AddListener()
    end
end

function UIListener:CreateVoidEventHandler(target, methodName)
    if not target then
        Log.fatal("[UI] Cannot Find Lua Table For UIEvent")
        return
    end
    local func = target[methodName]
    if not func then
        Log.fatal("[UI] Cannot Find Lua Function For UIEvent, ", methodName, "  ui ", target._className)
        return
    end
    return func
end


function UIListener.CallMethond(widget, kind, ...)
    local listener = widgets[kind][widget]
    return listener.handler(listener.target, ...)
end

function UIListener:AddListener()
    if self.widget then
        self.event = self.widget[UIEventFuncs[self.kind][2]]
        local widget = tostring(self.widget)
        self.address = widget
        local kind = self.kind
        if not widgets[kind] then
            widgets[kind] = {}
        end
        widgets[kind][widget] = self
        self.event:AddListener(function(...)
            UIListener.CallMethond(widget, kind, ...)
        end)
    end
end

function UIListener:RemoveListener()
    if self.widget then
        self.event:RemoveAllListeners()
    end
end

function UIListener:Dispose()
    widgets[self.kind][self.address] = nil
    self.widget = nil
    self.handler = nil
    self.target = nil
    self.event = nil
end
--endregion

--region
---UIEventTriggerListener触发的UI事件基类
---@class TriggerListener:UIListener
_class( "TriggerListener", UIListener )
TriggerListener = TriggerListener

function TriggerListener:AddListener()
    if self.widget then
        local widget = tostring(self.widget)
        self.address = widget
        local kind = self.kind
        if not widgets[kind] then
            widgets[kind] = {}
        end
        widgets[kind][widget] = self
        self.event = UIEventTriggerListener.Get(self.widget.gameObject)
        self.event[UIEventFuncs[self.kind][2]] = function(...)
            UIListener.CallMethond(widget, kind, ...)
        end
    end
end

function TriggerListener:RemoveListener()
    if self.widget then
        self.event[UIEventFuncs[self.kind][2]] = nil
    end
end
--endregion

--region
---UILongPressTriggerListener触发的UI事件基类
---@class LongPressTrigger:TriggerListener
_class( "LongPressTrigger", TriggerListener )
LongPressTrigger = LongPressTrigger

function LongPressTrigger:AddListener()
    if self.widget then
        local widget = tostring(self.widget)
        self.address = widget
        local kind = self.kind
        if not widgets[kind] then
            widgets[kind] = {}
        end
        widgets[kind][widget] = self
        self.event = UILongPressTriggerListener.Get(self.widget.gameObject)
        self.event[UIEventFuncs[self.kind][2]] = function(...)
            UIListener.CallMethond(widget, kind, ...)
        end
    end
end
--endregion


--region 按钮单击事件绑定
---@class UIClickListener:TriggerListener
_class( "UIClickListener", TriggerListener )
UIClickListener = UIClickListener

function UIClickListener:Constructor()
    self.kind = UIEvent.Click
    self:AddEvent()
end
--endregion

--region 按钮双击事件绑定
---@class UIDoubleClickListener:TriggerListener
_class( "UIDoubleClickListener", TriggerListener )
UIDoubleClickListener = UIDoubleClickListener

function UIDoubleClickListener:Constructor()
    self.kind = UIEvent.DoubleClick
    self:AddEvent()
end
--endregion

--region 按下鼠标按钮事件绑定
---@class UIPressedListener:TriggerListener
_class( "UIPressedListener", TriggerListener )
UIPressedListener = UIPressedListener

function UIPressedListener:Constructor()
    self.kind = UIEvent.Press
    self:AddEvent()
end
--endregion

--region 按钮鼠标按钮事件绑定
---@class UIReleaseListener:TriggerListener
_class( "UIReleaseListener", TriggerListener )
UIReleaseListener = UIReleaseListener

function UIReleaseListener:Constructor()
    self.kind = UIEvent.Release
    self:AddEvent()
end
--endregion

--region 鼠标悬到按钮事件绑定
---@class UIHoveredListener:TriggerListener
_class( "UIHoveredListener", TriggerListener )
UIHoveredListener = UIHoveredListener

function UIHoveredListener:Constructor()
    self.kind = UIEvent.Hovered
    self:AddEvent()
end
--endregion

--region 鼠标悬过按钮事件绑定
---@class UIPressedListener:TriggerListener
_class( "UIUnHoveredListener", TriggerListener )
UIUnHoveredListener = UIUnHoveredListener

function UIUnHoveredListener:Constructor()
    self.kind = UIEvent.Unhovered
    self:AddEvent()
end
--endregion

--region 选中事件绑定
---@class UISelectListener:TriggerListener
_class( "UISelectListener", TriggerListener )
UISelectListener = UISelectListener

function UISelectListener:Constructor()
    self.kind = UIEvent.Select
    self:AddEvent()
end
--endregion

--region 更新事件绑定
---@class UIUpdateSelectListener:TriggerListener
_class( "UIUpdateSelectListener", TriggerListener )
UIUpdateSelectListener = UIUpdateSelectListener

function UIUpdateSelectListener:Constructor()
    self.kind = UIEvent.UpdateSelect
    self:AddEvent()
end
--endregion

--region 开始拖拽事件绑定
---@class UIBeginDragListener:TriggerListener
_class( "UIBeginDragListener", TriggerListener )
UIBeginDragListener = UIBeginDragListener

function UIBeginDragListener:Constructor()
    self.kind = UIEvent.BeginDrag
    self:AddEvent()
end
--endregion

--region 拖拽事件绑定
---@class UIDragListener:TriggerListener
_class( "UIDragListener", TriggerListener )
UIDragListener = UIDragListener

function UIDragListener:Constructor()
    self.kind = UIEvent.Drag
    self:AddEvent()
end
--endregion

--region 结束拖拽事件绑定
---@class UIEndDragListener:TriggerListener
_class( "UIEndDragListener", TriggerListener )
UIEndDragListener = UIEndDragListener

function UIEndDragListener:Constructor()
    self.kind = UIEvent.EndDrag
    self:AddEvent()
end
--endregion

--region 滚动事件绑定
---@class UIScrollListener:TriggerListener
_class( "UIScrollListener", TriggerListener )
UIScrollListener = UIScrollListener

function UIScrollListener:Constructor()
    self.kind = UIEvent.Scroll
    self:AddEvent()
end
--endregion

--region 得到焦点事件绑定
---@class UIFocusListener:TriggerListener
_class( "UIFocusListener", TriggerListener )
UIFocusListener = UIFocusListener

function UIFocusListener:Constructor()
    self.kind = UIEvent.ApplicationFocus
    self:AddEvent()
end
--endregion

--region 长按按钮单击事件绑定
---@class LongClickListener:LongPressTrigger
_class( "LongClickListener", LongPressTrigger )
LongClickListener = LongClickListener

function LongClickListener:Constructor()
    self.kind = UIEvent.LongClick
    self:AddEvent()
end
--endregion

--region 长按按钮长按事件绑定
---@class LongPressListener:LongPressTrigger
_class( "LongPressListener", LongPressTrigger )
LongPressListener = LongPressListener

function LongPressListener:Constructor()
    self.kind = UIEvent.LongPress
    self:AddEvent()
end
--endregion

--region Toggle状态改变事件绑定
---@class ToggleListener:UIListener
_class( "ToggleListener", UIListener )
ToggleListener = ToggleListener

function ToggleListener:Constructor()
    self.kind = UIEvent.ToggleChanged
    self:AddEvent()
end

function ToggleListener:AddListener()
    if self.widget then
        if not self.h3dToggle then
            local go = self.widget.gameObject
            local h3dToggle = go:GetComponent("H3DToggle")
            if not h3dToggle then
                h3dToggle = go:AddComponent(typeof(H3DToggle))
            end
            self.h3dToggle = h3dToggle
        end
        local widget = tostring(self.widget)
        self.address = widget
        local kind = self.kind
        if not widgets[kind] then
            widgets[kind] = {}
        end
        widgets[kind][widget] = self
        self.h3dToggle:OnValueChanged(function(...)
            UIListener.CallMethond(widget, kind, ...)
        end)
    end
end

function ToggleListener:RemoveListener()
    if self.widget and self.h3dToggle then
        self.h3dToggle:OnValueChanged(nil)
    end
end

function ToggleListener:Dispose()
    self.h3dToggle = nil
end
--endregion

--region Slider状态改变事件绑定
---@class SliderListener:UIListener
_class( "SliderListener", UIListener )
SliderListener = SliderListener

function SliderListener:Constructor()
    self.kind = UIEvent.SliderChanged
    self:AddEvent()
end
--endregion

--region DropDown状态改变事件绑定
---@class DropDownListener:UIListener
_class( "DropDownListener", UIListener )
DropDownListener = DropDownListener

function DropDownListener:Constructor()
    self.kind = UIEvent.DropdownChanged
    self:AddEvent()
end
--endregion

--region ScrollRect改变事件绑定
---@class ScrollRectListener:UIListener
_class( "ScrollRectListener", UIListener )
ScrollRectListener = ScrollRectListener

function ScrollRectListener:Constructor()
    self.kind = UIEvent.ScrollRectChanged
    self:AddEvent()
end
--endregion

--region InputField改变事件绑定
---@class InputFieldListener:UIListener
_class( "InputFieldListener", UIListener )
InputFieldListener = InputFieldListener

function InputFieldListener:Constructor()
    self.kind = UIEvent.InputFieldChanged
    self:AddEvent()
end
--endregion

--region InputField结束编辑事件绑定
---@class InputFieldEndEdit:UIListener
_class( "InputFieldEndEdit", UIListener )
InputFieldEndEdit = InputFieldEndEdit

function InputFieldEndEdit:Constructor()
    self.kind = UIEvent.InputFieldEndEdit
    self:AddEvent()
end
--endregion

--region InputField结束编辑事件绑定
---@class InputFieldValidata:UIListener
_class( "InputFieldValidata", UIListener )
InputFieldValidata = InputFieldValidata

function InputFieldValidata:Constructor()
    self.kind = UIEvent.InputFieldValidate
    self:AddEvent()
end

function InputFieldValidata:AddListener()
    if self.widget then
        local widget = tostring(self.widget)
        self.address = widget
        local kind = self.kind
        if not widgets[kind] then
            widgets[kind] = {}
        end
        widgets[kind][widget] = self
        self.widget[UIEventFuncs[self.kind][2]] = function(...)
            return UIListener.CallMethond(widget, kind, ...)
        end
    end
end

function InputFieldValidata:RemoveListener()
    if self.widget then
        self.widget[UIEventFuncs[self.kind][2]] = nil
    end
end

--endregion

--endregion
