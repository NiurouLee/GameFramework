--[[------------------------------------------------------------------------------------------
    ActiveSkillCalculator :主动技能计算器
    由于需要存放的逻辑数据不同，技能分成两大类
    一种是通过划线触发的技能，包括普通攻击和连锁技
    一种是可立即施放的技能，星灵主动技、怪物技能、机关技能等都属于这一类。
    主动技流程：
    对每个施法目标（可能是怪、人、机关、格子等技能目标选择器选出来的Entity）调用技能效果计算服务计算
    每一个技能效果，得到一组技能结果，并将技能结果转存到施法者的SkillRoutineComponent组件里，
    随后技能表现将使用该数据进行演播
]] --------------------------------------------------------------------------------------------

---@class ActiveSkillCalculator: Object
_class("ActiveSkillCalculator", Object)
ActiveSkillCalculator = ActiveSkillCalculator

---@param world MainWorld
function ActiveSkillCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")

    ---@type ForEachEffectCalculator
    self._foreachEffectCalculator = ForEachEffectCalculator:New(world)
end

---对所有目标计算技能效果
---@param casterEntity Entity 施法者
---@param scopeResult SkillScopeResult 范围
---@param skillID number 技能ID
---@param targetIDArray Array 目标的ID列表
function ActiveSkillCalculator:DoCalculateSkill(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local attackRange = skillEffectResultContainer:GetScopeResult():GetAttackRange()
    local logger = self._world:GetMatchLogger()
    local casterEntityID = casterEntity:GetID()
    logger:BeginSkill(casterEntityID, casterEntity:GridLocation():GetGridPos(), skillID, attackRange)
    self._foreachEffectCalculator:DoSkillEffectCalculate(casterEntity)
    logger:EndSkill(casterEntityID)
end
