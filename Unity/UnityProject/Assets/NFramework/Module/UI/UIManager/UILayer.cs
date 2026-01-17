namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        public void __WindowSetUpLayer(ViewConfig inViewConfig, Window inWindow)
        {
            inWindow.SetLayer(inViewConfig.Layer);
        }
    }
}