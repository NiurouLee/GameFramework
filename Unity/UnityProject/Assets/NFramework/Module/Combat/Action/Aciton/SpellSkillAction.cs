using NFramework.Module.EntityModule;
using NFramework.Core.ILiveing;
using UnityEngine;

namespace NFramework.Module.Combat
{
    public class SpellSkillActionAbility : Entity, IActionAbility
    {
        public Combat Owner => GetParent<Combat>();

        public bool TryMakeAction(out SpellSkillAction action)
        {
            if (!Enable)
            {
                action = null;
            }
            else
            {
                action = Owner.AddChild<SpellSkillAction>();
                action.ActionAbility = this;
                action.Creator = Owner;
            }
            return Enable;
        }
    }

    public class SpellSkillAction : Entity, IActionExecution, IUpdateSystem
    {
        public SkillAbility SkillAbility { get; set; }
        public SkillExecution SkillExecution { get; set; }
        public Combat InputTarget { get; set; }
        public Vector3 InputPoint;
        public float InputDirection;
        public Entity ActionAbility { get; set; }
        public EffectAssignAction SourceAssignAction { get; set; }
        public Combat Creator { get; set; }
        public Combat Target { get; set; }

        public void FinishAction()
        {
            Dispose();
        }

        private void PreProcess()
        {
            Creator.TriggerActionPoint(ActionPointType.PreSpell, this);
        }

        public void SpellSkill(bool actionOccupy = true)
        {
            PreProcess();
            SkillExecution = (SkillExecution)SkillAbility.CreateExecution();

            SkillExecution.ActionOccupy = actionOccupy;
            if (InputTarget != null)
            {
                SkillExecution.TargetList.Add(InputTarget);
            }
            SkillExecution.InputPoint = this.InputPoint;
            SkillExecution.InputDirection = InputDirection;
            SkillExecution.BeginExecute();
        }

        public void Update()
        {
            if (SkillExecution != null)
            {
                if (SkillExecution.IsDisposed)
                {
                    PostProcess();
                    FinishAction();
                }
            }
        }

        private void PostProcess()
        {
            Creator.TriggerActionPoint(ActionPointType.PostSpell, this);
        }

        public void Update(float deltaTime)
        {
            throw new System.NotImplementedException();
        }
    }
}