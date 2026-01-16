namespace NFramework.Module.GameModule
{
    /// <summary>
    /// 游戏业务模块中心
    /// </summary>
    public class GameModuleM : IFrameWorkModule
    {
        public void Awake()
        {
        }

        public void GetGameModule<T>() where T : IGameModule
        {

        }

        public void Open()
        {
        }

        public void Update(float elapseSeconds, float realElapseSeconds)
        {
        }

        public void Close()
        {
        }

        public void Destroy()
        {
        }
    }
}