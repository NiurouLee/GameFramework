using NFramework.Module.EntityModule;
using UnityEngine;

namespace Logic
{
    public sealed class CombatEntity : Entity
    {
        public GameObject HeroObject { get; set; }
        public Transform ModelTrans { get; set; }
    }
}