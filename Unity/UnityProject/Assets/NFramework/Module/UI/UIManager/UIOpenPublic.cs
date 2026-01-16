
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        public Promise OpenAsync<T>() where T : Window, new()
        {
            var vc = this.GetViewConfig<T>();
            return _OpenAsync<T>(vc);
        }
        public Promise OpenAsync<T, I>(I inViewData) where T : Window, IViewSetData<I>, new() where I : class
        {
            var vc = this.GetViewConfig<T>();
            return _OpenAsync<T, I>(vc, inViewData);
        }
        public Promise OpenAsync(string inWindowName)
        {
            var vc = this.GetViewConfig(inWindowName);
            return _OpenAsync(vc);
        }
        public Promise OpenAsync<I>(string inWindowName, I inViewData = null) where I : class
        {
            var vc = this.GetViewConfig(inWindowName);
            return _OpenAsync<I>(vc, inViewData);
        }

    }
}