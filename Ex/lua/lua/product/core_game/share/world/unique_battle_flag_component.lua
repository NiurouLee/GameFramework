--用于控制对局特殊规则开关
--比如禁用主动技、AI双倍

---@class BattleFlagsComponent: Object
_class("BattleFlagsComponent", Object)
BattleFlagsComponent = BattleFlagsComponent

function BattleFlagsComponent:Constructor(world)
    self.flags = {}

    self._frontAndObliqueOffsetDataList = {} --国际象棋兵，偏移方向
    self._chessTransformationIndex = 0 --国际象棋兵，变身顺序

    self._curseTowerIndex = 1 ---诅咒塔的索引
    self._curseRound = 1 ---诅咒塔索引对应的回合

    self._summonMeantimeLimitEntityID = {} --限制同时存在数量的召唤，当新的召唤成功后，如果同时存在的数量超过了限制，销毁最先召唤的。

    --配置的固定点召唤机关缓存相关
    self._summonOnFixPosLimitEntityIDList = {} --召唤机关ID列表
    self._summonOnFixPosLimitIndex = 0 --召唤次数，由于获取是先加一，再返回，所以此处初始值需要为-1
    
    ---N30Boss_斐桀洛 使用技能变更场景的次数
    self._sceneChangeTimes = 0
end

function BattleFlagsComponent:HasFlag(flag)
    return self.flags[flag]
end

function BattleFlagsComponent:AddFlag(flag)
    self.flags[flag] = true
end

function BattleFlagsComponent:RemoveFlag(flag)
    self.flags[flag] = false
end

function BattleFlagsComponent:GetFrontAndObliqueOffsetData(entityID)
    return self._frontAndObliqueOffsetDataList[entityID]
end

---@param dir Vector2
function BattleFlagsComponent:SetFrontAndObliqueOffsetData(entityID, dir)
    self._frontAndObliqueOffsetDataList[entityID] = dir
end

function BattleFlagsComponent:GetChessTransformationIndex()
    self._chessTransformationIndex = self._chessTransformationIndex + 1
    return self._chessTransformationIndex
end

function BattleFlagsComponent:GetCurrentCurseTowerIndex()
    return self._curseTowerIndex
end

function BattleFlagsComponent:SetCurrentCurseTowerIndex(index)
    self._curseTowerIndex = index
end

function BattleFlagsComponent:GetCurrentCurseTowerRound()
    return self._curseRound
end

function BattleFlagsComponent:SetCurrentCurseTowerRound(round)
    self._curseRound = round
end

function BattleFlagsComponent:GetSummonMeantimeLimitEntityID(trapID)
    return self._summonMeantimeLimitEntityID[trapID] or {}
end

function BattleFlagsComponent:SetSummonMeantimeLimitEntityID(trapID, entityIDList)
    -- if not self._summonMeantimeLimitEntityID[trapID] then
    --     self._summonMeantimeLimitEntityID[trapID] = {}
    -- end
    -- table.insert(self._summonMeantimeLimitEntityID, entityID)
    self._summonMeantimeLimitEntityID[trapID] = entityIDList
end

function BattleFlagsComponent:GetSummonOnFixPosLimitIndex()
    --self._summonOnFixPosLimitIndex = self._summonOnFixPosLimitIndex + 1
    return self._summonOnFixPosLimitIndex
end
function BattleFlagsComponent:SetSummonOnFixPosLimitIndex(index)
    self._summonOnFixPosLimitIndex = index
end

function BattleFlagsComponent:GetSummonOnFixPosLimitEntityID(trapID)
    return self._summonOnFixPosLimitEntityIDList[trapID] or {}
end

function BattleFlagsComponent:SetSummonOnFixPosLimitEntityID(trapID, entityIDList)
    self._summonOnFixPosLimitEntityIDList[trapID] = entityIDList
end

function BattleFlagsComponent:GetSceneChangeTimes()
    return self._sceneChangeTimes
end

function BattleFlagsComponent:AddSceneChangeTimes(num)
    self._sceneChangeTimes = self._sceneChangeTimes + num
end

--[[------------------------------------------------------------------------------------------
    MainWorld Extensions
]]
---@return BattleFlagsComponent
function MainWorld:BattleFlags()
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.BattleFlags)
end

function MainWorld:AddBattleFlags()
    local index = self.BW_UniqueComponentsEnum.BattleFlags
    local com = BattleFlagsComponent:New(self)
    self:SetUniqueComponent(index, com)
end

function MainWorld:HasBattleFlag(flag)
    local com = self:BattleFlags()
    if not com then
        return false
    end
    return com:HasFlag(flag)
end

function MainWorld:AddBattleFlag(flag)
    local index = self.BW_UniqueComponentsEnum.BattleFlags
    local com = self:BattleFlags()
    if not com then
        com = BattleFlagsComponent:New(self)
    end
    com:AddFlag(flag)
    self:SetUniqueComponent(index, com)
end

function MainWorld:RemoveBattleFlag(flag)
    local index = self.BW_UniqueComponentsEnum.BattleFlags
    local com = self:BattleFlags()
    if not com then
        return
    end
    com:RemoveFlag(flag)
    self:SetUniqueComponent(index, com)
end
