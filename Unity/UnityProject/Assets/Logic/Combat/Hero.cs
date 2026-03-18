using DG.Tweening;
using NFramework.Module;
using NFramework.Module.Combat;
using NPOI.SS.Formula.Functions;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.UIElements;
using NFramework.Module.EntityModule;


namespace Logic.Combat
{
    /// <summary>
    /// 
    /// </summary>
    public sealed class Hero : MonoBehaviour
    {
        /// <summary>
        /// 战斗单元
        /// </summary>
        public CombatEntity CombatEntity;
        /// <summary>
        /// 动画组件
        /// </summary>
        public AnimationComponent AnimationComponent;
        public float MoveSpeed = 1f;
        public float AnimTime = 0.05f;
        public GameObject AttackPrefab;
        public GameObject SkillEffectPrefab;
        public GameObject HitEffectPrefab;
        public Transform InventoryPanelTrm;
        public Transform EquipmentPanelTrm;
        public GameObject ItemPrefab;
        public UnityEngine.UI.Text DamageText;
        public UnityEngine.UI.Text CureText;
        public UnityEngine.UI.Image HealthBatImage;
        public Transform CanvasTrm;
        private Tweener MoveTweener { get; set; }
        private Tweener LookAtTweener { get; set; }
        public static Hero Instance { get; set; }
        public Vector3 Position { get; set; }
        public Vector3 Rotation { get; set; }
        public bool SkillPlaying { get; set; }
        private int combatContextId = 1;
        /// <summary>
        ///战斗上下文 
        /// </summary>
        private CombatContext combatContext;

        /// <summary>
        /// 外层管理 
        /// </summary>
        private SkillComponent SkillComponent;
        void Start()
        {
            Instance = this;
            ///创建战斗上下文
            this.combatContext = NFROOT.Instance.GetM<CombatM>().CreateCombatContext(combatContextId);
            ///添加一个战斗单元 CombatEntityAwake里已经创建好了各种Component
            this.CombatEntity = this.combatContext.AddChild<CombatEntity>();
            //添加映射gameObject2CombatEntity
            this.combatContext.GameObject2Entity.Add(this.gameObject, CombatEntity);

            CombatEntity.ListenActionPoint(ActionPointType.PreSpell, OnPreSpell);
            CombatEntity.ListenActionPoint(ActionPointType.PostSpell, OnPostSpell);
            CombatEntity.ListenActionPoint(ActionPointType.PostReceiveDamage, OnReceiveDamage);
            CombatEntity.ListenActionPoint(ActionPointType.PostReceiveCure, OnReceiveCure);
            CombatEntity.ListenActionPoint(ActionPointType.PostReceiveStatus, OnReceiveSatus);




            ///扣除血量
            this.CombatEntity.CurrentHealth.Minus(30000);


            // var allConfigs = ConfigHelper.GetAll<AbilityConfigObject>().Values.ToArray();
            ///获取能力配置（技能）
            AbilityConfig[] abilityConfigObjects = new AbilityConfig[10];
            ///绑定技能和按键的映射
            for (int i = 0; i < abilityConfigObjects.Length; i++)
            {
                var config = abilityConfigObjects[i];
                if (config.Type != "Skill")
                {
                    continue;
                }
                var skillid = config.Id;
                if (skillid == 3001)
                {
                    continue;
                }
                var SkillComponent = CombatEntity.GetComponent<SkillComponent>();
                SkillComponent = this.SkillComponent;
                var aiblity = SkillComponent.AttachSkill(config.Id);
                if (skillid == 1001) SkillComponent.BindSkillInput(KeyCode.Q, skillid);
                if (skillid == 1002) SkillComponent.BindSkillInput(KeyCode.W, skillid);
                if (skillid == 1003) SkillComponent.BindSkillInput(KeyCode.E, skillid);
                if (skillid == 1004) SkillComponent.BindSkillInput(KeyCode.R, skillid);
            }
            CombatEntity.GetComponent<SpellSkillComponent>().LoadExecutionObjects();
            HealthBatImage.fillAmount = this.CombatEntity.CurrentHealth.Percent();
            //设置UI血量
        }

        void Update()
        {
            var transformComponent = CombatEntity.GetComponent<TransformComponent>();
            transformComponent.Position = this.transform.position;
            transformComponent.Rotation = this.transform.rotation;
            if (CombatEntity.SpellingSkillExecution != null && CombatEntity.SpellingSkillExecution.ActionOccupy)
            {
                return;
            }
            if (Input.GetMouseButton((int)MouseButton.RightMouse))
            {
                if (RaycastHelper.CastMapPoint(out var point))
                {
                    var time = Vector3.Distance(this.transform.position, point) * MoveSpeed * 0.5f;
                    StopMove();
                    MoveTweener = transform.DOMove(point, time).SetEase(Ease.Linear).OnComplete
                    (
                        () => { AnimationComponent.PlayAnimation(AnimationType.Idle); }
                    );
                    LookAtTweener = this.transform.GetChild(0).DOLookAt(point, 0.2f);
                    AnimationComponent.PlayAnimation(AnimationType.Walk);
                }
            }
        }

        public void OnPreSpell(Entity combatAction)
        {
            if (combatAction is SpellSkillAction spellAction)
            {
                var thisTransform = this.CombatEntity.TransformComponent;
                if (spellAction.InputTarget != null)
                {
                    var targetPos = spellAction.InputTarget.TransformComponent.Position;
                    thisTransform.Rotation = Quaternion.LookRotation(targetPos - thisTransform.Position);
                }
                else if (spellAction.InputPoint != Vector3.zero)
                {
                    var targetPos = spellAction.InputPoint;
                    thisTransform.Rotation = Quaternion.LookRotation(targetPos - thisTransform.Position);
                }
                DisableMove();
                if (spellAction.SkillExecution != null)
                {
                    if (spellAction.SkillExecution.InputTarget != null)
                    {
                        this.transform.LookAt(spellAction.SkillExecution.InputTarget.TransformComponent.Position);
                    }
                    else if (spellAction.SkillExecution.InputPoint != null)
                    {
                        this.transform.LookAt(spellAction.SkillExecution.InputPoint);
                    }
                    else
                    {
                        this.transform.localEulerAngles = new Vector3(0, spellAction.SkillExecution.InputRadian, 0);
                    }
                    thisTransform.Position = transform.position;
                    thisTransform.Rotation = transform.localRotation;
                }
            }
        }

        private void OnPostSpell(Entity CombatAction)
        {
            if (CombatAction is SpellSkillAction spellAction)
            {
                if (spellAction.SkillExecution != null)
                {
                    AnimationComponent.PlayAnimation(AnimationType.Idle);
                }
            }
        }

        /// <summary>
        /// 掉血
        /// </summary>
        /// <param name="combatAction"></param>
        private void OnReceiveDamage(Entity combatAction)
        {
            if (combatAction is DamageAction damageAction)
            {
                HealthBatImage.fillAmount = CombatEntity.CurrentHealth.Percent();
            }
        }

        /// <summary>
        /// 加血
        /// </summary>
        /// <param name="combatAction"></param>
        private void OnReceiveCure(Entity combatAction)
        {
            if (combatAction is CureAction cureAction)
            {
                HealthBatImage.fillAmount = CombatEntity.CurrentHealth.Percent();
            }
        }

        private void OnReceiveSatus(Entity combatAction)
        {
        }


        public void StopMove()
        {
            MoveTweener?.Kill();
            LookAtTweener?.Kill();
        }

        public void DisableMove()
        {
            MoveTweener?.Kill();
            LookAtTweener?.Kill();
            CombatEntity.GetComponent<MotionComponent>().Enable = false;
        }

        public void Attack()
        {
            if (CombatEntity.AttackSpellAbility.TryMakeAction(out AttackAction action))
            {
                action.Target = CombatEntity;
                SpawnLinEffect(AttackPrefab, this.transform.position, action.Target.TransformComponent.Position);
                SpawnHitEffect(this.transform.position, action.Target.TransformComponent.Position);
                CombatEntity.GetComponent<AttributeComponent>().Attack.BaseValue = 999;
                action.ApplyAttack();
            }

        }

        private void SpawnLinEffect(GameObject effectPrefab, Vector3 p1, Vector3 p2)
        {
            var attackEffect = Instantiate(effectPrefab);
            attackEffect.transform.position = Vector3.up;
            attackEffect.GetComponent<LineRenderer>().SetPosition(0, p1);
            attackEffect.GetComponent<LineRenderer>().SetPosition(1, p2);
            Destroy(attackEffect, 1f);
        }

        private void SpawnHitEffect(Vector3 p1, Vector3 p2)
        {
            var vec = p1 - p2;
            var hitPoint = p2 + vec.normalized * 0.6f;
            hitPoint += Vector3.up;
            var hitEffect = Instantiate(HitEffectPrefab);
            hitEffect.transform.position = hitPoint;
            Destroy(hitEffect, 1f);
        }




    }


}