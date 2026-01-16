using System;
using System.Collections.Generic;
using Unity.Collections;

namespace NFramework.Module.Config.DataPipeline
{
    public interface IConfigDataProvider : IDisposable
    {
        void Initialize();
        
        /// <summary>
        /// 加载二进制数据，返回NativeArray
        /// </summary>
        NativeArray<byte> LoadBinaryData(string configType, string configId, Allocator allocator);
        
        /// <summary>
        /// 获取指定类型的所有配置ID
        /// </summary>
        List<string> GetAllConfigNames(string configType);
    }
}