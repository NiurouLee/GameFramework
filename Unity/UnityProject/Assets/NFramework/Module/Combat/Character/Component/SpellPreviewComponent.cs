using NFramework.Core.Live;
using NFramework.Module.Combat;
using NFramework.Module.EntityModule;
using UnityEngine;

namespace NFramework.Module.Combat
{
    public class SpellPreviewComponent : Entity, IUpdateSystem
    {
        public CombatEntity OwnerEntity => GetParent<CombatEntity>();
        public SkillComponent SkillComponent => OwnerEntity.GetComponent<SkillComponent>();
        private bool Previewing { get; set; }
        private Ability PreviewingSkill { get; set; }

        public void Update(float deltaTime)
        {
            var skillComponent = OwnerEntity.GetComponent<SkillComponent>();
            if(Input.GetKeyDown(KeyCode.Q))
            {
                c
            }
        }
    }
}