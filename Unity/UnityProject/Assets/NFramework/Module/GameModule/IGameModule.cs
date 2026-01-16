namespace NFramework.Module.GameModule
{
    public interface IGameModule
    {
        public void Awake();
        public void Open();
        public void Update(float elapseSeconds, float realElapseSeconds);
        public void Close();
        public void Destroy();
    }
}