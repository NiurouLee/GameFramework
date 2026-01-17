using NFramework.Module.EventModule;
using NFramework.Module.ObjectPoolModule;

namespace NFramework.Module.UIModule
{
    public class EventRecordsComponent : ViewComponent
    {
        private EventRecords m_viewEventRecords;
        public EventRecords Event
        {
            get
            {
                if (m_viewEventRecords == null)
                {
                    m_viewEventRecords = GetM<ObjectPoolM>().Alloc<EventRecords>();
                    m_viewEventRecords.Awake();
                    m_viewEventRecords.SetSchedule(NFROOT.Instance.GetModule<EventM>().D);
                }
                return m_viewEventRecords;
            }
        }

        public override void OnDestroy()
        {
            if (m_viewEventRecords != null)
            {
                m_viewEventRecords.Destroy();
                GetM<ObjectPoolM>().Free(m_viewEventRecords);
                m_viewEventRecords = null;
            }
        }
    }

    public static class ViewEventRecordsComponentExtensions
    {
        public static void Subscribe<T>(this View inView, RefAction<T> callback) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.Subscribe<T>(callback);
        }

        public static void Subscribe<T>(this View inView, RefAction<T> callback, RefFunc<T> condition) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.Subscribe<T>(callback, condition);
        }

        public static void Subscribe<T>(this View inView, RefAction<T> callback, string channel) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.Subscribe<T>(callback, channel);
        }

        public static void UnSubscribe<T>(this View inView, RefAction<T> callback) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.UnSubscribe<T>(callback);
        }

        public static void UnSubscribe<T>(this View inView, RefAction<T> callback, RefFunc<T> condition) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.UnSubscribe<T>(callback, condition);
        }

        public static void UnSubscribe<T>(this View inView, RefAction<T> callback, string channel) where T : IEvent
        {
            var component = UIUtils.CheckAndAdd<EventRecordsComponent>(inView);
            component.Event.UnSubscribe<T>(callback, channel);
        }
    }
}
