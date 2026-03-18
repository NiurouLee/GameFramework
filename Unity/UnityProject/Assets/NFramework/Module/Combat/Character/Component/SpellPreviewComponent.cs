using NFramework.Core.Live;
using NFramework.Module.Combat;
using NFramework.Module.EntityModule;
using UnityEngine;

namespace NFramework.Module.Combat
{
    /// <summary>
    /// 技能示范预览组件 
    /// </summary>
    public class SpellPreviewComponent : Entity, IUpdateSystem
    {
        public CombatEntity OwnerEntity => GetParent<CombatEntity>();
        public SkillComponent SkillComponent => OwnerEntity.GetComponent<SkillComponent>();
        private bool Previewing { get; set; }
        private Ability PreviewingSkill { get; set; }

        public void Update(float deltaTime)
        {
            var skillComponent = OwnerEntity.GetComponent<SkillComponent>();
            if (Input.GetKeyDown(KeyCode.Q))
            {
                Cursor.visible = false;
                var skillId = skillComponent.skillInputDict[KeyCode.Q];
                var skill = skillComponent.GetSkill(skillId);
                PreviewingSkill = skill;
                EnterPreview();
            }
            if (Input.GetKeyDown(KeyCode.W))
            {
                Cursor.visible = false;
                var skillId = skillComponent.skillInputDict[KeyCode.W];
                var skill = skillComponent.GetSkill(skillId);
                PreviewingSkill = skill;
                EnterPreview();
            }

            if (Input.GetKeyDown(KeyCode.E))
            {
                Cursor.visible = false;
                var skillId = skillComponent.skillInputDict[KeyCode.E];
                var skill = skillComponent.GetSkill(skillId);
                PreviewingSkill = skill;
                EnterPreview();
            }
            if (Input.GetKeyDown(KeyCode.R))
            {
                Cursor.visible = false;
                var skillId = skillComponent.skillInputDict[KeyCode.R];
                var skill = skillComponent.GetSkill(skillId);
                PreviewingSkill = skill;
                EnterPreview();
            }
        }
        public void EnterPreview()
        {
            CancelPreview();
            Previewing=true;
            var targetSelectType= SkillTargetSelectType.Custom;
            var AffectTargetType= SkillAffectTargetType.EnemyTeam;
            var skillId=PreviewingSkill.SkillConfigObject.Id;
            if(PreviewingSkill.SkillConfigObject.)
        }


    }
}