--电影准备目的
--- @class MoviePrepareTarget
local MoviePrepareTarget = {
    PT_Maker = 1,       --准备制作
    PT_Playback = 2,    --准备回放
}
_enum("MoviePrepareTarget", MoviePrepareTarget)


--电影准备阶段
--- @class MoviePrepareType
local MoviePrepareType = {
    PT_Scene = 1,           --场景布置
    PT_Furniture = 2,       --自由搭配-家具
    PT_Prop = 3,            --剧情道具
    PT_Actor = 4,     --演员选择
    PT_Result = 5,      --结算
}
_enum("MoviePrepareType", MoviePrepareType)

--电影准备阶段
--- @class MoviePrepareItemType
local MoviePrepareItemType = {
    PIT_Select = 3,         --选项
    PIT_Item = 2,           --道具
    PIT_BackGroup = 4,      --家具背景选择
}
_enum("MoviePrepareItemType", MoviePrepareItemType)

--演员页面类型
---@class ActorPageType
local ActorPageType = {
    Actor = 1, --演员
    Item = 2  --物品
}
_enum("ActorPageType",ActorPageType)
