--[[
    风船星灵保存在本地的信息，这里只做注释用
]]
---@class AircraftSaveData
local AircraftSaveData = {
    ---@type table<number,AircraftSavePet>
    pets = nil, --星灵集合
    ---@type table<number,number>
    queue = nil, --排队队列中的星灵id
    playerID = nil, --玩家id
    time = nil --时间
}

---@class AircraftSavePet
local AircraftSavePet = {
    pet = nil, --星灵templateid
    ---@type AircraftPetSaveData
    data = nil
}

---@class AircraftPetSaveData
local AircraftPetSaveData = {
    --公用
    floor = nil, --所在楼层
    state = nil, --状态
    belongArea = nil, --所属区域
    remainTime = nil, --行为剩余时间
    actionIndex = nil, --该行为在行为库中的索引，下一次不能随到这个
    --漫游
    area = nil, --漫游区域
    --与家具交互
    furnID = nil, --家具id，实际是家具唯一Key
    point = nil, --家具交互点索引
    --社交
    airSocialActionType = nil,
    socialRound = nil,
    socialFurnitureId = nil,
    socialPointHolderIndex = nil,
    socialLocationIndex = nil,
    socialAreaType = nil,
    socialPetCount = nil,
    --
    NONE = nil
}
