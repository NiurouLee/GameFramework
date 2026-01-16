--[[------------------------------------------------------------------------------------------
    L2R_NormalAttackResult : 逻辑层发给播放层的普攻结果
]] --------------------------------------------------------------------------------------------

---@class L2R_NormalAttackResult: Object
_class("L2R_NormalAttackResult", Object)

function L2R_NormalAttackResult:Constructor()
    --表现用 存放普攻的爆点播放顺序
    self._playNormalSkillSequence = {}

    --连线的每个点触发的机关，key是路点的索引，value是每个格子上触发的机关列表
    self._chainPathTriggerTrapDic = {}

    ---普攻的结果字典，key是entityID值，value的类型是SkillPathNormalAttackData
    self._normalAttackResultList = {}

    --连线出战星灵
    self._petRoundTeam = {}

    ---普攻阶段是否需要最后一击
    self._isFinalAtk = false
end

function L2R_NormalAttackResult:ClearNormalAttackResult()
    table.clear(self._playNormalSkillSequence)
    table.clear(self._chainPathTriggerTrapDic)
    table.clear(self._normalAttackResultList)
    self._petRoundTeam = {}
    self._isFinalAtk = false
end

function L2R_NormalAttackResult:SetPlayNormalAttackFinalAttack(finalAtk)
    self._isFinalAtk = finalAtk
end

function L2R_NormalAttackResult:SetCurPlayNormalSkillPlayStartTime(order, currentTimeMs)
    local cur = self._playNormalSkillSequence[order]
    cur.playStartTime = currentTimeMs
end

---设置连线普攻爆点数据
function L2R_NormalAttackResult:SetPlayNormalSkillSequence(playNormalSkillSequence)
    self._playNormalSkillSequence = playNormalSkillSequence
end

function L2R_NormalAttackResult:GetNormalSkillSequenceWithAttackGridData(skillID, beAttackPos, attackPos)
    for i = 1, #self._playNormalSkillSequence do
        local playNormalSkill = self._playNormalSkillSequence[i]
        if
            playNormalSkill.skillID == skillID and playNormalSkill.beAttackPos.x == beAttackPos.x and
                playNormalSkill.beAttackPos.y == beAttackPos.y and
                playNormalSkill.attackPos.x == attackPos.x and
                playNormalSkill.attackPos.y == attackPos.y
         then
            return playNormalSkill
        end
    end
    return nil
end

function L2R_NormalAttackResult:GetNormalSkillSequenceWithOrder(order)
    for i = 1, #self._playNormalSkillSequence do
        local playNormalSkill = self._playNormalSkillSequence[i]
        if playNormalSkill.order == order then
            return playNormalSkill
        end
    end
    return nil
end

function L2R_NormalAttackResult:GetPlayNormalSkillSequence()
    return self._playNormalSkillSequence
end

function L2R_NormalAttackResult:SetChainPathTriggerTrap(trapsDic)
    self._chainPathTriggerTrapDic = trapsDic
end
---连线格子上触发的机关
function L2R_NormalAttackResult:GetChainPathTriggerTrap(pathIndex)
    return self._chainPathTriggerTrapDic[pathIndex]
end

function L2R_NormalAttackResult:SetNormalSkillWaitTimeDic(dic)
    self._normalSkillWaitTimeDic = dic
end
---星灵在格子上攻击前需要等待的时间
function L2R_NormalAttackResult:GetNormalSkillWaitTimeDic(petIndex, chainIndex)
    return self._normalSkillWaitTimeDic[petIndex][chainIndex]
end

function L2R_NormalAttackResult:SetPathMoveStartWaitTime(pathMoveStartWaitTime)
    self._pathMoveStartWaitTime = pathMoveStartWaitTime
end
---普攻连线开始等待的时间
function L2R_NormalAttackResult:GetPathMoveStartWaitTime()
    return self._pathMoveStartWaitTime
end

function L2R_NormalAttackResult:GetPetNormalAttackResult(petEntityID)
    return self._normalAttackResultList[petEntityID]
end


function L2R_NormalAttackResult:SetPetNormalAttackResultList(dataList)
    self._normalAttackResultList = dataList
end


function L2R_NormalAttackResult:GetPlayNormalAttackFinalAttack()
    return self._isFinalAtk
end
