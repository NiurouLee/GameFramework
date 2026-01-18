using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// ViewConfig运行时读取器，从JSON文件读取配置到字典中
    /// </summary>
    public static class ViewConfigReader
    {
        private static Dictionary<string, ViewConfig> s_ConfigMap;
        private static bool s_Initialized = false;

        /// <summary>
        /// 初始化，从JSON文件加载所有ViewConfig到字典中
        /// </summary>
        public static void Initialize()
        {
            if (s_Initialized) return;

            s_ConfigMap = new Dictionary<string, ViewConfig>();
            LoadFromJson();
            s_Initialized = true;
        }

        /// <summary>
        /// 根据配置ID获取ViewConfig
        /// </summary>
        public static ViewConfig GetViewConfig(string configID)
        {
            if (!s_Initialized)
            {
                Initialize();
            }

            if (s_ConfigMap != null && s_ConfigMap.TryGetValue(configID, out ViewConfig config))
            {
                return config;
            }

            return new ViewConfig();
        }

        /// <summary>
        /// 获取所有ViewConfig的字典
        /// </summary>
        public static Dictionary<string, ViewConfig> GetAllViewConfigs()
        {
            if (!s_Initialized)
            {
                Initialize();
            }

            return s_ConfigMap ?? new Dictionary<string, ViewConfig>();
        }

        /// <summary>
        /// 重新加载配置（用于运行时更新）
        /// </summary>
        public static void Reload()
        {
            s_Initialized = false;
            Initialize();
        }

        /// <summary>
        /// 从JSON文件加载配置
        /// </summary>
        private static void LoadFromJson()
        {
            string jsonPath = Path.Combine(Application.streamingAssetsPath, "ConfigData/UI/ViewConfigs.json");
            
            // 如果StreamingAssets中没有，尝试从Resources加载
            if (!File.Exists(jsonPath))
            {
                TextAsset jsonAsset = Resources.Load<TextAsset>("ConfigData/UI/ViewConfigs");
                if (jsonAsset != null)
                {
                    LoadFromJsonString(jsonAsset.text);
                    return;
                }
            }

            if (File.Exists(jsonPath))
            {
                try
                {
                    string json = File.ReadAllText(jsonPath);
                    LoadFromJsonString(json);
                }
                catch (System.Exception ex)
                {
                    Debug.LogError($"加载ViewConfigs.json失败: {ex.Message}");
                }
            }
        }

        /// <summary>
        /// 从JSON字符串加载配置
        /// </summary>
        private static void LoadFromJsonString(string json)
        {
            try
            {
                ViewConfigsContainer container = JsonUtility.FromJson<ViewConfigsContainer>(json);
                if (container != null && container.Configs != null)
                {
                    foreach (var data in container.Configs)
                    {
                        if (string.IsNullOrEmpty(data.ID)) continue;

                        ViewConfig config = new ViewConfig();
                        config.ID = data.ID;
                        config.AssetID = data.AssetID;
                        config.SetLayer(data.Layer);
                        config.SetWindow(data.IsWindow);
                        config.SetFixedLayer(data.IsFixedLayer);

                        s_ConfigMap[data.ID] = config;
                    }
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"解析ViewConfigs.json失败: {ex.Message}");
            }
        }

        [System.Serializable]
        private class ViewConfigData
        {
            public string ID;
            public string AssetID;
            public ushort Layer;
            public bool IsWindow;
            public bool IsFixedLayer;
        }

        [System.Serializable]
        private class ViewConfigsContainer
        {
            public List<ViewConfigData> Configs = new List<ViewConfigData>();
        }
    }
}
