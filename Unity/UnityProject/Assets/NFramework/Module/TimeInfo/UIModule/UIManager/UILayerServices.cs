using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    public abstract class UILayerServices
    {
        public static short OneUiSortOder = 50;
        private GameObject go;
        public GameObject Go => go;
        public int BaseOrder { get; private set; }
        protected List<Window> stack;
        protected Dictionary<string, Window> windowMap;
        protected UIM UIM;

        public UILayerServices(UIM inUIM, GameObject inGo)
        {
            this.UIM = inUIM;
            this.go = inGo;
            this.stack = new List<Window>();
            this.windowMap = new Dictionary<string, Window>();
        }

        public bool TryGetWindow(string inWindowID, out Window outWindow)
        {
            if (this.windowMap.TryGetValue(inWindowID, out outWindow))
            {
                return true;
            }

            outWindow = null;
            return false;
        }

        public abstract void PushWindow(Window inWindow, ViewConfig inViewConfig);
        public abstract void PopWindow(ViewConfig inViewConfig);
    }

    public class UIStackLayerServices : UILayerServices
    {
        private List<int> orders;

        public UIStackLayerServices(UIM inUIM, GameObject inGo) : base(inUIM, inGo)
        {
            orders = new List<int>(1000);
        }

        public override void PushWindow(Window inWindow, ViewConfig inViewConfig)
        {
            this.stack.Add(inWindow);
            this.windowMap.Add(inViewConfig.ID, inWindow);
            var canvas = inWindow.RectTransform.GetOrAddComponent<Canvas>();
            this.orders.Sort();
            var currentMax = this.orders[^1];
            canvas.sortingOrder = currentMax + OneUiSortOder;
        }

        public override void PopWindow(ViewConfig inViewConfig)
        {
            var id = inViewConfig.ID;
            if (this.windowMap.TryGetValue(id, out var window))
            {
                var order = window.Order;
                this.UIM.Close(window);
                this.stack.Remove(window);
                this.windowMap.Remove(inViewConfig.ID);
                this.orders.Remove(order);
            }
        }
    }

    public class UIFixedLayerServices : UILayerServices
    {
        public UIFixedLayerServices(UIM inUIM, GameObject inGo) : base(inUIM, inGo)
        {
        }

        public override void PushWindow(Window inWindow, ViewConfig inViewConfig)
        {
            stack.Add(inWindow);
            this.windowMap.Add(inViewConfig.ID, inWindow);
            var canvas = inWindow.RectTransform.GetOrAddComponent<Canvas>();
            canvas.sortingOrder = inViewConfig.Layer;
        }

        public override void PopWindow(ViewConfig inViewConfig)
        {
            if (this.windowMap.TryGetValue(inViewConfig.ID, out var window))
            {
                this.UIM.Close(window);
                this.stack.Remove(window);
                this.windowMap.Remove(inViewConfig.ID);
            }
        }
    }
}