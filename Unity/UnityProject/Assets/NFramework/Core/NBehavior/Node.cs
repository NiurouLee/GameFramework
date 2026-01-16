using UnityEngine.Assertions;

namespace NFramework.NBehavior
{
    public abstract class Node 
    {

        public enum State
        {
            INACTIVE,
            ACTIVE,
            STOP_REQUESTED,
        }

        protected State currentState = State.INACTIVE;

        public State CurrentState
        {
            get { return currentState; }
        }

        public Root RootNode;

        private Container parentNode;

        public Container ParentNode
        {
            get
            {
                return parentNode;
            }
        }

        private string label;

        public string Label
        {
            get
            {
                return label;
            }
        }
        private string name;
        public string Name
        {
            get
            {
                return name;
            }
        }

        public virtual Blackboard Blackboard
        {
            get
            {
                return RootNode.Blackboard;
            }
        }

        public virtual Clock Clock
        {
            get
            {
                return RootNode.Clock;
            }
        }

        public bool IsStopRequested
        {
            get
            {
                return this.currentState == State.STOP_REQUESTED;
            }
        }

        public bool IsActive
        {

            get
            {
                return this.currentState == State.ACTIVE;
            }
        }

        public Node(string inName)
        {
            this.name = inName;
        }


        public virtual void SetRoot(Root inRootNode)
        {
            this.RootNode = inRootNode;
        }

        public void SetParent(Container inParentNode)
        {
            this.parentNode = inParentNode;
        }

#if NFRAMEWORK_DEBUG
public float DebugLastStopRequestAt=0.0f;
public float DebugLstStoppedAt=0.0f;
public int DebugNumStartCalls=0;
public int DebugNumStopCalls=0;
public int DebugNumStoppedCalls=0;
public bool DebugLastResult=false;
#endif


        public void Start()
        {
            Assert.AreEqual(this.currentState, State.INACTIVE, "can only start in inActive nodes");
#if NFRRAMEWORK_DEUBG
RootNode.TotalNumStartCall++;
this.DebugNumStartCalls++;
#endif
            this.currentState = State.ACTIVE;
            DoStart();
        }

        protected virtual void DoStart()
        {

        }

        public void Stop()
        {
            Assert.AreEqual(this.currentState, State.ACTIVE, "can only stop active nodes");
            this.currentState = State.STOP_REQUESTED;
#if NFRAMEWORK_DEBUG
RootNode.TotalNumStopCalls++;
this.DebugLastStopRequestAt= UnityEngine.Time.time;
this.DebugNumStopCalls++;
#endif
            DoStop();
        }

        protected virtual void DoStop()
        {

        }


        protected virtual void Stopped(bool success)
        {
            Assert.AreNotEqual(this.CurrentState, State.INACTIVE, "Called 'Stopped' while in state INACTIVE, something is wrong!");
            this.currentState = State.INACTIVE;
#if NFRAMEWORK_DEBUG
            RootNode.TotalNumStoppedCalls++;
            this.DebugNumStoppedCalls++;
            this.DebugLastStoppedAt= UnityEngine.Time.time;
            DebugLastResult= success;
#endif
            if (this.parentNode != null)
            {
                this.parentNode.ChildStopped(this, success);
            }
        }

        public virtual void ParentCompositeStopped(Composite inComposite)
        {
            DoParentCompositeStopped(inComposite);
        }

        protected virtual void DoParentCompositeStopped(Composite composite)
        {
            //be careful with this!
        }

        public override string ToString()
        {
            return !string.IsNullOrEmpty(this.label) ? (this.Name + "{" + label + "}") : this.Name;
        }


        protected string GetPath()
        {
            if (parentNode != null)
            {
                return parentNode.GetPath() + "/" + this.Name;
            }
            return this.Name;
        }

    }
}