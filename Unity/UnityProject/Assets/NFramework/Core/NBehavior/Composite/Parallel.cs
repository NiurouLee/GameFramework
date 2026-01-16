using System;
using System.Collections.Generic;
using NFramework.Core.Collections;
using UnityEngine.Assertions;

namespace NFramework.NBehavior
{
    /// <summary>
    /// 并行复合节点
    /// </summary>
    public class Parallel : Composite
    {
        public enum Policy
        {
            ONE,
            ALL,
        }


        private Policy failurePolicy;
        private Policy successPolicy;
        private int childrenCount = 0;
        private int runningCount = 0;
        private int succeededCount = 0;
        private int failedCount = 0;
        private Dictionary<Node, bool> childrenResult;
        private bool successState;
        private bool childrenAborted;

        public Parallel(Policy inSuccessPolicy, Policy inFailurePolicy) : base("Parallel")
        {
            this.successPolicy = inSuccessPolicy;
            this.failurePolicy = inFailurePolicy;
            this.childrenCount = 0;
            this.childrenResult = DictionaryPool.Alloc<Node, bool>();
        }

        protected override void DoStart()
        {
            for (int i = 0; i < children.Count; i++)
            {
                var child = children[i];
                Assert.AreEqual(child.CurrentState, State.INACTIVE);
            }
            childrenAborted = false;
            runningCount = 0;
            succeededCount = 0;
            failedCount = 0;
            for (int i = 0; i < children.Count; i++)
            {
                var child = children[i];
                runningCount++;
                child.Start();
            }
        }

        protected override void DoStop()
        {
            Assert.IsTrue(runningCount + succeededCount + failedCount == childrenCount);
            for (int i = 0; i < children.Count; i++)
            {
                var child = children[i];
                if (child.IsActive)
                {
                    child.Stop();
                }
            }
        }

        protected override void DoChildStopped(Node inChild, bool inResult)
        {
            runningCount--;
            if (inResult)
            {
                succeededCount++;
            }
            else
            {
                failedCount++;
            }
            childrenResult[inChild] = inResult;
            if (runningCount == 0)
            {
                if (!this.childrenAborted)
                {
                    if (failurePolicy == Policy.ONE && failedCount > 0)
                    {
                        successState = false;
                    }
                    else if (successPolicy == Policy.ONE && succeededCount > 0)
                    {
                        successState = true;
                    }
                    else if (successPolicy == Policy.ALL && succeededCount == childrenCount)
                    {
                        successState = true;
                    }
                    else
                    {
                        successState = false;
                    }
                }
                Stopped(successState);
            }
            else if (!this.childrenAborted)
            {
                Assert.IsFalse(succeededCount == childrenCount);
                Assert.IsFalse(failedCount == childrenCount);

                if (failurePolicy == Policy.ONE && failedCount > 0)
                {
                    successState = false;
                    childrenAborted = true;
                }
                else if (successPolicy == Policy.ONE && succeededCount > 0)
                {
                    successState = true;
                    childrenAborted = true;
                }

                if (childrenAborted)
                {
                    for (int i = 0; i < children.Count; i++)
                    {
                        var child = children[i];
                        if (child.IsActive)
                        {
                            child.Stop();
                        }
                    }
                }
            }
        }

        public override void StopLowePriorityChildrenForChild(Node inChild, bool inImmediateRestart)
        {
            if (inImmediateRestart)
            {
                Assert.IsFalse(inChild.IsActive);
                if (childrenResult[inChild])
                {
                    succeededCount--;
                }
                else
                {
                    failedCount--;
                }
                runningCount++;
                inChild.Start();
            }
            else
            {
                throw new NotImplementedException();
            }
        }
    }
}
