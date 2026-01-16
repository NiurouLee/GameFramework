using UnityEngine.Assertions;

namespace NFramework.NBehavior
{
    public abstract class Container : Node
    {
        private bool collapse = false;
        public bool Collapse
        {
            get
            {
                return collapse;
            }
            set
            {
                collapse = value;
            }
        }

        public Container(string name) : base(name)
        {

        }

        public void ChildStopped(Node inChild, bool inSucceeded)
        {
            Assert.AreNotEqual(this.currentState, State.INACTIVE, "A child of a Container wa stopped while the container was inactive");
            this.DoChildStopped(inChild, inSucceeded);
        }

        protected abstract void DoChildStopped(Node inChild, bool inSucceeded);

#if NFRAMEWORK_DEBUG
public abstract Node[] DebugChild
{
    get;
}
#endif
    }
}
