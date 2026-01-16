
using NFramework.Core.ObjectPool;
using NFramework.Module.EntityModule;

namespace NFramework.Module.UIModule
{
    public abstract class ViewComponent : UIObject, IFreeToPool
    {
        public View View { get; private set; }
        public void Awake(View inView)
        {
            this.View = inView;
        }

        public virtual void Awake()
        {
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