using System;

namespace NFramework.Module.UIModule
{
    public class ViewInputComponent : ViewComponent
    {
    }

    public static class ViewInputComponentExtension
    {
        public static void BindInput<T>(this View inView, T inComponent, Action<T> inCallback)
            where T : IUIInputComponent, IUIInputTrigger<T>
        {
            var component = ViewUtils.CheckAndAdd<ViewInputComponent>(inView);
        }
    }
}