---数据埋点类型
DataPointType = {
    TeamId = 1, --队伍编号
    LoopId = 2, --内循环编号
    -------------基准信息------------
    MatchType = 10, --关卡类型
    LevelId = 11, --关卡id
    PlayerId = 12, --玩家ID
    PlayerLevel = 13, --玩家等级
    BattleStartTime = 14, --战斗开始时间【格式为 2020-3-5 16:00:00】
    BattleEndTime = 15, --战斗结束时间【格式为 2020-3-5 16:00:00】
    AlwaysAutoFight = 16, --是否全程自动战斗
    -----------阵容--------------
    PetId = 103, --使用阵容
    PetAttack = 104, --阵容攻击力
    PetDefense = 105, --防御力
    PetHP = 106, --生命值
    PetAwake = 109, --觉醒
    PetLevel = 110, --等级
    PetGrade = 111, --突破
    PetEquip = 112, --装备
    PetAffinity = 113, --好感度
    ---------------胜率--------------
    MatchResult = 201, -- 对局结果【win、lose、giveup、noend】
    OneStarPass = 202, --1星条件是否达成
    TwoStarPass = 203, -- 2星条件是否达成
    ThreeStarPass = 204, --3星条件是否达成
    IsFirstPassLevel = 205, --是否首次通关
    ---------------时长---------------
    BattleRoundCount = 300, -- 设置战斗回合累计数量
    BattleTotalTime = 302, --战斗累计时长
    AvgRoundTime = 303, --平均单回合用时
    VarRoundTime = 307, --每回合时长的方差
    AvgLinkTime = 308, --平均决策时长
    AvgShowTime = 310, --平均战斗表现时长
    ---------------连通率---------------
    InitConnectRate = 400, --进入战斗时的连通率
    ConnectRateAvg = 401, -- 回合开始时的平均连通率
    ConnectRateStd = 402, -- 回合开始时连通率的标准差
    ---------------Chain长度---------------
    ChainMax = 500, --chain最大值
    LowChainRate = 501, --低连接率[chain小于等于3的次数/有效回合数]
    ChainAvg = 502, --chain平均值
    ChainStd = 503, --chain的标准差
    AuroraTimeCount = 504, --机关时刻次数
    AuroraChainAvg = 505, --极光时刻下chain平均值
    ---------------combo数---------------
    ComboAvg = 601, -- combo平均值
    ComboMax = 602, -- combo最大值
    ComboSum = 603, -- combo总和
    AuroraComboAvg = 604, --极光时刻下combo平均值
    ---------------普通攻击----------------
    PetNormalDamage = 701, --每个角色普攻累计造成的伤害量
    PetNormalDamageRate = 702, --角色的普攻伤害占比
    AvgRoundNormalDamage = 703, --每回合平均普攻输出
    StdRoundNormalDamage = 705, --每回合普攻伤害标准差
    SumNormalDamage = 706, --普攻实际伤害值累计
    ----------------连锁技----------------------
    ChainSkillFrequency = 802, --连锁技的施放频率[连锁技的累计触发次数/有效回合数]
    ChainSkillStrength = 803, --连锁技强度[每次连锁技的阶段数之和/连锁技累计触发次数]
    ChainComboRealFrequency = 804, --连锁技实际频数
    PetChainSkillCount = 805, --角色连锁技频数
    PetChainSkillDamage = 806, --角色连锁技造成的伤害量
    PetChainSkillDamageRate = 807, --角色的连锁技伤害占比
    AvgRoundChainDamage = 808, --每回合平均连锁技输出
    StdRoundChainDamage = 809, --每回合连锁技伤害标准差
    SumChainDamage = 810, --连锁技实际伤害累计
    ----------------------主动技----------------------
    TeamActiveSkillDamage = 901, --每个角色主动技累计造成的伤害量
    TeamActiveSkillCount = 902, --角色主动技施放次数
    ActiveSkillDamageSum = 903, --主动技实际伤害值累计
    ----------------------敌方行动----------------------
    MaxPetBehitDamage = 1001, --单次最大伤害量
    MaxRoundPetBehitDamage = 1002, --单回合最大伤害量
    AvgRoundPetBehitVal = 1003, --平均单回合伤害量
    AvgRoundPetBehitCount = 1004, --玩家平均每回合受到攻击的次数
    ----------------------伤害汇总----------------------
    DamageTypeRate = 1101, --不同类型的输出占比
    PetDamageRate = 1102, --角色输出占比
    AvgRoundPetDamage = 1103, --所有伤害类型在一个回合内（包括极光时刻的）造成的伤害之和/有效回合数
    ---------------------治疗统计------------------------
    AddBloodTotal = 1200, --累计治疗血量 占玩家生命上限的百分比
    ChainSkillAddBlood = 1201, --连锁技主动技之类比例【二者占总回血量的占比，被动回血不计入】
    AddBloodSpilled = 1203, --加血溢出【超过血量上限部分的治疗总量，占玩家生命上限的百分比】
    ---------------------秘境统计------------------------
    MazePetBlood = 1300, --战斗结束后，秘境宝宝血量
    MazePetPower = 1301, --战斗结束后主动技CD
    MazeLight = 1302, --剩余灯盏
    MazeLayer = 1303, --秘境层数
    MazeRoomIndex = 1304, --秘境房间
    MazeVersion = 1305 --秘境版本
}
