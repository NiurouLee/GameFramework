
using NFramework.Module.EntityModule;

namespace NFramework.Module.Combat
{
    public interface IAbilityExecution
    {
        public Entity Ability { get; set; }
        public Combat Owner { get; }
        public void BeginExecute();
        public void EndExecute();
    }
}