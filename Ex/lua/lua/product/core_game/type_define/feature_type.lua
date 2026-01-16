---@class FeatureType
FeatureType = {
    DayNight        = 1, ---昼夜
    Sanity          = 2, ---San值
    PersonaSkill    = 3, ---P5合击技
    Card            = 4, ---选牌
    MasterSkill     = 5, ---空裔技能
    Scan            = 6, ---阿克希亚
    MasterSkillRecover = 7, ---空裔技能-回复
    MasterSkillTeleport = 8, ---空裔技能-瞬移
    TrapCount = 9, ---显示指定机关数量 N29boss
    PopStar = 10, ---消灭星星的模块技能（转色）
}
_enum("FeatureType", FeatureType)

---@class FeatureDayNightState
FeatureDayNightState = {
    Day = 1, ---白天
    Night = 2, ---晚上
}
_enum("FeatureDayNightState", FeatureDayNightState)

---@class FeatureCardCompositionType--卡牌组合成的类型--为不在castActiveSkill消息中增加成员，细分每种卡牌组合
FeatureCardCompositionType = {
    NONE = 0, --
    ABC = 1, --
    AAA = 2, --
    BBB = 3, --
    CCC = 4, --
    AAB = 5, --
    AAC = 6, --
    BBA = 7, --
    BBC = 8, --
    CCA = 9, --
    CCB = 10, --
}
_enum("FeatureCardCompositionType", FeatureCardCompositionType)

---@class FeatureCardType
FeatureCardType = {
    MIN = 1,--
    A = 1, --
    B = 2, --
    C = 3, --
    MAX = 3,--
}
_enum("FeatureCardType", FeatureCardType)


--卡牌技能 释放限制 目标光灵没有指定buff，对应 SkillTriggerTypeExtraParam.CardTarPetNotHasBuff 的目标类型
---@class FeatureTarPetSelectType
FeatureTarPetSelectType = {
    TeamLeader = 1,--
    TeamTail = 2, --
}
_enum("FeatureTarPetSelectType", FeatureTarPetSelectType)

--时装修改ui表现
---@class FeatureCardUiType
FeatureCardUiType = {
    Default = 1,--
    Skin1 = 2, --
}
_enum("FeatureCardUiType", FeatureCardUiType)
--空裔技能替换ui表现
---@class FeatureMasterSkillUiType
FeatureMasterSkillUiType = {
    Default = 1,--
    TypeSeason = 2, --
}
_enum("FeatureMasterSkillUiType", FeatureMasterSkillUiType)