namespace NFramework.Module.EventModule
{
    public interface IEventRegister
    {
        public BaseRegister Subscribe<T>(RefAction<T> callback) where T : IEvent;

        public BaseRegister Subscribe<T>(RefAction<T> callback, RefFunc<T> condition) where T : IEvent;

        public BaseRegister Subscribe<T>(RefAction<T> callback, string channel) where T : IEvent;

        public void UnSubscribe<T>(RefAction<T> callback) where T : IEvent;

        public void UnSubscribe<T>(RefAction<T> callback, RefFunc<T> condition) where T : IEvent;

        public void UnSubscribe<T>(RefAction<T> callback, string channel) where T : IEvent;

        public void UnSubscribe(BaseRegister inRegister);

        public bool Check<T>(RefAction<T> callback) where T : IEvent;

        public bool Check<T>(RefAction<T> callback, RefFunc<T> condition) where T : IEvent;

        public bool Check<T>(RefAction<T> callback, string channel) where T : IEvent;
    }
}