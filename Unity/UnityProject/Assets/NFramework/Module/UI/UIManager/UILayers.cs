using System.Collections.Generic;
using UnityEngine;

namespace NFramework.Module.UIModule
{

    public partial class UIM
    {
        public Dictionary<UIlayer, UILayerServices> layerServices = new Dictionary<UIlayer, UILayerServices>();

        public void AwakeLayer(Canvas inCanvas)
        {
            foreach (var item in System.Enum.GetValues(typeof(UIlayer)))
            {
                UIlayer _layerEnum = (UIlayer)item;
                var _go = new GameObject(item.ToString());
                var _trans = _go.AddComponent<RectTransform>();
                _trans.sizeDelta = new Vector2(0, 0);
                _trans.SetParent(inCanvas.transform, false);
                UILayerServices _services = new UILayerServices(this, _layerEnum, _go);
                this.layerServices.Add(_layerEnum, _services);
            }
        }

        private void __WindowSetUpLayer(ViewConfig inViewConfig, Window inWindow)
        {
            var layer = inViewConfig.Layer;
            var layerServices = this.layerServices[(UIlayer)layer];
            var window = inWindow;
            window.Facade.transform.SetParent(layerServices.Go.transform, false);
        }
    }
}