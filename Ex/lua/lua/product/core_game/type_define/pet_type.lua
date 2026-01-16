--筛选类型,ui使用，真正的类型再pet_info的里面
PetFilterType = {
    None = 0, --全部
    ElementBlue = 1, --水属性
    ElementRed = 2, --火属性
    ElementGreen = 3, --森属性
    ElementYellow = 4, --雷属性
    MainElementBlue = 11, --主属性，水
    MainElementRed = 12, --主属性，火
    MainElementGreen = 13, --主属性，森
    MainElementYellow = 14, --主属性，雷
    NotInRoom = 100, --未入驻房间
    InCentralRoom = 101, --主控室
    InPowerRoom = 102, --能源室
    InMazeRoom = 103, --秘境室
    InPrismRoom = 104, --棱镜室
    InResouceRoom = 105, --资源室
    InTowerRoom = 106, --灯塔室
    InEvilRoom = 107, --恶鬼室
    BaiYeCheng = 1001, --白夜城
    BaiYeXiaCheng = 1002, --白夜下城
    QiGuang = 1003, --启光
    BeiJing = 1004, --北境
    HongYouBanShou = 1005, --红油扳手
    TaiYangJiaoTuan = 1006, --太阳教团，即真理结社
    YouMin = 1007, --游民
    RiShi = 1008, --日蚀
    JobColor = 2001, --转色类【变化】
    JobBlood = 2002, --续航类【狙击】
    JobAttack = 2003, --伤害类【爆破】
    JobFunction = 2004, --功能类【辅助】
    -- 羁绊类型
    FT_Start = 3001, --
    GongTing = 3001, -- 宫廷
    JiaoHui = 3002, -- 教会
    GuiZu = 3003, -- 贵族
    SiTianShi = 3004, -- 四天使
    SiLingBu = 3005, -- 司令部
    JunDui = 3006, -- 军队
    KeYanWeiYuanHui = 3007, -- 科研委员会
    GongWuYuan = 3008, -- 公务员
    TanSuoDui = 3009, -- 探索队
    GanBu = 3010, -- 干部
    ChengYuan = 3011, -- 成员
    YiSiTaWanBang = 3012, -- 伊斯塔万帮
    LieQueBang = 3013, -- 烈雀帮
    JuMin = 3014, -- 居民
    GaoJiSheYuan = 3015, -- 高级成员
    PuTongSheYuan = 3016, -- 普通社员
    XinShiGongHui = 3017, -- 信使公会
    YouMinFriend = 3018, -- 游民羁绊类型
    LingXiu = 3019, -- 领袖
    JingYing = 3020, -- 精英
    AnGui = 3021, -- 暗鬼
    --其他的筛选条件
    RedPoint_Break = 8000,--突破红点
	Refine = 8001,--精炼

    DontFilter = 9000, --指定某个星灵永远不被过滤
    FT_End = 9999 --结束标志
}

-- CG图鉴类型
---@class 
BookCGType = {
    Main = 1, -- 主线
    Ext = 2, -- 番外
    Pet = 3, --星灵
    Season = 4, --赛季
    Max = 4 -- 等于最大的就可以
}

-- 角色图鉴类型
---@class BookRoleType
BookRoleType = {
    Pet = 1, -- 宝宝
    Monster = 2 -- 怪物
}

-- 图鉴总览入口类型
---@class BookMainType
BookMainType = {
    RenShiQingBao = 1, --人事情报
    CG = 2, -- CG档案
    Music = 3, --音乐集
    Plot = 4, -- 剧情
    Medal = 5 --勋章
}

--- @class PetAttributeType
local PetAttributeType = {
    None = 0,
    Attack = 1, --攻
    Defence = 2, --防
    HP = 3 --血
}
_enum("PetAttributeType", PetAttributeType)

---@class PetTagType
local PetTagType = {
    Camp = 1, -- 所属阵营，表中字段说明为“主标签”
    Function = 2, -- 功能性，表中字段说明为“副标签”
    Friend = 3 -- 羁绊标签
}
_enum("PetTagType", PetTagType)

---@class PetIntimacyCondition
local PetIntimacyCondition = {
    Affinity = 1, --星灵好感度
    Grade = 2, --升维
    Three = 3, --观看过剧情
    Time = 4, --时间
    ServerTime = 5, --服务器时间
    AffinityEqual = 6, --星灵好感度等级对应的 必须满足==
    DateLock = 7, --指定日期 value(月）value2(日)
    Skin = 8, --典藏时装
    SpeSkin = 9 --带语音皮肤
}
_enum("PetIntimacyCondition", PetIntimacyCondition)
