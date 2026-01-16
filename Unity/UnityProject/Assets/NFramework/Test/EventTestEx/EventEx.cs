using NFramework.Module.EventModule;

namespace NFramework.Test.EventTestEx
{
    public struct NormalEvent : IEvent
    {
        public int ID;
    }

    public struct ChannelEvent : IChannelEvent
    {
        public string Channel => "111";
    }
}