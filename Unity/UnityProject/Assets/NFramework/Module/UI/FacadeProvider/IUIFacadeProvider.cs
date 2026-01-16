using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public interface IUIFacadeProvider
    {
        public UIFacade Alloc<T>() where T : View;
        public Promise<UIFacade>.Deferred AllocAsync<T>() where T : View;
        public Promise<UIFacade>.Deferred AllocAsync(string inViewID);
        public void Free(UIFacade inUIFacade);
        public void Destroy();
    }
}