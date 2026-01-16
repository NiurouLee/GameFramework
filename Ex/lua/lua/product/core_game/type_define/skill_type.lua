---@class SkillType
---@field Normal number
---@field Chain number
---@field Active number
---@field MonsterSkill number
---@field TrapSkill number
SkillType = SkillType

_enum(
    "SkillType",
    {
        SKillTypeStart = 1,
        Normal = 1, --普通攻击（星灵和怪）
        Chain = 2, --连锁技（星灵）
        Active = 3, --主动技（星灵）
        Passive = 4, --被动技（星灵）
        MonsterSkill = 5, --怪物技能（怪）
        TrapSkill = 6, --机关技能（机关）
        BuffSkill = 7, --buff触发的技能（buff）
        FeatureSkill = 8, --模块技能(P5模块合击技、空裔技能。。）
        SKillTypeEnd = 8 --end
    }
)
