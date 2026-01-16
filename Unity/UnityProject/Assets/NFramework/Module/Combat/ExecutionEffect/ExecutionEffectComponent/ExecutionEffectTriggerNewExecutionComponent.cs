using NFramework.Module.EntityModule;

namespace NFramework.Module.Combat
{
    public class ExecutionEffectTriggerNewExecutionComponent : Entity
    {
        public Combat Owner => GetParent<SkillExecution>().Owner;

        public void OnTriggerExecutionEffect(ExecutionEffect executionEffect)
        {
            ExecutionConfigObject executionObject = Owner.AttachExecution(executionEffect.executeClipData.actionEventData.NewExecutionId);
            if (executionObject == null)
            {
                return;
            }
            var parentExecution = parent.GetParent<SkillExecution>();
            var execution = parentExecution.Owner.AddChild<SkillExecution, SkillAbility>(parentExecution.SkillAbility);
            execution.executionConfigObject = executionObject;
            execution.InputPoint = parentExecution.InputPoint;
            execution.InputDirection = parentExecution.InputDirection;
            execution.LoadExecutionEffect();
            execution.BeginExecute();
        }
    }
}