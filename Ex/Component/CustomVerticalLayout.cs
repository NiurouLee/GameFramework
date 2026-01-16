using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CustomVerticalLayout : VerticalLayoutGroup
{
    // 当子物体发生变化时，Unity会调用这个方法
    protected override void OnTransformChildrenChanged()
    {
        // 强制重建布局
        Canvas.ForceUpdateCanvases();
        LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform);
    }
}
