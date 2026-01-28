using Sirenix.OdinInspector;

namespace Logic
{
    public class AbilityConfigObject : SerializedScriptableObject
    {
        [LabelText("技能ID"), DelayedProperty]
        public int Id;

        [LabelText("显示名称")]
        public string ShowName;

        public SkillSpellType SkillSpellType;
    }
}