using System;
using System.Collections.Generic;
using UnityEngine;

namespace Ez.UI
{
    public class UIEffectBindGroup : MonoBehaviour
    {
        public List<UIEffectBind> m_BindList = new List<UIEffectBind>();
        
        /// <summary>
        /// 动态添加绑定
        /// </summary>
        /// <param name="bind"></param>
        public void AddBind(UIEffectBind bind)
        {
            m_BindList.Add(bind);
        }

        public void Play()
        {
            foreach (var bind in m_BindList)
            {
                bind.PlayEffect();
            }
        }
        
        public void Stop()
        {
            foreach (var bind in m_BindList)
            {
                bind.StopEffect();
            }
        }

        private void OnDestroy()
        {
            foreach (var bind in m_BindList)
            {
                bind.Release();
            }
        }
    }
}