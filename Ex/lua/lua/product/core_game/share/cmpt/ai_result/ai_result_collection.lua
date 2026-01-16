--[[------------------------------------------------------------------------------------------
    AIResultCollection : 
]]--------------------------------------------------------------------------------------------


_class( "AIResultCollection", Object )
---@class AIResultCollection: Object
AIResultCollection = AIResultCollection

function AIResultCollection:Constructor()
    ---元素类型都是 AISkillResult
    ---普攻结果列表
    self._normalAttackResultList = {}
    ---施法结果列表
    self._spellResultList = {}
        ---移动的数据，元素类型是 MonsterWalkResult
    self._walkResultList = {}

end

function AIResultCollection:ClearCollection()
    self._normalAttackResultList = {}
    self._spellResultList = {}
    self._walkResultList = {}
end

function AIResultCollection:HasNormalAttackResult()
    local resCount = #self._normalAttackResultList
    if resCount > 0 then 
        return true
    end

    return false
end

function AIResultCollection:GetNormalAttackResultList()
    return self._normalAttackResultList
end

function AIResultCollection:HasSpellResult()
    local resCount = #self._spellResultList
    if resCount > 0 then 
        return true
    end

    return false
end

function AIResultCollection:GetSpellResultList()
    return self._spellResultList
end

function AIResultCollection:AddSpellResult(res)
    self._spellResultList[#self._spellResultList +1] = res
end

function AIResultCollection:AddNormalAttackResult(res)
    self._normalAttackResultList[#self._normalAttackResultList +1] = res
end

---@return MonsterWalkResult[]
function AIResultCollection:GetWalkResultList()
    return self._walkResultList
end

function AIResultCollection:AddWalkResult(walkResult)
    self._walkResultList[#self._walkResultList + 1] = walkResult
end