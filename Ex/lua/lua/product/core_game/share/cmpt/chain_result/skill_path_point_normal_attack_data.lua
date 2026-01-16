--[[------------------------------------------------------------------------------------------
    SkillPathPointNormalAttackData : 单个宝宝的单个划线点的普通攻击数据
]] --------------------------------------------------------------------------------------------

_class("SkillPathPointNormalAttackData", Object)
---@class SkillPathPointNormalAttackData: Object
SkillPathPointNormalAttackData = SkillPathPointNormalAttackData

function SkillPathPointNormalAttackData:Constructor()
    --key是被攻击的格子坐标，类型是vector2
    --value是被攻击格子目标上的entity id，以及伤害值
    self._attackGridDic = {}
end

function SkillPathPointNormalAttackData:GetAttackGridDic()
    return self._attackGridDic
end

---获得光灵在该位置的普攻数据
function SkillPathPointNormalAttackData:GetPetOrderGridArray(petEntity, pathPosition)
    local orderGridArray = {}
    ---@type BuffComponent
    local buffComponent = petEntity:BuffComponent()
    local normalAttackCrossTwoCount = buffComponent:GetBuffValue("NormalAttackCrossTwoCount")
    if normalAttackCrossTwoCount and normalAttackCrossTwoCount > 0 then
        --普攻范围是十字两格（SP雷霆）
        orderGridArray = self:GetOrderGridArrayCrossTwo(pathPosition)
    else
        --常规普攻，把该位置周围的8个格子做顺序
        orderGridArray = self:GetOrderGridArray(pathPosition)
    end

    return orderGridArray
end

---某个点将一个列表里的格子按照顺时针进行排序
---@param attackGridDic table 序列格子
---@param pathPointPos vector2 参照点
---@return Array
function SkillPathPointNormalAttackData:GetOrderGridArray(pathPointPos)
    local orderArray = {}
    self:_CheckAttackPoint(pathPointPos, 0, 1, orderArray)
    self:_CheckAttackPoint(pathPointPos, 1, 0, orderArray)
    self:_CheckAttackPoint(pathPointPos, 0, -1, orderArray)
    self:_CheckAttackPoint(pathPointPos, -1, 0, orderArray)
    --
    self:_CheckAttackPoint(pathPointPos, 1, 1, orderArray)
    self:_CheckAttackPoint(pathPointPos, 1, -1, orderArray)
    self:_CheckAttackPoint(pathPointPos, -1, -1, orderArray)
    self:_CheckAttackPoint(pathPointPos, -1, 1, orderArray)
    return orderArray
end

function SkillPathPointNormalAttackData:_CheckAttackPoint(pathPointPos, disx, disy, orderArray)
    local attackPos = Vector2(0, 0)
    attackPos.x = pathPointPos.x + disx
    attackPos.y = pathPointPos.y + disy
    local isKey = table.iskey(self._attackGridDic, attackPos)
    if isKey == true then
        orderArray[#orderArray + 1] = attackPos
    end
end

--region 十字两格的普攻
--一个orderArray在计算的时候对应一个普攻数据，这里如果第一个格子有数据了就不再寻找第二个，第一个没有则找第二个。
function SkillPathPointNormalAttackData:GetOrderGridArrayCrossTwo(pathPointPos)
    local orderArray = {}

    local hasAddAttack = true
    hasAddAttack = self:_CheckAttackPointHaveAttackData(pathPointPos, 0, 1, orderArray)
    if hasAddAttack == false then
        self:_CheckAttackPoint(pathPointPos, 0, 2, orderArray)
    end

    hasAddAttack = self:_CheckAttackPointHaveAttackData(pathPointPos, 1, 0, orderArray)
    if hasAddAttack == false then
        self:_CheckAttackPoint(pathPointPos, 2, 0, orderArray)
    end

    hasAddAttack = self:_CheckAttackPointHaveAttackData(pathPointPos, 0, -1, orderArray)
    if hasAddAttack == false then
        self:_CheckAttackPoint(pathPointPos, 0, -2, orderArray)
    end

    hasAddAttack = self:_CheckAttackPointHaveAttackData(pathPointPos, -1, 0, orderArray)
    if hasAddAttack == false then
        self:_CheckAttackPoint(pathPointPos, -2, 0, orderArray)
    end

    return orderArray
end

function SkillPathPointNormalAttackData:_CheckAttackPointHaveAttackData(pathPointPos, disx, disy, orderArray)
    local orderArrayCount1 = #orderArray
    self:_CheckAttackPoint(pathPointPos, disx, disy, orderArray)
    local orderArrayCount2 = #orderArray
    return orderArrayCount2 > orderArrayCount1
end

--endregion 十字两格的普攻

function SkillPathPointNormalAttackData:GetPathPointAttackCount()
    return table.count(self._attackGridDic)
end

function SkillPathPointNormalAttackData:AddAttackGridData(
    beAttackPosition,
    targetEntityID,
    skillId,
    petEntityID,
    casterPos)
    --Log.fatal("AddAttackGridData() beAttackPosition=", beAttackPosition)
    local hasAttackGridData = self:HasAttackInfo(beAttackPosition, targetEntityID)
    if hasAttackGridData ~= true then
        -- self._world:GetSyncLogger():Trace(
        --     {
        --         key = "NormalAttackAddAttackGrid",
        --         entityID = petEntityID,
        --         targetID = targetEntityID,
        --         beAttackPos = tostring(beAttackPosition),
        --         attackPos = tostring(casterPos)
        --     }
        -- )
        local attackGridData = AttackGridData:New(targetEntityID, nil, beAttackPosition, skillId)
        self._attackGridDic[beAttackPosition] = attackGridData
    else
        Log.fatal("Already has attack grid data")
    end
end

function SkillPathPointNormalAttackData:HasAttackGridData(beAttackPosition)
    return table.iskey(self._attackGridDic, beAttackPosition)
end

---判断是否已经存了被攻击信息
---如果目标ID已经存在，就说明不需要再加入了
function SkillPathPointNormalAttackData:HasAttackInfo(beAttackPosition, targetEntityID)
    local hasPos = self:HasAttackGridData(beAttackPosition)
    local hasTarget = false
    for k, v in pairs(self._attackGridDic) do
        ---@type AttackGridData
        local attackGridData = v
        local curIDList = attackGridData:GetTargetIdList()
        if curIDList then
            for i = 1, #curIDList do
                if curIDList[i] == targetEntityID then
                    hasTarget = true
                end
            end
        end
    end

    if hasPos == true or hasTarget == true then
        return true
    end

    return false
end

---只用被攻击的点检查是否可以添加普攻数据
function SkillPathPointNormalAttackData:AddAttackGridDataOnlyCheckPos(
    beAttackPosition,
    targetEntityID,
    skillId,
    petEntityID,
    casterPos)
    local hasAttackGridData = self:HasAttackInfoOnlyCheckPos(beAttackPosition, targetEntityID)
    if hasAttackGridData ~= true then
        local attackGridData = AttackGridData:New(targetEntityID, nil, beAttackPosition, skillId)
        self._attackGridDic[beAttackPosition] = attackGridData
    else
        Log.fatal("Already has attack grid data")
    end
end
---
function SkillPathPointNormalAttackData:HasAttackInfoOnlyCheckPos(beAttackPosition, targetEntityID)
    local hasPos = self:HasAttackGridData(beAttackPosition)
    if hasPos == true then
        return true
    end

    return false
end

function SkillPathPointNormalAttackData:Dump()
    local s = ""
    for k, v in pairs(self._attackGridDic) do
        s = s .. "pos=" .. tostring(k)
    end
    return s
end
