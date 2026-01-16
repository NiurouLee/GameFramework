
namespace NFramework.NBehavior
{
    /// <summary>
    /// 随机选择器
    /// </summary>
    public class RandomSelector : Composite
    {
        static System.Random rng = new System.Random();
#if NFRAMEWORK_DEBUG
        public static void DebugSetSeed(int inSeed)
        {
            rng = new System.Random(inSeed);
        }
#endif

        private int m_currentIndex = -1;
        private int[] m_randomizedOrder;

        public RandomSelector(string inName) : base(inName)
        {
        }

        public override void StopLowePriorityChildrenForChild(Node inChild, bool inImmediateRestart)
        {
        }

        protected override void DoChildStopped(Node inChild, bool inSucceeded)
        {
        }
    }
}
