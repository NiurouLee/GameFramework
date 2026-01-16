---@class SeasonEventPointLoadState
local SeasonEventPointLoadState = {
    None = 0,
    Wait = 1,    --在队列中等待，每次只加载1个
    Loading = 2, --加载中
    Invalid = 3, --无效，加载完之后发现不需要了
    Finish = 4,  --加载完成
    Closed = 5   --关闭
}
_enum("SeasonEventPointLoadState", SeasonEventPointLoadState)

---@class SeasonEventPointLoadType
local SeasonEventPointLoadType = {
    Sync = 1,   --同步加载
    Async = 2,  --异步加载
}
_enum("SeasonEventPointLoadType", SeasonEventPointLoadType)

--区
---@class SeasonZone
local SeasonZone = {
    One = 1,  --一区
    Two = 2,  --二区
    Three = 3 --三区
}
_enum("SeasonZone", SeasonZone)

--相机模式
---@class SeasonCameraMode
local SeasonCameraMode = {
    Drag = 1,   --拖拽
    Follow = 2, --跟随主角
}
_enum("SeasonCameraMode", SeasonCameraMode)

--玩家动画
---@class SeasonPlayerAnimation
local SeasonPlayerAnimation = {
    Move = "smove",     --移动
    Stand = "stand",    --休闲
    Click = "click",    --普通待机
    Click1 = "click01", --点击
    Click2 = "click02", --战斗待机
    Spanner = "banshou" --扳手
}
_enum("SeasonPlayerAnimation", SeasonPlayerAnimation)

--LayerMask
---@class SeasonLayerMask
local SeasonLayerMask = {
    Stage = 13, --事件点
    Scene = 20, --场景地表层
}
_enum("SeasonLayerMask", SeasonLayerMask)

--地图层级
---@class SeasonSceneLayer
local SeasonSceneLayer = {
    SoundMaterial = "Layer", --地面音效
    ZoneFlag = "Layer0",     --区标识面
    Ground = "Layer1",       --地表层
    Building = "Layer2",     --建筑层
    HighBuilding = "Layer3", --高层建筑层
    FogMask = "Layer4",      --战争迷雾遮罩层
    Ambient = "Layer5",   --氛围特效(解锁后显示)
    AmbientMap = "Layer7", --氛围特效(满足地块条件显示，和地图变化一起变化)
}
_enum("SeasonSceneLayer", SeasonSceneLayer)

--表现触发方式
---@class SeasonExpressTriggerType
local SeasonExpressTriggerType = {
    Active = 1,  --主动触发
    Passive = 2, --被动触发
}
_enum("SeasonExpressTriggerType", SeasonExpressTriggerType)

--表现类型
---@class SeasonExpressType
local SeasonExpressType = {
    Level = 1,      --关卡
    Animation = 2,  --动作(包含事件点和主角的动画以及对应的特效)
    Effect = 3,     --特效(只是特效)
    Story = 4,      --剧情
    Bubble = 5,     --气泡
    Reward = 6,     --奖励展示
    Show = 7,       --是否显示模型
    Obstacle = 8,   --是否开启障碍物的路径阻挡
    Focus = 9,      --聚焦(主角，事件点，坐标)
    LockInput = 10, --锁定输入(锁定地图点击、拖拽)
    Sign = 11,      --头顶信号
}
_enum("SeasonExpressType", SeasonExpressType)

--聚焦表现聚焦对象类型
---@class SeasonExpressFocusObjType
local SeasonExpressFocusObjType = {
    Player = 1,     --主角
    EventPoint = 2, --事件点
    Position = 3,   --坐标
}
_enum("SeasonExpressFocusObjType", SeasonExpressFocusObjType)

--聚焦表现聚焦类型
---@class SeasonExpressFocusType
local SeasonExpressFocusType = {
    Left = 1,   --左聚焦
    Center = 2, --居中聚焦
    Right = 3,  --右聚焦
}
_enum("SeasonExpressFocusType", SeasonExpressFocusType)

--表现执行的状态
---@class SeasonExpressState
local SeasonExpressState = {
    NotStart = 1, --还未开始
    Playing = 2,  --正在播放
    Over = 3,     --表现结束
}
_enum("SeasonExpressState", SeasonExpressState)

--事件点类型
---@class SeasonEventPointType
local SeasonEventPointType = {
    MainLevel = 1, --主线关
    SubLevel = 2,  --支线关
    MainStory = 3, --主线剧情关
    SubStory = 4,  --支线剧情关
    Box = 5,       --宝箱
    Mechanism = 6,  --机关
    DailyLevel = 7, --日常关
}
_enum("SeasonEventPointType", SeasonEventPointType)

--赛季输入模式
---@class SeasonInputMode
local SeasonInputMode = {
    Input = 1,     --输入
    LockInput = 2, --屏蔽输入(只屏蔽地图点击、拖拽)
}
_enum("SeasonInputMode", SeasonInputMode)

---@class UISeasonLevelDiff 赛季玩法战斗关难度
local UISeasonLevelDiff = {
    Normal = 1, --战斗关普通难度
    Hard   = 2, --战斗关高难难度
}
_enum("UISeasonLevelDiff", UISeasonLevelDiff)

---@class UISeasonOvalTipType 赛季边缘气泡类型
local UISeasonOvalTipType = {
    Player  = 1, --主角
    Mission = 2, --主线关
    Box     = 3, --宝箱
    Daily   = 4, --日常关
}
_enum("UISeasonOvalTipType", UISeasonOvalTipType)

---@class ESeasonExtInfo 赛季扩展信息枚举
local ESeasonExtInfo = {
    SeasonFirstPlotReadState  = 1, --赛季系统（剧情）剧情已读状态
}
_enum("ESeasonExtInfo", ESeasonExtInfo)

--点击特效播放阶段
---@class SeasonClickEffectPhase
local SeasonClickEffectPhase = {
    None = 0,
    Click = 1,
    In = 2,
    Loop = 3,
}
_enum("SeasonClickEffectPhase", SeasonClickEffectPhase)

--地表材质
---@class SeasonMapMaterial
local SeasonMapMaterial = {
    Default = 1, --默认
    Metal = 2, --金属
    Stone = 3, --石头
}
_enum("SeasonMapMaterial", SeasonMapMaterial)

--输入阶段
---@class SeasonInputPhase
local SeasonInputPhase = {
    None = 0, --默认
    Down = 2, --按下
    Up = 3,   --抬起
}
_enum("SeasonInputPhase", SeasonInputPhase)

--日常关状态
---@class SeasonDailyState
local SeasonDailyState = {
    Lock = 0, --锁定
    Time = 1, --时间未到
    Mission = 2, --关卡未完成
    MaxReward = 3, --超过了最大奖励次数
    Unlock = 4, --解锁并可以挑战
}
_enum("SeasonDailyState", SeasonDailyState)

--日常关刷新阶段
---@class SeasonDailyResetPhase
local SeasonDailyResetPhase = {
    None = 0, --无需刷新
    Waiting = 1, --等待刷新
    Reseting = 2, --刷新中
    Success = 3, --刷新成功
}
_enum("SeasonDailyResetPhase", SeasonDailyResetPhase)

--头顶图标类型
---@class SeasonSignType
local SeasonSignType = {
    Before = 1, --提前显示(播放表现前处理)
    Play = 2, --播放表现的时候处理
}
_enum("SeasonSignType", SeasonSignType)

