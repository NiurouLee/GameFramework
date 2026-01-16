using NFramework.Core.Collections;
using Proto.Promises;
using UnityEngine;

namespace NFramework.Module.ResModule
{
    /// <summary>
    /// 资源加载记录,这一层会cache count,引用计数
    /// </summary>
    public class ResLoadRecords : BaseRecordsSet<ResHandler>, IResLoader
    {
        public void Free<T>(T inObj) where T : Object
        {
            throw new System.NotImplementedException();
        }

        public T Load<T>(string inAssetID) where T : Object
        {
            throw new System.NotImplementedException();
        }

        public Promise<T> LoadAsync<T>(string inAssetID) where T : Object
        {
            throw new System.NotImplementedException();
        }

    }
}
