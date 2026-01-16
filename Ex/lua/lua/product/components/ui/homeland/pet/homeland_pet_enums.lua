---@class HomelandPetLoadState
local HomelandPetLoadState = {
    None = 0,
    Wait = 1, --在队列中等待，每次只加载1个
    Loading = 2, --加载中
    Invalid = 3, --无效，加载完之后发现不需要了
    Finish = 4, --加载完成
    Closed = 5 --关闭
}
_enum("HomelandPetLoadState", HomelandPetLoadState)

---@class HomelandPetAnimName
local HomelandPetAnimName = {
    --基础动作，共用风船的
    Stand = "stand",
    Walk = "walk",
    Click = "click01",
    Sit = "sit",
    
    --基础动作，家园光灵特有的
    Run = "move",
    Greet = "stand", --"greet"
    Happy = "happy",
    --无此动作<depression>
    Depression = "depression",
    Angry = "angry",
    --无此动作<amaze>
    Amaze = "amaze",
    Surprise = "surprise",
    Sad = "sad",
	
	--游泳动作，家园光灵在泳池中的动作
    Float = "float_hli",	--漂浮
    Swim = "swim_hli",	--游泳
    FastSwim = "fastswim_hli",	--快速游泳
}
_enum("HomelandPetAnimName", HomelandPetAnimName)

--- @class HomelandPetBehaviorType
local HomelandPetBehaviorType = {
    Free = 1, --空闲
    Roam = 2, --漫游
    InteractingPlayer = 3, --和玩家交互
    Following = 4, --跟随玩家
    InteractingFurniture = 5, --和家具交互
    TreasureIdle = 6, --提示宝物
    GreetPlayer = 7, --和玩家打招呼
    StoryPlaying = 8,--剧情触发中
    StoryWaitingBuild = 9,--待触发剧情家具交互中
    StoryWaitingBuildStand = 10,--待触发剧情家具旁站立中
    StoryWaitingStand = 11,--待触发剧情站立中
    StoryWaitingWalk = 12,--待触发剧情散步中
    SwimmingPool = 14, --泳池
    FishingPrepare = 15, --钓鱼比赛 河边准备
    FishingMatch = 16, --钓鱼比赛
}
_enum("HomelandPetBehaviorType", HomelandPetBehaviorType)

--- @class HomelandPetComponentType
local HomelandPetComponentType = {
    Move = 1, --移动
    Bubble = 2, --冒泡
    Animation = 3, --动画
    Face = 4, --表情
    Soliloquize = 5, --自言自语
    InteractionAnimation = 6, --交互动画
    Swim = 7, --游泳
    ExtraAnimation = 8, --Pet Extra 动画
}
_enum("HomelandPetComponentType", HomelandPetComponentType)

--- @class HomelandPetBehaviorStructure
local HomelandPetBehaviorStructure =
{
    [HomelandPetBehaviorType.Free] =
    {
        HomelandPetComponentType.Animation,
        HomelandPetComponentType.Bubble,
    },
    [HomelandPetBehaviorType.Roam] =
    {
        HomelandPetComponentType.Move,
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Soliloquize,
    },
    [HomelandPetBehaviorType.InteractingPlayer] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Animation
    },
    [HomelandPetBehaviorType.Following] =
    {
        HomelandPetComponentType.Move,
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Animation
    },
    [HomelandPetBehaviorType.InteractingFurniture] =
    {
        {
            HomelandPetComponentType.Move,
            HomelandPetComponentType.Bubble,
            HomelandPetComponentType.InteractionAnimation,
        }
    },
    [HomelandPetBehaviorType.TreasureIdle] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Animation,
    },
    [HomelandPetBehaviorType.GreetPlayer] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Animation
    },
    [HomelandPetBehaviorType.StoryPlaying] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Face,
        HomelandPetComponentType.Animation,
    },
    [HomelandPetBehaviorType.StoryWaitingStand] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Face,
        HomelandPetComponentType.Animation,
    },
    [HomelandPetBehaviorType.StoryWaitingWalk] =
    {
        HomelandPetComponentType.Move,
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Face,
        HomelandPetComponentType.Animation,
    },
    [HomelandPetBehaviorType.StoryWaitingBuild] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Face,
        HomelandPetComponentType.Animation,
        HomelandPetComponentType.InteractionAnimation,
    },
    [HomelandPetBehaviorType.StoryWaitingBuildStand] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.Face,
        HomelandPetComponentType.Animation,
    },
    [HomelandPetBehaviorType.SwimmingPool] =
    {
        {
            HomelandPetComponentType.Move,
            HomelandPetComponentType.Swim,
        }
    },
    [HomelandPetBehaviorType.FishingPrepare] =
    {
        {
            HomelandPetComponentType.Bubble
        }
    },
    [HomelandPetBehaviorType.FishingMatch] =
    {
        HomelandPetComponentType.Bubble,
        HomelandPetComponentType.ExtraAnimation
    },
}
_enum("HomelandPetBehaviorStructure", HomelandPetBehaviorStructure)

--- @class HomelandPetComponentState
local HomelandPetComponentState = {
    Resting = 1,
    Failure = 2,
    Success = 3,
    Running = 4,
    Error = 5,
}
_enum("HomelandPetComponentState", HomelandPetComponentState)

--- @class HomelandPetMode
local HomelandPetMode = {
    Normal = 1,
    Debug = 2
}
_enum("HomelandPetMode", HomelandPetMode)

---@class HomelandPetOccupiedType
local HomelandPetOccupiedType = {
    None = 0,
    Treasure = 1, --探宝
    StoryWaiting = 2, --剧情等待
    FishingMatch = 3, --钓鱼比赛
}
_enum("HomelandPetOccupiedType", HomelandPetOccupiedType)

---@class HomelandPetModeChangeProcessType
local HomelandPetModeChangeProcessType = {
    RefreshNavmeshPos = 0,  --刷新可达位置
    Custom = 1,             --自定义处理方法
}
_enum("HomelandPetModeChangeProcessType", HomelandPetModeChangeProcessType)

--光灵动作类型
--- @class HomelandPetMotionType
local HomelandPetMotionType = {
    None = 1,	--
    Swim = 2 --游泳
}
_enum("HomelandPetMotionType", HomelandPetMotionType)

--光灵交互中执行的
--- @class HomelandRoleInteractingFunction
local HomelandRoleInteractingFunction = {
    None = 0,	--
    ChangeSwimsuit = 1 --换泳衣
}
_enum("HomelandRoleInteractingFunction", HomelandRoleInteractingFunction)

--光灵交互中执行的
--- @class HomelandInteractAnimationType
local HomelandInteractAnimationType = {
    In = 1,
    Loop = 2,
    Out = 3,
}
_enum("HomelandInteractAnimationType", HomelandInteractAnimationType)
