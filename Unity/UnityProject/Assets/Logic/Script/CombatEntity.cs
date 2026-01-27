using Sirenix.OdinInspector;
using UnityEngine;

namespace Logic
{
    public sealed class CombatEntity
    {
        public GameObject HeroObject { get; set; }
        public Transform ModelTrans { get; set; }
        public healthPointComponent CurrentHealth{get; private set;}
    }
}