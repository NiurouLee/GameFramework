--[[------------------------------------------------------------------------------------------
    PlayNormalAttackResultComponent : 逻辑层发给播放层的普攻结果
]] --------------------------------------------------------------------------------------------

---@class PlayNormalAttackResultComponent: Object
_class("PlayNormalAttackResultComponent", Object)

function PlayNormalAttackResultComponent:Constructor()
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

function PlayNormalAttackResultComponent:ClearNormalAttackResult()
    table.clear(self._playNormalSkillSequence)
    table.clear(self._chainPathTriggerTrapDic)
    table.clear(self._normalAttackResultList)
    self._petRoundTeam = {}
    self._isFinalAtk = false
end

function PlayNormalAttackResultComponent:SetPlayNormalAttackFinalAttack(finalAtk)
    self._isFinalAtk = finalAtk
end

function PlayNormalAttackResultComponent:SetCurPlayNormalSkillPlayStartTime(order, currentTimeMs)
    local cur = self._playNormalSkillSequence[order]
    cur.playStartTime = currentTimeMs
end

---设置连线普攻爆点数据
function PlayNormalAttackResultComponent:SetPlayNormalSkillSequence(playNormalSkillSequence)
    self._playNormalSkillSequence = playNormalSkillSequence
end

function PlayNormalAttackResultComponent:GetNormalSkillSequenceWithAttackGridData(skillID, beAttackPos, attackPos)
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

function PlayNormalAttackResultComponent:GetNormalSkillSequenceWithOrder(order)
    for i = 1, #self._playNormalSkillSequence do
        local playNormalSkill = self._playNormalSkillSequence[i]
        if playNormalSkill.order == order then
            return playNormalSkill
        end
    end
    return nil
end

function PlayNormalAttackResultComponent:GetPlayNormalSkillSequence()
    return self._playNormalSkillSequence
end

function PlayNormalAttackResultComponent:SetChainPathTriggerTrap(trapsDic)
    self._chainPathTriggerTrapDic = trapsDic
end
---连线格子上触发的机关
function PlayNormalAttackResultComponent:GetChainPathTriggerTrap(pathIndex)
    return self._chainPathTriggerTrapDic[pathIndex]
end

function PlayNormalAttackResultComponent:SetNormalSkillWaitTimeDic(dic)
    self._normalSkillWaitTimeDic = dic
end
---星灵在格子上攻击前需要等待的时间
function PlayNormalAttackResultComponent:GetNormalSkillWaitTimeDic(petIndex, chainIndex)
    return self._normalSkillWaitTimeDic[petIndex][chainIndex]
end

function PlayNormalAttackResultComponent:SetPathMoveStartWaitTime(pathMoveStartWaitTime)
    self._pathMoveStartWaitTime = pathMoveStartWaitTime
end
---普攻连线开始等待的时间
function PlayNormalAttackResultComponent:GetPathMoveStartWaitTime()
    return self._pathMoveStartWaitTime
end

function PlayNormalAttackResultComponent:GetPetNormalAttackResult(petEntityID)
    return self._normalAttackResultList[petEntityID]
end

function PlayNormalAttackResultComponent:SetPetNormalAttackResultList(dataList)
    self._normalAttackResultList = dataList
end

function PlayNormalAttackResultComponent:GetPetRoundTeam()
    return self._petRoundTeam
end

function PlayNormalAttackResultComponent:SetPetRoundTeam(petRoundTeam)
    self._petRoundTeam = petRoundTeam
end

function PlayNormalAttackResultComponent:GetPlayNormalAttackFinalAttack()
    return self._isFinalAtk
end
-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function PlayNormalAttackResultComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function PlayNormalAttackResultComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end ---@return PlayNormalAttackResultComponent
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] function Entity:PlayNormalAttackResult()
    return self:GetComponent(self.WEComponentsEnum.PlayNormalAttackResult)
end

function Entity:HasPlayNormalAttackResult()
    return self:HasComponent(self.WEComponentsEnum.PlayNormalAttackResult)
end

function Entity:AddPlayNormalAttackResult()
    local index = self.WEComponentsEnum.PlayNormalAttackResult
    local component = PlayNormalAttackResultComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePlayNormalAttackResult()
    local index = self.WEComponentsEnum.PlayNormalAttackResult
    local component = PlayNormalAttackResultComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemovePlayNormalAttackResult()
    if self:HasPlayNormalAttackResult() then
        self:RemoveComponent(self.WEComponentsEnum.PlayNormalAttackResult)
    end
end
