--[[------------------------------------------------------------------------------------------
    SkillPathNormalAttackData : 存储每个划线点的普通攻击数据集
]] --------------------------------------------------------------------------------------------

---@class SkillPathNormalAttackData: Object
_class("SkillPathNormalAttackData", Object)
SkillPathNormalAttackData = SkillPathNormalAttackData

function SkillPathNormalAttackData:Constructor()
    self._defaultDamageRateOnGrid = 0.1
    --key是划线点的格子坐标，类型是vector2
    --value是当前划线点的攻击数据，类型是SkillPathPointNormalAttackData
    self._pathPointAttackDic = {}
end

function SkillPathNormalAttackData:ClearNormalAttackData()
    self._pathPointAttackDic = {}
end

function SkillPathNormalAttackData:GetPathAttackData()
    return self._pathPointAttackDic
end

function SkillPathNormalAttackData:GetPathPointAttackData(pathPointPosition)
    --return self._pathPointAttackDic[pathPointPosition]
    for k, v in pairs(self._pathPointAttackDic) do
        if k == pathPointPosition then
            return v
        end
    end
end

function SkillPathNormalAttackData:Dump()
    for k, v in pairs(self._pathPointAttackDic) do
        local s = " pos=" .. tostring(k) .. "attack=[" .. v:Dump() .. "]"
        Log.fatal(s)
    end
end

function SkillPathNormalAttackData:AddPathPointNormalAttackData(pathPointPosition, pathPointNormalAttackData)
    --Log.fatal("AddPathPointNormalAttackData() pos=", tostring(pathPointPosition))

    local hasPathPointData = self:HasPathPointNormalAttackData(pathPointPosition)
    if hasPathPointData ~= true then
        self._pathPointAttackDic[pathPointPosition] = pathPointNormalAttackData
    else
        Log.fatal("Already has path point attack data")
    end
end

function SkillPathNormalAttackData:HasPathPointNormalAttackData(pathPointPosition)
    return table.iskey(self._pathPointAttackDic, pathPointPosition)
end

---传入的点是否有伤害,最后一个造成伤害的普攻静帧
function SkillPathNormalAttackData:HasPathPointNormalDamage(pathPointPosition)
    local hasAttack = self:HasPathPointNormalAttackData(pathPointPosition)
    if hasAttack == false then
        return false
    end

    ---@type SkillPathPointNormalAttackData
    local pathPointNormalAttackData = self:GetPathPointAttackData(pathPointPosition)
    if pathPointNormalAttackData ~= nil then
        local attackGridDic = pathPointNormalAttackData:GetAttackGridDic()

        for beAttackPos, attackGridData in pairs(attackGridDic) do
            ---@type AttackGridData
            local attackGridData = attackGridData
            local beAttackEntityIDList = attackGridData:GetTargetIdList()
            local castDamageList = attackGridData:GetDamageList()
            local castBloodList = attackGridData:GetBloodList()
            if beAttackEntityIDList and castDamageList and table.count(castDamageList) > 0 then
                for i = 1, #beAttackEntityIDList do
                    local id = beAttackEntityIDList[i]
                    local damage = castDamageList[id]
                    if id > 0 and damage > 0 then
                        return true
                    end
                end
            end
        end
    else
        Log.fatal("pathPoint has no attack data", pathPointPosition)
    end

    return false
end

function SkillPathNormalAttackData:RemovePathPointNormalAttackData(pathPointPosition)
    self._pathPointAttackDic[pathPointPosition] = nil
end

function SkillPathNormalAttackData:RemoveUnusedPathPointData(chain_path_data)
    for k, v in pairs(self._pathPointAttackDic) do
        local has_path_point = table.icontains(chain_path_data, k)
        if not has_path_point then
            --Log.fatal("RemoveUnusedPathPointData ",k.x," ",k.y)
            self:RemovePathPointNormalAttackData(k)
        end
    end
end
