using System;
using System.Collections;

namespace NFramework.Module.EngineWrapper
{
    public class EngineWrapperM : IFrameWorkModule
    {
        public void AddUpdate(Action<float> value) { EngineLoop.Instance.AddUpdate(value); }
        public void RemoveUpdate(Action<float> value) { EngineLoop.Instance.RemoveUpdate(value); }

        public void AddLateUpdate(Action<float> value) { EngineLoop.Instance.AddLateUpdate(value); }
        public void RemoveLateUpdate(Action<float> value) { EngineLoop.Instance.RemoveLateUpdate(value); }

        public void AddFixedUpdate(Action<float> value) { EngineLoop.Instance.AddFixedUpdate(value); }
        public void RemoveFixedUpdate(Action<float> value) { EngineLoop.Instance.RemoveFixedUpdate(value); }


        public void AddEndOfFrameUpdate(Action<float> value) { EngineLoop.Instance.AddEndOfFrameUpdate(value); }
        public void RemoveEndOfFrameUpdate(Action<float> value) { EngineLoop.Instance.RemoveEndOfFrameUpdate(value); }


        public void AddOnApplicationQuitEvent(Action value) { EngineLoop.Instance.AddOnApplicationQuitEvent(value); }
        public void RemoveOnApplicationQuitEvent(Action value) { EngineLoop.Instance.RemoveOnApplicationQuitEvent(value); }

        public void AddOnApplicationFocusEvent(Action<bool> value) { EngineLoop.Instance.AddOnApplicationFocusEvent(value); }
        public void RemoveOnApplicationFocusEvent(Action<bool> value) { EngineLoop.Instance.RemoveOnApplicationFocusEvent(value); }

        public void AddOnApplicationPauseEvent(Action<bool> value) { EngineLoop.Instance.AddOnApplicationPauseEvent(value); }
        public void RemoveOnApplicationPauseEvent(Action<bool> value) { EngineLoop.Instance.RemoveOnApplicationPauseEvent(value); }

        public void StartCoroutine(IEnumerator coroutine)
        {
            EngineLoop.Instance.StartCoroutine(coroutine);
        }

        public void StopCoroutine(IEnumerator coroutine)
        {
            EngineLoop.Instance.StopCoroutine(coroutine);
        }
    }
}