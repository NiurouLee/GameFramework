--点选格子的策略
PickPosPolicy = {
    MaxTargetCount = 0,
    MovePathEndPos = 1, --艾米：路径终点
    PetFei = 2, --绯：在非森格子中，选择伤害敌人格子数最多的点
    PetJiaBaiLie = 3, --加百列：在水火雷中选择格子数最多的洗版
    PetKaLian = 4, --卡莲：选择伤害敌人格子数最多的点，瞬移到最边上的点
    PetSaiKa = 5, --塞卡：血量从高到低排序
    NearestPos = 6, --最近的点
    HeroPos = 7, --原地释放
    PetXiNuoPu = 8, --希诺普：第一个点找最近的非绿色格，第二个点找点选范围中非绿色格 （可点选范围随点击数量变化）
    PetBonai = 9, --柏乃（赫柏，鬼）：SelectTeamPos设置为队长
    PetYuSen = 10, --雨森：首先选择怪物周围一圈内的机关所在位置；若无，则取距离自己最近的怪物一圈距离自己最近的位置；若均无，则终止释放
    PetSaiKaReverse = 11, --塞卡 改：血量从低到高排序
    PetLuoYi = 12, --罗伊 范围内最近的非黄色格子 能量消耗与点选位置有没有指定机关有关
    PetQingTong = 13, --清瞳：怪物周围一圈距离自己最近的非蓝色格子或点击机关所在位置
    PetLen = 14, --莲：注释太长，这里写不下，参考 //depot_matchsrpg/mr/项目管理/策划/光灵技能文档/自动战斗策略.xlsx
    PetGiles = 15, --贾尔斯：选择全场绝对血量最低的怪物攻击，在能攻击到的前提下优先选玩家所在的格子施放。
    PetVice = 16, --薇丝：先选择BOSS，没有BOSS再选择小怪。同级内优先选择有指定buff的存活目标，没有带buff的再选择血量绝对值最高的。
    PetReinhardt = 17, --莱因哈特，每次选择能命中最多格伤害的位置点选
    FeatureMasterSkill = 18, --模块，空裔技能 选择离自己最近的非队长属性的格子
    PetSPKaLian = 19, --SP卡莲
    PetSPKaLianWithDamage = 20, --SP卡莲觉醒2+
    PetFeiYa = 21, --菲雅：（能量>=2，释放两次主动技）第一次选择场上血量最低的怪物所在格子，第二次再次选择该格子
    PetJudge = 22, --法官：地图上没有石膏机关，则在周围两圈随机释放；如果有，则选择能摧毁最多石膏机关的位置
    Pet1601701 = 23, --珀拉珂,选宝宝左右可选的列中黄格子多的，点选有怪物的列
    Pet1601751 = 24, --阿克希亚
    PetZhongxuMain = 25, --仲胥 1技能 选离队伍最近的非火格子（无怪、可召唤机关）召唤机关
    PetZhongxuExtra = 26, --仲胥 2技能 先点1技能召唤的机关，然后随意一个方向，点方向上可以点的最远格子（只有释放1技能的回合可用,指有机关）
    PetYeliyaMain = 27, --耶利亚 1技能 第一个点，范围内有强化格则点强化格，否则点能打到最多目标的点，都没有则不放；点到强化格后续点选时，优先强化格，没有则向最近的敌人靠近
    PetYeliyaExtra = 28, --耶利亚 2技能 范围内有强化格则点强化格，否则点能打到最多目标的点，都没有则不放
    PetLingEn = 29, --零恩 1技能 热量层数大于配置，则点能打到最多目标的点；热量层数小于配置，则点自己
    PetDiNa = 30, --蒂娜：超最近的怪连线，优先去最多非水格子路线
    PetNaNuSaiEr = 31, --纳努塞尔 原来是选净化机关数最多的点（默认策略),修改为如果没有机关可以净化，则原地释放
    PetANaTuoLi = 32, --阿纳托利 最近的两个怪脚下，至少点一个
    FeatureMasterSkillExtra = 33, --模块，空裔技能 扩展 多选格 选择离自己最近的非指定属性（列表）的格子
    PetSorkBekk = 34, --鳄鱼 索克&贝克 选伤害目标最多的方向，需要根据点选方向计算碰撞位置作为技能中心
    PetDanTang = 35, --丹棠：在非火格子中，选择伤害敌人格子数最多的点
    PickupConvertWithWeight = 36, --带有权重计算的点选专色，MSG64606/MSG64611
    Pet1502051SPBaiLan = 37, --MSG65201
    --MSG67220通用注释：LocalTeam开头的策略固定以【玩家队伍】为自身，无视施法者身份
    LocalTeamSelectGrid1x4Or2x2Convert = 38, --MSG67220-1，希诺普改版，中心位置固定取LocalTeam，期望格子颜色可配，万色视作期望格子颜色
    LocalTeamSelectCenterGridFor3x3Convert = 39, --MSG67220-2，从玩家所在位置开始，从第0圈（中心）开始计算一个期望颜色格子小于指定值的3x3区域
    LocalTeamSelectCornerGridsFor3x3Convert = 40, --MSG67220-3，双点选，优先选择非期望颜色格子数>=配置值的位置，没有则随机释放
    LocalTeamSelectCenterGridFor1xCrossConvert = 41, --MSG67220-4
    LocalTeamPickupConvertWithWeight = 42, --MSG67220 36的翻版，区别是固定以玩家队伍为自身进行计算，以支持空裔模块作为施法者
    PetLarrey = 43, --莱蕾：自己左右两列中，选择火格子最少的那一列，优先选择距离自己近的
    PetSinan = 44,--只选列作为范围，自己左右两列中，水格子多的那一列的离队伍最近的非水格子,如果有俩格子离自己一样近，直接随机选,如果有一列全都是水格子，就选另一列的离队伍最近的非水格子,如果左右两列都是水格子，就从左右第二列中按照相同规则选，依此类推
    PetJocelyn = 45,--乔斯琳：面前一格，四方向或者八方向，选一个怪层数最多的方向
    MAX = 99
}

--自动战斗技能范围配置用途
AutoFightScopeUseType = {
    Replace = 1, --替换原配置
    Other = 2, --额外配置
    PickPosPolicy = 3, --点选格子策略参数（与技能范围无关，强行使用配置中的AutoFightSkillScopeTypeAndTargetType；策划不想新增列！！！）
    ReplaceTargetAndTrapCount = 4, --通过配置的范围计算范围内目标数量,并且指定机关要满足数量
}

--关卡自动战斗策略
LevelPosPolicy = {
    ProtectTrap = 1, --守护机关周围2圈的怪物权值增加
    KillMonster = 2, --需要击杀的怪物权值增加
    GotoExitPos = 3, --走向出口
    GotoTrapPos = 4 --走向机关，只踩一次
}

--[[
    星灵技能标签
]]
PetSkillTag = {
    Attack = 1, --伤害
    RandPieceColor = 2, --随机洗板
    FixedPieceColor = 3, --定向洗板
    AddBlood = 4, --治疗
    Transport = 5, --位移
    San = 6, --san值相关，@featureServiceLogic:IsActiveSkillCanCast(...)
    SummonTrap = 7 --召唤机关，用来标识技能是否使用机关属性的机关召唤上限来设置是否可以释放
}
