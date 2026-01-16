
namespace NFramework.Module.EventModule
{
    public class EventM : IFrameWorkModule
    {
        public EventSchedule D = new EventSchedule();

        public override void Awake()
        {
            D = new EventSchedule();
        }
    }
}