---@class HomelandMode
local HomelandMode = {
    Normal = 1,
    Build = 2,
    Story = 3
}
_enum("HomelandMode", HomelandMode)

---@field Idle number
---@field Walk number
---@field Run number
---@class HomelandCharMoveType: Object
_enum("HomelandCharMoveType", HomelandCharMoveType)
HomelandCharMoveType = {
    Idle = 0, --
    Walk = 1, -- 
    Run = 2, --
    Rush = 3, --
}

-- 对应 cfg_homeland_minimap_icon 的 ID
---@class HomelandMapIconType
local HomelandMapIconType = {
    Player = 1, --
    Pet = 2, --
    FishingPoint = 3, --
    CommonBuild = 4, --
    WhiteTower = 5, --
    BreedLand = 6, --培育地块
    Shop = 7, -- 商店
    Treasure = 8, -- 探宝
    StorageBox = 9, -- 置物箱(复用CommonBuild的prefab和script)
    Domitory = 10, --宿舍
    FindTreasureNPC = 11, --寻宝NPC
    TracePoint = 12, --引导点
    WishCoinPoint = 13, --许愿币鱼点
    RareFishingPoint = 14, --线索鱼点
    PetFishingPoint = 15, --光灵特殊鱼点
}
_enum("HomelandMapIconType", HomelandMapIconType)

---@class HomelandFishingPointType
local HomelandFishingPointType = {
    Normal = 1, --
    River = 2, --
    Gold = 3, --
    Box = 4, --
    GoldPetFish = 5--
}
_enum("HomelandFishingPointType", HomelandFishingPointType)

---@class HomelandFilterType
local HomelandFilterType = {
    All = 1, --
    Edit = 2, --
    Forge = 3 --
}
_enum("HomelandFilterType", HomelandFilterType)
