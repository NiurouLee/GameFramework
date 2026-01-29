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

                }
                var aiblity = CombatEntity.GetComponent<SkillComponent>().AttachSkill(config.Id);
                if(skillid==1001)CombatEntity.

            }
        }

        public void 
    }


}