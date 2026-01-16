--[[------------------------------------------------------------------------------------------
    SkillHitBackEffectParam : 技能击退效果参数
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillHitBackEffectParam", SkillEffectParamBase)
---@class SkillHitBackEffectParam: SkillEffectParamBase
SkillHitBackEffectParam = SkillHitBackEffectParam

---@class HitBackType
HitBackType = {
    PushAway = 1, --击退
    PullBack = 2 --拉回
}
_enum("HitBackType", HitBackType)

---@class HitBackCalcType
HitBackCalcType = {
    Instant = 1, --即时结算
    Delay = 2, --延迟统一结算
    PlayStage = 3 --演播阶段
}
_enum("HitBackCalcType", HitBackCalcType)

---@class HitBackDirectionBackupPlan
HitBackDirectionBackupPlan = {
    AlwaysUp = 1 --如果位置无效，固定朝y+方向击退
}
_enum("HitBackDirectionBackupPlan", HitBackDirectionBackupPlan)

---@class HitBackInteractnWithBoardType
---击退中和棋盘的互动类型
HitBackInteractnWithBoardType = {
    None = 0, --
    OutBoardEdge = 1, --击退出棋盘
    Other = 2 --反弹？转向？
}
_enum("HitBackInteractnWithBoardType", HitBackInteractnWithBoardType)

function SkillHitBackEffectParam:Constructor(t)
    self._enableByPickNum = t.enableByPickNum
    self._distance = t.distance
    self._type = t.type
    self._dirType = t.dir
    self._calcType = t.calcType or HitBackCalcType.Instant
    self._excludeCasterPos = t.excludeCasterPos
    self._ignorePlayerBlock = t.ignorePlayerBlock or false
    self._checkBuffEffect = t.checkBuffEffect --检查目标身上buff，有buff才击退
    self._forceUseCasterPos = t.forceUseCasterPos or false --是否使用施法者位置为击退中心
    self._extraParam = t.extraParam ---参数多了为了方便传到计算函数后面的如果有需要可以都加这个里面
    self._notCalcBomb = t.notCalcBomb --击退不计算触发炸弹，默认nil计算
    self._ignorePathBlock = t.ignorePathBlock or false --忽略击退路径上的阻挡（被包围时可击退至外圈）
    self._backupDirectionPlan = t.backupDirectionPlan
    self._interactType = t.interactType or HitBackInteractnWithBoardType.None --击退中和棋盘边的互动类型，默认0 无效果
    self._casterPosAsBlock = t.casterPosAsBlock or false
end

function SkillHitBackEffectParam:GetEffectType()
    return SkillEffectType.HitBack
end

function SkillHitBackEffectParam:GetDistance()
    return self._distance
end

function SkillHitBackEffectParam:GetDirType()
    return self._dirType
end

function SkillHitBackEffectParam:ExcludeCasterPos()
    return self._excludeCasterPos
end

function SkillHitBackEffectParam:GetType()
    return self._type
end

---提取击退的结算类型
---@return HitBackCalcType
function SkillHitBackEffectParam:GetCalcType()
    return self._calcType
end

function SkillHitBackEffectParam:GetIgnorePlayerBlock()
    return self._ignorePlayerBlock
end

function SkillHitBackEffectParam:GetCheckBuffEffect()
    return self._checkBuffEffect
end

function SkillHitBackEffectParam:GetExtraParam()
    return self._extraParam
end

function SkillHitBackEffectParam:GetForceUseCasterPos()
    return self._forceUseCasterPos
end

function SkillHitBackEffectParam:GetEnableByPickNum()
    return self._enableByPickNum
end

function SkillHitBackEffectParam:GetNotCalcBomb()
    return self._notCalcBomb
end

function SkillHitBackEffectParam:GetIgnorePathBlock()
    return self._ignorePathBlock
end

function SkillHitBackEffectParam:GetBackupDirectionPlan()
    return self._backupDirectionPlan
end

function SkillHitBackEffectParam:GetInteractType()
    return self._interactType
end

function SkillHitBackEffectParam:IsCasterPosAsBlock()
    return self._casterPosAsBlock
end
