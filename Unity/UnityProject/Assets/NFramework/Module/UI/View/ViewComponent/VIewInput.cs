using System;

namespace NFramework.Module.UIModule
{
    public class ViewInput : ViewComponent
    {


    }

    public static class ViewInputComponentExtension
    {
        public static void BindInput<T>(this View inView, T inComponent, Action<T> inCallback) where T : IUIInputComponent ,IUIInputTrigger<T>
        {
            var component = ViewComponentUtils.CheckAndAdd<ViewInput>(inView);
            // component.BindInput<T>(inCallback);
        }


    }
}