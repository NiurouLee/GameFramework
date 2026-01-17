using System;

namespace NFramework.Module.UIModule
{
    public interface IUIComponent
    {
        public void UIAwake();
        public void UIDestroy();
    }

    public interface IUIInputComponent : IUIComponent
    {

    }

    public interface IUIInputTrigger<T>
    {
        public event Action<T> OnInputTrigger;
        public void TriggerInput(T inComponent);
    }
}