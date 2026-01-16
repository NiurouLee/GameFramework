---设计目的：单个技能表现段使用的上下文，指令集类型的phase会使用，其他phase理论上也可以使用

_class("SkillPhaseContext", Object)
---@class SkillPhaseContext: Object
SkillPhaseContext = SkillPhaseContext

function SkillPhaseContext:Constructor(world, casterEntity)
    ---@type MainWorld
    self._world = world

    ---施法者
    self._casterEntity = casterEntity

    ---当前伤害的索引
    self._curDamageResultIndex = 1

    ---当前伤害阶段的索引
    self._curDamageResultStageIndex = 1

    ---当前buff的索引
    self._curBuffResultIndex = 1

    ---当前单个伤害结果的多个伤害信息
    self._curDamageInfoIndex = 1

    ---当前伤害的序列索引，用于一次技能效果对同一目标打多次伤害的情况，分批播放使用
    self._curDamageIndex = 1

    ---当前SummonEverything内的召唤结果索引
    self._curSummonInEverythingIndex = 1

    ---这个是各种效果都会使用的，当前目标的ID
    self._curTargetEntityID = nil

    ---等待队列，应该是极少会用到，目前有击退
    self._waitTaskList = {}

    ---当前拾取格子的坐标
    self._curGridPos = nil

    --效果范围格子集合
    self._scopeGridList = nil

    --格子范围
    self._scopeGridRange = nil
    --最大的范围数量
    self._maxRangeCount = nil
    self._curScopeGridRangeIndex = -1

    self._eHUDTargets = {} --PlayHUDVisible的目标HUD对象

    self._curEffectResultMap = {}

    ---当前SummonOnFixPosLimit内的召唤结果索引
    self._curSummonOnFixPosIndex = 1
end

--设置当前的伤害结果
---@param damageRes SkillDamageEffectResult
function SkillPhaseContext:SetCurDamageResultIndex(damageIndex)
    self._curDamageResultIndex = damageIndex
end

function SkillPhaseContext:GetCurDamageResultIndex()
    return self._curDamageResultIndex
end

--设置当前的伤害阶段
---@param damageRes SkillDamageEffectResult
function SkillPhaseContext:SetCurDamageResultStageIndex(damageStageIndex)
    self._curDamageResultStageIndex = damageStageIndex
end

--获取当前的伤害阶段 默认是1
function SkillPhaseContext:GetCurDamageResultStageIndex()
    return self._curDamageResultStageIndex
end

--設置當前buff索引
function SkillPhaseContext:SetCurBuffResultIndex(buffIndex)
    self._curBuffResultIndex = buffIndex
end

function SkillPhaseContext:GetCurBuffResultIndex()
    return self._curBuffResultIndex
end

function SkillPhaseContext:SetCurDamageInfoIndex(damageInfoIndex)
    self._curDamageInfoIndex = damageInfoIndex
end

function SkillPhaseContext:GetCurDamageInfoIndex()
    return self._curDamageInfoIndex
end

function SkillPhaseContext:SetCurSummonInEverythingIndex(index)
    self._curSummonInEverythingIndex = index
end

function SkillPhaseContext:GetCurSummonInEverythingIndex()
    return self._curSummonInEverythingIndex
end

function SkillPhaseContext:SetCurSummonOnFixPosIndex(index)
    self._curSummonOnFixPosIndex = index
end

function SkillPhaseContext:GetCurSummonOnFixPosIndex()
    return self._curSummonOnFixPosIndex
end

function SkillPhaseContext:GetCurTargetEntityID()
    return self._curTargetEntityID
end

function SkillPhaseContext:SetCurTargetEntityID(targetID)
    self._curTargetEntityID = targetID
end

function SkillPhaseContext:AddPhaseTask(taskID)
    self._waitTaskList[#self._waitTaskList + 1] = taskID
end

function SkillPhaseContext:GetPhaseTaskList()
    return self._waitTaskList
end

function SkillPhaseContext:GetCurGridPos()
    return self._curGridPos
end

function SkillPhaseContext:SetCurGridPos(gridPos)
    self._curGridPos = gridPos
end

function SkillPhaseContext:SetScopeGridList(gridPosArr)
    self._scopeGridList = gridPosArr
end

function SkillPhaseContext:SetScopeGridRange(gridRange, maxRangeCount)
    self._scopeGridRange = gridRange
    self._maxRangeCount = maxRangeCount
end

function SkillPhaseContext:GetScopeGridRange()
    return self._scopeGridRange
end

function SkillPhaseContext:GetMaxRangeCount()
    return self._maxRangeCount
end

function SkillPhaseContext:SetCurScopeGridRangeIndex(index)
    self._curScopeGridRangeIndex = index
end

function SkillPhaseContext:GetCurScopeGridRangeIndex()
    return self._curScopeGridRangeIndex
end

---@return Entity[]
function SkillPhaseContext:GetHUDTargets()
    return self._eHUDTargets
end

function SkillPhaseContext:SetHUDTargets(huds)
    self._eHUDTargets = huds
end

function SkillPhaseContext:SetCurResultIndexByType(effectType, index)
    self._curEffectResultMap[effectType] = index
end

function SkillPhaseContext:GetCurResultIndexByType(effectType)
    return self._curEffectResultMap[effectType] or -1
end

function SkillPhaseContext:SetSpecialScopeResultList(specialScopeResultList)
    self._specialScopeResultList = specialScopeResultList
end

function SkillPhaseContext:GetSpecialScopeResultList()
    return self._specialScopeResultList
end

function SkillPhaseContext:SetCurDamageIndex(damageIndex)
    self._curDamageIndex = damageIndex
end

function SkillPhaseContext:GetCurDamageIndex()
    return self._curDamageIndex
end