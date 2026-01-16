---@class AffixType
local AffixType={
    None = 0,
    ChangePetAttr = 1,                      ---修改宝宝属性
    ChangePetChainCount = 2,                ---修改宝宝连锁机触发条件
    CloseAuroraTime = 3,                    ---无法进入极光时刻
    TeamLeadOnlyInElementAttack = 4,        ---队长只有在自己属性的格子才攻击
    ChangeMonsterAttr = 5,                  ---修改特定MonsterID怪物属性
    ReplaceMonsterAI = 6,                   ---替换怪物AI
    ReplaceMonsterSkill = 7,                ---替换怪物技能
    ReplaceLevelComplete = 8,               ---替换关卡完成条件
    ChangeTrapAttr = 9,                     ---修改特定TrapID机关属性
    PlayerBeHitLimit = 10,                  ---单场对局玩家被打次数限制
    AddAffixBuff = 11,                      ---使用Buff
    ChangeWaveBeginMonsterID = 12,          ---修改 波次开始 怪物ID
    ChangeWaveInternalMonsterID = 13,       ---修改 波次中刷怪 怪物ID
    ChangeWaveBeginTrapID =14,              ---修改 波次开始 机关ID
    ChangeWaveInternalTrapID =15,           ---修改 波次中刷怪 机关ID
    AddWaveBeginMonsterIDAndPos =16,        ---波次开始 增加怪物ID和位置
    AddWaveInternalMonsterIDAndPos =17,     ---波次中刷怪 增加机关ID和位置
    AddWaveBeginTrapIDAndPos =18,           ---波次开始 增加机关ID和位置
    AddWaveInternalTrapIDAndPos =19,        ---波次中刷怪 增加机关ID和位置
    ChangeAllMonsterAttr = 20,              ---修改全部怪物的攻防血参数
    ChangeLevelRound = 21,                  ---修改关卡回合数
    ChangeWaveInternalParam = 22,           ---修改波次刷新时的参数，修改配置参数的形式
    AddWaveInternalParam = 23,              ---增加一个波次刷新,直接增加配置
    ReplaceMonsterBuff = 24,                ---替换怪物身上的Buff,只替换monster表里的buff,不替换monster_class表里面的
    ReplaceMonsterEliteBuff= 25,            ---替换怪物身上的精英词缀
    AddMonsterBuff = 26,                    ---增加怪物身上的Buff
    AddMonsterEliteBuff= 27,                ---增加怪物身上的精英词缀
    ReplaceTrapSkill = 28,					---替换机关技能
    ReplaceTrapBuff = 29,                   ---替换机关身上的Buff
    AddTrapBuff = 30,                       ---增加机关身上的Buff
    ReplaceMonsterSpSkill = 31,             ---修改怪物身上特殊技能，出生技，死亡技，掉落技等
    ChangePieceRefreshType = 32,            ---修改棋盘刷新方式
    ReplaceFeatureModule = 33,              ---替换关卡模块
    NoAuroraTimeLimit = 34,                 ---不限制单回合极光时刻次数
    ReplacePieceGenWeight = 35,             ---修改格子生成权重（开局和刷新）
    IncreasePetNoDefenceDamage = 36,        ---提高光灵造成的无视防御伤害（真伤类型、攻击者NoDefence为1、被击者基础防御力为0）
    ChangePetAddBuffMaxRound = 37,          ---光灵加某效果buff时持续时间+N
    AddChainPathNum = 38,                   ---连线时格子数增加（例：第一个格子视为chain数为3），影响连锁触发、显示chain数、伤害率、极光条件
}
_enum("AffixType",AffixType)

---@class ChangePetAttrType
local ChangePetAttrType={
    AllPetCurHPPercent = 1, ---修改所有星灵当前血量
    AllPetMaxHPPercent = 2, ---修改所有星灵最大血量
    AllPetDefence =3,       ---修改所有星灵防御
}
_enum("ChangePetAttrType",ChangePetAttrType)
---@class AffixAttrType
local AffixAttrType = {
    HP =1 ,
    Attack= 2,
    Defence = 3,
}
_enum("AffixAttrType",AffixAttrType)

---@class ChangeMonsterAttrType
local ChangeMonsterAttrType={
    ReplaceHP = 1,     ---替换怪物血量
    ReplaceAttack = 2, ---替换怪物攻击力
    ReplaceDefence =3, ---替换怪物防御
}
_enum("ChangeMonsterAttrType",ChangeMonsterAttrType)

---@class ChangeTrapAttrType
local ChangeTrapAttrType={
    ReplaceHP = 1,     ---替换机关血量
    ReplaceAttack = 2, ---替换机关攻击力
    ReplaceDefence =3, ---替换机关防御
}
_enum("ChangeTrapAttrType",ChangeTrapAttrType)

---@class ReplaceMonsterSpSkillType
local ReplaceMonsterSpSkillType={
    Appear = 1,  ---出生技
    Die = 2,     ---死亡技
    Drop =3,     ---掉落技
}
_enum("ReplaceMonsterSpSkillType",ReplaceMonsterSpSkillType)

---@class PieceRefreshType
local PieceRefreshType={
    Inplace = 1, --原地刷新
    FallingDown = 2, --掉落刷新
    Destroy = 3, --销毁，不刷新连线路径
}

_enum("PieceRefreshType",PieceRefreshType)

--词缀可配置隐藏显示 对应cfg_word_buff 的 HideUIType列
---@class AffixHideUIType
local AffixHideUIType={
    None = 0, --
    HideInGame = 1, --局内隐藏显示改词缀
}
_enum("AffixHideUIType",AffixHideUIType)