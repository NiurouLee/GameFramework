using NFramework.Module.ResModule;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public class ViewResLoadComponent : ViewComponent
    {
        public ResLoadRecords ResLoadRecords { get; private set; }
    }

    public static class ViewResLoadComponentExtensions
    {
        public static T LoadRes<T>(this View inView, string inAssetID) where T : UnityEngine.Object
        {
            if (inView is Container container)
            {
                var loaderComponent = ViewComponentUtils.CheckAndAdd<ViewResLoadComponent>(container);
                return loaderComponent.ResLoadRecords.Load<T>(inAssetID);
            }

            var parent = inView.Parent;
            if (parent == null || parent == inView)
            {
                return null;
            }

            while (parent != null)
            {
                if (parent is Container containerP)
                {
                    return containerP.LoadRes<T>(inAssetID);
                }
                parent = parent.Parent;
            }
            return null;
        }
        public static Promise<T> LoadResAsync<T>(this Container inContainer, string inAssetID) where T : UnityEngine.Object
        {
            var component = ViewComponentUtils.CheckAndAdd<ViewResLoadComponent>(inContainer);
            return component.ResLoadRecords.LoadAsync<T>(inAssetID);
        }
        public static void FreeRes<T>(this Container inContainer, T inObj) where T : UnityEngine.Object
        {
            var component = ViewComponentUtils.CheckAndAdd<ViewResLoadComponent>(inContainer);
            component.ResLoadRecords.Free(inObj);
        }
    }
}

