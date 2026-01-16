using NFramework.Module.EntityModule;
using NFramework.Core.ILiveing;

namespace NFramework.Module.Combat
{
    public class AbilityEffectDamageBloodSuckComponent : Entity, IAwakeSystem, IDestroySystem
    {
        public Combat Owner => GetParent<AbilityEffect>().Owner;
        public void Awake()
        {
            Owner.DamageActionAbility.AddComponent<DamageBloodSuckComponent>();
        }

        public void Destroy()
        {
            var component = Owner.DamageActionAbility.GetComponent<DamageBloodSuckComponent>();
            if (component != null)
            {
                component.Dispose();
            }
        }
    }
}