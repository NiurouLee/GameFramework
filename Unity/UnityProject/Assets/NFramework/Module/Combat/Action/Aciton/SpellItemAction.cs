using NFramework.Module.EntityModule;

namespace NFramework.Module.Combat
{
    public class SpellItemActionAbility : Entity, IActionAbility
    {
        public bool Enable { get; set; }
        public Combat Owner => GetParent<Combat>();

        public bool TryMakeAction(out SpellItemAction action)
        {
            if (!Enable)
            {
                action = null;
            }
            else
            {
                action = Owner.AddChild<SpellItemAction>();
                action.ActionAbility = this;
                action.Creator = Owner;
            }
            return Enable;
        }
    }


    public class SpellItemAction : Entity, IActionExecution
    {
        public SpellItemActionAbility ItemAbility;
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
            Creator.TriggerActionPoint(ActionPointType.PreGiveItem, this);
            Target.TriggerActionPoint(ActionPointType.PreReceiveItem, this);
        }

        public void UseItem()
        {
            PreProcess();
            ItemAbility.GetComponent<AbilityEffectComponent>().TryAssignAllEffectToTarget(Target);
            PostProcess();
            FinishAction();
        }

        private void PostProcess()
        {
            Creator.TriggerActionPoint(ActionPointType.PostGiveItem, this);
            Target.TriggerActionPoint(ActionPointType.PostReceiveItem, this);
        }

    }
}