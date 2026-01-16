using System;
using System.Collections;
using System.Collections.Generic;

namespace NFramework.Module.UIModule
{
    public delegate bool UI2ParentEvent<T>(ref T view2ParentEvent);
    public static class ViewComponentUtils
    {
        public static bool Check<T>(View inView, out T outComponent) where T : ViewComponent
        {
            if (inView.Has(ViewStateFlag.Components) & inView.TryGetComponent<T>(out outComponent))
            {
                return true;
            }
            outComponent = null;
            return false;
        }
        public static T CheckAndAdd<T>(View inView) where T : ViewComponent, new()
        {
            if (inView.TryGetComponent<T>(out var component))
            {
                return component as T;
            }
            return inView.AddComponent<T>();
        }
    }

}