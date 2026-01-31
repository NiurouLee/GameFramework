using DG.Tweening;
using NFramework.Module;
using NFramework.Module.Combat;
using NFramework.Module.ResModule;
using NPOI.SS.Formula.Functions;
using UnityEngine;

namespace Logic.Combat
{
    public sealed class Hero : MonoBehaviour
    {
        public CombatEntity CombatEntity;
        public AnimationComponent AnimationComponent;
        public float MoveSpeed = 1f;
        public float AnimTime = 0.05f;
        public GameObject AttackPrefab;
        public GameObject SkillEffectPrefab;
        public GameObject HitEffectPrefab;
        public Transform InventoryPanelTrm;
        public Transform EquipmentPanelTrm;
        public GameObject ItemPrefab;
        public Text DamageText;
        public Text CureText;
        public UnityEngine.UI.Image HealthBatImage;
        public Transform CanvasTrm;
        private Tweener MoveTweener { get; set; }
        private Tweener LookAtTweener { get; set; }
        public static Hero Instance { get; set; }
        public Vector3 Position { get; set; }
        public Vector3 Rotation { get; set; }
        public bool SkillPlaying { get; set; }
        private int combatContextId = 1;
        private CombatContext combatContext;
    
        private SkillComponent SkillComponent;
        void Start()
        {
            Instance = this;
            this.combatContext = NFROOT.Instance.GetM<CombatM>().CreateCombatContext(combatContextId);
            this.CombatEntity = this.combatContext.AddChild<CombatEntity>();
            this.combatContext.GameObject2Entity.Add(this.gameObject, CombatEntity);

            this.CombatEntity.CurrentHealth.Minus(30000);
            // var allConfigs = ConfigHelper.GetAll<AbilityConfigObject>().Values.ToArray();
            AbilityConfig[] abilityConfigObjects = new AbilityConfig[10];
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

        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Q))
            {
                SkillComponent.TryUseSkill(KeyCode.Q);
            }
            if (Input.GetKeyDown(KeyCode.W))
            {
                CombatEntity.GetComponent<SkillComponent>().TryUseSkill(KeyCode.W);
            }
            if (Input.GetKeyDown(KeyCode.E))
        }

    }


}