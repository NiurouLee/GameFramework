using NFramework.Module.LogModule;
using Unity.VisualScripting;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {

        private void _Close(string inWindowName)
        {
            if (string.IsNullOrEmpty(inWindowName))
            {
                this.GetFrameWorkModule<LoggerM>().ErrStack($"UIM::Close inWindowName is null");

            }
            var vc = GetViewConfig(inWindowName);
            if (this.CheckWindowReq(vc, out var outWindowRequest))
            {
                if (outWindowRequest.Stage == WindowRequestStage.WindowOpen)
                {
                    this.__Close(outWindowRequest.CacheWindowObj);
                }
                else if (outWindowRequest.Stage == WindowRequestStage.FacadeLoading)
                {
                    outWindowRequest.Cancel();
                }
            }
        }

        private void __Close(Window inWindow)
        {
            var cacheWindow = inWindow;
            var cacheFacade = inWindow.Facade;

            inWindow.Hide();
            // inWindow.Destroy();
            //入池
        }
    }
}