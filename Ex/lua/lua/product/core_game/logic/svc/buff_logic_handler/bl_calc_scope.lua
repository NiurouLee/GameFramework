require("battle_const")
require('buff_logic_base')

local buffValueKeyFormat = BattleConst.BuffCalcScopeKeyFormat

---@param instance BuffInstance
local function getBuffValueKey(instance)
    return string.format(buffValueKeyFormat, instance:BuffID())
end

local function getBuffValueKeyByBuffID(buffID)
    return string.format(buffValueKeyFormat, buffID)
end

_class("BuffLogicCalcScope", BuffLogicBase)
---@class BuffLogicCalcScope:BuffLogicBase
BuffLogicCalcScope = BuffLogicCalcScope

function BuffLogicCalcScope:Constructor(buffInstance, logicParam)
    self._skillID = logicParam.skillID
end

function BuffLogicCalcScope:DoLogic()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    local entity = self:GetEntity()

    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(self._skillID)

    local scopeResult = scopeCalc:CalcSkillScope(
        skillConfigData,
        entity:GetGridPosition(),
        entity:GetGridDirection(),
        entity:BodyArea():GetArea(),
        entity
    )

    self:GetBuffComponent():SetBuffValue(getBuffValueKey(self._buffInstance), scopeResult)

    return BuffResultCalcScope:New(scopeResult)
end

function BuffLogicCalcScope:DoOverlap()
    return self:DoLogic()
end

_class("BuffLogicClearCalcScope", BuffLogicBase)
---@class BuffLogicClearCalcScope:BuffLogicBase
BuffLogicClearCalcScope = BuffLogicClearCalcScope

function BuffLogicClearCalcScope:DoLogic()
    self:GetBuffComponent():SetBuffValue(getBuffValueKey(self._buffInstance), nil)

    return true
end

function BuffLogicClearCalcScope:DoOverlap()
    return self:DoLogic()
end

--region 展示计算范围，表现向buff
_class("BuffLogicShowCalcScope", BuffLogicBase)
---@class BuffLogicShowCalcScope:BuffLogicBase
BuffLogicShowCalcScope = BuffLogicShowCalcScope

function BuffLogicShowCalcScope:Constructor(buffInstance, logicParam)
    self._showBuffID = logicParam.showBuffID
end

function BuffLogicShowCalcScope:DoLogic()
    --预览显示没有逻辑，这里只是把数据传给表现
    local scopeResult = self:GetBuffComponent():GetBuffValue(getBuffValueKeyByBuffID(self._showBuffID))
    if not scopeResult then
        return
    end

    return BuffResultCalcScope:New(scopeResult)
end

function BuffLogicShowCalcScope:DoOverlap()
    return self:DoLogic()
end

_class("BuffLogicHideCalcScope", BuffLogicBase)
---@class BuffLogicHideCalcScope:BuffLogicBase
BuffLogicHideCalcScope = BuffLogicHideCalcScope

function BuffLogicHideCalcScope:DoLogic()
    --预览隐藏没有逻辑，直接由表现处理
    --目前只支持清除该单位创造的全部预警，更细化的控制方式有需要的时候再填坑
    return true
end

function BuffLogicHideCalcScope:DoOverlap()
    return self:DoLogic()
end
--endregion