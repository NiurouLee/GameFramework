using System;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.EventModule;
using NFramework.Module.Math;
using UnityEngine;

namespace NFramework.Module.Combat
{
    public class Combat : Entity, IAwakeSystem
    {
        public HealthPoint CurrentHealth;
        public ActionControlType ActionControlType;
        public EffectAssignActionAbility EffectAssignActionAbility;
        public AddStatusActionAbility AddStatusActionAbility;
        public SpellSkillActionAbility SpellSkillActionAbility;
        public SpellItemActionAbility SpellItemActionAbility;
        public DamageActionAbility DamageActionAbility;
        public CureActionAbility CureActionAbility;
        public SkillExecution SpellingSkillExecution;
        public TransformComponent TransformComponent => GetComponent<TransformComponent>();
        public OrcaComponent OrcaComponent => GetComponent<OrcaComponent>();
        public AnimationComponent AnimationComponent => GetComponent<AnimationComponent>();
        public AttributeComponent AttributeComponent => GetComponent<AttributeComponent>();
        public AABBComponent AABBComponent => GetComponent<AABBComponent>();
        public TagComponent TagComponent => GetComponent<TagComponent>();

        public void Awake()
        {
            var @event = new SyncCreateCombat(Id);
            Framework.Instance.GetModule<EventM>().D.Publish(ref @event);
            AddComponent<TransformComponent>();
            AddComponent<OrcaComponent>();
            AddComponent<AnimationComponent>();
            AABB aabb = new AABB(new Vector2(-1, -1), new Vector2(1, 1));
            AddComponent<AABBComponent, AABB>(aabb);
            AddComponent<AttributeComponent>();
            AddComponent<ActionPointComponent>();
            AddComponent<ConditionComponent>();

            AddComponent<MotionComponent>();

            AddComponent<StatusComponent>();
            AddComponent<SkillComponent>();
            AddComponent<ExecutionComponent>();
            AddComponent<ItemComponent>();

            AddComponent<SpellSkillComponent>();
            AddComponent<JoystickComponent>();

            CurrentHealth = AddChild<HealthPoint>();

            EffectAssignActionAbility = AttachAction<EffectAssignActionAbility>();

            AddStatusActionAbility = AttachAction<AddStatusActionAbility>();

            SpellSkillActionAbility = AttachAction<SpellSkillActionAbility>();

            SpellItemActionAbility = AttachAction<SpellItemActionAbility>();

            DamageActionAbility = AttachAction<DamageActionAbility>();
            
            CureActionAbility = AttachAction<CureActionAbility>();

            OrcaComponent.AddAgent2D(TransformComponent.Position);

            ListenActionPoint(ActionPointType.PostReceiveDamage, e =>
            {
                var damageAction = e as DamageAction;
                var syncDamage = new SyncDamage(this.Id, damageAction.DamageValue);
                Framework.Instance.GetModule<EventM>().D.Publish(ref syncDamage);
            });

            ListenActionPoint(ActionPointType.PostReceiveCure, e =>
            {
                var cureAction = e as CureAction;
                var syncCure = new SyncCure(this.Id, cureAction.CureValue);
                Framework.Instance.GetModule<EventM>().D.Publish(ref syncCure);
            });
        }


        public void Dead()
        {
            var syncDeleteCombat = new SyncDeleteCombat(this.Id);
            Framework.Instance.GetModule<EventM>().D.Publish(ref syncDeleteCombat);
            GetParent<CombatContext>().RemoveCombat(this.Id);
        }


        /// <summary>
        /// 接收伤害
        /// </summary>
        /// <param name="actionExecution"></param>
        public void ReceiveDamage(IActionExecution actionExecution)
        {
            var damageAction = actionExecution as DamageAction;
            CurrentHealth.Minus(damageAction.DamageValue);
        }
        /// <summary>
        /// 接受治疗
        /// </summary>
        /// <param name="actionExecution"></param>
        public void ReceiveCure(IActionExecution actionExecution)
        {
            var cureAction = actionExecution as CureAction;
            CurrentHealth.Add(cureAction.CureValue);
        }

        public bool CheckDead()
        {
            return CurrentHealth.Value <= 0;
        }

        //能力
        public T AttachAbility<T>(object configObject) where T : Entity, IAbility, IAwakeSystem<object>
        {
            var ability = AddChild<T, object>(configObject);
            ability.AddComponent<AbilityLevelComponent>();
            return ability;
        }


        //行动
        public T AttachAction<T>() where T : Entity, IActionAbility
        {
            var action = AddChild<T>();
            action.AddComponent<ActionComponent, Type>(typeof(T));
            action.Enable = true;
            return action;
        }


        public StatusAbility AttachStatus(int statusId)
        {
            return GetComponent<StatusComponent>().AttachStatus(statusId);
        }

        public StatusAbility GetStatus(int statusId, int index = 0)
        {
            return GetComponent<StatusComponent>().GetStatus(statusId, index);
        }

        public void OnStatueRemove(StatusAbility statusAbility)
        {
            GetComponent<StatusComponent>().OnStatusRemove(statusAbility);
        }
        public bool HasStatus(int statusId)
        {
            return GetComponent<StatusComponent>().HasStatus(statusId);
        }

        public void OnStatuesChanged(StatusAbility statusAbility)
        {
            GetComponent<StatusComponent>().OnStatuesChanged(statusAbility);
        }


        public SkillAbility AttachSkill(int skillId)
        {
            return GetComponent<SkillComponent>().AttachSkill(skillId);
        }

        public SkillAbility GetSkill(int skillId)
        {
            return GetComponent<SkillComponent>().GetSkill(skillId);
        }


        public ExecutionConfigObject AttachExecution(int executionId)
        {
            return GetComponent<ExecutionComponent>().AttachExecution(executionId);
        }

        public ExecutionConfigObject GetExecution(int executionID)
        {
            return GetComponent<ExecutionComponent>().GetExecution(executionID);
        }

        public ItemAbility AttachItem(int itemID)
        {
            return GetComponent<ItemComponent>().AttachItem(itemID);
        }

        public ItemAbility GetItem(int itemID)
        {
            return GetComponent<ItemComponent>().GetItem(itemID);
        }


        #region ActionPoint
        public void ListenActionPoint(ActionPointType type, Action<Entity> action)
        {
            GetComponent<ActionPointComponent>().AddListener(type, action);
        }

        public void UnListenActionPoint(ActionPointType type, Action<Entity> action)
        {
            GetComponent<ActionPointComponent>().RemoveListener(type, action);
        }

        public void TriggerActionPoint(ActionPointType type, Entity action)
        {
            GetComponent<ActionPointComponent>().TriggerActionPoint(type, action);
        }
        #endregion


        public void ListenCondition(ConditionType type, Action action, object obj = null)
        {
            GetComponent<ConditionComponent>().AddListener(type, action, obj);
        }

        public void UnListenCondition(ConditionType type, Action action)
        {
            GetComponent<ConditionComponent>().RemoveListener(type, action);
        }
    }
}