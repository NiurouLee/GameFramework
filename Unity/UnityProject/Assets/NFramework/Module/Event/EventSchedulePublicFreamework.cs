

namespace NFramework.Module.EventModule
{
    public partial class EventSchedule
    {
        public TM GetM<TM>() where TM : FrameworkModule
        {
            return NFROOT.I.G<TM>();
        }
    }
}