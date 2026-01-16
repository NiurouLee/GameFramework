using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.TimerModule;

namespace NFramework.Module.Combat
{
    public class AbilityItemLifeTimeComponent : Entity, IAwakeSystem<long>, IDestroySystem
    {
        public long lifeTimer;
        public void Awake(long p1)
        {
            lifeTimer = Framework.Instance.GetModule<TimerM>().NewOnceTimer(p1, this.Dispose);
        }


        public void Destroy()
        {
            Framework.Instance.GetModule<TimerM>().RemoveTimer(lifeTimer);
        }
    }
}