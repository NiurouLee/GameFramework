using System;

namespace NFramework.Module.UIModule
{
    public interface IUIClickComponent : IUIInputComponent, IUIInputTrigger<IUIClickComponent>
    {

    }
    public class FButton : IUIClickComponent
    {
        public event Action<IUIClickComponent> OnInputTrigger;

        public void TriggerInput(IUIClickComponent inComponent)
        {
            OnInputTrigger?.Invoke(this);
        }

        public void UIAwake()
        {
        }

        public void UIDestroy()
        {
        }

    }
}