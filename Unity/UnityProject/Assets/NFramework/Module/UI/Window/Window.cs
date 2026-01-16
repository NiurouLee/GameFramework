using System;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// Container 上一层，
    /// </summary>
    public class Window : Container
    {
        public void Close()
        {
            Framework.Instance.GetModule<UIM>().Close(this);
        }
        private IUIFacadeProvider _selfFacadeProvider;
        public IUIFacadeProvider GetSelfFacadeProvider()
        {
            if (_selfFacadeProvider == null)
            {
                // _selfFacadeProvider = new UIFacadeProviderWindow(this.ResLoadRecords);
            }
            return _selfFacadeProvider;
        }
    }
}