using System;

namespace NFramework.Module.UIModule
{
    [Flags]
    public enum UIlayer : Byte
    {
        BackGround = 0,
        Hud = 1,
        Common = 2,
        CommonH = 3,
        Pop = 4,
        PopH = 5,
        Guide = 6,
        Toast = 7,
        ToastH = 8,
        loading = 9,
        Lock = 10,
        SystemToast = 11,

    }
}