using System.Collections.Generic;
using NFramework.UI;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    public abstract class UILayerServices
    {
        public static short OneUiSortOder = 50;
        private GameObject go;
        public GameObject Go => go;
        public int BaseOrder { get; private set; }
        private List<Window> stack;
        private UIM uIM;

        public UILayerServices(UIM inUIM, GameObject inGo)
        {
            this.uIM = inUIM;
            this.go = inGo;
            stack = new List<Window>();
        }

        public bool TryGetWindow(string inWindowID, out Window outWindow)
        {
            outWindow = null;
            foreach (var item in stack)
            {
                if (uIM.GetViewConfig(item).ID == inWindowID)
                {
                    outWindow = item;
                    return true;
                }
            }
            return false;
        }
        public void PushWindow(Window inWindow)
        {
            stack.Add(inWindow);
        }
        public void PopWindow(Window inWindow)
        {
            stack.Remove(inWindow);
        }
    }

    public class UIStackLayerServices : UILayerServices
    {
        public UIStackLayerServices(UIM inUIM, GameObject inGo) : base(inUIM, inGo)
        {
        }
    }

    public class UIFixedLayerServices : UILayerServices
    {
        public UIFixedLayerServices(UIM inUIM, GameObject inGo) : base(inUIM, inGo)
        {
        }
    }

}