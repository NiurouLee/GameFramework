using System.Collections.Generic;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.ResModule;

namespace NFramework.Module.Combat
{
    public class SkillComponent : Entity
    {
        public Combat Combat => GetParent<Combat>();
        public Dictionary<int, SkillAbility> skillDict = new Dictionary<int, SkillAbility>();
        public SkillAbility AttachSkill(int skillId)
        {
            SkillConfigObject skillConfigObject = Framework.I.G<ResM>().Load<SkillConfigObject>(string.Empty);
            if (skillConfigObject == null)
            {
                return null;
            }

            var skill = Combat.AttachAbility<SkillAbility>(skillConfigObject);
            if (!skillDict.ContainsKey(skill.SkillConfigObject.Id))
            {
                skillDict.Add(skill.SkillConfigObject.Id, skill);
            }
            return skill;
        }

        public SkillAbility GetSkill(int skillId)
        {
            if (skillDict.TryGetValue(skillId, out var skill))
            {
                return skill;
            }
            return null;
        }
    }
}