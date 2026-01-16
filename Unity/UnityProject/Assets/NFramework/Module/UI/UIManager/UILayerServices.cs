using System.Collections.Generic;
using NFramework.UI;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    public class UILayerServices
    {
        public static short OneUiSortOder = 50;
        private UIlayer layer;
        private GameObject go;
        public GameObject Go => go;
        public int BaseOrder { get; private set; }
        private List<Window> stack;
        private UIM uIM;

        public UILayerServices(UIM inUIM, UIlayer inLayer, GameObject inGo)
        {
            this.uIM = inUIM;
            this.layer = inLayer;
            this.go = inGo;
            BaseOrder = (int)inLayer * 1000;
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
    }
}