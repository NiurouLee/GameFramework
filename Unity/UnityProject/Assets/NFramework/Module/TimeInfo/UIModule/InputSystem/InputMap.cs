using System.Collections.Generic;

namespace NFramework.Module.UIModule
{
    public static class InputMap
    {
        public static Dictionary<InputEnum, System.Type> InputMapDefine = new()
        {
            { InputEnum.Click, typeof(IUIClickComponent) },
            { InputEnum.DoubleClick, typeof(IUIClickComponent) },
            { InputEnum.LongClick, typeof(IUIClickComponent) },
            { InputEnum.Select, typeof(IUISelectComponent) },
        };

        public static Dictionary<System.Type, List<InputEnum>> InputMapComponent = new()
        {
            { typeof(IUIClickComponent), new List<InputEnum> { InputEnum.Click }},
            { typeof(IUISelectComponent), new List<InputEnum> { InputEnum.Select }},
            { typeof(IUIInputComponent), new List<InputEnum> { InputEnum.Click, InputEnum.DoubleClick, InputEnum.LongClick }},
        };
    }
}