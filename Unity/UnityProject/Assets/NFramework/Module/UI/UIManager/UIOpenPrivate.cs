using System.Collections.Generic;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        /// <summary>
        /// 缓存打开中、打开的windowReq
        /// </summary>
        public Dictionary<string, WindowRequest> WindowRequestDictionary = new Dictionary<string, WindowRequest>();

        private bool CheckWindowReq(ViewConfig inViewConfig, out WindowRequest outWindowRequest)
        {
            var windowID = inViewConfig.ID;
            if (this.WindowRequestDictionary.TryGetValue(windowID, out var request))
            {
                outWindowRequest = request;
                return false;
            }
            else
            {
                outWindowRequest = null;
                return true;
            }
        }

        private Promise _OpenAsync<T>(ViewConfig inViewConfig) where T : Window, new()
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = new WindowRequest<T>(inViewConfig);
                windowRequest.SetStage(WindowRequestStage.Construct);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                var window = this.CreateView<T>();
                ___OpenAsync(inViewConfig, windowRequest, window, null);
                return deferred.Promise;

            }
        }

        private Promise _OpenAsync<T, I>(ViewConfig inViewConfig, I inViewData) where T : Window, IViewSetData<I>, new() where I : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = new WindowRequest<T, I>(inViewConfig);
                windowRequest.SetStage(WindowRequestStage.Construct);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                var window = this.CreateView<T>();
                ___OpenAsync(inViewConfig, windowRequest, window, inViewData);
                return deferred.Promise;
            }
        }

        private Promise _OpenAsync(ViewConfig inViewConfig)
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = new WindowRequest(inViewConfig);
                windowRequest.SetStage(WindowRequestStage.Construct);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                var window = this.CreateView(inViewConfig);
                ___OpenAsync(inViewConfig, windowRequest, window as Window, null);
                return deferred.Promise;

            }
        }
        private Promise _OpenAsync<I>(ViewConfig inViewConfig, I inViewData) where I : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = new WindowRequest(inViewConfig);
                windowRequest.SetStage(WindowRequestStage.Construct);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                var window = this.CreateView(inViewConfig);
                ___OpenAsync(inViewConfig, windowRequest, window as Window, inViewData);
                return deferred.Promise;

            }
        }
        private bool CheckWindowReq(string inWindowID, out WindowRequest outWindowRequest)
        {
            if (this.WindowRequestDictionary.TryGetValue(inWindowID, out var request))
            {
                outWindowRequest = request;
                return false;
            }
            else
            {
                outWindowRequest = null;
                return true;
            }
        }
    }
}