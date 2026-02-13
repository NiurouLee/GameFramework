using NFramework.Core.Live;
using NFramework.Module.EntityModule;

namespace NFramework.Module
{
    public class FrameworkModule : Entity, IAwakeSystem, IDestroySystem
    {
        public virtual void Awake()
        {
            
        }

        public virtual void Destroy()
        {
        }

    }
}