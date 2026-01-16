using System.IO.IsolatedStorage;

namespace NFramework.NBehavior
{
    /// <summary>
    /// 装饰器
    /// </summary>
    public abstract class Decorator : Container
    {
        protected Node Decoratee;

        public Decorator(string name, Node inDecoratee) : base(name)
        {
            this.Decoratee = inDecoratee;
            this.Decoratee.SetParent(this);
        }

        public override void SetRoot(Root inRootNode)
        {
            base.SetRoot(inRootNode);
            Decoratee.SetRoot(RootNode);
        }

        public override void ParentCompositeStopped(Composite inComposite)
        {
            base.ParentCompositeStopped(inComposite);
            Decoratee.ParentCompositeStopped(inComposite);
        }
    }
}
