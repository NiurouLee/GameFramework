using System;
using System.Collections.Generic;
using Proto.Promises;
using UnityEngine;

namespace NFramework.Module.ResModule
{
    public class ResM : IFrameWorkModule
    {
        public Dictionary<string, string> AssetID2PathDic = new Dictionary<string, string>();

        public void AwakeAssetID2PathMap(List<Tuple<string, string>> inCfgList)
        {
            this.AssetID2PathDic = new Dictionary<string, string>();
            foreach (var item in inCfgList)
            {
                this.AssetID2PathDic.Add(item.Item1, item.Item2);
            }
        }

        public T Load<T>(string inAssetID) where T : UnityEngine.Object
        {
            if (this.AssetID2PathDic.TryGetValue(inAssetID, out var path))
            {
                return Resources.Load(path) as T;
            }
            return null;
        }

        public Promise<T> LoadAsync<T>(string inAssetID) where T : UnityEngine.Object
        {
            var deferred = Promise.NewDeferred<T>();
            var asyncOperation = Resources.LoadAsync<T>(inAssetID);
            asyncOperation.completed += (asyncOperation) =>
            {
                var assetOperation = asyncOperation as ResourceRequest;
                var result = assetOperation.asset as T;
                deferred.Resolve(result);
            };
            return deferred.Promise;
        }



        public Promise<T> LoadAsyncAndInstantiate<T>(string inAssetID) where T : UnityEngine.Object
        {
            var deferred = Promise.NewDeferred<T>();
            var asyncOperation = Resources.LoadAsync<T>(inAssetID);
            asyncOperation.completed += (asyncOperation) =>
               {
                   var assetOperation = asyncOperation as ResourceRequest;
                   var result = assetOperation.asset as T;
                   var _object = UnityEngine.Object.Instantiate(result);
                   deferred.Resolve(_object);
               };
            return deferred.Promise;
        }

    }

}

