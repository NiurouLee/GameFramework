--[[------------------------------------------------------------------------------------------
    TrapSelfDestroyParam : 机关自销毁参数
]] --------------------------------------------------------------------------------------------


_class("TrapSelfDestroyParam", Object)
---@class TrapSelfDestroyParam: Object
TrapSelfDestroyParam = TrapSelfDestroyParam

function TrapSelfDestroyParam:Constructor(num)
    self._num = num
end

function TrapSelfDestroyParam:GetNum()
    return self._num
end

function TrapSelfDestroyParam:NextNum()
    self._num = self._num - 1
end
---续命
function TrapSelfDestroyParam:AddNum(value)
    if not value then
        value =1
    end
    self._num = self._num + value
end