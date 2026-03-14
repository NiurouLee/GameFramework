using UnityEngine;
using UnityEngine.UI;
using NFramework.Module.UIModule;
using TMPro;

namespace NFramework.Module.UIModule
{
  public partial class ExchangeMainWindow : Window
  {
    protected override void OnAwake()
    {
      base.OnAwake();
    }

    public void OnUpdate()
    {
      int x = 0;
      this.RectTransform.localRotation = Quaternion.Euler(x, x, x);
    }

    protected override void OnShow()
    {
    }
  }
}
