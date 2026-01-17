using GameObject = UnityEngine.GameObject;
using Vector3 = UnityEngine.Vector3;
using UnityEngine;
using UnityEngine.EventSystems;
using Unity.VisualScripting;
using UnityEngine.UI;

namespace NFramework.Module.UIModule
{
    public partial class UIM : FrameworkModule
    {
        private GameObject uiRoot;
        public Camera UICamera { get; private set; }
        private Canvas uiCanvas;
        private Transform uiCanvasTrf;
        private EventSystem eventSystem;
        private CanvasScaler scaler;
        private UIFixedLayerServices fixedLayer;
        private UIStackLayerServices stackLayer;


        public override void Awake()
        {
            base.Awake();
            var _go = UnityEngine.Resources.Load<GameObject>("UIROOT");
            var _root = UnityEngine.Object.Instantiate(_go);
            this.AwakeRoot(_root);
            this.AwakeLayer();
        }

        public void AwakeRoot(GameObject inRoot)
        {
            uiRoot = inRoot;
            uiRoot.transform.localPosition = new Vector3(0, 1000, 0);
            uiRoot.name = "[UIROOT]";
            UnityEngine.GameObject.DontDestroyOnLoad(uiRoot);
            UICamera = uiRoot.GetOrAddComponent<Camera>();
            uiCanvasTrf = uiRoot.transform.Find("Canvas");
            uiCanvas = uiCanvasTrf.GetComponent<Canvas>();
            eventSystem = uiRoot.GetComponentInChildren<EventSystem>();
            scaler = this.uiCanvas.GetOrAddComponent<CanvasScaler>();
        }

        public void AwakeLayer()
        {
            var fixedLayerGo = new GameObject("FixedLayer");
            fixedLayerGo.transform.SetParent(this.uiRoot.transform);
            this.fixedLayer = new UIFixedLayerServices(this, fixedLayerGo);
            var stackLayerGo = new GameObject("StackLayer");
            stackLayerGo.transform.SetParent(this.uiRoot.transform);
            this.stackLayer = new UIStackLayerServices(this, stackLayerGo);
        }


        public void __WindowSetUpLayer(ViewConfig inViewConfig, Window inWindow)
        {
            if (inViewConfig.IsFixedLayer)
            {
                this.fixedLayer.PushWindow(inWindow, inViewConfig);
            }
            else
            {
                this.stackLayer.PushWindow(inWindow, inViewConfig);
            }
        }

        private void __windowSetupCanvas(Window inwWindow)
        {
            var canvas = inwWindow.RectTransform.GetOrAddComponent<UnityEngine.Canvas>();
            canvas.renderMode = UnityEngine.RenderMode.ScreenSpaceCamera;
            canvas.worldCamera = this.UICamera;
            var graphicRaycaster = inwWindow.RectTransform.GetOrAddComponent<UnityEngine.UI.GraphicRaycaster>();
        }
    }
}