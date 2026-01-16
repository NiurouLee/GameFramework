--[[
    HomelandActorStateType : 家园角色状态机状态类型枚举
]]

---@class HomelandActorStateType: Object
_enum("HomelandActorStateType", HomelandActorStateType)
HomelandActorStateType = {
    Idle = 1,           --待机/水中漂浮
    Run = 2,            --跑步/走路
    Swim = 3,           --游泳/慢速游泳
    Dash = 4,           --冲刺
    Interact = 5,       --交互
    Axe = 6,            --持斧
    Pick = 7,           --持镐
    Fish = 8,           --钓鱼
    Navigate = 9,       --寻路
    Stationary = 10,    --禁止移动

    Dispose = 11,       --销毁

    NotDefined = 99,    --未定义
}

function HomelandActorStateType.TypeToName(type)
    for name, value in pairs(HomelandActorStateType) do
        if type == value then
            return name
        end
    end
end