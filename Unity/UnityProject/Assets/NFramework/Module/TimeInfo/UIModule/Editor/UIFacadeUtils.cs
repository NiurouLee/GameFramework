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
            var editorData = UIFacadeInspector.GetEditorData(_uiFacade);
            if (editorData == null || editorData.Components == null) return true;
            
            for (int i = 0; i < editorData.Components.Length; i++)
            {
                if (i == index)
                {
                    continue;
                }
                UIComponent _c = editorData.Components[i];
                if (_c != null && _c.Name == name)
                {
                    return false;
                }
            }
            return true;
        }
#endif
    }
}