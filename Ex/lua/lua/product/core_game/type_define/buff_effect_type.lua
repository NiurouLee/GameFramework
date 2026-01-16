--[[
    一个buff效果是激活条件、触发条件、卸载条件、表现ID、触发逻辑等配置项的确定类型的组合
    换句话说，一个buff效果的配置项类型都是一样的，参数可以不同
]]
---@class BuffEffectType
BuffEffectType = {
    None = 0,
    --region 控制类 1000-1999
    Stun = 1001, --眩晕
    Fear = 1002, --恐惧
    Sleep = 1003, --睡眠
    Accelerate = 1004, --加速/减速
    Palsy = 1005, --瘫痪
    --endregion

    --DOT类 2000-2999
    Burn = 2001, --灼烧 每回合伤害
    Poison = 2002, ---中毒 每回合伤害
    Bleed = 2003, --流血 每回合伤害
    PoisonByAttack = 20021, ---中毒 根据附加buff的实体攻击力，每回合伤害

    --光环类 3000-3999
    LayerShield = 3001, --层数护盾
    HealthShield = 3002, ---血条护盾
    ShieldToHP = 3003, --血条护盾转血量
    LockHPAlways = 3004, --持久锁血
    LockHPByRound = 3005, ---回合锁血每回合只能打掉一个阶段的血量
    Benumb = 3006, --麻痹
    ControlImmunized = 3007, --霸体，免疫任何控制
    AttackMiss = 3008, --失明，普攻miss
    Invincible = 3009, --无敌，只受某种伤害
    MoveDamage = 3010, --重伤，每走一个格子收到伤害
    DamageReduce = 3011, --减伤，最终伤害值
    AttackImmuned = 3012, --物免，普攻免疫
    SkillImmuned = 3013, --魔免，技能免疫
    DoubleChain = 3014, -- 二次连锁
    HitDropByCount = 3015, ---被击掉落,指定次数内每次只要被打就掉落
    HitDropByHP = 3016, ---被击掉落，第一次达到指定血量掉落
    ImmumneBuff = 3017, --免疫指定效果的buff的buff
    ImmumneTranslate = 3018, --免疫位移
    ElementImmuned = 3021, --免疫指定属性的攻击
    HarmReduction = 3022, --减伤
    BreakInvincible = 3028, --破除无敌
    DragonMark = 3029, --龙之印记
    ShieldToHPByLayer = 3030,
    --减益类 4000-4999
    --增益类 5000-5999
    CastSkillAddBuff = 4001, ---释放技能給怪上buff
    CastSkillHitBuff = 4002, ---释放技能攻擊怪
    MonsterTrunStartAddHp = 4005, ---每个怪物回合加血10%
    PlayerTrunStartAddHp = 4006, ---玩家回合开始固定掉血10%
    AddHpMax = 4007, --加生命上限
    ReduceHpMax = 4008, --减生命上限
    AddAttack = 4009, ---增加攻击力
    AddDefence = 4010, ---增加防御力
    AddPositiveBuff = 4011, ---给自己加增益类buff
    AddNegativeBuff = 4012, ---给自己加减益类buff
    AddMonsterNegativeBuff = 4013, ---给怪物加debuff
    AddHpByRefreshWaterGrid = 4020, ---特定格子刷新时恢复血量
    AddAttackByFullHP = 4021, ---满血量的时候增加特定属性的角色输出
    AddSkillIncreaseByAnyAttack = 4022, ---薇丝被动技能，每次造成伤害叠加一层Buff,下次造成伤害时提高层数百分比的最终伤害，回合结束清空
    AddNormalSkillIncreaseProb = 4024, --增加普攻伤害  高爆火药 普通攻击有5%几率造成150%伤害
    AddSkillIncreaseByTargetBuff = 4025, --对异常状态的敌人伤害增加20%   神裁之手
    AddSkillIncreaseByPetBuff = 4026, --增加伤害  叛乱回声  当己方队伍处在异常状态中时增加20%的伤害
    AddSkillIncreaseByHit = 4027, --增加伤害  复仇刻印  每次受到伤害时都会获得一个+3%伤害增益效果，该效果可叠加（持续一回合）
    AddSkillIncreaseByHp = 4028, --满血时增加50%伤害 太阳荣光
    AddSkillIncreaseByHpPercent = 4029, --攻击时增加玩家当前已损失生命值百分比的伤害    诸神黄昏
    ChangePetPower = 4030, --改变星灵主动技能CD
    ChangeMonsterPower = 4031, --改变怪物 行动力
    ChangeHPByDeath = 4032, --改在死亡瞬间使你复活并补满血量。每次完整的秘境探险仅会生效一次。  旧都之心
    ChangeHPByHpPercent = 4033, --秒杀生命值低于15%的敌人 裂解水晶
    AddShieldByHpSpilled = 4034, --溢出最大生命值的治疗量会按比例转化为一层持续一回合的护盾  超载光盾
    RemoveTargetShieldByNormalSkill = 4035, --普通攻击将直接消除敌人的护盾  消磁手套
    RefreshGrid = 4036, --开场时身边8格范围内会随机刷出一个万色格    万华镜
    DropItem = 4037, --战斗开始时，在战场中刷新一个可拾取的补充电源  空投信标/战地医疗
    AddSuperChainSkillDamage = 4039, --超级连锁伤害加成
    AddElementRestrained = 4040, --属性克制效果提升
    AddTargetAttackMiss = 4041, --普通攻击会给敌人附加失明效果，使其攻击时有30%概率无法命中 炫光目镜
    AddPoisonAround = 4043, --当敌人回合开始时，中毒状态的敌人会给身边8格的敌人附加中毒效果    爆裂毒源
    AddPoisonDamage = 4044, --敌人受到的中毒伤害增加5% 瓦解腐液
    ChangeAttackSkill = 4046, --更改普通攻击技能
    HitBackEndDamage = 4047, --击退后造成攻击力百分比伤害
    ChangeSkillIncreaseByDistance = 4048, --根绝距离更改伤害系数加成
    AddBuff = 4049, --添加buff效果
    ReflexiveDamage = 4050, --反伤
    AddChainDamage = 4060, --園丁被動，主動技能有效時，連鎖技傷害加深
    GuideLockPlayerHPPercent = 4075, ---新手引导锁定玩家最少血量
    GuideLockRoundCount = 4076,
    AddBeHitElementRestrained = 4077, -- 增加自身受伤时的克制属性系数
    IncreaseActiveSkillAtk = 4079,
    NotShowBossHP = 4093, --不显示BOSS大血条
    CurShowBossHP = 4096, --自己显示BOSS大血条
    NotPlayMaterialAnimation = 4103, ---不播放材质动画（预览半透/被击）
    NotBeSelectedAsSkillTarget = 4104, ---不会被选为技能目标
    NotShowPreviewSkill = 4106, ---不显示技能预览
    LegendPetEnergy = 4107, --传说光灵能量
    NotBeSelectedAsSingleSkillTarget = 4108, ---不会被单体技能选中
    NotBeSelectedAsNormalSkillTarget = 4109, ---不会被普工技能选中
    TransmitDamage = 4110, ---传递伤害
    Silence = 4150, ---沉默（光灵） 无法释放主动技
    ForceMoveImmunized = 4151, --免疫 强制位移（及牵引的强制效果）
    --region 特殊UI显示相关 6000-6100
    ShowEquipRefineUI = 6000, --点击光灵头像，显示装备精炼相关UI
    --endregion
    SetInternalFlag = 10001, -- 添加一个指定flag的计数 flagKey和单次触发的计数由配置决定
    ---新手引导时锁定回合数
    ShadowChainSKill = 95012, --全息投影
    ShadowChainSKillPro = 950121, --全息投影升级版 小恶犬被动技
    CoffinMusume = 29038011, ---棺材娘专属减伤
    CoffinMusumeAtkDef = 29038012, ---棺材娘专属减伤
}
_enum("BuffEffectType", BuffEffectType)

--以下内容由策划编辑

_G.UnitTurnDelayStartEffectType = {
    1001, --眩晕
    10013, --眩晕
    10014, --眩晕
    1002, --恐惧
    1004, --减速
    3008, --致盲
}

--[[
示例1：少的话可以写一行，比如
_G.UnitTurnDelayStartEffectType = { 1024, 2048 }
]]

--[[
示例2：多的话可以换行
_G.UnitTurnDelayStartEffectType = {
    1024,
    2048
}
]]

--[[
示例3：换行可以加备注，记得前面用--分隔，逗号必须在--之前，否则会崩
_G.UnitTurnDelayStartEffectType = {
    1024, --随便写的数，假装它是眩晕
    2048, --另一个随便写的数，假装它是另一个想延后的效果
}
]]
