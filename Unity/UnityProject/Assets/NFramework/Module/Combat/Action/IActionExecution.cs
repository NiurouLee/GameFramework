
using NFramework.Module.EntityModule;

namespace NFramework.Module.Combat
{
    public interface IActionExecution
    {
        public Entity ActionAbility { get; set; }
        public EffectAssignAction SourceAssignAction { get; set; }
        public Combat Creator { get; set; }
        public Combat Target { get; set; }
        public void FinishAction();

    }
}