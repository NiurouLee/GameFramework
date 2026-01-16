
using System;
using System.Collections.Generic;
using UnityEngine;

namespace NFramework.Ex.UI
{

    public class UIEx : MonoBehaviour
    {

        void Start()
        {
            // var assetList = new List<Tuple<string, string>>();
            // assetList.Add(new Tuple<string, string>("DemoWindow", "DemoWindow"));
            // Framework.Instance.GetModule<Res>().AwakeAssetID2PathMap(assetList);

            // var go = UnityEngine.Resources.Load("UIROOT");
            // var root = Instantiate(go) as GameObject;
            // Framework.Instance.GetModule<UI>().AwakeRoot(root);
            // Framework.Instance.GetModule<UI>().AwakeLayer();
            // var list = new List<Tuple<Type, string, ViewConfig>>();
            // var viewConfig = new ViewConfig();
            // viewConfig.Name = "DemoWindow";
            // viewConfig.AssetID = "DemoWindow";
            // list.Add(new Tuple<Type, string, ViewConfig>(typeof(DemoWindow), "DemoWindow", viewConfig));
            // Framework.Instance.GetModule<UI>().AwakeTypeCfg(list);
            // // UIManager.Instance.OpenSync<DemoWindow, DemoWindowData>(new DemoWindowData() { Name = "DemoWindowEx" });
        }
    }
}