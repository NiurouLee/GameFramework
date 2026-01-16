--[[------------------------------------------------------------------------------------------
    LogicChainPathComponent : 划线的逻辑组件，表现层通过Command更新
]] --------------------------------------------------------------------------------------------

_class("LogicChainPathComponent", Object)
---@class LogicChainPathComponent: Object
LogicChainPathComponent = LogicChainPathComponent
function LogicChainPathComponent:Constructor()
    self._elementType = -1
    self._chainPath = {}
    self._cutChainPath = {}
    self._pathSuperGridCount = {}
    self._pathPoorGridCount = {}
    self._pathChainRate = {}
end

function LogicChainPathComponent:ClearLogicChainPath()
    self._elementType = -1
    self._chainPath = {}
    self._cutChainPath = {}
    self._pathSuperGridCount = {}
    self._pathPoorGridCount = {}
    self._pathChainRate = {}
end

---@return Vector2[]
function LogicChainPathComponent:GetLogicChainPath()
    return self._chainPath
end

function LogicChainPathComponent:GetLogicPieceType()
    return self._elementType
end

function LogicChainPathComponent:SetLogicChainPath(chainPath, elementType)
    self._chainPath = chainPath
    self._elementType = elementType
end

function LogicChainPathComponent:SetChainRateAtIndex(index, rate)
    self._pathChainRate[index] = rate
end

function LogicChainPathComponent:GetChainRateAtIndex(index)
    return self._pathChainRate[index] or 1
end

function LogicChainPathComponent:SetCutChainPath(cutChainPath)
    self._cutChainPath = cutChainPath
end

function LogicChainPathComponent:GetCutChainPath()
    return self._cutChainPath
end

function LogicChainPathComponent:SetPathSuperGridCount(t)
    self._pathSuperGridCount = t
end

function LogicChainPathComponent:GetSuperGridCountAtPathIndex(index)
    return self._pathSuperGridCount[index]
end

function LogicChainPathComponent:SetPathPoorGridCount(t)
    self._pathPoorGridCount = t
end

function LogicChainPathComponent:GetPoorGridCountAtPathIndex(index)
    return self._pathPoorGridCount[index]
end

--是否可以移动穿过怪物
function LogicChainPathComponent:SetChainAcrossMonster(chainAcrossMonster)
    self._chainAcrossMonster = chainAcrossMonster
end
function LogicChainPathComponent:GetChainAcrossMonster()
    return self._chainAcrossMonster
end

function LogicChainPathComponent:SetChainMonsterPosList(monsterPosList)
    self._monsterPosList = monsterPosList
end
function LogicChainPathComponent:GetChainMonsterPosList()
    return self._monsterPosList
end

---@return LogicChainPathComponent
function Entity:LogicChainPath()
    return self:GetComponent(self.WEComponentsEnum.LogicChainPath)
end

function Entity:HasLogicChainPath()
    return self:HasComponent(self.WEComponentsEnum.LogicChainPath)
end

function Entity:AddLogicChainPath()
    local index = self.WEComponentsEnum.LogicChainPath
    local component = LogicChainPathComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceLogicChainPath()
    local index = self.WEComponentsEnum.LogicChainPath
    local component = LogicChainPathComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveLogicChainPath()
    if self:HasLogicChainPath() then
        self:RemoveComponent(self.WEComponentsEnum.LogicChainPath)
    end
end
