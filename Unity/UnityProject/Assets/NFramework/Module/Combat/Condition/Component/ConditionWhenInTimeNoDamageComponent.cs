using System;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.TimerModule;

namespace NFramework.Module.Combat
{
    public class ConditionWhenInTimeNoDamageComponent : Entity, IAwakeSystem<long>, IDestroySystem
    {
        public long time;
        private long noDamageTime;
        public void Awake(long a)
        {
            time = a;
            parent.GetParent<Combat>().ListenActionPoint(ActionPointType.PostReceiveDamage, WhenReceiveDamage);
        }

        public void Destroy()
        {
            Framework.Instance.GetModule<TimerM>().RemoveTimer(noDamageTime);
            parent.GetParent<Combat>().UnListenActionPoint(ActionPointType.PostReceiveDamage, WhenReceiveDamage);
        }

        public void StartListen(Action whenNoDamageInTimeCallback)
        {
            noDamageTime = Framework.Instance.GetModule<TimerM>().NewOnceTimer(time, whenNoDamageInTimeCallback);
        }

        private void WhenReceiveDamage(Entity combatAction)
        {
            Framework.Instance.GetModule<TimerM>().RemoveTimer(noDamageTime);
        }


    }
}