

namespace NFramework.Module.EventModule
{
    public partial class EventSchedule
    {
        public TM GetFrameworkModule<TM>() where TM : IFrameWorkModule
        {
            return Framework.I.G<TM>();
        }
    }
}