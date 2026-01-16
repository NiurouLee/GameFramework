using System;
using System.Collections.Generic;
using Google.FlatBuffers;
using Unity.Collections;

namespace NFramework.Module.Config.DataPipeline
{
    public class ConfigDataLoader
    {
        private static ConfigDataLoader _instance;
        private static readonly object _lock = new object();

        public static ConfigDataLoader Instance
        {
            get
            {
                if (_instance == null)
                {
                    lock (_lock)
                    {
                        _instance ??= new ConfigDataLoader();
                    }
                }
                return _instance;
            }
        }

        private IConfigDataProvider _dataProvider;
        private readonly Dictionary<string, object> _cachedConfigs = new Dictionary<string, object>();
        private bool _enableCache = true;

        private ConfigDataLoader() { }

        public void Initialize(IConfigDataProvider dataProvider, bool enableCache = true)
        {
            _dataProvider = dataProvider;
            _enableCache = enableCache;
            _dataProvider.Initialize();
        }

        public void Dispose()
        {
            _dataProvider?.Dispose();
            _dataProvider = null;
            _cachedConfigs.Clear();
        }

        public T LoadConfig<T>(string configType, string configId) where T : class, IFlatbufferObject, new()
        {
            if (_dataProvider == null)
                throw new InvalidOperationException("ConfigDataLoader not initialized");

            string cacheKey = $"{configType}.{configId}";

            if (_enableCache && _cachedConfigs.TryGetValue(cacheKey, out var cached))
                return cached as T;

            using var nativeData = _dataProvider.LoadBinaryData(configType, configId, Allocator.Temp);
            var config = new T();
            if (nativeData.Length == 0)
            {
                return config;
            }
            {
                var buffer = new ByteBuffer(nativeData.ToArray());
                if (config is IFlatbufferObject flatObj)
                {
                    flatObj.__init(buffer.GetInt(buffer.Position) + buffer.Position, buffer);

                    if (_enableCache)
                        _cachedConfigs[cacheKey] = config;

                    return config;
                }
            }
            return config;
        }



        public Dictionary<string, T> LoadAllConfigs<T>(string configType) where T : class, IFlatbufferObject, new()
        {
            if (_dataProvider == null)
                throw new InvalidOperationException("ConfigDataLoader not initialized");

            var result = new Dictionary<string, T>();
            var names = _dataProvider.GetAllConfigNames(configType);

            foreach (var name in names)
            {
                var config = LoadConfig<T>(configType, name);
                if (config != null)
                    result[name] = config;
            }

            return result;
        }

        public void ClearCache()
        {
            _cachedConfigs.Clear();
        }
    }
}