require("skill_effect_param_base")

_class("SkillEffectSummonMultipleTrapParam", SkillEffectParamBase)
---@class SkillEffectSummonMultipleTrapParam : SkillEffectParamBase
SkillEffectSummonMultipleTrapParam = SkillEffectSummonMultipleTrapParam

function SkillEffectSummonMultipleTrapParam:Constructor(t)
    -- self._listTargetType = {}
    -- if type(t.targetType) == "number" then
    --     self._listTargetType[#self._listTargetType + 1] = t.targetType
    -- elseif type(t.targetType) == "table" then
    --     self._listTargetType = t.targetType
    -- end

    local metaSrc = t.src

    local colorDic = {}

    if (not metaSrc) then
        colorDic = self:_GenerateFullColorTable()
    elseif ("number" == type(metaSrc)) then
        colorDic = {
            [tonumber(metaSrc)] = true
        }
    else
        if #metaSrc == 0 then
            colorDic = self:_GenerateFullColorTable()
        else
            colorDic = {}
            for i = 1, #metaSrc do
                colorDic[tonumber(metaSrc[i])] = true
            end
        end
    end
    self._colorDic = colorDic

    self._trapID = t.trapID

    self._maxCount = t.maxCount
    self._isRandom = (t.random == 1)

    self._absPosArray = t.absPos or {}
    self._emptyPieceOnly = (t.emptyPieceOnly == 1)
    self._ignoreBlock = t.ignoreBlock or false
    self._ignoreAbyss = t.ignoreAbyss or false
    self._maxRandCount = t.maxRandCount
    self._minRandCount = t.minRandCount
    self:CheckMinMaxRoundCount()

    -- 在最大数的基础上增加额外数值，首发纳努塞尔
    self._additionalCountScopeType = t.additionalCountScopeType
    self._additionalCountScopeParam = t.additionalCountScopeParam
    self._additionalCountElementType = t.additionalCountElementType or {}
    self._additionalCountParam = t.additionalCountParam
    self._maxAdditionalCount = t.maxAdditionalCount

    self._transferDisabled = (t.transferDisabled == 1)
    self._isEmptyOrTrap = t.emptyOrTrap
    self._findPosTrapId = t.findPosTrapId
    ---策划想要世界Boss召唤机关的时候每次都一样，所以给增加一个参数控制使用的随机数
    self._useBoardRandom = t.useBoardRandom or 0

    --阻挡召唤的机关类型，且在机关表中，将对应的机关配置TypeParam：isBlockSummon=1
    --例如：琪尔的地雷阻挡掉落怪物的碎石机关，则召唤碎石的技能里需要配置上琪尔的地雷机关类型
    --琪尔的地雷机关配置中，需要配置TypeParam：isBlockSummon=1
    self._blockSummonTrapType = t.blockSummonTrapType

    --符文刺客
    self._excludeTraps = t.excludeTraps
    self._isFindRandEmptyPosIfNoValid = t.isFindRandEmptyPosIfNoValid or false

    self._sortValidPosType = t.sortValidPosType
end

function SkillEffectSummonMultipleTrapParam:_GenerateFullColorTable()
    local t = {}
    for key, value in pairs(PieceType) do
        t[value] = true
    end

    return t
end

function SkillEffectSummonMultipleTrapParam:GetEffectType()
    return SkillEffectType.SummonMultipleTrap
end

function SkillEffectSummonMultipleTrapParam:GetSelectedColorTable()
    return self._colorDic
end

function SkillEffectSummonMultipleTrapParam:GetTrapID()
    return self._trapID
end

function SkillEffectSummonMultipleTrapParam:GetMaxCount()
    return self._maxCount
end

function SkillEffectSummonMultipleTrapParam:IsRandom()
    return self._isRandom
end

function SkillEffectSummonMultipleTrapParam:GetAbsPosArray()
    return self._absPosArray
end

function SkillEffectSummonMultipleTrapParam:IsEmptyPosOnly()
    return self._emptyPieceOnly
end

---@return boolean
---是否忽略阻挡召唤机关，true表示即使该位置有阻挡机关生成的阻挡，也会召唤机关
function SkillEffectSummonMultipleTrapParam:IgnoreBlock()
    return self._ignoreBlock
end

function SkillEffectSummonMultipleTrapParam:CheckMinMaxRoundCount()
    if self._minRandCount or self._maxRandCount then
        if not self._minRandCount or not self._maxRandCount then
            Log.fatal("Config Failed ,minRoundCount:", self._minRandCount, "maxRound", self._maxRandCount)
        elseif self._minRandCount > self._maxRandCount then
            Log.fatal("Config Failed ,minRoundCount:", self._minRandCount, "maxRound", self._maxRandCount)
        end
    end
end

function SkillEffectSummonMultipleTrapParam:GetRandCount()
    return self._minRandCount, self._maxRandCount
end

function SkillEffectSummonMultipleTrapParam:GetIgnoreAbyss()
    return self._ignoreAbyss
end

function SkillEffectSummonMultipleTrapParam:GetAdditionalCountScopeType()
    return self._additionalCountScopeType
end

function SkillEffectSummonMultipleTrapParam:GetAdditionalCountScopeParam()
    return self._additionalCountScopeParam
end

function SkillEffectSummonMultipleTrapParam:GetAdditionalCountElementType()
    return self._additionalCountElementType
end

function SkillEffectSummonMultipleTrapParam:GetAdditionalCountElementDic()
    local d = {}

    for _, element in ipairs(self._additionalCountElementType) do
        d[element] = true
    end

    return d
end

function SkillEffectSummonMultipleTrapParam:GetAdditionalCountParam()
    return self._additionalCountParam
end

function SkillEffectSummonMultipleTrapParam:GetMaxAdditionalCount()
    return self._maxAdditionalCount
end

function SkillEffectSummonMultipleTrapParam:IsTransferDisabled()
    return self._transferDisabled
end

---雨森用
function SkillEffectSummonMultipleTrapParam:IsEmptyOrTrap()
    return self._isEmptyOrTrap
end

---雨森用
function SkillEffectSummonMultipleTrapParam:GetFindPosTrapId()
    return self._findPosTrapId
end

function SkillEffectSummonMultipleTrapParam:IsUseBoardRandom()
    return self._useBoardRandom == 1
end

function SkillEffectSummonMultipleTrapParam:GetBlockSummonTrapType()
    return self._blockSummonTrapType
end

--符文刺客 离场 脚下避免有其他符文刺客机关
function SkillEffectSummonMultipleTrapParam:GetExcludeTraps()
    return self._excludeTraps
end
function SkillEffectSummonMultipleTrapParam:IsFindRandEmptyPosIfNoValid()
    return self._isFindRandEmptyPosIfNoValid
end

function SkillEffectSummonMultipleTrapParam:GetSortValidPosType()
    return self._sortValidPosType
end
