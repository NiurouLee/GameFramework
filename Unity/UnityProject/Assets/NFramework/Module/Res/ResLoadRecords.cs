using System.Collections.Generic;
using NFramework.Core.Collections;
using Proto.Promises;
using UnityEngine;

namespace NFramework.Module.ResModule
{
    /// <summary>
    /// 资源加载记录,这一层会cache count,引用计数
    /// </summary>
    public class ResLoadRecords : BaseRecordMap<string, ResHandler>, IResLoader
    {
        private Dictionary<object, ResHandler> _loadedMap;
        private Dictionary<string, ResHandler> _loadingMap;
        private Dictionary<string, int> _ResRefCount;
        public UnOrderMultiMapLink<string, ICancelable> _loadingPromises;
        public T Load<T>(string inAssetID) where T : Object
        {
            if (!CheckResID(inAssetID))
            {
                return null;
            }
            AddRef(inAssetID);
            if (this.TryGet(inAssetID, out var handler))
            {
                this._ResRefCount[inAssetID]++;
                return handler.AssetObject as T;
            }
            //先异步加载又同步加载的话 不能空转，这样加载资源的逻辑会泡不到，所以不能while(true)
            //yoo底层处理了。
            var handle = this.GetM<ResM>().Load<T>(inAssetID);
            if (handle.state == ResHandlerState.Loaded)
            {
                this._loadedMap.TryAdd(inAssetID, handle);
                return handle.AssetObject as T;
            }
            else
            {
                //todo:按理说不应该来到这里
                throw new System.Exception("load failed");
            }
            return null;
        }

        public Promise<T> LoadAsync<T>(string inAssetID) where T : Object
        {
            CheckResID(inAssetID);
            AddRef(inAssetID);
            var deferred = Promise.NewDeferred<T>();
            if (this.TryGet(inAssetID, out var handler))
            {
                deferred.Resolve(handler.AssetObject as T);
                return deferred.Promise;
            }
            if (this._loadingMap.TryGetValue(inAssetID, out var loadingHandler))
            {
                this._loadingPromises.Add(inAssetID, deferred);
                return deferred.Promise;
            }
            //从未加载过
            else
            {
                var loadHandler = this.GetM<ResM>().LoadAsync<T>(inAssetID);
                this._loadingMap.Add(inAssetID, loadHandler);
                this._loadingPromises.Add(inAssetID, deferred);
                loadHandler.OnComplete += callback;
                return deferred.Promise;
            }

            void callback(ResHandler inHandler)
            {
                this.onHandleComplete<T>(inHandler);
            }
        }

        private void onHandleComplete<T>(ResHandler inHandler) where T : Object
        {
            if (inHandler.state == ResHandlerState.Loaded)
            {
                this.TryAdd(inHandler.assetID, inHandler);
                this._loadedMap.Add(inHandler.AssetObject, inHandler);
                var link = this._loadingPromises[inHandler.assetID];
                if (link.Count > 0)
                {
                    var first = link.First;
                    while (first != null)
                    {
                        var deferred = (Promise<T>.Deferred)first.Value;
                        deferred.Resolve(inHandler.AssetObject as T);
                        first = first.Next;
                    }
                }
                this._loadingPromises.RemoveAll(inHandler.assetID);
                this._loadingMap.Remove(inHandler.assetID);
            }
        }

        private bool CheckResID(string inAssetID)
        {
            if (this._loadedMap.ContainsKey(inAssetID))
            {
                return true;
            }
            if (this._loadingMap.ContainsKey(inAssetID))
            {
                return true;
            }
            if (this._ResRefCount.ContainsKey(inAssetID))
            {
                return true;
            }
            if (string.IsNullOrEmpty(inAssetID))
            {
                return false;
            }
            if (!this.GetM<ResM>().HasResID(inAssetID))
            {
                return false;
            }
            return true;
        }

        private void AddRef(string inAssetID)
        {
            if (this._ResRefCount.TryGetValue(inAssetID, out var refCount) && refCount > 0)
            {
                refCount++;
            }
            else
            {
                this._ResRefCount[inAssetID] = 1;
            }
        }
        private void RemoveRef(string inAssetID)
        {
            if (this._ResRefCount.TryGetValue(inAssetID, out var refCount) && refCount > 0)
            {
                refCount--;
                if (refCount == 0)
                {
                    var handler = this._loadingMap[inAssetID];
                    this._loadingMap.Remove(inAssetID);
                    this._loadingPromises.RemoveAll(inAssetID);
                    this._ResRefCount.Remove(inAssetID);
                    this.TryRemove(inAssetID);
                    this.GetM<ResM>().Free(handler);
                }
            }
        }


        public void Free(string inAssetID)
        {
            foreach (var handler in this._loadedMap.Values)
            {
                if (handler.assetID == inAssetID)
                {
                    this.RemoveRef(inAssetID);
                }
            }
        }

        public void Free<T>(T inObj) where T : UnityEngine.Object
        {
            if (inObj == null)
            {
                this.Error?.Print("inObj is null");
                return;
            }
            foreach (var handler in this._loadedMap.Values)
            {
                if (handler.AssetObject == inObj)
                {
                    this.RemoveRef(handler.assetID);
                    break;
                }
            }
        }
    }
}