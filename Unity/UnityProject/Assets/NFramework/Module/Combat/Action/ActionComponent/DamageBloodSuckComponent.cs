using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;

namespace NFramework.Module.Combat
{

    public class DamageBloodSuckComponent : Entity, IAwakeSystem, IDestroySystem
    {
        public Combat Owner => GetParent<Combat>();
        public void Awake()
        {
            Owner.ListenActionPoint(ActionPointType.PostCauseDamage, OnCauseDamage);
        }

        public void Destroy()
        {
            Owner.UnListenActionPoint(ActionPointType.PostCauseDamage, OnCauseDamage);
        }

        public void OnCauseDamage(Entity action)
        {
            DamageAction damageAction = (DamageAction)action;
            float value = damageAction.DamageValue * 0.2f;
            if (Owner.CureActionAbility.TryMakeAction(out var cureAction))
            {
                cureAction.Creator = Owner;
                cureAction.Target = Owner;
                cureAction.CureValue = (int)value;
                cureAction.SourceAssignAction = null;
                cureAction.ApplyCure();
            }
        }

    }

}