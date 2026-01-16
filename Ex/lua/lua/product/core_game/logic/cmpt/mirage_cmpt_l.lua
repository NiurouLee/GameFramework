--[[
    MirageComponent : 幻境
]]
---@class MirageComponent: Object
_class("MirageComponent", Object)
MirageComponent = MirageComponent

---
function MirageComponent:Constructor()
    self._isOpen = false
    self._maxRound = 5
    self._curRound = 0

    ---是否强制关闭幻境
    self._forceClose = false

    self._movePos = Vector2.zero

    self._trapRefreshID = 0
    self._trapInheritAttributes = nil
    self._mirageBossEntityID = 0
end

---------------------------------------------------
---设置幻境开启状态
function MirageComponent:SetMirageOpenState(isOpen)
    self._isOpen = isOpen
end

---获取幻境是否开启
function MirageComponent:IsMirageOpen()
    return self._isOpen
end

---设置幻境强制关闭状态
function MirageComponent:SetMirageForceClose(forceClose)
    self._forceClose = forceClose
    if self._forceClose then
        self._isOpen = false
    end
end

---获取幻境强制关闭状态
function MirageComponent:IsMirageForceClose()
    return self._forceClose
end

---设置幻境子弹机关刷新ID
function MirageComponent:SetTrapRefreshID(refreshID)
    self._trapRefreshID = refreshID
end

---获取幻境子弹机关刷新ID
function MirageComponent:GetTrapRefreshID()
    return self._trapRefreshID
end

---设置幻境子弹属性继承值
function MirageComponent:SetMirageTrapInheritAttributes(attributes)
    self._trapInheritAttributes = attributes
end

---获取幻境子弹属性继承值
function MirageComponent:GetMirageTrapInheritAttributes()
    return self._trapInheritAttributes
end

---设置幻境Boss的对象ID
function MirageComponent:SetMirageBossEntityID(bossEntityID)
    self._mirageBossEntityID = bossEntityID
end

---获取幻境Boss的对象ID
function MirageComponent:GetMirageBossEntityID()
    return self._mirageBossEntityID
end

function MirageComponent:SetRoundCount(curRound)
    if curRound > self._maxRound then
        return
    end

    --回合达到最大时，终止幻境
    if curRound == self._maxRound then
        self:SetMirageOpenState(false)
    end

    self._curRound = curRound
end

function MirageComponent:GetRoundCount()
    return self._curRound
end

function MirageComponent:GetRemainRoundCount()
    return self._maxRound - self._curRound
end

function MirageComponent:IsRoundOver()
    if self._maxRound > self._curRound then
        return false
    end
    return true
end

function MirageComponent:SetMovePos(gridPos)
    self._movePos = gridPos
end

function MirageComponent:GetMovePos()
    return self._movePos
end

function MirageComponent:SetWalkResult(walkResult)
    self._walkResult = walkResult
end

function MirageComponent:GetWalkResult()
    return self._walkResult
end

--[[
    Entity Extensions
]]
---@return MirageComponent
function Entity:Mirage()
    return self:GetComponent(self.WEComponentsEnum.Mirage)
end

function Entity:HasMirage()
    return self:HasComponent(self.WEComponentsEnum.Mirage)
end

function Entity:AddMirage()
    local index = self.WEComponentsEnum.Mirage
    local component = MirageComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceMirage()
    local index = self.WEComponentsEnum.Mirage
    local component = MirageComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveMirage()
    if self:HasMirage() then
        self:RemoveComponent(self.WEComponentsEnum.Mirage)
    end
end
