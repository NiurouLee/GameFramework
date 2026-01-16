--[[
    风船枚举
]]
-------------------------------------------------------------------------
--[[
    风船数值
]]
---@class AircraftConst
local AircraftConst = {
    DecorateAreaCount = 25
}
_enum("AircraftConst", AircraftConst)
-------------------------------------------------------------------------
--[[
    风船星灵状态
]]
---@class AirPetState
local AirPetState = {
    None = 0, --无效
    Wandering = 1, --漫游中
    OnFurniture = 2, --家具交互中
    Transiting = 3, --过渡中
    WaitingElevator = 4, --等电梯
    InElevator = 5, --电梯中
    Social = 6, --社交中
    Leaving = 7, --离开中
    Working = 8, --工作中
    Selected = 9, --点击交互中
    RandomEvent = 10, --随机事件行为中
    WaitForEnter = 11, --等待进入
    RandomEventWith = 12, --随机剧情伴随行为
    Upstairs = 13, --正在上楼梯
    MoveToWork = 14, --正在走向工作房间
    SendingGift = 15, --送礼中
    Testing = 1000, --测试状态
    END = 9999
}
_enum("AirPetState", AirPetState)
------------------------------------------------------------------------
--[[
    风船娱乐区域
]]
---@class AirRestAreaType
local AirRestAreaType = {
    RestRoom = 10001, --休息室
    CoffeeHouse = 10002, --咖啡厅
    Bar = 10003, --酒吧
    EntertainmentRoom = 10004, --娱乐室
    Board3 = 10005, --3层甲板
    Board4 = 10006, --4层甲板
    CenterRoom = 10007, --主控室
    None = 9999
}
_enum("AirRestAreaType", AirRestAreaType)
--------------------------------------------------------------------------
--[[
    房间状态
]]
---@class AirUIState
local AirUIState = {
    SpaceNotOpen = 0, --未开放,会显示解锁条件
    SpaceUnclean = 1, --未清理
    SpaceUnbuild = 2, --未建造
    AisleNotOpen = 3, --过道未开放
    AisleUnclean = 4, --过道未清理
    AisleUnbuild = 5, --过道未建造，2020-7-15废弃，过道一键建成，没有未建造状态
    Aisle = 6, --已建造过道
    RoomBuilding = 7, --建造中
    RoomIdle = 8, --房间空闲
    RoomUpgrading = 9, --房间升级中
    RoomStopWork = 10, --房间停止工作
    EvilClearing = 11, --恶鬼净化室净化中
    EvilClearEnd = 12, --恶鬼净化室净化完成
    SpaceCleaning = 13, --空间清理中
    RoomDegrading = 14, --房间降级中
    RoomTearing = 15, --房间拆除中
    CollectAward = 16, --可领取奖励
    ---
    RestAreaRoom = 17, --休息区房间
    RestAreaRoomLock = 18, --娱乐区房间未解锁(1级)
    CanCollectAward = 19, --可领取奖励，但是不领取奖励
    HaveNewTask = 20, --有新的派遣任务
    ---
    SpaceClosed = 21 --空间未到开放时间,关门不显示解锁条件
}
_enum("AirUIState", AirUIState)
--------------------------------------------------------------------
--[[
    家具类型
]]
---@class AirFurnitureType
local AirFurnitureType = {
    --通用
    RestChair = 1001, --通用坐
    RestEmpty = 1002, --通用空地
    --休息室
    RestSofa = 1003, --懒人沙发
    RestChess = 1004, --象棋
    RestRobot = 1005, --投影机器人
    --咖啡厅
    CoffeeShelf = 2003, --书架
    CoffeeDesk = 2004, --书桌
    CoffeeMachine = 2005, --咖啡
    CoffeeSpecimen = 2006, --标本
    --娱乐室
    GameDarts = 3003, --飞镖
    GameSnooker = 3004, --台球
    GameBoxingBall = 3005, --拳击球
    GameMachine = 3006, --游戏机
    --酒吧
    BarWineTable = 4003, --调酒桌
    BarCounter = 4004, --吧台
    BarStage = 4005, --演奏台
    BarMusicBox = 4006, --点唱机
    None = 9999
}
_enum("AirFurnitureType", AirFurnitureType)
-------------------------------------------------------------------
---@class AirRandomActionType
local AirRandomActionType = {
    Wandering = 1, --漫游
    Furniture = 2 --与家具交互
}
_enum("AirRandomActionType", AirRandomActionType)
-------------------------------------------------------------------
---@class AircraftRoomTag 房间标签，标记星灵用
local AircraftRoomTag = {
    RestRoom = 1,
    CoffeeHouse = 2,
    Bar = 3,
    Game = 4
}
_enum("AircraftRoomTag", AircraftRoomTag)
-------------------------------------------------------------------
---@class AircraftSocialTag 社交标签
local AircraftSocialTag = {
    Hot = 1, -- 热情
    Normal = 2, -- 正常
    Lone = 3 -- 孤僻
}
_enum("AircraftSocialTag", AircraftSocialTag)
------------------------------------------------------------------------
---@class AirSocialAreaType
local AirSocialAreaType = {
    Work = 1, -- 工作区
    Happy = 2 -- 娱乐区
}
_enum("AirSocialAreaType", AirSocialAreaType)
------------------------------------------------------------------------
---@class AirSocialActionType
local AirSocialActionType = {
    Gather = 1, -- 聚集聊天
    WalkTalk = 2, -- 边走边聊
    Furniture = 3 -- 家具交互
}
_enum("AirSocialActionType", AirSocialActionType)
------------------------------------------------------------------------
------@class AirGroupActionStateType
local AirGroupActionStateType = {
    None = 0, -- 空状态
    Move = 1, -- 全部行走完
    Follow = 2, -- 移动中聊天
    LookAt = 3, --全部转向
    Talk = 4, -- 循环对话
    Furniture = 5, -- 所有家具交互完
    Stand = 6, -- 站立等待
    Closer = 7, -- 靠近(暂未用)
    Located = 8, -- 定位到某点
    Correct = 9, -- 校正
    MoveTalk = 10, -- 边走边聊
    FurnitureTalk = 11 -- 边家具边聊
    ---GroupTalk = 12, --可能触发有真实聊天内容的对话
    -- 边走边聊
}
_enum("AirGroupActionStateType", AirGroupActionStateType)
--------------------------------------------------------------------
---分层状态
------@class AirSocialSubLibType
local AirSocialSubLibType = {
    -- 边走边聊
    [AirGroupActionStateType.MoveTalk] = {
        AirGroupActionStateType.Move,
        AirGroupActionStateType.LookAt,
        AirGroupActionStateType.Stand
        -- AirGroupActionStateType.Correct
    }
}
_enum("AirSocialSubLibType", AirSocialSubLibType)
------------------------------------------------------------------
---@class AirPetMoveState
local AirPetMoveState = {
    Moving = 1, --正在移动
    Blocked = 2, --被阻挡
    Pausing = 3, --暂停
    Prepare = 4, --准备阶段
    Arrived = 5, --到达
    Prepare1 = 6,
    NONE = 99
}
_enum("AirPetMoveState", AirPetMoveState)
------------------------------------------------------------------
---风船星灵计算下一个行动
---@class AirPetCalcNextActionState
local AirPetCalcNextActionState = {
    None = 0, -- 空状态
    Prepare = 1, --准备
    Calculate = 2, --计算
    Finish = 3, --完成
    Wait = 4, --等待
    Max = 99
}
_enum("AirPetCalcNextActionState", AirPetCalcNextActionState)
------------------------家具动作序列---------------------------
---@class AirFurnitureSeqType
local AirFurnitureSeqType = {
    XiaQi = 10001, --下棋
    WuTai = 20001, --演奏台
    TaiQiu = 30001, --台球
    BiaoBen = 40001 --标本
}
_enum("AirFurnitureSeqType", AirFurnitureSeqType)

--------------------------亲近/远离---------------------------------
---@class AirRelationType
local AirRelationType = {
    Pets = 1, --星灵
    ShiLi = 2, --势力
    All = 3 --所有人
}
_enum("AirRelationType", AirRelationType)
---------------------------------------------------------------------
--[[
    风船楼梯门状态
]]
---@class AirStairDoorState
local AirStairDoorState = {
    Idle = 1,
    Opening = 2,
    Stay = 3,
    Closing = 4
}
_enum("AirStairDoorState", AirStairDoorState)
---------------------------------------------------------------------
--[[
    星灵走楼梯状态
]]
---@class AirPetStairState
local AirPetStairState = {
    Enter = 1,
    Hide = 2,
    Wait = 3,
    Exit = 4,
    Finish = 5
}
_enum("AirPetStairState", AirPetStairState)

--------------------------------------------------------------------
--[[
    星灵与家具交互行为状态
]]
---@class AirPetFurState
local AirPetFurState = {
    FadeIn = 1,
    Idle = 2,
    FadeOut = 3,
    None = 4
}
_enum("AirPetFurState", AirPetFurState)
-------------------------------------------------------------------
--[[
    风船层，对应GameObject的Layer
]]
---@class AircraftLayer
local AircraftLayer = {
    Default = 1,
    Ground = 13,
    Smelt = 14, --熔炼炉
    Tactic = 15, --战术室
    Award = 18,
    Pet = 20,
    BookShelf = 21, --书架
    DispatchTaskMap = 22, --派遣任务地图
    Furniture = 23,
    Surface = 24, --家具所在面
    DragLayer = 25 --家具拖拽层
}
_enum("AircraftLayer", AircraftLayer)
--------------------------------------------------------------------
--[[
    星灵动画名称
]]
---@class AirPetAnimName
local AirPetAnimName = {
    Stand = "stand",
    Walk = "walk",
    Click = "click01",
    Sit = "sit"
}
_enum("AirPetAnimName", AirPetAnimName)
--------------------------------------------------------------------
--[[
    电梯状态
]]
---@class ElevatorState
local ElevatorState = {
    Idle = 1, --空闲
    Moving = 2, --移动中，去接星灵
    WaitEnter = 3, --星灵进入过程中
    WaitExit = 4, --星灵离开过程中
    Delivering = 5 --运送中
}
_enum("ElevatorState", ElevatorState)
-------------------------------------------------------------------
--[[
    移动速度
]]
---@class AircraftSpeed
local AircraftSpeed = {
    Pet = 0.9, --星灵移速
    Elevator = 1.5 --电梯上下移动的速度
}
_enum("AircraftSpeed", AircraftSpeed)
--------------------------------------------------------------------
--[[
    风船内操作门的动画
]]
---@class AircraftDoorAnim
local AircraftDoorAnim = {
    BuildRoom = 1,
    TearDown = 2,
    LevelUp = 3,
    LevelDown = 4
}
_enum("AircraftDoorAnim", AircraftDoorAnim)
--------------------------------------------------------------------
--[[
    风船NavAgent类型
]]
---@class AircraftNavAgent
local AircraftNavAgent = {
    Normal = 0,
    Oversize = 1
}
_enum("AircraftNavAgent", AircraftNavAgent)
--------------------------------------------------------------------
--[[
    风船运行模式
]]
---@class AircraftMode
local AircraftMode = {
    Normal = 0,
    Decorate = 1 --装扮模式
}
_enum("AircraftMode", AircraftMode)
--------------------------------------------------------------------
--[[
    风船家具层
]]
---@class FurnitureLayer
local AircraftFurnitureLayer = {
    First = 1,
    Second = 2,
    Third = 3
}
_enum("FurnitureLayer", AircraftFurnitureLayer)
--------------------------------------------------------------------
--[[
    装修操作模式
]]
---@class DecorateMode
local AircraftDecorateMode = {
    FullView = 1, --全景选区域
    Edit = 2 --编辑家具
}
_enum("DecorateMode", AircraftDecorateMode)
--------------------------------------------------------------------
--[[
    家具操作类型
]]
---@class FurnitureOpration
local FurnitureOpration = {
    Steady = 1, --固定的
    Movable = 2, --可移动
    Free = 3 --可移动可撤销
}
_enum("FurnitureOpration", FurnitureOpration)
--------------------------------------------------------------------
--[[
    家具摆放类型，这个枚举与编辑器枚举对应
]]
---@class LocationType
local LocationType = {
    Floor = 0, --地板
    Wall = 1, --墙
    Ceiling = 2 --天花板
}
_enum("LocationType", LocationType)
--------------------------------------------------------------------
---@class AircraftSocialTalkType
local AircraftSocialTalkType = {
    Normal = 1, --只有点点点的虚假聊天
    RealTalk = 2 --真实的聊天
}
_enum("AircraftSocialTalkType", AircraftSocialTalkType)
--------------------------------------------------------------------
---@class AircraftSpecialActionType
local AircraftSpecialActionType = {
    PresentBag = 1, --礼包
    Name = 2, --真实的聊天
    Light = 3 --光环
}
_enum("AircraftSpecialActionType", AircraftSpecialActionType)
--------------------------------------------------------------------
---@class AircraftPetFurSpacialActionType
local AircraftPetFurSpacialActionType = {
    WithGivenPoint = 1, --只与家具的特定点交互
    OccupyFurniture = 2 --与特定点交互，且占据整个家具
}
_enum("AircraftPetFurSpacialActionType", AircraftPetFurSpacialActionType)
-----------------------------------------------------------------------------------
--[[
    星灵行走到目标点执行任务的状态
]]
---@class AircraftPetMoveToDoState
local AircraftPetMoveToDoState = {
    MoveToElevator = 1, --走到电梯点
    MoveToStair = 2, --走到楼梯点
    Wait = 3, --星灵控制权交给电梯或楼梯
    Blocked = 4, --被阻挡
    MoveToActionTarget = 5, --走到行为执行点
    Stop = 6 --停止
}
_enum("AircraftPetMoveToDoState", AircraftPetMoveToDoState)
-----------------------------------------------------------------------------------
--[[
    星灵走到目标点主行任务的类型
]]
---@class AircraftPetMoveType
local AircraftPetMoveType = {
    ToWandering = 1,
    ToFurniture = 2,
    ToWork = 3,
    ToLeave = 4
}
_enum("AircraftPetMoveType", AircraftPetMoveType)
-----------------------------------------------------------------------------------
--[[
    星灵加载状态
]]
---@class AircraftPetLoadState
local AircraftPetLoadState = {
    None = 0,
    Wait = 1, --在队列中等待，每次只加载1个
    Loading = 2, --加载中
    Invalid = 3, --无效，加载完之后发现不需要了
    Finish = 4, --加载完成
    Closed = 5 --关闭
}
_enum("AircraftPetLoadState", AircraftPetLoadState)
-----------------------------------------------------------------------------------
--[[
    星灵送礼气泡id
]]
---@class AircraftPetGiftBubble
local AircraftPetGiftBubble = {
    Gift = "eff_meme_liwuhe.prefab", --礼包
    VisitName = "UIAircraftVisitPetName.prefab", --访客名字
    Light = "eff_aircraft_guest.prefab" --访客光圈
}
_enum("AircraftPetGiftBubble", AircraftPetGiftBubble)
-----------------------------------------------------------------------------------
--[[
    星灵送礼文本标签
]]
---@class AircraftPetGiftTag
local AircraftPetGiftTag = {
    Gift = 1, --送礼
    Visit = 2 --拜访
}
_enum("AircraftPetGiftTag", AircraftPetGiftTag)
-----------------------------------------------------------------------------------
--[[
    星灵特效挂点类型
]]
---@class AircraftPetSlotType
local AircraftPetSlotType = {
    None = 0, --无挂点，不跟随星灵
    Root = 1,
    Head = 2,
    Custom = 3 --自定义挂点
}
_enum("AircraftPetSlotType", AircraftPetSlotType)
-----------------------------------------------------------------------------------
--[[
    星灵等电梯状态
]]
---@class AircraftWaitElevState
local AircraftWaitElevState = {
    MoveToLine = 1, --走向排队点
    WaitInLine = 2, --在队列中排队
    MoveToNext = 3, --走向前1个点
    Finished = 4 --完成
}
_enum("AircraftWaitElevState", AircraftWaitElevState)

--[[
    星灵动作类型
]]
---@class AircraftActionType
local AircraftActionType = {
    None = 0,
    Face = 1 --面目表情动作
}
_enum("AircraftActionType", AircraftActionType)
