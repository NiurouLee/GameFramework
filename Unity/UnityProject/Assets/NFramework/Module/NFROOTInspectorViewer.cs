using UnityEngine;
using NFramework.Module;

namespace NFramework.Module
{
    /// <summary>
    /// NFROOT Inspector查看器包装器
    /// 将此组件添加到GameObject上，即可在Inspector中查看NFROOT的层级结构
    /// </summary>
    public class NFROOTInspectorViewer : MonoBehaviour
    {
        [Header("NFROOT查看器")]
        [Tooltip("点击刷新按钮更新层级结构")]
        public bool autoRefresh = true;
        
        private void OnEnable()
        {
            if (autoRefresh)
            {
                // 标记需要刷新
            }
        }
    }
}
