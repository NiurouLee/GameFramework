using NFramework.Module.ObjectPoolModule;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        public T CreateViewComponent<T>() where T : ViewComponent, new()
        {
            var component = GetFrameWorkModule<ObjectPoolM>().Alloc<T>();
            return component;
        }
    }
}