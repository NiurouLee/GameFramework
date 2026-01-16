using System;
using NFramework.Module.ResModule;
using Proto.Promises;
using NFramework.Module.LogModule;

namespace NFramework.Module.UIModule
{
    /// <summary>
    ///  UIRequest阶段,当前到那个阶段了
    /// </summary>
    [Flags]
    public enum WindowRequestStage : Byte
    {
        Construct = 0,
        CacheInitData = 1,
        ConstructWindow = 2,
        ConstructWindowDone = 3,
        FacadeLoading = 4,
        FacadeLoaded = 5,
        LayerServicesChecking = 6,
        SetupData = 7,
        WindowAwake = 8,
        WindowOpen = 8,
        windowOpenAnim = 9,
        WindowClose = 10,
        WindowCloseAnim = 11,
        GameObjectUnloading = 12,
        Invalid = 13,
    }

    /// <summary>
    /// 把打开一个UI封装成Request
    /// </summary>
    public class WindowRequest : IEquatable<WindowRequest>
    {
        public string Name { get; private set; }
        public ViewConfig Config { get; private set; }
        public WindowRequestStage Stage { get; private set; }
        public Window CacheWindowObj { get; private set; }
        public UIFacade CacheFacadeObj { get; private set; }
        public System.Object CacheViewDataObj { get; private set; }

        public WindowRequest(ViewConfig inConfig)
        {
            if (inConfig == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack(" WindowRequest inConfig is null");
            }

            this.Config = inConfig;
            this.Name = inConfig.ID;
            SetStage(WindowRequestStage.Construct);
        }

        public void SetStage(WindowRequestStage inStage)
        {
            if (inStage == this.Stage)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest Err:Stage Repeat,WindowName：{this.Name}");

            }

            if (inStage < this.Stage)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest Err:Stage Inverse,WindowName：{this.Name}");
            }

            this.Stage = inStage;
        }

        public virtual void CacheWindow(Window inWindow)
        {
            if (inWindow == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set Window Err,inWindow is null:WindowName{this.Name}");
            }

            if (this.CacheWindowObj != null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set Window Err,Window dont is null:WindowName{this.Name}");
            }

            this.CacheWindowObj = inWindow;
        }


        public virtual void CacheFacade(UIFacade inFacade)
        {
            if (inFacade == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set Facade Err,inFacade is null:WindowName{this.Name}");
            }

            if (this.CacheFacadeObj != null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set Facade Err,Facade dont is null:WindowName{this.Name}");
            }

            this.CacheFacadeObj = inFacade;
        }


        public virtual void CacheViewData(System.Object inViewData)
        {
            if (inViewData == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set ViewData Err,inViewData is null:WindowName{this.Name}");
            }
            if (this.CacheViewDataObj != null)
            {
                Framework.Instance.GetModule<LoggerM>()?.ErrStack($"WindowRequest set ViewData Err,ViewData dont is null:WindowName{this.Name}");
            }
            this.CacheViewDataObj = inViewData;
        }

        public bool Equals(WindowRequest other)
        {
            if (other is null) return false;
            if (ReferenceEquals(this, other)) return true;
            return Name == other.Name;
        }

        public override bool Equals(object obj)
        {
            if (obj is null) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != GetType()) return false;
            return Equals((WindowRequest)obj);
        }

        public override int GetHashCode()
        {
            return (Name != null ? Name.GetHashCode() : 0);
        }

        public virtual void SetupViewData()
        {

        }


        /// <summary>
        /// 返回给业务的Promise
        /// </summary>
        public Promise.Deferred Deferred;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="promise"></param>
        public virtual void SetPromiseDeferred(Promise.Deferred deferred)
        {
            this.Deferred = deferred;
        }

        internal void Cancel()
        {
        }
    }

    public class WindowRequest<I> : WindowRequest where I : class
    {
        public WindowRequest(ViewConfig inConfig) : base(inConfig)
        {
        }
        public override void SetupViewData()
        {
            if (this.CacheWindowObj is IViewSetData<I> viewSetData)
            {
                viewSetData.SetData(this.CacheViewDataObj as I);
            }
        }
    }

    public class WindowRequest<T, I> : WindowRequest<I> where T : Window, IViewSetData<I>, new() where I : class
    {
        public T Window { get; private set; }
        public WindowRequest(ViewConfig inConfig) : base(inConfig)
        {
        }

        public override void CacheWindow(Window inWindow)
        {
            base.CacheWindow(inWindow);
            if (inWindow is T window)
            {
                this.Window = window;
            }
        }
    }
}