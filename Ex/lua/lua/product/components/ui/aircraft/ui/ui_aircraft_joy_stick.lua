--[[
    风船摇杆
]]
---@class UIAircraftJoyStick:Object
_class("UIAircraftJoyStick", Object)
UIAircraftJoyStick = UIAircraftJoyStick

function UIAircraftJoyStick:Constructor(eventListener, image, normalSprite, dragSprite, content, resetBtn)
    self._content = content
    self._dragTip = content:GetChild(0)
    self._dragTipGo = self._dragTip.gameObject
    self._resetBtn = resetBtn
    local resetEvent = resetBtn:GetComponent(typeof(UIEventTriggerListener))
    resetEvent.onClick = function()
        resetBtn:SetActive(false)
        if self.onReset then
            self.onReset()
        end
    end

    eventListener.onBeginDrag = function()
        image.sprite = dragSprite
        self._dragTipGo:SetActive(true)
        self:OnBeginDrag()
        if self.onBegin then
            self.onBegin()
        end
    end
    eventListener.onEndDrag = function()
        image.sprite = normalSprite
        self._dragTipGo:SetActive(false)
        self:OnEndDrag()
        if self.onEnd then
            --end回调返回结束时是否需要显示归正按钮
            local showReset = self.onEnd()
            if showReset then
                resetBtn:SetActive(true)
            end
        else
            resetBtn:SetActive(true)
        end
    end
    self._dragging = false

    --外部可访问的回调
    self.onBegin = nil
    self.onEnd = nil
    self.onDrag = nil
    self.onReset = nil
end

function UIAircraftJoyStick:SetActive(active)
end

function UIAircraftJoyStick:OnBeginDrag()
    self._dragging = true
end
function UIAircraftJoyStick:OnEndDrag()
    self._dragging = false
end

function UIAircraftJoyStick:Dispose()
    self.onBegin = nil
    self.onEnd = nil
    self.onDrag = nil
end

function UIAircraftJoyStick:GetDrag()
    return self._dragging, self._content.localPosition:Clone()
end

function UIAircraftJoyStick:Update()
    if self._dragging then
        local pos = self._content.localPosition:Clone()
        -- self._dragTip.rotation = Quaternion.FromToRotation(Vector3.up, pos)
        self._dragTip.up = pos
        if self.onDrag then
            self.onDrag(pos)
        end
    end
end
