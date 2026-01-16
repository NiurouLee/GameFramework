--[[------------------------------------------------------------------------------------------
    RenderChainPathComponent : 划线的表现组件
]] --------------------------------------------------------------------------------------------

_class("RenderChainPathComponent", Object)
---@class RenderChainPathComponent: Object
RenderChainPathComponent = RenderChainPathComponent

function RenderChainPathComponent:Constructor(chainPath, elementType, cutChainPath, pathChainRate)
    self._chainPath = chainPath
    self._elementType = elementType
    self._cutChainPath = cutChainPath
    self._pathChainRate = pathChainRate

    self._monsterShadowPosList = {}
    self._cantRefresh = false
end

---@return Vector2[]
function RenderChainPathComponent:GetRenderChainPath()
    return self._chainPath
end

function RenderChainPathComponent:GetRenderPieceType()
    return self._elementType
end

function RenderChainPathComponent:GetRenderCutChainPath()
    return self._cutChainPath
end

function RenderChainPathComponent:GetRenderPathChainRateAtIndex(index)
    return self._pathChainRate[index]
end

function RenderChainPathComponent:ClearRenderChainPath()
    self._chainPath = nil
    self._elementType = nil
    self._cutChainPath = nil
    self._pathChainRate = nil

    self._monsterShadowPosList = {}
    self._cantRefresh = false
end

--是否可以移动穿过怪物
function RenderChainPathComponent:SetChainAcrossMonster(chainAcrossMonster)
    self._chainAcrossMonster = chainAcrossMonster
end
function RenderChainPathComponent:GetChainAcrossMonster()
    return self._chainAcrossMonster
end

function RenderChainPathComponent:SetChainMonsterShadowPosList(monsterShadowPosList)
    self._monsterShadowPosList = monsterShadowPosList
end
function RenderChainPathComponent:GetChainMonsterShadowPosList()
    return self._monsterShadowPosList
end

function RenderChainPathComponent:SetChainAcrossMonsterMoveEffect(moveEffect)
    self._moveEffect = moveEffect
end
function RenderChainPathComponent:GetChainAcrossMonsterMoveEffect()
    return self._moveEffect
end

function RenderChainPathComponent:SetConnectAreaRenderCantRefresh(cantRefresh)
    self._cantRefresh = cantRefresh
end
function RenderChainPathComponent:GetConnectAreaRenderCantRefresh()
    return self._cantRefresh
end

---@return RenderChainPathComponent
function Entity:RenderChainPath()
    return self:GetComponent(self.WEComponentsEnum.RenderChainPath)
end

function Entity:HasRenderChainPath()
    return self:HasComponent(self.WEComponentsEnum.RenderChainPath)
end

function Entity:AddRenderChainPath()
    local index = self.WEComponentsEnum.RenderChainPath
    local component = RenderChainPathComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceRenderChainPath(chainPath, elementType, cutChainPath, pathChainRate)
    local index = self.WEComponentsEnum.RenderChainPath
    local component = RenderChainPathComponent:New(chainPath, elementType, cutChainPath, pathChainRate)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveRenderChainPath()
    if self:HasRenderChainPath() then
        self:RemoveComponent(self.WEComponentsEnum.RenderChainPath)
    end
end
