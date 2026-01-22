using Proto.Promises;
using NFramework.Module.ResModule;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// uiFacade 提供者
    /// </summary>
    public class UIFacadeProviderDynamic : ViewComponent, IUIFacadeProvider
    {
        private IResLoader m_ResLoader;

        public override void Awake(View inView)
        {
            base.Awake(inView);
            m_ResLoader = ViewUtils.CheckAndAdd<ViewResLoadComponent>(inView);
        }

        public UIFacade Alloc<T>() where T : View
        {
            var viewConfig = this.GetM<UIM>().GetViewConfig<T>();
            var viewID = viewConfig.ID;
            return this.Alloc(viewID);
        }

        public UIFacade Alloc(string inViewID)
        {
            var viewConfig = this.GetM<UIM>().GetViewConfig(inViewID);
            var assetId = viewConfig.AssetID;
            var go = this.m_ResLoader.Load<GameObject>(assetId);
            var goIns = Object.Instantiate(go);
            return goIns.GetComponent<UIFacade>();
        }

        public Promise<UIFacade>.Deferred AllocAsync<T>() where T : View
        {
            var viewConfig = this.GetM<UIM>().GetViewConfig<T>();
            var viewId = viewConfig.ID;
            var deferred = this.AllocAsync(viewId);
            return deferred;
        }

        public Promise<UIFacade>.Deferred AllocAsync(string inViewID)
        {
            var viewConfig = this.GetM<UIM>().GetViewConfig(inViewID);
            var assetId = viewConfig.AssetID;
            var deferred = Promise<UIFacade>.NewDeferred();
            this.InstantiateAsync(assetId, deferred);
            return deferred;
        }

        private async void InstantiateAsync(string inAssetID, Promise<UIFacade>.Deferred inDeferred)
        {
            this.View.AddPromise(inDeferred);
            var go = await this.m_ResLoader.LoadAsync<GameObject>(inAssetID);
            var goIns = Object.Instantiate(go);
            inDeferred.Resolve(goIns.GetComponent<UIFacade>());
        }

        public void Destroy()
        {
        }

        public void Free(UIFacade inUIFacade)
        {
        }
    }
}
