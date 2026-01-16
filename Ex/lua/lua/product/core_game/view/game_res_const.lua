---@class GameResourceConst
GameResourceConst = {
    --取情报销毁特效
    BookEffect = 338,
    --新手引导弱引导连线
    GuideWeakPath = 446,
    --region 怪物出场特效
    MonsterAppearEffMultiBodyArea = {370, 371, 372, 373}, --eff_ruchang_boss_blue--eff_ruchang_boss_red--eff_ruchang_boss_green--eff_ruchang_boss_yellow
    MonsterAppearEffSingleBodyArea = {319, 320, 321, 322}, --eff_ruchang_bule_M--eff_ruchang_red_M--eff_ruchang_green_M--eff_ruchang_yellow_M
    PetAppearEff = {1322, 1323, 1324, 1325}, --eff_ruchang_blue--eff_ruchang_red--eff_ruchang_green--eff_ruchang_yellow
    --endregion
    EffLinkLine2Exit = 319, --连接到出口的特效
    --region 入场特效
    EffRuchangKaichang = 325, --eff_ruchang_kaichang
    EffRuchangGeziglow = 326, --eff_ruchang_geziglow
    EffRuchuangPetBao = 327, --eff_ruchuang_pet_bao
    EffRuchuangHeti = 328, --eff_ruchuang_heti
    EffRuchangActorpoint = "eff_ruchang_actorpoint", --入场运镜宝宝挂点
    AnimRuchangCameratempLen = 3000, --入场运镜主相机动画阶段1时长ms
    EffRuchangBlackboard = 1611, --eff_ruchang_blackboard
    EffBoardShowLine = 1776, --gezi_line
    BrillantLine = "gezi_wangge.prefab", ---华丽效果下常驻的线条
    EnterFaceAnimCfgID = 3001,
    ---入场人物的表情

    -----------------------战棋-----------------------
    ChessPet_CanAction_SingleGridEffectID = 3481,---棋子未行动特效，给单格怪使用
    ChessPet_CanAction_MultiGridEffectID = 3482,---棋子未行动特效，给多格怪使用

    ChessPet_CanAction_Selected_SingleGridEffectID = 3483,---棋子未行动特效，选中状态，给单格怪使用
    ChessPet_CanAction_Selected_MultiGridEffectID = 3484,---棋子未行动特效，选中状态，给多格怪使用

    ChessPet_MoveRange_EffectID = 3478,---移动范围上挂的蓝色格子特效

    ChessPet_AttackRange_EffectID = 3479,---攻击范围上挂的白色格子特效

    ChessPet_AttackTarget_EffectID = 3480,---可攻击目标脚下红色特效
	
    ChessPet_RecoverRange_EffectID = 34800,---治疗范围上挂的绿色格子特效

    -----------------------------------------------------
    PrismEffectID = {62101, 62102, 62103, 62104, 62105},	--十字棱镜的特效
    PrismEffectName = {"gezi_lingjing_blue_", "gezi_lingjing_red_", "gezi_lingjing_green_", "gezi_lingjing_yellow_", "gezi_lingjing_any_"},	--十字棱镜的特效
	
    --endregion
    End = 99999
}
_enum("GameResourceConst", GameResourceConst)

---@class GameCacheResGroup
_class("GameCacheResGroup", Object)
GameCacheResGroup = GameCacheResGroup
function GameCacheResGroup:Constructor(t)
    self.EffectTable = {}
    --key 特效ID，value缓存数量
    self.EffectTable[GameResourceConst.BookEffect] = 1

    for _, eff in ipairs(GameResourceConst.MonsterAppearEffMultiBodyArea) do
        self.EffectTable[eff] = 2
    end
    for _, eff in ipairs(GameResourceConst.MonsterAppearEffSingleBodyArea) do
        self.EffectTable[eff] = 2
    end
    --self.EffectTable[GameResourceConst.EffRuchangKaichang] = 1
    --self.EffectTable[GameResourceConst.EffRuchangGeziglow] = 1
    --self.EffectTable[GameResourceConst.EffRuchuangPetBao] = 1
    --self.EffectTable[GameResourceConst.EffRuchuangHeti] = 1
    self.EffectTable[GameResourceConst.EffRuchangBlackboard] = 1
end
