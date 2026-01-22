
using NFramework.Core.Live;
using NFramework.Core.ObjectPool;
using NFramework.Module.EntityModule;

namespace NFramework.Module.UIModule
{
    public abstract class ViewComponent : UIObject, IFreeToPool, IAwakeSystem<View>, IDestroySystem
    {
        public View View { get; private set; }

        public virtual void Awake(View inView)
        {
            this.View = inView;
        }


        public void Destroy()
        {
            this.View = null;
        }

        public virtual void OnDestroy()
        {
        }

        public void Check(View inView)
        {
        }

        public void FreeToPool()
        {
            this.Destroy();
        }
    }
}