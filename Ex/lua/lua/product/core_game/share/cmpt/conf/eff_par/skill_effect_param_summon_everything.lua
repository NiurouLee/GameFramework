---@class SkillEffectEnum_SummonBehavior
local SkillEffectEnum_SummonBehavior = {
    START = 0,
    Nonrandom = 1, -- 非随机召唤
    Random = 2, -- 随机召唤
    OutOfGridRange = 3, --场外召唤机关
    RandomDifferent = 8, --随机召唤 每一个都不同
    END = 9 -- 需要手动加1
}
_enum("SkillEffectEnum_SummonBehavior", SkillEffectEnum_SummonBehavior) ----------------------------------------------------------------
---@class SkillEffectEnum_SummonExceptionType
local SkillEffectEnum_SummonExceptionType = {
    None = 0,
    Around4 = 1, ---周围四个格子
    Ring9 = 2, ---周围9圈
    Around4AndNearToFar = 3, ---周围四个格子-然后从近到远
    Around4AndNearToFarNoRandom = 4 ---周围四个格子-然后从近到远；不随机，按顺序找可召唤点
}
_enum("SkillEffectEnum_SummonExceptionType", SkillEffectEnum_SummonExceptionType)

--[[----------------------------------------------------------------
    SkillEffectParam_SummonEverything : 召唤一切效果参数
--]]
_class("SkillEffectParam_SummonEverything", SkillEffectParamBase)
---@class SkillEffectParam_SummonEverything: SkillEffectParamBase
SkillEffectParam_SummonEverything = SkillEffectParam_SummonEverything

function SkillEffectParam_SummonEverything:Constructor(t)
    self.m_nSummonType = t.summonType
    self.m_nSummonBehavior = SkillEffectEnum_SummonBehavior.Nonrandom -- 默认非随机召唤
    if
        (t.SummonBehavior ~= nil) and
            (t.SummonBehavior > SkillEffectEnum_SummonBehavior.START and
                t.SummonBehavior < SkillEffectEnum_SummonBehavior.END)
     then
        self.m_nSummonBehavior = t.SummonBehavior
    end

    self.m_nNumber = 1 -- 如果是非随机召唤是召唤怪物数量  如果是随机召唤就是随机召唤次数
    if t.Number ~= nil and type(t.Number) == "number" and t.Number > 1 then
        self.m_nNumber = t.Number
    end
    
    if t.NumberRange ~= nil and type(t.NumberRange) == "table" then
        local min = t.NumberRange[1]
        local max = t.NumberRange[2]
        self.m_nNumberRange = {} -- 次数范围
        self.m_nNumberRange.min = min
        self.m_nNumberRange.max = max
    end

    self.m_InheritAttribute = {} --Attack, Defense, MaxHP
    -- 继承母体的属性 百分比
    if t.InheritAttribute ~= nil and type(t.InheritAttribute) == "table" then
        self.m_InheritAttribute = t.InheritAttribute
    end

    self.m_listSummonID = {}
    if type(t.summonID) == "number" then
        self.m_listSummonID[#self.m_listSummonID + 1] = t.summonID
    elseif type(t.summonID) == "table" then
        self.m_listSummonID = t.summonID
    end
    self.m_recordCasterCfgID = false
    if t.RecordCasterCfgID then
        self.m_recordCasterCfgID = true
    end
    ---是否用记录的ID替换召唤ID
    self.m_useRecordIDAsSummonID = false
    if t.UseRecordIDAsSummonID then
        self.m_useRecordIDAsSummonID = true
    end
    self._force = t.force or false --true无视阻挡信息强制召唤

    --召唤monster上限
    self.m_monsterLimitCount = t.monsterLimitCount or 0
    --可以指定用来判断数量上限的id
    self.m_limitCheckID = {}
    if t.limitCheckID then
        if type(t.limitCheckID) == "number" then
            self.m_limitCheckID[#self.m_limitCheckID + 1] = t.limitCheckID
        elseif type(t.limitCheckID) == "table" then
            self.m_limitCheckID = t.limitCheckID
        end
    end

    ---怪物召唤怪物的时候，继承母体属性类型
    ---默认值为0，读取monster表里的数值
    ---值为1，读取施法者身上的基础三维数值。为了解决不灭B再召唤不灭C，用的属性不是不灭B当前属性，而是表里的值
    ---值为2：读取施法者当前面板的三维数值，包含攻击加成和防御加成
    self._useAttribute = t.useAttribute or 0

    if t.direction and t.direction[1] and t.direction[2] then
        self._direction = Vector2(t.direction[1], t.direction[2])
    else
        self._direction = Vector2(0, 1)
        ---若召唤的是monster 没配置则返回nil
        if self.m_nSummonType == SkillEffectEnum_SummonType.Monster then
            self._direction = nil
        end
    end
    ---@type boolean
    self._ignoreBlock = false
    if t.ignoreBlock then
        self._ignoreBlock = t.ignoreBlock == 1
    end
    self._exceptionType = t.exceptionType or SkillEffectEnum_SummonExceptionType.None

    --召唤物使用施法者的朝向，默认不使用
    self._summonUseCasterDir = t.summonUseCasterDir or 0

    --召唤怪继承母体元素属性，默认不继承
    self._inheritElement = t.inheritElement or false

    --施法者（怪物）初始化出生Buff，删除当前身上所有的Buff，添加配置中的BornBuff；用于搭配分身技能
    self._initCasterBornBuff = t.initCasterBornBuff or 0

    ---@type boolean
    self._summonCheckIgnoreBodyArea = false
    if t.summonCheckIgnoreBodyArea then
        self._summonCheckIgnoreBodyArea = t.summonCheckIgnoreBodyArea == 1
    end
    --召唤物(怪物)根据方向旋转bodyArea 默认不 --针对异形怪，bodyArea以（0,-1）为默认朝向
    self._modifyMonsterBodyAreaByDir = false
    if t.modifyMonsterBodyAreaByDir then
        self._modifyMonsterBodyAreaByDir = t.modifyMonsterBodyAreaByDir == 1
    end
end

function SkillEffectParam_SummonEverything:GetEffectType()
    return SkillEffectType.SummonEverything
end

---获取召唤目标类型ID
function SkillEffectParam_SummonEverything:GetSummonType()
    return self.m_nSummonType
end
---获取召唤目标类型ID
function SkillEffectParam_SummonEverything:GetSummonList()
    return self.m_listSummonID
end
---是否记录召唤者的配置ID（monsetID或trapID）
function SkillEffectParam_SummonEverything:IsRecordCasterCfgID()
    return self.m_recordCasterCfgID
end
---是否用记录的ID替换召唤ID
function SkillEffectParam_SummonEverything:IsUseRecordIDAsSummonID()
    return self.m_useRecordIDAsSummonID
end
---可以指定用来判断上限的id table
function SkillEffectParam_SummonEverything:GetLimitCheckID()
    return self.m_limitCheckID
end
-- 获取召唤目标类型ID拷贝数据
function SkillEffectParam_SummonEverything:GetCpSummonList()
    local retSummonId = {}
    for key, value in pairs(self.m_listSummonID) do
        retSummonId[key] = value
    end
end

---@return boolean
function SkillEffectParam_SummonEverything:GetForce()
    return self._force
end

---获取召唤怪物的行为 随机还是非随机
function SkillEffectParam_SummonEverything:GetSummonBehavior()
    return self.m_nSummonBehavior
end

---获取召唤怪物的数量 如果是非随机召唤是召唤怪物数量 如果是随机召唤就是随机召唤次数
function SkillEffectParam_SummonEverything:GetSummonNumber()
    return self.m_nNumber
end
---次数的范围，有这个则数量需要在范围内随机
function SkillEffectParam_SummonEverything:GetSummonNumberRange()
    return self.m_nNumberRange
end

---获取召唤怪继承母体三围数据 攻 防 血 Attack, Defense, MaxHP
function SkillEffectParam_SummonEverything:GetInheritAttribute()
    return self.m_InheritAttribute
end

---获取召唤怪物的上限
function SkillEffectParam_SummonEverything:GetSummonMonsterLimitCount()
    return self.m_monsterLimitCount
end

function SkillEffectParam_SummonEverything:GetUseAttribute()
    return self._useAttribute
end

function SkillEffectParam_SummonEverything:GetDirection()
    return self._direction
end

function SkillEffectParam_SummonEverything:IsIgnoreBlock()
    return self._ignoreBlock
end

function SkillEffectParam_SummonEverything:GetSummonExceptionType()
    return self._exceptionType
end

function SkillEffectParam_SummonEverything:GetSummonUseCasterDir()
    return self._summonUseCasterDir
end

---获取召唤怪继承母体元素属性
function SkillEffectParam_SummonEverything:GetInheritElement()
    return self._inheritElement
end

function SkillEffectParam_SummonEverything:GetInitCasterBornBuff()
    return self._initCasterBornBuff
end
function SkillEffectParam_SummonEverything:GetModifyMonsterBodyAreaByDir()
    return self._modifyMonsterBodyAreaByDir
end
function SkillEffectParam_SummonEverything:GetSummonCheckIgnoreBodyArea()
    return self._summonCheckIgnoreBodyArea
end