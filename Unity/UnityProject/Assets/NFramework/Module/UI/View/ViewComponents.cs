using System.Collections.Generic;
using NFramework.Core.Collections;

namespace NFramework.Module.UIModule
{
    public partial class View
    {
        private Dictionary<System.Type, ViewComponent> m_Components;
        public Dictionary<System.Type, ViewComponent> Components
        {
            get
            {
                if (m_Components == null)
                {
                    m_Components = DictionaryPool.Alloc<System.Type, ViewComponent>();
                }
                return m_Components;
            }
        }
        public T AddComponent<T>() where T : ViewComponent, new()
        {
            this.Learn(ViewStateFlag.Components);
            var component = GetFM<UIM>().CreateViewComponent<T>();
            Components.Add(typeof(T), component);
            return component;
        }
        public T GetComponent<T>() where T : ViewComponent
        {
            if (this.Has(ViewStateFlag.Components) & Components.TryGetValue(typeof(T), out var component))
            {
                return component as T;
            }
            return null;
        }
        public bool TryGetComponent<T>(out T outComponent) where T : ViewComponent
        {
            if (this.Has(ViewStateFlag.Components) & Components.TryGetValue(typeof(T), out var component))
            {
                outComponent = component as T;
                return true;
            }
            outComponent = null;
            return false;
        }
    }
}