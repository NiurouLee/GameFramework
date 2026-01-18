using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace NFramework.Module.UIModule
{
    public static class UIFacadeUtils
    {
#if UNITY_EDITOR
        public static bool CheckName(UnityEngine.Object target, int index, string name)
        {
            UIFacade _uiFacade = (UIFacade)target;
            if (_uiFacade == null || _uiFacade.m_UIElements == null) return true;
            
            for (int i = 0; i < _uiFacade.m_UIElements.Count; i++)
            {
                if (i == index)
                {
                    continue;
                }
                var element = _uiFacade.m_UIElements[i];
                if (element != null && element.Name == name)
                {
                    return false;
                }
            }
            return true;
        }
#endif
    }
}