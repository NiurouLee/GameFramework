using System.Collections.Generic;
using Entitas;
using NFramework.Core.Live;
using UnityEngine;

namespace Logic
{
    /// <summary>
    /// 战斗上下文，
    /// </summary>
    public class CombatContext : Entity, IAwakeSystem, IUpdateSystem
    {

        public Dictionary<GameObject, CombatEntity> Object2Entities { get; } = new Dictionary<GameObject, CombatEntity>();
        public Dictionary<GameObject,AbilityItem>

        public void Awake()
        {

        }

        public void Update(float deltaTime)
        {

        }
    }
}