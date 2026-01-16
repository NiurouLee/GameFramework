using NFramework.Module.EntityModule;
using NFramework.Module.EventModule;

namespace NFramework.Module.Combat
{
    public class ExecutionEffectParticleEffectComponent : Entity
    {
        public Combat Owner => GetParent<SkillExecution>().Owner;

        public void OnTriggerExecutionEffect(ExecutionEffect executionEffect)
        {
            var @event = new SyncParticleEffect(Owner.Id, executionEffect.executeClipData.ParticleEffectData.ParticleEffectName, Owner.TransformComponent.Position, Owner.TransformComponent.Rotation);
            Framework.I.G<EventM>().D.Fire(ref @event);
        }

        public void OnTriggerExecutionEffectEnd(ExecutionEffect executionEffect)
        {
            var @event = new SyncDeleteParticleEffect(Owner.Id, executionEffect.executeClipData.ParticleEffectData.ParticleEffectName);
            Framework.I.G<EventM>().D.Fire(ref @event);
        }
    }
}