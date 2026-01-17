using System;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// Container 上一层，
    /// </summary>
    public class Window : Container
    {
        public void Close()
        {
            Framework.Instance.GetModule<UIM>().Close(this);
        }
    }
}