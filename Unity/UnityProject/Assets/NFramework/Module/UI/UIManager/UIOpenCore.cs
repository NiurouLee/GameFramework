namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        private async void ___OpenAsync(ViewConfig inViewConfig, WindowRequest inWindowRequest, Window inWindow, System.Object inViewData)
        {

            inWindowRequest.CacheViewData(inViewData);
            inWindowRequest.SetStage(WindowRequestStage.CacheInitData);
            inWindowRequest.SetStage(WindowRequestStage.ConstructWindow);
            inWindowRequest.CacheWindow(inWindow);
            inWindowRequest.SetStage(WindowRequestStage.ConstructWindowDone);
            var windowFacadeProvider = inWindow.GetSelfFacadeProvider();
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoading);
            var facade = await windowFacadeProvider.AllocAsync(inViewConfig.ID).Promise;
            inWindowRequest.CacheFacade(facade);
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoaded);
            inWindow.SetUIFacade(facade, windowFacadeProvider);
            inWindow.Awake();
            inWindow.Show();
            inWindowRequest.Deferred.Resolve();
        }

    }
}