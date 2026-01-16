_class("BuffResultCalcScope", BuffResultBase)
---@class BuffResultCalcScope:BuffResultBase
---@field New fun(scopeResult:SkillScopeResult):BuffResultCalcScope
BuffResultCalcScope = BuffResultCalcScope

function BuffResultCalcScope:Constructor(scopeResult)
    self.scopeResult = scopeResult
end

---@return SkillScopeResult
function BuffResultCalcScope:GetScopeResult()
    return self.scopeResult
end
