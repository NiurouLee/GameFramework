using UnityEngine.Assertions;

namespace NFramework.NBehavior
{
    public class Sequence : Composite
    {
        /// <summary>
        /// 顺序节点，可以动态添加子节点
        /// </summary>
        protected int currentIndex { get; set; }
        public Sequence() : base("Sequence")
        {

        }
        protected override void DoStart()
        {
            for (int i = 0; i < this.children.Count; i++)
            {
                var child = this.children[i];
                Assert.AreEqual(child.CurrentState, Node.State.INACTIVE);
            }
            this.currentIndex = -1;
            ProcessChildren();
            base.DoStart();
        }

        protected override void DoStop()
        {
            children[currentIndex].Stop();
        }

        protected override void DoChildStopped(Node inChild, bool inResult)
        {
            if (inResult)
            {
                ProcessChildren();
            }
            else
            {
                Stopped(false);
            }
        }

        private void ProcessChildren()
        {
            if (++currentIndex < children.Count)
            {
                if (IsStopRequested)
                {
                    Stopped(false);
                }
                else
                {
                    children[currentIndex].Start();
                }
            }
            else
            {
                Stopped(true);
            }
        }


        public override void StopLowePriorityChildrenForChild(Node inAbortForChild, bool inImmediateRestart)
        {
            int indexForChild = 0;
            bool fount = false;
            for (int i = 0; i < children.Count; i++)
            {
                var currentChild = children[i];
                if (currentChild == inAbortForChild)
                {
                    fount = true;
                }
                else if (!fount)
                {
                    indexForChild++;
                }
                else if (fount && currentChild.IsActive)
                {
                    if (inImmediateRestart)
                    {
                        currentIndex = indexForChild - 1;
                    }
                    else
                    {
                        currentIndex = children.Count;
                    }

                    currentChild.Stop();
                    break;
                }
            }
        }
    }
}
