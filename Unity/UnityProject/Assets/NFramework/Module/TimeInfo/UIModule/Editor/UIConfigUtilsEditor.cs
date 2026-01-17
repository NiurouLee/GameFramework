using System.Collections.Generic;
using NFramework.Module.UIModule;
using Unity.VisualScripting;

namespace NFramework.Module.UIModule
{

    public class UIConfigUtilsEditor
    {
        public static Dictionary<string, ViewConfig> m_ViewConfigDic = new Dictionary<string, ViewConfig>();
        public static ViewConfig GetViewConfig(UnityEngine.Object target)
        {
            UIFacade _uiFacade = (UIFacade)target;
            
            // 如果ID为空，使用GameObject的InstanceID作为临时key
            string key = string.IsNullOrEmpty(_uiFacade.ID) ? 
                $"temp_{_uiFacade.gameObject.GetInstanceID()}" : _uiFacade.ID;
            
            if (m_ViewConfigDic.TryGetValue(key, out var config))
            {
                // 如果ID发生了变化，更新配置的ID
                if (!string.IsNullOrEmpty(_uiFacade.ID) && config.ID != _uiFacade.ID)
                {
                    config.ID = _uiFacade.ID;
                }
                return config;
            }

            var _config = new ViewConfig();
            _config.ID = _uiFacade.ID;
            m_ViewConfigDic.Add(key, _config);
            return _config;
        }

        public static void SaveViewConfig(UnityEngine.Object target)
        {
            UIFacade _uiFacade = (UIFacade)target;
        }
    }
}