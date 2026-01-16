---纯逻辑的实体，其ConfigID放到EntityConfigIDConst中；纯渲染的实体，其ConfigID放到EntityConfigIDRender中；不允许出现既是逻辑又是渲染的实体ConfigID

---@class EntityConfigIDConst
---@field Board   number
---@field Team number
---@field Pet number
---@field Monster number
---@field Trap number
local EntityConfigIDConst = {
    "Board",
    "Team",
    "Pet",
    "PetShadow",
    "SkillHolder",
    "Monster",
    "Trap",
    "ChessPet",
    "Network",
    "PersonaSkillHolder",--
}
_autoEnum("EntityConfigIDConst", EntityConfigIDConst)
