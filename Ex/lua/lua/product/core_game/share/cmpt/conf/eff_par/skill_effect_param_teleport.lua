--[[----------------------------------------------------------------
    2020-04-14 韩玉信添加
    SkillEffectParam_Teleport : 瞬移
--]] ----------------------------------------------------------------

----------------------------------------------------------------
require "skill_damage_effect_param"
require("skill_effect_param_base")
--- @class EnumSkillEffectParam_Teleport
local EnumSkillEffectParam_Teleport = {
    PickUp = 0,
    User = 1, ---自定义
    CrossFarest = 2, --以目标为中心十字最远处（用于类似于求国王蓄力位置）
    Forward = 3, --往前直到目标或板边
    UserPointArray = 4, --目标位置集合，选中第一个不是释放者的位置
    SkillRange_Far = 5, ---技能范围内距离玩家最远的目标（顺时针查找）
    SkillRange_Near = 6, ---技能范围内距离玩家最近的目标（顺时针查找）
    SkillScopePos = 7, --选择的技能范围
    TeleportTargetToCasterPos = 8, --移动目标到施法者坐标
    TeleportTargetToPickPos = 9, --瞬移目标到点选位置
    TeleportTargetToSquareRing = 10, ---按圈寻找一圈一圈
    TeleportExitBoard = 11, ---离场
    CurPosBeforeSkillRangeNearest = 12, ---技能范围内距离玩家最近的目标（顺时针查找），如果自己当前位置与目标的距离等于选出来最近的坐标，优先自己当前位置。6基础上改的
    SkillScopePosFirst = 13, --选择的技能范围中的第一个坐标
    TargetPos = 14, --瞬移到目标坐标
    UseTeleportAndSummonTrapLastResult = 15, --使用技能效果113的最后一个结果
    SkillScopeRandPos = 16, --技能范围内随机一个位置
    RoninKenshiStep = 17, --浪人剑客技能1，说明太复杂，注释写在SkillEffectCalc_Teleport里了
    NingKingJump = 18, --夜王二阶段技能2跃起使用，跳到玩家身边能释放爪击的位置
    TeleportMountForward = 19, --阿尔法：将贝塔撞向目标
    UseMountTeleportExtraPos = 20, --阿尔法：上面的瞬移完成后，若贝塔未动，则瞬移自己到贝塔周围一圈距离光灵较远的位置上
    CasterGridDirectionForward = 21, ---按boss的当前朝向击退，不左右摇摆
    TeleportPosByTargetPos = 22,--瞬移到目标面前。并且根据目标位置调整坐标。
    TeleportTargetToCasterPosValid = 23, --移动目标到施法者坐标(如果不可用，则一圈一圈找可用坐标)
    Boss2904001 = 24, ---黑化非莱克斯专属瞬移，根据玩家所在的为止，瞬移的方向和最大距离不同
    TeleportTargetToFirstPickPos = 25, --瞬移目标到第一个点选位置（模块技能瞬移队伍）
    TargetAroundNearestCaster = 26, --目标周围，距离施法者(单格)最近的格子。优先十字，再一圈内的X位置。一圈都没有再扩大一圈的十字
    TargetPosWithCasterBody = 27, --瞬移到目标坐标，14的多格施法者分支，考虑身形
    PickUpWithPath = 28, --瞬移到最后一个点选位置，并记录所有点选位置作为表现移动路径 --耶利亚
    TargetAroundTrap = 29, --目标周围1圈，指定机关的上面。如果在可以原地瞬移，如果没位置，可以不动
    TargetAroundCalcCurBodyAreaAndDirCanDiffusion = 30, --落点是优先中心点在玩家周围一圈，中心点不行就身形内一个点（落地时候面朝玩家）。周围一圈都被占满的话就往外扩圈找合法位置，还是落地的时候面朝玩家。需要计算角度
    TrunToTargetOnSite = 31, --原地转向朝目标，多格有身形不变中心点变的需求
    TeleportWithScopeAndTrunToTarget = 32, --瞬移后转向朝目标，参数带范围参数，内外，随机位置，朝向。
    FourHorsemenApproachPlayer = 33, --四骑士接近玩家的传送
    FourHorsemenAvoidPlayer = 34, --四骑士远离玩家的传送
    BossDriller = 35, --N29Boss 钻探者专属 召唤平台怪前调整朝向及位置(朝向场景中心，如果本身在中心则朝向光灵，如果在角落，则需要向旁边移动一格)
    HostOriginalPosSquareRing = 36, --同10，按圈寻点，中心位置使用宿主位移的起始位置，若无记录，则使用本身的位置
    NightKingTeleportRecordCalcState = 37, --夜王3阶段 突进 计算目标点时记录计算阶段（正常情况、原目标点有阻挡等），用于后续伤害修改范围
    NightKingDoubleCrossTeleport = 38, --夜王3阶段 米字方向上突进到玩家身前，如果有阻挡，则以原目标点为中心逆时针逐圈找新的合法点
    NightKingTeleportWithPath = 39, --夜王3阶段 瞬移到目标周围十字格中离boss（如果有机关，则是最后一个机关）最近的点，并记录所有指定机关位置作为表现移动路径
    TargetTeleportSelectPos = 40, --目标位移到指定坐标，如果被阻挡则在周围一圈中寻找距离原本位置最近的点
    PickUpAndSetDir = 41, --PickUp 加 设置朝向
    Boss2905701Move = 42, --在指定ID的机关BodyArea以内，寻找距离玩家【无视阻挡高定逻辑】
    Boss2905701BackToPos = 43, --传送回规定的坐标位置【无视阻挡高定逻辑】
    Boss2905701MovePlayerToTrap = 44, --将玩家移到指定机关之上（存在多个时随机处理）
    SkillRange_FarAndDir = 45, ---技能范围内距离玩家最远的坐标,并且设置朝向

}
_enum("EnumSkillEffectParam_Teleport", EnumSkillEffectParam_Teleport)
----------------------------------------------------------------
_class("SkillEffectParam_Teleport", SkillEffectParamBase)
---@class SkillEffectParam_Teleport: SkillEffectParamBase
SkillEffectParam_Teleport = SkillEffectParam_Teleport

function SkillEffectParam_Teleport:Constructor(t)
    ---@type EnumSkillEffectParam_Teleport
    self.m_nTeleportType = t.teleport or t.Teleport
    self.m_posUser = t.userPoint
    self.m_dirUser = t.userDir

    self.m_resetDirection = tonumber(t.resetDirection) == 1

    self._trapID = t.trapID or 0

    self._boss2904001CrossMaxLength = t.boss2904001CrossMaxLength
    self._boss2904001RotatedCrossMaxLength = t.boss2904001RotatedCrossMaxLength

    self._horsemenMonsterClassID = t.horsemenMonsterClassID
    self._bossNightKingPathTrapID = t.bossNightKingPathTrapID

    self._checkBlock  = t.checkBlock or 0   --是否检查阻挡，默认0不检测，无视阻挡传

    self._boss2905701MoveTrapID = t.boss2905701MoveTrapID

    self._boss2905701BackToPosX = t.boss2905701BackToPosX
    self._boss2905701BackToPosY = t.boss2905701BackToPosY

    self._boss2905701MovePlayerToTrapIDArray = t.boss2905701MovePlayerToTrapIDArray
end

function SkillEffectParam_Teleport:GetEffectType()
    return SkillEffectType.Teleport
end

function SkillEffectParam_Teleport:GetTeleportType()
    return self.m_nTeleportType
end

function SkillEffectParam_Teleport:GetUserPoint()
    return self.m_posUser
end

function SkillEffectParam_Teleport:GetUserDir()
    return self.m_dirUser
end

function SkillEffectParam_Teleport:IsResetDirection()
    return self.m_resetDirection
end

function SkillEffectParam_Teleport:GetTrapID()
    return self._trapID
end

function SkillEffectParam_Teleport:GetBoss2904001CrossMaxLength()
    return self._boss2904001CrossMaxLength
end

function SkillEffectParam_Teleport:GetBoss2904001RotatedCrossMaxLength()
    return self._boss2904001RotatedCrossMaxLength
end

function SkillEffectParam_Teleport:GetHorsemenMonsterClassID()
    return self._horsemenMonsterClassID
end
function SkillEffectParam_Teleport:GetBossNightKingPathTrapID()
    return self._bossNightKingPathTrapID
end

function SkillEffectParam_Teleport:GetCheckBlock()
    return self._checkBlock
end

function SkillEffectParam_Teleport:GetBoss2905701MoveTrapID()
    return self._boss2905701MoveTrapID
end

function SkillEffectParam_Teleport:GetBoss2905701BackToPos()
    Log.assert((self._boss2905701BackToPosX ~= nil) and (self._boss2905701BackToPosY ~= nil), "瞬移参数无效")
    return Vector2.new(self._boss2905701BackToPosX, self._boss2905701BackToPosY)
end

function SkillEffectParam_Teleport:GetBoss2905701MovePlayerToTrapIDArray()
    return self._boss2905701MovePlayerToTrapID
end
----------------------------------------------------------------
