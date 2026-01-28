using NFramework.Core.Live;
using NFramework.Module.Combat;
using NFramework.Module.EntityModule;

namespace Logic
{
    public partial class Ability : Entity,IAwakeSystem<AbilityConfigObject>
    {
        public CombatEntity OwnerEntity => GetParent<CombatEntity>();
        public Entity ParentEntity => parent;
        public AbilityConfig Config { get; set; }
        public AbilityConfigObject ConfigObject { get; set; }
        public bool Spelling { get; set; }
        public ExecutionConfigObject ExecutionObject { get; set; }
        public bool IsBuff => Config.Type == "Buff";
        public bool IsSKll => !IsBuff;

    }
}