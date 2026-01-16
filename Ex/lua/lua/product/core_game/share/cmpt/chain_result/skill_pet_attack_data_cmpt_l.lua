--[[------------------------------------------------------------------------------------------
    SkillPetAttackDataComponent : 星灵的普攻和连锁技施法时的运行时数据
    说明：
    星灵的普攻以及连锁技数据是以连线为基础，计算出来的连线格子序列攻击数据
    每个星灵都可能会出战，因此也都需要有自己的连线攻击数据队列，因此进局后的每个星灵Entity身上会挂上本组件

    为了方便数据组织，此组件关联了一些辅助对象：
    SkillPathNormalAttackData 对象，存储连线队里里，每个连线点的普通攻击数据
    SkillChainAttackData 对象，存储连线队列在最后一点时的连锁技攻击数据

    普攻和连锁技都是基于连线发起的，与主动技的施法驱动方式不同，两者分开，维护上较为容易
    另外，只有星灵Entity挂这个组件，其他Entity，包括怪，机关等都不需要这个组件
]] --------------------------------------------------------------------------------------------

_class("SkillPetAttackDataComponent", Object)
---@class SkillPetAttackDataComponent: Object
SkillPetAttackDataComponent = SkillPetAttackDataComponent

function SkillPetAttackDataComponent:Constructor()
    self._chainSkillID = -1
    self._normalAttackData = SkillPathNormalAttackData:New()
    ---@type SkillChainAttackData[]
    self._chainSkillAttackData = {}
    self._chainSkillShadowData = {} --虚影连锁技
    self._chainSkillAgentData = {} --代理连锁技
    self._curCastDamage = 0 --当前打出来的伤害
    self._curChainDamageRate = 0
    self._curSuperGridNum = 0 --当前强化格子数
    self._curPoorGridNum = 0 --当前弱化格子数
    self._curChainSkillIndex = 0
    self._curChainSkillStage = 0--是该光灵技能配置中第几阶段的连锁技（根据连线数）
    --是否执行连锁技
    self._castChainSkill = false
end

function SkillPetAttackDataComponent:ClearPetAttackData()
    self._curCastDamage = 0
    self._chainSkillID = -1
    self._curChainSkillIndex=0
    self._curChainSkillStage = 0
    self._normalAttackData:ClearNormalAttackData()
    self:ClearPetChainAttackData()
end

function SkillPetAttackDataComponent:GetChainAttackDataList()
    return self._chainSkillAttackData
end

function SkillPetAttackDataComponent:GetShadowChainAttackDataList()
    return self._chainSkillShadowData
end

function SkillPetAttackDataComponent:GetAgentChainAttackDataList()
    return self._chainSkillAgentData
end

function SkillPetAttackDataComponent:ClearPetChainAttackData()
    self._chainSkillAttackData = {}
    self._chainSkillShadowData = {} --虚影连锁技
    self._chainSkillAgentData = {} --代理连锁技
end

function SkillPetAttackDataComponent:GetNormalAttackData()
    return self._normalAttackData
end
---@return SkillChainAttackData
function SkillPetAttackDataComponent:GetChainAttackData(idx)
    if idx == nil then
        return self._chainSkillAttackData
    end
    return self._chainSkillAttackData[idx]
end

function SkillPetAttackDataComponent:GetChainShadowData(idx)
    if idx == nil then
        return self._chainSkillShadowData
    end
    return self._chainSkillShadowData[idx]
end

function SkillPetAttackDataComponent:GetChainAgentData(idx)
    if idx == nil then
        return self._chainSkillAgentData
    end
    return self._chainSkillAgentData[idx]
end

function SkillPetAttackDataComponent:GetChainSkillID()
    return self._chainSkillID
end

function SkillPetAttackDataComponent:SetChainSkillID(chainSkillID)
    self._chainSkillID = chainSkillID
end

function SkillPetAttackDataComponent:SetCurChainSkillIndex(idx)
    self._curChainSkillIndex=idx
end

function SkillPetAttackDataComponent:GetCurChainSkillIndex()
    return self._curChainSkillIndex
end

function SkillPetAttackDataComponent:SetCurChainSkillStage(chainSkillStage)
    self._curChainSkillStage=chainSkillStage
end

function SkillPetAttackDataComponent:GetCurChainSkillStage()
    return self._curChainSkillStage
end

function SkillPetAttackDataComponent:AddNormalAttackData(pathPointPosition, pathPointNormalAttackData)
    self._normalAttackData:AddPathPointNormalAttackData(pathPointPosition, pathPointNormalAttackData)
end

function SkillPetAttackDataComponent:AddChainAttackData(idx)
    if self._chainSkillAttackData[idx] == nil then
        self._chainSkillAttackData[idx] = SkillChainAttackData:New(idx)
    end
end

function SkillPetAttackDataComponent:AddChainShadowData(idx)
    if self._chainSkillShadowData[idx] == nil then
        self._chainSkillShadowData[idx] = SkillChainAttackData:New(idx)
    end
end

function SkillPetAttackDataComponent:AddChainAgentData(idx)
    if self._chainSkillAgentData[idx] == nil then
        self._chainSkillAgentData[idx] = SkillChainAttackData:New(idx)
    end
end

function SkillPetAttackDataComponent:HasNormalAttackData(pathPointPosition)
    return self._normalAttackData:HasPathPointNormalAttackData(pathPointPosition)
end

function SkillPetAttackDataComponent:RemoveNormalAttackData(pathPointPosition)
    self._normalAttackData:RemovePathPointNormalAttackData(pathPointPosition)
end

function SkillPetAttackDataComponent:RemoveUnusedPathPointData(chain_path_data)
    --检查可能出现的回退，清理掉没有的数据
    self._normalAttackData:RemoveUnusedPathPointData(chain_path_data)
end

function SkillPetAttackDataComponent:HasChainAttackDamage()
    for i, v in ipairs(self._chainSkillAttackData) do
        ---@type SkillChainAttackData
        local chainAttackData = v
        if chainAttackData:GetEffectResultByArray(SkillEffectType.Damage) then
            return true
        end
    end
    return false
end

function SkillPetAttackDataComponent:HasChainScopeData()
    for i, v in ipairs(self._chainSkillAttackData) do
        if v:GetScopeResult():GetAttackRange() then
            return true
        end
    end
    return false
end

function SkillPetAttackDataComponent:GetCastChainSkill()
    return self._castChainSkill
end

function SkillPetAttackDataComponent:SetCastChainSkill(cast)
    self._castChainSkill = cast
end

function SkillPetAttackDataComponent:SetCurrentChainDamageRate(value)
    self._curChainDamageRate = value
end

function SkillPetAttackDataComponent:GetCurrentChainDamageRate()
    return self._curChainDamageRate
end

function SkillPetAttackDataComponent:SetCurrentSuperGridNum(value)
    self._curSuperGridNum = value
end

function SkillPetAttackDataComponent:GetCurrentSuperGridNum()
    return self._curSuperGridNum
end

function SkillPetAttackDataComponent:SetCurrentPoorGridNum(value)
    self._curPoorGridNum = value
end

function SkillPetAttackDataComponent:GetCurrentPoorGridNum()
    return self._curPoorGridNum
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return SkillPetAttackDataComponent
function Entity:SkillPetAttackData()
    if EDITOR and CHECK_RENDER_ACCESS_LOGIC then
        local debugInfo = debug.getinfo(2, "S")
        local filePath = debugInfo.short_src
        local renderIndex = string.find(filePath, "_r.lua")
        if renderIndex ~= nil then
            Log.exception("render file :", filePath, " call SkillPetAttackData() ", Log.traceback())
            return nil
        end
    end
    return self:GetComponent(self.WEComponentsEnum.SkillPetAttackData)
end

function Entity:HasSkillPetAttackData()
    return self:HasComponent(self.WEComponentsEnum.SkillPetAttackData)
end

function Entity:AddSkillPetAttackData()
    local index = self.WEComponentsEnum.SkillPetAttackData
    local component = SkillPetAttackDataComponent:New()
    self:AddComponent(index, component)
end

function Entity:RemoveSkillPetAttackData()
    if self:HasSkillPetAttackData() then
        self:RemoveComponent(self.WEComponentsEnum.SkillPetAttackData)
    end
end
