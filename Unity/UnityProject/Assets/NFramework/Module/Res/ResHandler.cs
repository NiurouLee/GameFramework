
using System;

namespace NFramework.Module.ResModule
{
    public enum ResHandlerState
    {
        None,
        Loading,
        Loaded,
        Failed
    }

    public class ResHandler
    {
        public string assetID;
        public event Action<UnityEngine.Object> OnComplete;
        public ResHandlerState state { get; private set; }

        public void Awake(string inAssetID, Action<UnityEngine.Object> inOnComplete = null)
        {
            assetID = inAssetID;
            OnComplete += inOnComplete;
        }

        public void SetResult(UnityEngine.Object inObj)
        {
            state = ResHandlerState.Loaded;
            OnComplete?.Invoke(inObj);
        }

        public void SetFailed()
        {
            state = ResHandlerState.Failed;
            OnComplete?.Invoke(null);
        }

        public void Cancel()
        {

        }

        public void Dispose()
        { }

    }
}