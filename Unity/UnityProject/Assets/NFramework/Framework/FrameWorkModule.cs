namespace NFramework
{
    public abstract class IFrameWorkModule
    {
        public virtual void Awake() { }
        public virtual void Open() { }
        public virtual void Update(float elapseSeconds, float realElapseSeconds) { }
        public virtual void Close() { }
        public virtual void Destroy() { }

        public T GetFrameWorkModule<T>() where T : IFrameWorkModule
        {
            return Framework.Instance.GetModule<T>();
        }
    }
}