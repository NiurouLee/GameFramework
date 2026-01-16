using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.EventModule;

namespace NFramework.Module.Combat
{


    public enum AnimationType
    {
        Idle,
        Walk,
        Attack,
        Dead,
    }

    public class AnimationComponent : Entity, IAwakeSystem
    {
        public AnimationType currentType;

        public void PlayAnimation(AnimationType inType, float speed = 1f)
        {
            currentType = inType;
            bool isLoop = currentType == AnimationType.Idle || currentType == AnimationType.Walk ? true : false;
            var syncAnimation = new SyncAnimation(GetParent<Combat>().Id, inType, speed, isLoop);
            Framework.Instance.GetModule<EventM>().D.Publish(ref syncAnimation);
        }

        public void Awake()
        {

        }
    }
}
