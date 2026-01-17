using Proto.Promises;
using NFramework.Module.ResModule;

namespace NFramework.Module.UIModule
{
    public interface IUIFacadeProviderDynamic
    {
        UIFacade Alloc<T>() where T : View;
        UIFacade Alloc(string inViewID);
        Promise<UIFacade>.Deferred AllocAsync<T>() where T : View;
        Promise<UIFacade> AllocAsync(string inViewID);
        void Destroy();
        void Free(UIFacade inUIFacade);
    }

    /// <summary>
    /// uiFacade 提供者
    /// </summary>
    public class UIFacadeProviderDynamic : IUIFacadeProvider, IUIFacadeProviderDynamic
    {
        private IResLoader m_ResLoader;

        public UIFacadeProviderDynamic(IResLoader inResLoader)
        {
            m_ResLoader = inResLoader;
        }

        public UIFacade Alloc<T>() where T : View
        {
            return null;
        }

        public Promise<UIFacade>.Deferred AllocAsync<T>() where T : View
        {
            return Promise<UIFacade>.NewDeferred();
        }

        public UIFacade Alloc(string inViewID)
        {
            return null;
        }

        public Promise<UIFacade> AllocAsync(string inViewID)
        {
            return Promise<UIFacade>.Resolved(null);
        }


        public void Free(UIFacade inUIFacade)
        {
        }

        public void Destroy()
        {
            throw new System.NotImplementedException();
        }

        Promise<UIFacade>.Deferred IUIFacadeProvider.AllocAsync(string inViewID)
        {
            throw new System.NotImplementedException();
        }
    }
}
