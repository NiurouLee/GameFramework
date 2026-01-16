using System.Threading;
using NFramework.Module.EntityModule;
using NFramework.Module.TimerModule;

namespace NFramework.Module.Combat
{
    public class AddStatusActionAbility : Entity, IActionAbility
    {
        public bool Enable { get; set; }
        public Combat Owner => GetParent<Combat>();
        public bool TryMakeAction(out AddStatusAction action)
        {
            if (!Enable)
            {
                action = null;
            }
            else
            {
                action = Owner.AddChild<AddStatusAction>();
                action.ActionAbility = this;
                action.Creator = Owner;
            }
            return Enable;
        }
    }

    public class AddStatusAction : Entity, IActionExecution
    {
        public Entity SourceAbility { get; set; }
        public Entity ActionAbility { get; set; }
        public EffectAssignAction SourceAssignAction { get; set; }
        public Combat Creator { get; set; }
        public Combat Target { get; set; }

        public void FinishAction()
        {
            Dispose();
        }

        public void PreProcess()
        {

        }

        public void ApplyStatus()
        {
            AddStatusEffect addStatusEffect = (AddStatusEffect)SourceAssignAction.AbilityEffect.effect;
            StatusConfigObject statusConfigObject = addStatusEffect.StatusConfigObject;
            StatusAbility status = null;
            if (!statusConfigObject.CanStack)
            {
                if (Target.HasStatus(statusConfigObject.Id))
                {
                    status = Target.GetStatus(statusConfigObject.Id);
                    var statusLifeTimer = status.GetComponent<StatusLifeTimeComponent>().LifeTimer;
                    Framework.Instance.GetModule<TimerM>().RestTimer(statusLifeTimer);
                    return;
                }
            }
            status = Target.AttachStatus(statusConfigObject.Id);
            status.Creator = Creator;
            status.GetComponent<AbilityLevelComponent>().Level = SourceAbility.GetComponent<AbilityLevelComponent>().Level;
            status.duration = (int)addStatusEffect.Duration;

            status.SetParams(addStatusEffect.ParamsDict);
            status.AddComponent<StatusLifeTimeComponent>();
            status.ActivateAbility();
            PostProcess();
            FinishAction();

        }

        public void PostProcess()
        {
            Creator.TriggerActionPoint(ActionPointType.PostGiveStatus, this);
            Target.TriggerActionPoint(ActionPointType.PostReceiveStatus, this);
        }

    }

}
