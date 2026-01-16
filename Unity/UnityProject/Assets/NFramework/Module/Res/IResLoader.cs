using System;
using Proto.Promises;

namespace NFramework.Module.ResModule
{
    public interface IResLoader
    {
        public T Load<T>(string inAssetID) where T : UnityEngine.Object;
        public Promise<T> LoadAsync<T>(string inAssetID) where T : UnityEngine.Object;
        public void Free<T>(T inObj) where T : UnityEngine.Object;
    }

    public interface IResHandlerProvider
    {
        public ResHandler load<T>(string inAssetID);
        public ResHandler LoadAsync<T>(string inAssetID);
        public void FreeResHandler(ResHandler inResHandler);
    }

}