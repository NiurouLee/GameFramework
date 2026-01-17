using System;

namespace NFramework.Module.UIModule
{
    public interface IUISelectComponent : IUIInputComponent
    {
        public bool IsSelected { get; set; }
        public event Action<IUISelectComponent, bool> OnSelect;
        public void OnSelectTrigger(bool isSelected);
    }
}