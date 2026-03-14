using NFramework.Module.ResModule;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// 资源加载组件
    /// </summary>
    public class ViewResLoadComponent : ViewComponent, IResLoader
    {
        public ResLoadRecords ResLoadRecords { get; private set; }

        public override void Awake(View inView)
        {
            base.Awake(inView);
            this.ResLoadRecords = new ResLoadRecords();
        }

        private string MappingAssetID(string inAssetID)
        {
            return this.GetM<UIM>().MappingAssetID(inAssetID);
        }

        public T Load<T>(string inAssetID) where T : UnityEngine.Object
        {
            var assetID = this.MappingAssetID(inAssetID);
            return ResLoadRecords.Load<T>(assetID);
        }

        public Promise<T> LoadAsync<T>(string inAssetID) where T : UnityEngine.Object
        {
            var assetID = this.MappingAssetID(inAssetID);
            return ResLoadRecords.LoadAsync<T>(assetID);
        }

        public void Free<T>(T inObj) where T : UnityEngine.Object
        {
            ResLoadRecords.Free(inObj);
        }
        public void Free(string inAssetID)
        {
            ResLoadRecords.Free(inAssetID);
        }
    }


    public static class ViewResLoadComponentExtensions
    {
        public static T LoadRes<T>(this View inView, string inAssetID) where T : UnityEngine.Object
        {
            if (ViewUtils.GetContainer<Container>(inView, out var container))
            {
                var loaderComponent = ViewUtils.CheckAndAdd<ViewResLoadComponent>(container);
                return loaderComponent.Load<T>(inAssetID);
            }

            throw new System.Exception("view dont have container");
        }

        public static Promise<T> LoadResAsync<T>(this View inView, string inAssetID) where T : UnityEngine.Object
        {
            if (ViewUtils.GetContainer<Container>(inView, out var container))
            {
                var component = ViewUtils.CheckAndAdd<ViewResLoadComponent>(container);
                return component.LoadAsync<T>(inAssetID);
            }

            throw new System.Exception("view dont have container");
        }

        public static void FreeRes<T>(this View inView, T inObj) where T : UnityEngine.Object
        {
            if (ViewUtils.GetContainer<Container>(inView, out var container))
            {
                var component = ViewUtils.CheckAndAdd<ViewResLoadComponent>(container);
                component.Free(inObj);
            }

            throw new System.Exception("view dont have container");
        }
    }
}