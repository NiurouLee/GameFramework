using UnityEngine.Assertions;

namespace NFramework.NBehavior
{
    public class Root : Decorator
    {
        private Node mainNode;
        private Blackboard blackboard;

        public override Blackboard Blackboard
        {
            get
            {
                return blackboard;
            }
        }

        private Clock clock;
        public override Clock Clock
        {
            get
            {
                return clock;
            }
        }

#if NFRAMEWORK_DEBUG
    public int TotalNumStartCalls=0;
    public int TotalNumStopCalls=0;
    public int TOtalNumStoppedCalls=0;
#endif

        public Root(Node mainNode) : base("Root", mainNode)
        {
            this.mainNode = mainNode;
            this.clock = null;
            // this.blackboard = new Blackboard(this.clock);
            this.SetRoot(this);
        }

        public Root(Blackboard inBlackboard, Node inMainNode) : base("Root", inMainNode)
        {
            this.blackboard = inBlackboard;
            this.mainNode = inMainNode;
            this.clock = null;
            this.SetRoot(this);
        }

        public Root(Blackboard inBlackboard, Clock inClock, Node inMainNode) : base("Root", inMainNode)
        {
            this.blackboard = inBlackboard;
            this.clock = inClock;
            this.mainNode = inMainNode;
            this.SetRoot(this);
        }

        public override void SetRoot(Root inRootNode)
        {
            Assert.AreEqual(this, inRootNode);
            base.SetRoot(inRootNode);
            this.mainNode.SetRoot(inRootNode);
        }


        protected override void DoStart()
        {
            // this.blackboard.Enable();
            this.mainNode.Start();
        }

        protected override void DoStop()
        {
            // if (this.mainNode.IsActive)
            // {
            //     this.mainNode.Stop();
            // }
            // else
            // {
            //     this.clock.RemoveTimer(this.mainNode.Start);
            // }
        }


        protected override void DoChildStopped(Node inNode, bool isSuccess)
        {
            // if (!IsStopRequested)
            // {
            //     this.clock.AddTimer(0, 0, this.mainNode.Start);
            // }
            // else
            // {
            //     this.blackboard.Disable();
            //     Stopped(isSuccess);
            // }
        }

    }
}



