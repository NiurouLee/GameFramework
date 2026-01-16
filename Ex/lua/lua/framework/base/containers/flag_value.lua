--标记容器
---@class FlagValue:Object
_class("FlagValue", Object)
FlagValue = FlagValue

--简单的标记类，封装lua number 最多64位
function FlagValue:Constructor(n)
    self._flags = n or 0
end

---@param flag 取值范围0到63
function FlagValue:SetFlag(flag)
    if flag < 0 or flag > 63 then
        error("flag value set flag 0-63 overflow")
        return
    end

    self._flags = self._flags | (1 << flag)
end

---@param flag 取值范围0到63
function FlagValue:ResetFlag(flag)
    if flag < 0 or flag > 63 then
        error("flag value set flag 0-63 overflow")
        return
    end

    self._flags = self._flags & (~(1 << flag))
end

---@param flag 取值范围0到63
function FlagValue:CheckFlag(flag)
    if flag < 0 or flag > 63 then
        Log.error("flag value set flag 0-63 overflow")
        return false
    end

    return (self._flags & (1 << flag)) > 0
end

function FlagValue:Clear()
    self._flags = 0
end

function FlagValue:Get()
    return self._flags
end
