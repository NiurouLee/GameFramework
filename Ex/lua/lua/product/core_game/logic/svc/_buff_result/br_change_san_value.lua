_class("BuffResultChangeSanValue", BuffResultBase)
---@class BuffResultChangeSanValue : BuffResultBase
BuffResultChangeSanValue = BuffResultChangeSanValue

function BuffResultChangeSanValue:Constructor(curSan, oldSan, realModifyValue,debtVal,modifyTimes)
    self._curSan = curSan
    self._oldSan = oldSan
    self._realModifyValue = realModifyValue
    self._debtVal = debtVal
    self._modifyTimes = modifyTimes
end

function BuffResultChangeSanValue:GetCurSan() return self._curSan end
function BuffResultChangeSanValue:GetOldSan() return self._oldSan end
function BuffResultChangeSanValue:GetRealModifyValue() return self._realModifyValue end
function BuffResultChangeSanValue:GetDebtVal() return self._debtVal end
function BuffResultChangeSanValue:GetModifyTimes() return self._modifyTimes end
