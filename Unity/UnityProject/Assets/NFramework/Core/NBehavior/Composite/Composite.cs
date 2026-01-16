
using System.Collections.Generic;
using NFramework.Core.ILiveing;

namespace NFramework.NBehavior
{
    /// <summary>
    /// 复合节点，可以有子节点
    /// </summary>
    public abstract class Composite : Container
    {
        protected List<Node> children;

        public Composite(string inName) : base(inName)
        {
        }

        public override void SetRoot(Root inRootNode)
        {
            base.SetRoot(inRootNode);


        }

        protected override void Stopped(bool inSuccess)
        {
            if (this.children != null)
            {
                for (int i = 0; i < this.children.Count; i++)
                {
                    var child = this.children[i];
                    child.ParentCompositeStopped(this);
                }
            }
            base.Stopped(inSuccess);
        }


        protected T AddChild<T>(string inName) where T : Node, IAwakeSystem, new()
        {
            var child = new T();
            child.SetParent(this);
            this.children.Add(child);
            LivingSystem.Awake(child);
            return child;
        }

        protected T AddChild<T, A>(string inName, A a) where T : Node, IAwakeSystem<A>, new()
        {
            var child = new T();
            child.SetParent(this);
            this.children.Add(child);
            LivingSystem.Awake(child, a);
            return child;
        }

        protected T AddChild<T, A, B>(string inName, A a, B b) where T : Node, IAwakeSystem<A, B>, new()
        {
            var child = new T();
            child.SetParent(this);
            this.children.Add(child);
            LivingSystem.Awake(child, a, b);
            return child;
        }

        public abstract void StopLowePriorityChildrenForChild(Node inChild, bool inImmediateRestart);

    }
}
