using NFramework.Module.EventModule;

namespace NFramework.Test.EventTestEx
{
    public class RegisterEx
    {
        private EventRecords records;
        public RegisterEx()
        {
            records = new EventRecords();
            records.Awake();
            records.SetSchedule(Framework.Instance.GetModule<EventM>().D);
        }

        #region  normal
        private void OnNormalEvent(ref NormalEvent normalEvent)
        {
            UnityEngine.Debug.Log("OnNormalEvent");
        }
        public void TestRegister()
        {
            Framework.Instance.GetModule<EventM>().D.Subscribe<NormalEvent>(this.OnNormalEvent);
        }

        public void TestUnRegister()
        {
            Framework.Instance.GetModule<EventM>().D.UnSubscribe<NormalEvent>(this.OnNormalEvent);
        }

        public void TestRegisterRecords()
        {
            records.Subscribe<NormalEvent>(this.OnNormalEvent);
        }

        public void TestUnRegisterRecords()
        {
            records.UnSubscribe<NormalEvent>(this.OnNormalEvent);
        }

        #endregion
        private void OnChannelEvent(ref ChannelEvent initem)
        {
            UnityEngine.Debug.Log($"OnChannelEvent=>{initem.Channel}");
        }
        public void TestRegisterChannel()
        {
            Framework.Instance.GetModule<EventM>().D.Subscribe<ChannelEvent>(this.OnChannelEvent, "111");
        }
        public void TestUnRegisterChannel()
        {
            Framework.Instance.GetModule<EventM>().D.UnSubscribe<ChannelEvent>(this.OnChannelEvent, "111");
        }

        public void TestRegisterRecordsChannel()
        {
            records.Subscribe<ChannelEvent>(this.OnChannelEvent, "111");
        }

        public void TestUnRegisterRecordsChannel()
        {
            records.UnSubscribe<ChannelEvent>(this.OnChannelEvent, "111");
        }

        public void TestRegisterFilter()
        {
            Framework.Instance.GetModule<EventM>().D.Subscribe<NormalEvent>(this.OnFilterEvent, this.Filter);
        }

        private void OnFilterEvent(ref NormalEvent initem)
        {
            UnityEngine.Debug.Log($"OnFilterEvent=>{initem.ID}");
        }

        public void TestUnRegisterFilter()
        {
            Framework.Instance.GetModule<EventM>().D.UnSubscribe<NormalEvent>(this.OnFilterEvent, this.Filter);
        }

        public void TestRegisterRecordsFilter()
        {
            records.Subscribe<NormalEvent>(this.OnFilterEvent, this.Filter);
        }

        public void TestUnRegisterRecordsFilter()
        {
            records.UnSubscribe<NormalEvent>(this.OnFilterEvent, this.Filter);
        }

        private bool Filter(ref NormalEvent initem)
        {
            if (initem.ID == 1)
                return true;
            return false;
        }

        public void LogCount()
        {
            var normalCount = Framework.Instance.GetModule<EventM>().D.GetCount<NormalEvent>();
            UnityEngine.Debug.Log($"normalCount:{normalCount}");
            var channelCount = Framework.Instance.GetModule<EventM>().D.GetCount<ChannelEvent>();
            UnityEngine.Debug.Log($"channelCount:{channelCount}");
        }

        internal void TestUnRegisterAllRecords()
        {
            records.Destroy();
        }
    }
}