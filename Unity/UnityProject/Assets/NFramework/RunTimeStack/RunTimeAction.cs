
using NFramework.NBehavior;

namespace NFramework.RunTime
{
    public abstract class RunTimeAction : Sequence
    {
        protected override void DoStart()
        {
            this.currentIndex = -1; ;
            Execute();
        }
        public abstract void Execute();

    }
}
