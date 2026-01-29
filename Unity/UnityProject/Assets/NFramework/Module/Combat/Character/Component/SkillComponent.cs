using System.Collections.Generic;
using NFramework.Core.Live;
using NFramework.Module.EntityModule;
using NFramework.Module.ResModule;

namespace NFramework.Module.Combat
{
    public class SkillComponent : Entity
    {
        public CombatEntity Combat => GetParent<CombatEntity>();
        public Dictionary<int, Ability> skillDict = new Dictionary<int, Ability>();
        public Ability AttachSkill(int skillId)
        {
            AbilityConfigObject skillConfigObject = NFROOT.I.G<ResM>().Load<AbilityConfigObject>(string.Empty);
            if (skillConfigObject == null)
            {
                return null;
            }

            var skill = Combat.AttachAbility<Ability>(skillConfigObject);
            if (!skillDict.ContainsKey(skill.SkillConfigObject.Id))
            {
                skillDict.Add(skill.SkillConfigObject.Id, skill);
            }
            return skill;
        }

        public Ability GetSkill(int skillId)
        {
            if (skillDict.TryGetValue(skillId, out var skill))
            {
                return skill;
            }
            return null;
        }
    }
}