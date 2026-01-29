using NFramework.Module.EntityModule;
using NFramework.Core.Live;
using UnityEngine;

namespace NFramework.Module.Combat
{
    /// <summary>
    /// 预览释放技能组件
    /// </summary>
    public class SpellSkillActionAbility : Entity, IActionAbility
    {
        public CombatEntity Owner => GetParent<CombatEntity>();

        /// <summary>
        /// 构造一个预览Action
        /// </summary>
        /// <param name="action"></param>
        /// <returns></returns>
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

    /// <summary>
    /// 预览行为
    /// </summary>
    public class SpellSkillAction : Entity, IActionExecution, IUpdateSystem
    {
        public Ability SkillAbility { get; set; }
        public SkillExecution SkillExecution { get; set; }
        public CombatEntity InputTarget { get; set; }
        public Vector3 InputPoint;
        public float InputDirection;
        public Entity ActionAbility { get; set; }
        public EffectAssignAction SourceAssignAction { get; set; }
        public CombatEntity Creator { get; set; }
        public CombatEntity Target { get; set; }

        public void FinishAction()
        {
            Dispose();
        }

        /// <summary>
        /// 预览前处理
        /// </summary>
        private void PreProcess()
        {
            Creator.TriggerActionPoint(ActionPointType.PreSpell, this);
        }
        /// <summary>
        /// 开始预览
        /// </summary>
        /// <param name="actionOccupy"></param>
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