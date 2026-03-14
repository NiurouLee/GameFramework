
using System;
using NFramework.Core.Live;
using NFramework.Module.EntityModule;

namespace NFramework.Module.ResModule
{
    public enum ResHandlerState
    {
        None,
        Loading,
        Loaded,
        Failed,
        Cancel,
        Destroy,
    }

    public class ResHandler : Entity, IAwakeSystem<string>, IDestroySystem
    {
        public string assetID;
        public event Action<ResHandler> OnComplete;
        public System.Object AssetObject { get; private set; }
        public ResHandlerState state { get; private set; }

        public void Awake(string inAssetID)
        {
            assetID = inAssetID;
            state = ResHandlerState.Loading;
        }

        public void SetResult(UnityEngine.Object inObj)
        {
            state = ResHandlerState.Loaded;
            this.AssetObject = inObj;
            OnComplete?.Invoke(this);
        }
        public void SetFailed(System.Object inObj)
        {
            state = ResHandlerState.Failed;
            this.AssetObject = inObj;
            OnComplete?.Invoke(this);
        }

        public void Cancel()
        {
            this.state = ResHandlerState.Cancel;

        }

        public void Destroy()
        {
        }
    }
}