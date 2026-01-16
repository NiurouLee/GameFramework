--[[------------------------------------------------------------------------------------------
    PopStarLogicComponent : 消灭星星逻辑组件，记录消除区域数据、已消除数量、挑战关卡当前阶段
]]
--------------------------------------------------------------------------------------------

_class("PopStarLogicComponent", Object)
---@class PopStarLogicComponent: Object
PopStarLogicComponent = PopStarLogicComponent
function PopStarLogicComponent:Constructor()
    ---消除的连通区域
    self._popConnectPieces = {}

    ---已消除数量
    self._popGridNum = 0

    ---挑战关卡当前阶段
    self._challengeIndex = 1

    ---机关随机刷新数据
    self._totalWeight = 0
    self._trapRandomTab = {}
    self._trapCountDic = {}

    ---道具刷新数据字典，key为累计消除格子数，value为道具ID
    self._propIDDic = {}
end

---@return Vector2[]
function PopStarLogicComponent:GetPopConnectPieces()
    return self._popConnectPieces
end

function PopStarLogicComponent:SetPopConnectPieces(connectPieces)
    self._popConnectPieces = connectPieces
end

function PopStarLogicComponent:GetPopGridNum()
    return self._popGridNum
end

function PopStarLogicComponent:AddPopGridNum(num)
    self._popGridNum = self._popGridNum + num
end

function PopStarLogicComponent:GetChallengeIndex()
    return self._challengeIndex
end

function PopStarLogicComponent:SetChallengeIndex(index)
    self._challengeIndex = index
end

function PopStarLogicComponent:GetTrapRandomData()
    return self._totalWeight, self._trapRandomTab
end

function PopStarLogicComponent:SetTrapRandomData(totalWeight, trapRandomTab)
    self._totalWeight = totalWeight
    self._trapRandomTab = trapRandomTab
end

function PopStarLogicComponent:GetTrapRandomCount(trapID)
    if not self._trapCountDic[trapID] then
        return 0
    end
    return self._trapCountDic[trapID]
end

function PopStarLogicComponent:AddTrapRandomCount(trapID)
    if not self._trapCountDic[trapID] then
        self._trapCountDic[trapID] = 0
    end
    self._trapCountDic[trapID] = self._trapCountDic[trapID] + 1
end

function PopStarLogicComponent:AddPropID(num, propID)
    if self._propIDDic[num] then
        ---每达到累计数量的消除格子数时，只能生成一种道具，唯一
        ---不存在一个格子上出现多个道具的情况
        return
    end
    self._propIDDic[num] = propID
end

function PopStarLogicComponent:GetPropIDByPopNum(num)
    return self._propIDDic[num]
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
--------------------------------------------------------------------------------------------
---@return PopStarLogicComponent
function Entity:PopStarLogic()
    return self:GetComponent(self.WEComponentsEnum.PopStarLogic)
end

function Entity:HasPopStarLogic()
    return self:HasComponent(self.WEComponentsEnum.PopStarLogic)
end

function Entity:AddPopStarLogic()
    local index = self.WEComponentsEnum.PopStarLogic
    local component = PopStarLogicComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePopStarLogic()
    local index = self.WEComponentsEnum.PopStarLogic
    local component = PopStarLogicComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemovePopStarLogic()
    if self:HasPopStarLogic() then
        self:RemoveComponent(self.WEComponentsEnum.PopStarLogic)
    end
end
