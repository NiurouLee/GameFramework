using System;
using NFramework.Core.Collections;

namespace NFramework.Module.UIModule
{
    [Serializable]
    public class ViewConfig
    {
        public string ID;
        public string AssetID;
        private BitField32 Set;

        /// <summary>
        /// Layer
        /// </summary>
        /// <returns></returns>
        public UIlayer Layer => (UIlayer)this.Set.Low;
        public bool IsWindow => this.Set.GetBit(31);

        public void SetLayer(UIlayer inLayer)
        {
            this.Set.Low = (ushort)inLayer;
        }
        public void SetWindow(bool inWindow)
        {
            this.Set.SetBit(31, inWindow);
        }


    }
}