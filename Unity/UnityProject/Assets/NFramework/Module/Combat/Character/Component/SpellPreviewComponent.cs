namespace NFramework.Module.Combat
{
    public class SpellPreviewComponent : Entity
    {
        public CombatEntity OwnerEntity = GetParent<CombatEntity>();
        public SpellComponent SpellComponent => Parent.GetComponent<SpellComponent>();

        public v
    }
}