using UnityEngine;
using System;

namespace NFramework.Module.UIModule
{
    public partial class View
    {
        public UIFacade Facade { get; private set; }

        //记录Facade的Provider,根据不同的Facade 进行不同的归还策略
        public IUIFacadeProvider Provider { get; private set; }
        ///
        public void SetUIFacade(UIFacade inUIFacade, IUIFacadeProvider inProvider)
        {
            if (inUIFacade == null)
            {
                throw new Exception("SetUIFacade: inUIFacade is null");
            }
            if (inProvider == null)
            {
                throw new Exception("SetUIFacade: inProvider is null");
            }
            this.Facade = inUIFacade;
            this.RectTransform = inUIFacade.GetComponent<RectTransform>();
            this.OnBindFacade();
        }

        protected virtual void OnBindFacade()
        {
        }

        private void DestroyFacade()
        {
            this.Provider.Free(this.Facade);
            this.Facade = null;
            this.Provider = null;
            this.RectTransform = null;
        }
    }
}
