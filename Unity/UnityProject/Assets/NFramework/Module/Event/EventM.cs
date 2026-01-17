
namespace NFramework.Module.EventModule
{
    public class EventM : FrameworkModule
    {
        public EventSchedule D = new EventSchedule();

        public override void Awake()
        {
            D = new EventSchedule();
        }
    }
}