using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json;
using NFramework.Module.Combat;
using Org.BouncyCastle.Math.EC.Rfc7748;
using Sirenix.OdinInspector;
using Unity.VisualScripting;
using UnityEngine;

namespace Logic
{
    [CreateAssetMenu(fileName = "能力配置", menuName = "能力/能力配置")]
    public class AbilityConfigObject : SerializedScriptableObject
    {
        [LabelText("技能ID"), DelayedProperty]
        public int Id;
        [LabelText("显示名称")]
        public string ShowName;
        [HideInInspector]
        public SkillSpellType SkillSpellType;

        [HideInInspector]
        [ShowIf("SkillSpellType", SkillSpellType.Initiative)]
        public SkillAffectTargetType AffectTargetType;

        [HideInInspector]
        [LabelText("目标选取类型"), ShowIf("SkillSpellType", SkillSpellType.Initiative)]
        public SkillTargetSelectType TargetSelectType;

        [LabelText("触发点"), Space(30)]
        [ListDrawerSettings(DraggableItems = true, ShowItemCount = false, CustomAddFunction = "AddTrigger")]
        [HideReferenceObjectPicker]
        public List<TriggerConfig> TriggerActions = new List<TriggerConfig>();


        [LabelText("触发点"), Space(30)]
        [ListDrawerSettings(DraggableItems = true, ShowItemCount = false, HideAddButton = true)]
        [HideLabel, OnValueChanged("AddEffect"), ValueDropdown("EffectTypeSelect"), JsonIgnore]
        public string EffectTypeName = "(添加效果)";

        public IEnumerable<string> EffectTypeSelect()
        {
            var types = typeof(Effect).Assembly.GetTypes()
            .Where(x => !x.IsAbstract)
            .Where(x => typeof(Effect).IsAssignableFrom(x))
            .Where(x => x.GetCustomAttribute<EffectAttribute>() != null)
            .OrderBy(x => x.GetCustomAttribute<EffectAttribute>().Order)
            .Where(x => x.GetCustomAttribute<EffectAttribute>.EffectType);

            var results = types.ToList();
            results.Insert(0, "(添加效果)");
            return results;
        }

        private void AddEffect()
        {
            if(EffectTypeName!=("添加效果"))
            {
                var effectType= typeof(Effect).Assembly.GetTypes()
                .Where(x=>!x.IsAbstract)
                .Where(x=>typeof(Effect).IsAssignableFrom(x))
                .Where(x=>x.GetCustomAttribute<EffectAttribute>()!=null)
                .Where(x=>x.GetCustomAttribute<EffectAttribute>().EffectType==EffectTypeName)
                .FirstOrDefault();
            }
            var effect=Activator.CreateInstance(effectType) as Effect;
            effect.Enabled=true;
            effect.IsSkillEffect=true;
            Effects.Add(effect);
            EffectTypeName="(添加效果)";
        }
    }
}