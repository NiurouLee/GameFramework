using System.Threading;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.TimerModule;

namespace NFramework.Module.Combat
{
    public class ExecutionEffectTimerTriggerComponent : Entity, IAwakeSystem, IDestroySystem
    {
        public long startTime;
        public long endTime;
        public long startTimer;
        public long endTimer;
        public void Awake()
        {
            if (this.startTime > 0)
            {
                this.startTimer = Framework.I.G<TimerM>().NewOnceTimer(startTime, GetParent<ExecutionEffect>().StartTriggerEffect);
            }
            else
            {
                GetParent<ExecutionEffect>().StartTriggerEffect();
            }
            if (endTime > 0)
            {
                endTimer = Framework.I.G<TimerM>().NewOnceTimer(endTime, GetParent<ExecutionEffect>().EndEffect);
            }
        }

        public void Destroy()
        {
            Framework.I.G<TimerM>().RemoveTimer(startTimer);
            Framework.I.G<TimerM>().RemoveTimer(endTimer);
        }
    }
}