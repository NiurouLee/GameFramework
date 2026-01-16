using System;
using System.Collections.Generic;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.TimerModule;
using UnityEngine;


namespace NFramework.Module.Combat
{
    public class SkillExecution : Entity, IAbilityExecution, IAwakeSystem<SkillAbility>
    {
        public Entity Ability { get; set; }
        public Combat Owner => GetParent<Combat>();
        public SkillAbility SkillAbility => (SkillAbility)Ability;
        public ExecutionConfigObject executionConfigObject;
        public List<Combat> TargetList = new List<Combat>();
        public Vector3 InputPoint;
        public float InputDirection;
        public bool ActionOccupy = true;

        public void Awake(SkillAbility a)
        {
            Ability = a;
        }

        public void LoadExecutionEffect()
        {
            AddComponent<ExecutionEffectComponent>();
            Framework.Instance.GetModule<TimerM>().NewOnceTimer((long)executionConfigObject.TotalTime * 1000, this.EndExecute);
        }

        public void BeginExecute()
        {
            GetParent<Combat>().SpellingSkillExecution = this;
            if (SkillAbility != null)
            {
                SkillAbility.Spelling = true;
            }
            GetComponent<ExecutionEffectComponent>().BeginExecute();
        }

        public void EndExecute()
        {
            TargetList.Clear();
            GetParent<Combat>().SpellingSkillExecution = null;
            if (SkillAbility != null)
            { SkillAbility.Spelling = false; }
            Dispose();
        }

        public void SpawnCollisionItem(ExecuteClipData clipData)
        {
            var abilityItem = Owner.GetRoot<CombatContext>().AddAbilityItem(this, clipData);
            if (clipData.CollisionExecuteData.MoveType == CollisionMoveType.FixedPosition)
            {
                FixedPositionItem(abilityItem);
            }
            if (clipData.CollisionExecuteData.MoveType == CollisionMoveType.FixedDirection)
            {
                FixedDirectionItem(abilityItem);
            }
            if (clipData.CollisionExecuteData.MoveType == CollisionMoveType.TargetFly)
            {
                TargetFlyItem(abilityItem);
            }
            if (clipData.CollisionExecuteData.MoveType == CollisionMoveType.ForwardFly)
            {
                ForwardFlyItem(abilityItem);
            }
            if (clipData.CollisionExecuteData.MoveType == CollisionMoveType.PathFly)
            {
                PathFlyItem(abilityItem);
            }
        }

        private void TargetFlyItem(AbilityItem abilityItem)
        {
            abilityItem.TransformComponent.Position = Owner.TransformComponent.Position;
            ExecuteClipData clipData = abilityItem.GetComponent<AbilityItemCollisionExecuteComponent>().ExecuteClipData;
            abilityItem.AddComponent<AbilityItemMoveWithDoTweenComponent>().DoMoveToWithTime(TargetList[0].TransformComponent, clipData.Duration);

        }

        private void ForwardFlyItem(AbilityItem abilityItem)
        {
            abilityItem.TransformComponent.Position = Owner.TransformComponent.Position;
            var x = Mathf.Sin(Mathf.Deg2Rad * InputDirection);
            var z = Mathf.Cos(Mathf.Deg2Rad * InputDirection);
            var destination = abilityItem.TransformComponent.Position + new Vector3(x, 0, z) * 30;
            abilityItem.AddComponent<AbilityItemMoveWithDoTweenComponent>().DoMoveTo(destination, 1f).OnMoveFinish(() =>
            {
                abilityItem.Dispose();
            });
        }

        private void PathFlyItem(AbilityItem abilityItem)
        {
            abilityItem.TransformComponent.Position = Owner.TransformComponent.Position;
            var clipData = abilityItem.GetComponent<AbilityItemCollisionExecuteComponent>().ExecuteClipData;
            var pointList = clipData.CollisionExecuteData.GetPointList();
            var angle = Owner.TransformComponent.Rotation.eulerAngles.y - 90;
            abilityItem.TransformComponent.Position = pointList[0].Position;
            var moveComp = abilityItem.AddComponent<AbilityItemBezierMoveComponent>();
            moveComp.abilityItem = abilityItem;
            moveComp.pointList = pointList;
            moveComp.originPosition = Owner.TransformComponent.Position;
            moveComp.rotateAgree = angle * MathF.PI / 180;
            moveComp.speed = clipData.Duration / 10;
            moveComp.DOMove();
            abilityItem.AddComponent<AbilityItemLifeTimeComponent, long>((long)(clipData.Duration * 1000));
        }

        private void FixedPositionItem(AbilityItem abilityItem)
        {
            var clipData = abilityItem.GetComponent<AbilityItemCollisionExecuteComponent>().ExecuteClipData;
            abilityItem.TransformComponent.Position = InputPoint;
            abilityItem.AddComponent<AbilityItemLifeTimeComponent, long>((long)(clipData.Duration * 1000));
        }

        private void FixedDirectionItem(AbilityItem abilityItem)
        {
            var clipData = abilityItem.GetComponent<AbilityItemCollisionExecuteComponent>().ExecuteClipData;
            abilityItem.TransformComponent.Position = Owner.TransformComponent.Position;
            abilityItem.TransformComponent.Rotation = Owner.TransformComponent.Rotation;
            abilityItem.AddComponent<AbilityItemLifeTimeComponent, long>((long)(clipData.Duration * 1000));
        }

    }
}