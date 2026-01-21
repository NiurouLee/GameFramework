using System;
using System.Collections.Generic;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public partial class UIM : FrameworkModule
    {
        public ViewConfigServices ConfigServices { get; private set; }

        /// <summary>
        /// 初始化ViewConfig绑定关系（手动指定）
        /// </summary>
        public void AwakeTypeCfg(List<Tuple<Type, string, ViewConfig>> inCfgList)
        {
            this.ConfigServices = new ViewConfigServices();
            foreach (var item in inCfgList)
            {
                this.ConfigServices.AddViewConfig(item.Item1, item.Item2, item.Item3);
            }
        }

        /// <summary>
        /// 自动初始化ViewConfig绑定关系（从JSON加载并使用ViewTypeRegistry匹配View类型）
        /// </summary>
        public void AwakeTypeCfgAuto()
        {
            this.ConfigServices = new ViewConfigServices();

            // 初始化ViewConfigReader
            ViewConfigReader.Initialize();

            // 获取所有ViewConfig
            var configMap = ViewConfigReader.GetAllViewConfigs();

            // 建立绑定关系：ViewConfig.ID (脚本名称) -> View类型 -> ViewConfig
            foreach (var kvp in configMap)
            {
                string configID = kvp.Key; // 这是脚本名称，比如 "GameUILoginView"
                ViewConfig config = kvp.Value;

                // 从ViewTypeRegistry获取View类型（从生成的静态字典中读取）
                Type viewType = ViewTypeRegistry.GetViewType(configID);
                if (viewType != null)
                {
                    this.ConfigServices.AddViewConfig(viewType, configID, config);
                }
                else
                {
                    UnityEngine.Debug.LogWarning($"未找到View类型: {configID}，请确保已生成ViewTypeRegistryAuto.Generated.cs文件");
                }
            }
        }

        public ViewConfig GetViewConfig<T>(T inView) where T : View
        {
            return this.ConfigServices.GetViewConfig(inView);
        }

        public ViewConfig GetViewConfig<T>() where T : View
        {
            return this.ConfigServices.GetViewConfig<T>();
        }

        public ViewConfig GetViewConfig(string inID)
        {
            return this.ConfigServices.GetViewConfig(inID);
        }

        public string GetViewID<T>(T inView) where T : View
        {
            return this.ConfigServices.GetViewConfig(inView).ID;
        }

        public string GetViewID<T>() where T : View
        {
            return this.ConfigServices.GetViewConfig<T>().ID;
        }

        public T CreateView<T>() where T : View, new()
        {
            return new T();
        }

        public View CreateView(ViewConfig inViewConfig)
        {
            var type = this.ConfigServices.GetViewType(inViewConfig.ID);
            if (type == null)
            {
                throw new Exception($"ViewConfig {inViewConfig.ID} not found");
            }

            return Activator.CreateInstance(type) as View;
        }

        public string MappingAssetID(string inAssetID)
        {
            return "UI/" + inAssetID;
        }
    }
}