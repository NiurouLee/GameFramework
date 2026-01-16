---纯逻辑的实体，其ConfigID放到EntityConfigIDConst中；纯渲染的实体，其ConfigID放到EntityConfigIDRender中；不允许出现既是逻辑又是渲染的实体ConfigID
require("logic_entity_id")
---@class EntityConfigIDRender : Object
---@field Effect number
---@field EmptyGridEffect number
---@field MoveRange number
---@field SkillRangeOutline number
---@field AttackRange_Red number
---@field AttackRange_Green number
---@field AttackRange_Blue number
---@field AttackRange_Yellow number
---@field AttackRange_White number
---@field WarningArea number
---@field ConvertElement_Blue number
---@field ConvertElement_Green number
---@field ConvertElement_Red number
---@field ConvertElement_Yellow number
---@field TurnChangeEffect number
---@field PieceUpdownEffect number
---@field LinkLine_Red number
---@field LinkLine_Green number
---@field LinkLine_Blue number
---@field LinkLine_Yellow number
---@field LinkLine_Any number
---@field LinkGridDot_Red number
---@field LinkGridDot_Green number
---@field LinkGridDot_Blue number
---@field LinkGridDot_Yellow number
---@field LinkGridDot_Any number
---@field LinkGridInPath_Red number
---@field LinkGridInPath_Green number
---@field LinkGridInPath_Blue number
---@field LinkGridInPath_Yellow number
---@field LinkGridInPath_Any number
---@field LinkNum_Red number
---@field LinkNum_Green number
---@field LinkNum_Blue number
---@field LinkNum_Yellow number
---@field LinkNum_Any number
---@field LinkPos_Red number
---@field LinkPos_Green number
---@field LinkPos_Blue number
---@field LinkPos_Yellow number
---@field LinkPos_Any number
---@field CanMoveArrow number
---@field FinalAttackEffect number
---@field HPSlider number
---@field BossHPSlider number
---@field TrapHPSlider number
---@field PlayerHPSlider number
---@field Ghost number
---@field GuideGhost number
---@field LinkageInfo number
---@field LinkageNum number
---@field SkillTips number
---@field NormalDamage number
---@field DeBuffDamage number
---@field GuardDamage number
---@field MissDamage number
---@field RecoverDamage number
---@field RealDamage number
---@field CriticalDamage number
---@field PickUpArrow number
---@field Projectile number
---@field GuideFinger number
---@field GuideLinkLine number
---@field GuideSpot number
---@field GuidePiece number
---@field HeadStoryTips number
---@field EditorInfo number
---@field Preview number
---@field RenderBoard number
---@field HeadTrapRoundInfo number
---@field MonsterAreaOutLine number
---@field TrapAreaOutline number
local EntityConfigIDRender = {
    "Effect", --通过EffectService创建的常规特效
    "EmptyGridEffect",
    "MoveRange",
    "SkillRangeOutline",
    "AttackRange_Red",
    "AttackRange_Green",
    "AttackRange_Blue",
    "AttackRange_Yellow",
    "AttackRange_White",
    "WarningArea",
    "ConvertElement_Blue", --TODO貌似没有用
    "ConvertElement_Green", --TODO貌似没有用
    "ConvertElement_Red", --TODO貌似没有用
    "ConvertElement_Yellow", --TODO貌似没有用
    "TurnChangeEffect",
    "PieceUpdownEffect", --TODO貌似没有用
    "LinkLine_Red",
    "LinkLine_Green",
    "LinkLine_Blue",
    "LinkLine_Yellow",
    "LinkLine_Any",
    "LinkGridDot_Red",
    "LinkGridDot_Green",
    "LinkGridDot_Blue",
    "LinkGridDot_Yellow",
    "LinkGridDot_Any",
    "LinkGridInPath_Red",
    "LinkGridInPath_Green",
    "LinkGridInPath_Blue",
    "LinkGridInPath_Yellow",
    "LinkGridInPath_Any",
    "LinkNum_Red",
    "LinkNum_Green",
    "LinkNum_Blue",
    "LinkNum_Yellow",
    "LinkNum_Any",
    "LinkPos_Red",
    "LinkPos_Green",
    "LinkPos_Blue",
    "LinkPos_Yellow",
    "LinkPos_Any",
    "CanMoveArrow",
    "FinalAttackEffect",
    "HPSlider",
    "BossHPSlider",
    "TrapHPSlider",
    "PlayerHPSlider",
    "Ghost",
    "GuideGhost", --
    "LinkageInfo",
    "LinkageNum", --TODO貌似没有用
    "SkillTips",
    "NormalDamage",
    "DeBuffDamage",
    "GuardDamage",
    "MissDamage",
    "CriticalDamage",
    "RecoverDamage",
    "RealDamage",
    "PickUpArrow",
    "Projectile",
    "HeadTrapRoundInfo",
    --region 新手引导
    "GuideFinger",
    "GuideLinkLine",
    "GuideSpot",
    "GuidePiece",
    --endregion
    "HeadStoryTips",
    "EditorInfo",
    "Preview",
    "Grid",
    "RenderBoard",
    "MonsterAreaOutLine",
    "MoveRangePro",
    "MoveRangeArrow",
    "MoveRangeGrid",
    "DeathArea",
    "WaringDeathArea",
    "TrapAurasArea", ---机关的光环
    ---剧情使用的Entity
    "CutscenePlayer",
    "CutsceneMonster",
    "TrapAreaOutline", ------
    "GridFake",
    "RenderBoardSplice",
    --
    "StuntMonster", -- 仅为表现存在的分身
    "etc"
}
_autoEnum("EntityConfigIDRender", EntityConfigIDRender)

local renderConfigIdDict = _G["EntityConfigIDRender"]
EntityConfigIDConstLength = table.count(EntityConfigIDConst)
for k, value in pairs(renderConfigIdDict) do
    renderConfigIdDict[k] = EntityConfigIDConstLength + value --仅渲染的实体的ConfigId值永远在EntityConfigIDConst之后
end
