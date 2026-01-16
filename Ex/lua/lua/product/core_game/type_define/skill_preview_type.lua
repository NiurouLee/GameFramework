----1 3 4 6 作为光灵的话是使用指令拼出来的
---@class SkillPreviewType
SkillPreviewType = {
    SkillPreviewTypeStart = 0,
    Instruction = 0, --指令
    Scope = 1, ---按照技能范围
    Tips = 2, ---显示Tips
    ConvertElement = 3, --转色预览
    ActorDamage = 4, --单体伤害预览
    SupportAddBuff = 6, ---辅助类大招
    ScopeAndTips = 9, --既要技能范围又要显示Tips 怪物使用
    ScopeWithCasterPos = 14, ---以技能发起者坐标为中心坐标 怪物用
    ScopeWithCasterPosAndTips = 15, ---既要14类型的范围又要显示Tips 怪物用
    TrapActiveSkill = 16, ---机关选择释放主动技 弹出技能选择界面(风船)
    TrapDesc = 17, ---机关的固定说明
    AddHPChainSkill = 18, ---加血类型的连锁技
    ReplaceOtherSkillScopeAndTips = 19, --- 使用参数中填写的技能做技能预览 既要技能范围又要显示Tips
    TrapScopeAndTips = 20, ---机关的既要技能范围又要显示Tips，和9的区别是按钮颜色
    ScopeSingleChainSkill = 21, ---范围内打单体的连锁技 显示范围并且显示狙击图标
    ScopeSingleChainSkillInScope54 = 22, ---21号类型针对 54号范围的特殊处理版本
    ScopeAndEffectScope = 23, ---技能范围和技能效果范围合并显示逻辑 暂时只有舒摩尔Pro用 暂时逻辑是 技能范围-制定技能效果范围一个圈 技能效果范围一个圈 技能效果范围内有红格子
    ScopeAndEffectScopeAndTips = 24, ---23+tips
    ScopeAndTipsAndMoveParam = 25, --既要技能范围又要显示Tips 怪物使用。9基础上使用参数中的范围做移动箭头显示
    ScopeSingleChainSkillWithParam = 26, ---范围内打单体的连锁技 显示范围并且显示狙击图标,使用配置的参数显示，而不是真实范围
    ScopeCanConfig = 27, ---可以配置的技能预览效果,怪物可用
    N15MonsterChessSp = 28, ---N15怪物使用预览，包含提前计算怪物目标格子，在目标格子上显示波点模型，显示范围和tips，被攻击目标显示准星特效
    N15MonsterInstruction = 29, ---N15敌方棋子使用，参数就是cfg_active_skill_preview中的id　
    ScopeSilverGrid = 30, ---用格子材质动画的银色表示技能范围
    ScopeAndTipsAndArrowWithMoveParam = 31, --技能范围、技能Tips、可移动箭头；可移动范围的配置为中心点的偏移
    SkillEffect191InChain = 32, ---191专属，策划希望使用技能效果实现
    PetTrapMoveArrow = 33, ---201专属，策划希望使用技能效果实现
    N29DrillerMoveAttack = 34, ---N29Boss钻探者 专属预览 范围的attackRange用于显示移动路径，wholeRange显示范围
    TeleportRangeAndDamageRange = 35, ---skillPreviewParam中配置箭头范围，在箭头范围基础上每个位置计算攻击范围（使用配置的技能id来计算范围），显示tips
    SupportAddBuffWithCastCheck = 36, ---辅助类大招 附带主动技可释放检查（主要是最大血量检查）
    Pet1502051Chain = 37, --SP白兰连锁技专属，提前计算路线上的怪物/怪物和指定机关，修正连锁技技能ID进行预览
    SkillPreviewTypeEnd = 999
}
_enum("SkillPreviewType", SkillPreviewType)
