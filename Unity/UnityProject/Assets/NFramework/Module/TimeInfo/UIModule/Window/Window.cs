using System;
using UnityEngine;
using UnityEngine.UI;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// Container 上一层，
    /// </summary>
    public class Window : Container
    {
        public Canvas Canvas => this.RectTransform.GetComponent<Canvas>();
        public GraphicRaycaster GraphicRaycaster => this.RectTransform.GetComponent<GraphicRaycaster>();
        public int Order => Canvas.renderOrder;

        public void Close()
        {
            NFROOT.Instance.GetModule<UIM>().Close(this);
        }
    }
}