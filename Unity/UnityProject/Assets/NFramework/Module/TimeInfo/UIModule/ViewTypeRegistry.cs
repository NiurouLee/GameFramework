using System;
using System.Collections.Generic;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// View类型注册表，存储Type与ViewConfigID的映射关系
    /// 此类的数据由代码生成器自动填充
    /// </summary>
    public static class ViewTypeRegistry
    {
        private static Dictionary<Type, string> s_TypeToConfigIDMap;
        private static Dictionary<string, Type> s_ConfigIDToTypeMap;
        private static bool s_Initialized = false;

        /// <summary>
        /// 初始化，从生成的代码中加载映射关系
        /// </summary>
        private static void Initialize()
        {
            if (s_Initialized) return;

            s_TypeToConfigIDMap = new Dictionary<Type, string>();
            s_ConfigIDToTypeMap = new Dictionary<string, Type>();

            // 从生成的ViewTypeRegistryAuto中加载映射关系
            LoadFromGeneratedCode();

            s_Initialized = true;
        }

        /// <summary>
        /// 从生成的代码中加载映射关系
        /// </summary>
        private static void LoadFromGeneratedCode()
        {
            // 直接访问ViewTypeRegistryAuto的静态字典
            // 生成的代码会在静态字段初始化时填充字典
            if (ViewTypeRegistryAuto.TypeToConfigIDMap != null)
            {
                foreach (var kvp in ViewTypeRegistryAuto.TypeToConfigIDMap)
                {
                    s_TypeToConfigIDMap[kvp.Key] = kvp.Value;
                    s_ConfigIDToTypeMap[kvp.Value] = kvp.Key;
                }
            }
        }

        /// <summary>
        /// 根据View类型获取ViewConfigID
        /// </summary>
        public static string GetConfigID(Type viewType)
        {
            if (!s_Initialized) Initialize();

            if (viewType != null && s_TypeToConfigIDMap != null && s_TypeToConfigIDMap.TryGetValue(viewType, out string configID))
            {
                return configID;
            }
            return null;
        }

        /// <summary>
        /// 根据ViewConfigID获取View类型
        /// </summary>
        public static Type GetViewType(string configID)
        {
            if (!s_Initialized) Initialize();

            if (!string.IsNullOrEmpty(configID) && s_ConfigIDToTypeMap != null && s_ConfigIDToTypeMap.TryGetValue(configID, out Type viewType))
            {
                return viewType;
            }
            return null;
        }

        /// <summary>
        /// 获取所有注册的View类型
        /// </summary>
        public static Dictionary<Type, string> GetAllRegisteredTypes()
        {
            if (!s_Initialized) Initialize();

            return s_TypeToConfigIDMap != null ? new Dictionary<Type, string>(s_TypeToConfigIDMap) : new Dictionary<Type, string>();
        }
    }

    /// <summary>
    /// 自动生成的View类型映射表（由代码生成器生成）
    /// TypeToConfigIDMap字段在ViewTypeRegistryAuto.Generated.cs中定义
    /// </summary>
    public static partial class ViewTypeRegistryAuto
    {
        // TypeToConfigIDMap字段由代码生成器在ViewTypeRegistryAuto.Generated.cs中定义
    }
}
