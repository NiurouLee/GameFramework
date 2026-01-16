--entity类型

---@class EntityType:Object
local EntityType = {
    Pet = 2,
    Monster = 3,
    Piece = 4,
    Skill = 5,
    LinkLine = 6,
    MoveRange = 7,
    AttackRange = 8,
    Board = 9,
    HPSlider = 10,
    MoveRangeOutline = 11,
    SkillRangeOutline = 12,
    PreviewConvertElement = 13,
    ActiveSkillSelectInfo = 14,
    WarningArea = 15,
    Trap = 16,
    SkillHolder= 17,
    PickUpArrow = 18,
    FinalAttackEffect = 19,
    GuardDamage = 21,
    RecoverDamage = 22,
    NormalDamage = 23,
    DeBuffDamage = 24,
    PetShadow = 25,
    MissDamage = 26,
    Team = 27,
    MonsterAreaOutLine = 28,
    Ghost = 29,
    CutsceneMonster = 30,
    CutscenePlayer = 31,---3D剧情相关
    ChessPet = 32,---战棋棋子
    TrapAreaOutline = 33, ---
    PersonaSkillHolder = 34,
    GuideGhost = 35,--
    PieceFake = 36,--假格子
	MAX = 999
}
_enum("EntityType", EntityType)
EntityType = EntityType

---@class EntityTypeHelper:Singleton
---@field GetInstance EntityTypeHelper
_class("EntityTypeHelper", Singleton)
EntityTypeHelper = EntityTypeHelper

function EntityTypeHelper:IsBulletTimeEffectEntity(entityType)
    if
        entityType == EntityType.Pet or entityType == EntityType.Monster or entityType == EntityType.Trap or
            entityType == EntityType.CutsceneMonster or
            entityType == EntityType.PetShadow
     then
        return true
    end
    return false
end

---检查是否需要材质动画，只支持部分Entity播材质动画
function EntityTypeHelper:NeedMaterialAnimation(entityType)
    if
        entityType == EntityType.Pet or entityType == EntityType.Monster or entityType == EntityType.PetShadow or
            entityType == EntityType.Ghost or
            entityType == EntityType.GuideGhost or
            entityType == EntityType.CutsceneMonster or entityType == EntityType.ChessPet
     then
        return true
    end

    return false
end
