--[[------------------------------------------------------------------------------------------
    RenderBattleStatComponent : 表现层的统计数据
]] --------------------------------------------------------------------------------------------

_class("RenderBattleStatComponent", Object)
---@class RenderBattleStatComponent: Object
RenderBattleStatComponent = RenderBattleStatComponent

function RenderBattleStatComponent:Constructor()
    --最高倍速
    self._everSpeed = 1

    --region 光灵出战顺序修改队列
    self._finishedSequenceNoDic = {}
    ---@type BattleTeamOrderViewRequest[]
    self._changeTeamOrderViewQueue = {}
    self._viewQueueSequenceNo = 0
    ---@type BattleTeamOrderViewRequest|nil
    self._currentTeamOrderRequest = nil
    self._isChangeTeamOrderViewDisabled = false
    --endregion

    self._trapIDBySummonCasterEntityID = {}
end
function RenderBattleStatComponent:Initialize()
end

function RenderBattleStatComponent:GetEverSpeed()
    return self._everSpeed
end

function RenderBattleStatComponent:SetEverSpeed(speed)
    if speed > self._everSpeed then
        self._everSpeed = speed
    end
end

--region 光灵出战顺序修改队列
---@return boolean
function RenderBattleStatComponent:IsChangeTeamOrderViewDisabled()
    return self._isChangeTeamOrderViewDisabled
end

function RenderBattleStatComponent:SetChangeTeamOrderViewDisabled(v)
    self._isChangeTeamOrderViewDisabled = v
end

function RenderBattleStatComponent:GetChangeTeamOrderViewQueue()
    return self._changeTeamOrderViewQueue
end

function RenderBattleStatComponent:ClearChangeTeamOrderViewQueue()
    self._changeTeamOrderViewQueue = {}
end

---@return BattleTeamOrderViewRequest|nil
function RenderBattleStatComponent:GetCurrentTeamOrderRequest()
    return self._currentTeamOrderRequest
end

---@param req BattleTeamOrderViewRequest
function RenderBattleStatComponent:AddChangeTeamOrderViewRequest(req)
    self._viewQueueSequenceNo = self._viewQueueSequenceNo + 1
    req:SetRequestSequenceNo(self._viewQueueSequenceNo)
    table.insert(self._changeTeamOrderViewQueue, req)
end

---@return BattleTeamOrderViewRequest|nil
function RenderBattleStatComponent:PopFirstTeamOrderRequestAsCurrent()
    self._currentTeamOrderRequest = table.remove(self._changeTeamOrderViewQueue, 1)
    return self._currentTeamOrderRequest
end

function RenderBattleStatComponent:MarkCurrentTeamOrderRequestFinished()
    if not self._currentTeamOrderRequest then
        return
    end

    local seqNo = self._currentTeamOrderRequest:GetRequestSequenceNo()
    self._finishedSequenceNoDic[seqNo] = true
    self._currentTeamOrderRequest = nil
end

function RenderBattleStatComponent:IsChangeTeamOrderRequestFinished(seqNo)
    return self._finishedSequenceNoDic[seqNo]
end
--endregion

function RenderBattleStatComponent:AddTrapIDByCasterEntityID(trapID, casterEntityID)
    if not self._trapIDBySummonCasterEntityID[casterEntityID] then
        self._trapIDBySummonCasterEntityID[casterEntityID] = {}
    end

    if not table.icontains(self._trapIDBySummonCasterEntityID[casterEntityID], trapID) then
        table.insert(self._trapIDBySummonCasterEntityID[casterEntityID], trapID)
    end
end

function RenderBattleStatComponent:IsTrapSummonedByCasterBefore(trapID, casterEntityID)
    if not self._trapIDBySummonCasterEntityID[casterEntityID] then
        return false
    end

    return table.icontains(self._trapIDBySummonCasterEntityID[casterEntityID], trapID)
end

---@return RenderBattleStatComponent
function MainWorld:RenderBattleStat()
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.RenderBattleStat)
end

function MainWorld:HasRenderBattleStat()
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.RenderBattleStat) ~= nil
end

function MainWorld:AddRenderBattleStat()
    local index = self.BW_UniqueComponentsEnum.RenderBattleStat
    local component = RenderBattleStatComponent:New(self)
    component:Initialize()
    self:SetUniqueComponent(index, component)
end

function MainWorld:RemoveRenderBattleStat()
    if self:HasRenderBattleStat() then
        self:SetUniqueComponent(self.BW_UniqueComponentsEnum.RenderBattleStat, nil)
    end
end
