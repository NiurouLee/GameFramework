using NFramework.Module.EntityModule;
using UnityEngine;

namespace NFramework.Module.Combat
{
    /// <summary>
    /// 施法组件
    /// </summary>
    public class SpellSkillComponent : Entity
    {
        public CombatEntity Combat => GetParent<CombatEntity>();

        /// <summary>
        /// 预览技能
        /// </summary>
        /// <param name="spellSkill"></param>
        public void Spell(Ability spellSkill)
        {
            if (Combat.SpellingSkillExecution != null)
            {
                return;
            }
            if (Combat.SpellSkillActionAbility.TryMakeAction(out var spellAction))
            {
                spellAction.SkillAbility = spellSkill;
                spellAction.SpellSkill();
            }
        }

        public void SpellWithTarget(Ability spellSkill, CombatEntity target)
        {
            if (Combat.SpellingSkillExecution != null)
            {
                return;
            }
            spellSkill.Owner.TransformComponent.Rotation = Quaternion.LookRotation(target.TransformComponent.Position - spellSkill.Owner.TransformComponent.Position);
            if (Combat.SpellSkillActionAbility.TryMakeAction(out var spellSkillAction))
            {
                spellSkillAction.SkillAbility = spellSkill;
                spellSkillAction.InputTarget = target;
                spellSkillAction.InputDirection = spellSkill.Owner.TransformComponent.Rotation.eulerAngles.y;
                spellSkillAction.SpellSkill();
            }
        }

        public void SpellWithPoint(Ability spellSKill, Vector3 point)
        {
            if (Combat.SpellingSkillExecution != null) return;
            spellSKill.Owner.TransformComponent.Rotation = Quaternion.LookRotation(point - spellSKill.Owner.TransformComponent.Position);
            if (Combat.SpellSkillActionAbility.TryMakeAction(out var spellSkillAction))
            {
                spellSkillAction.SkillAbility = spellSKill;
                spellSkillAction.InputPoint = point;
                spellSkillAction.InputDirection = spellSKill.Owner.TransformComponent.Rotation.eulerAngles.y;
                spellSkillAction.SpellSkill();
            }
        }
    }
}