using System.Numerics;
using Entitas;
using NFramework.Core.Live;

namespace Logic
{
    /// <summary>
    /// 能力单元体
    /// </summary>
    public class AbilityItem : Entity, IPosition, IAwakeSystem<IAbilityExecute>
    {
        public Ability AbilityEntity { get; private set; }
        public IAbilityExecute AbilityExecute { get; private set; }
        public ExecuteTriggerType ExecuteTriggerType { get; set; }
        public Vector3 LocalPosition { get; set; }
        public Vector3 Position { get; set; }
        public Quaternion Rotation { get; set; }
        public CombatEntity TargetEntity { get; set; }
        public CombatEntity OwnerEntity => AbilityEntity.OwnerEntity;
        public AbilityItemViewComponent ItemProxy { get; set; }


    }
}