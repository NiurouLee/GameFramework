
namespace NFramework.UI
{
    public partial class UIManager
    {

        // public Window OpenSync<T>() where T : Window
        // {
        //     var vc = this.GetViewConfig<T>();
        //     return _OpenSync<T>(vc, null);
        // }

        // public Window OpenSync<T, I>(I inViewData) where T : Window, IViewSetData<I>, new() where I : IViewData
        // {
        //     var vc = this.GetViewConfig<T>();
        //     return _OpenSync<T>(vc, inViewData);
        // }

        // public Window OpenSync(string inWindowName, IViewData inViewData = null)
        // {
        //     var vc = this.GetViewConfig(inWindowName);
        //     return _OpenSync(vc, inViewData);
        // }


        // private Window _OpenSync(ViewConfig inConfig, IViewData inViewData = null)
        // {
        //     var windowRequest = new WindowRequest(inConfig);
        //     if (CheckWindowReq(windowRequest, out var outWindowRequest))
        //     {
        //         if (outWindowRequest.Stage == WindowRequestStage.WindowOpen)
        //         {
        //             return outWindowRequest.Window;
        //         }
        //         else
        //         {
        //             return outWindowRequest.Window;
        //         }
        //     }
        //     var window = this.CreateView<T>();
        //     window.SetData(inViewData);
        //     window.Awake();
        //     window.Show();
        // }

    }
}