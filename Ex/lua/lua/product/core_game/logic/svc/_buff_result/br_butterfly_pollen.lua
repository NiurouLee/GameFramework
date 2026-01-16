_class("BuffResultButterflyPollen", BuffResultBase)
---@class BuffResultButterflyPollen:BuffResultBase
---@field New fun():BuffResultButterflyPollen
BuffResultButterflyPollen = BuffResultButterflyPollen

---@param damageInfo DamageInfo
function BuffResultButterflyPollen:SetRecoveryDamageInfo(damageInfo)
    self._recoveryDamageInfo = damageInfo
end

---@param damageInfo DamageInfo
function BuffResultButterflyPollen:SetPoisonDamageInfo(damageInfo)
    self._poisonDamageInfo = damageInfo
end

---@return DamageInfo|nil
function BuffResultButterflyPollen:GetRecoveryDamageInfo()
    return self._recoveryDamageInfo
end

---@return DamageInfo|nil
function BuffResultButterflyPollen:GetPoisonDamageInfo()
    return self._poisonDamageInfo
end

---这个接口是为了配合PlayBuffService:PlayDamageBuff(...)的工作方式存在的
function BuffResultButterflyPollen:GetDamageInfo()
    return self._poisonDamageInfo
end