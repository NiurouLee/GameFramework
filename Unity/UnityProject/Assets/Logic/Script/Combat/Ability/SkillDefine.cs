namespace Logic
{
    using System;
    using System.Collections.Generic;
    using Sirenix.OdinInspector;

    [LabelText("技能类型")]
    public enum SkillSpellType
    {
        [LabelText("主动技能")]
        Initiative,

        [LabelText("被动技能")]
        Passive,
    }


    [LabelText("目标选取类型")]
    public enum SkillTargetSelectType
    {
        [LabelText("手动指定")]
        PlayerSelect,
        [LabelText("碰撞检测")]
        CollisionSelect,
        [LabelText("条件指定")]
        ConditionSelect,
        [LabelText("自定义")]
        Custom,
    }

    [LabelText("技能目标阵营")]
    public enum SkillEffectTargetType
    {
        [LabelText("自身")]
        Self = 0,
        [LabelText("己方")]
        SelfTeam = 1,
        [LabelText("敌方")]
        EnemyTeam = 2,
    }

    [LabelText("作用对象")]
    public enum AddSkillEffectTargetType
    {
        [LabelText("技能目标")]
        SkillTarget = 0,
        [LabelText("附身对象")]
        AttachTarget = 1,
        [LabelText("自身")]
        self = 2,
        [LabelText("其他")]
        other = 3
    }

    [LabelText("目标类型")]
    public enum SkillTargetType
    {
        [LabelText("单体检测")]
        Single = 0,

        [LabelText("多人检测")]
        Multiple = 1,
    }
    [LabelText("伤害类型")]
    public enum DamageType
    {
        [LabelText("物理伤害")]
        Physic = 0,
        [LabelText("魔法伤害")]
        Magic = 1,
        [LabelText("真实伤害")]
        Real = 2,
    }
    [LabelText("效果类型")]
    public enum SkillEffectType
    {

        [LabelText("添加效果")]
        None = 0,


    }





}