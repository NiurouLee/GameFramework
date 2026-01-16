---@class SkillTargetSelectionMode
SkillTargetSelectionMode = {
    Grid = 0, -- 默认行为，按范围覆盖的格子获取目标
    Entity = 1, -- 选择单体，技能范围覆盖内只会被选中一次
}

_enum("SkillTargetSelectionMode", SkillTargetSelectionMode)