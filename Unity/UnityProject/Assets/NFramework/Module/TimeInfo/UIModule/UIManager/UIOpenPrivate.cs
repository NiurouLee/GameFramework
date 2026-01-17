using System.Collections.Generic;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        #region  Cache
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

        #endregion


        #region  common
        private WindowRequest CreateRequestByWindow<TW>(ViewConfig inViewConfig) where TW : Window, new()
        {
            var windowRequest = new WindowRequestByWindow<TW>(inViewConfig);
            windowRequest.SetStage(WindowRequestStage.Construct);
            var window = this.CreateView<TW>();
            windowRequest.Cache(window);
            windowRequest.SetStage(WindowRequestStage.Cache);
            return windowRequest;
        }

        private WindowRequest CreateRequest<TW, TD>(ViewConfig inViewConfig, TD inViewData) where TW : Window, IViewSetData<TD>, new() where TD : class
        {
            var windowRequest = new WindowRequest<TW, TD>(inViewConfig);
            windowRequest.SetStage(WindowRequestStage.Construct);
            var window = this.CreateView<TW>();
            windowRequest.Cache(window, inViewData);
            windowRequest.SetStage(WindowRequestStage.Cache);
            return windowRequest;
        }

        private WindowRequestByWindow CreateRequest(ViewConfig inViewConfig)
        {
            var windowRequest = new WindowRequestByWindow(inViewConfig);
            windowRequest.SetStage(WindowRequestStage.Construct);
            var window = this.CreateView(inViewConfig) as Window;
            windowRequest.Setup(window);
            windowRequest.SetStage(WindowRequestStage.Cache);
            return windowRequest;
        }


        private WindowRequestByData<TD> CreateRequestByData<TD>(ViewConfig inViewConfig, TD inViewData) where TD : class
        {
            var windowRequest = new WindowRequestByData<TD>(inViewConfig);
            windowRequest.SetStage(WindowRequestStage.Construct);
            var window = this.CreateView(inViewConfig) as Window;
            windowRequest.Cache(window, inViewData);
            windowRequest.SetStage(WindowRequestStage.Cache);
            return windowRequest;
        }

        #endregion

        #region  Async
        private Promise _OpenAsync<TW>(ViewConfig inViewConfig) where TW : Window, new()
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = CreateRequestByWindow<TW>(inViewConfig);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                ___AsyncSetFacade(inViewConfig, windowRequest, deferred);
                return deferred.Promise;

            }
        }
        private Promise _OpenAsync<TD>(ViewConfig inViewConfig, TD inViewData) where TD : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = CreateRequestByData<TD>(inViewConfig, inViewData);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                ___AsyncSetFacade(inViewConfig, windowRequest, deferred);

                return deferred.Promise;

            }
        }

        private Promise _OpenAsync<TW, TD>(ViewConfig inViewConfig, TD inViewData) where TW : Window, IViewSetData<TD>, new() where TD : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return outWindowRequest.Deferred.Promise;
            }
            else
            {
                var windowRequest = CreateRequest<TW, TD>(inViewConfig, inViewData);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                ___AsyncSetFacade(inViewConfig, windowRequest, deferred);
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
                WindowRequestByWindow windowRequest = CreateRequest(inViewConfig);
                var deferred = Promise.NewDeferred();
                windowRequest.SetPromiseDeferred(deferred);
                ___AsyncSetFacade(inViewConfig, windowRequest, deferred);
                return deferred.Promise;
            }
        }


        private async void ___AsyncSetFacade(ViewConfig inViewConfig, WindowRequest inWindowRequest, Promise.Deferred inDeferred)
        {
            var windowFacadeProvider = this.___CreateWindowFacadeProvider(inWindowRequest.CacheWindowObj);
            inWindowRequest.CacheProvider(windowFacadeProvider);
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoading);
            var facade = await windowFacadeProvider.AllocAsync(inViewConfig.ID).Promise;
            inWindowRequest.CacheFacade(facade);
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoaded);
            this.__WindowSetUpLayer(inViewConfig, inWindowRequest.CacheWindowObj);
            inWindowRequest.SetStage(WindowRequestStage.Layer);
            inWindowRequest.Awake();
            inWindowRequest.Show();
            inDeferred.Resolve();
        }

        #endregion

        #region Sync
        private TW _OpenSync<TW>(ViewConfig inViewConfig) where TW : Window, new()
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return null;
            }
            else
            {
                var windowRequest = CreateRequestByWindow<TW>(inViewConfig);
                return ___SyncSetFacade(inViewConfig, windowRequest) as TW;
            }
        }
        private Window _OpenSync<TD>(ViewConfig inViewConfig, TD inViewData) where TD : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return null;
            }
            else
            {
                var windowRequest = CreateRequestByData<TD>(inViewConfig, inViewData);
                return ___SyncSetFacade(inViewConfig, windowRequest);
            }
        }


        private TW _OpenSync<TW, TD>(ViewConfig inViewConfig, TD inViewData) where TW : Window, IViewSetData<TD>, new() where TD : class
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return null;
            }
            else
            {
                var windowRequest = CreateRequestByWindow<TW>(inViewConfig);
                return ___SyncSetFacade(inViewConfig, windowRequest) as TW;
            }
        }

        private Window _OpenSync(ViewConfig inViewConfig)
        {
            if (CheckWindowReq(inViewConfig, out var outWindowRequest))
            {
                return null;
            }
            else
            {
                var windowRequest = CreateRequest(inViewConfig);
                return ___SyncSetFacade(inViewConfig, windowRequest);
            }
        }

        private Window ___SyncSetFacade(ViewConfig inViewConfig, WindowRequest inWindowRequest)
        {
            var windowFacadeProvider = this.___CreateWindowFacadeProvider(inWindowRequest.CacheWindowObj);
            inWindowRequest.CacheProvider(windowFacadeProvider);
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoading);
            var facade = windowFacadeProvider.Alloc(inViewConfig.ID);
            inWindowRequest.CacheFacade(facade);
            inWindowRequest.SetStage(WindowRequestStage.FacadeLoaded);
            this.__WindowSetUpLayer(inViewConfig, inWindowRequest.CacheWindowObj);
            inWindowRequest.SetStage(WindowRequestStage.Layer);
            inWindowRequest.Awake();
            inWindowRequest.Show();
            return inWindowRequest.CacheWindowObj;
        }


        #endregion
        
        #region  WinodwLife

        private IUIFacadeProvider ___CreateWindowFacadeProvider(Window inWindow)
        {
            var component = UIUtils.CheckAndAdd<ViewResLoadComponent>(inWindow);
            return new UIFacadeProviderDynamic(component);

        }


        #endregion
    }
}