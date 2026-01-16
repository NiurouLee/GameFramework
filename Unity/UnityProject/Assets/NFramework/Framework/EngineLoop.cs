using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

namespace NFramework
{
    public class EngineLoop : MonoBehaviour
    {
        public void Awake()
        {
            if (Instance != null)
            {
                throw new Exception("EngineLoop already created");
            }
            Instance = this;
            this.StartCoroutine(endOfFrame());
        }
        public static EngineLoop Instance { get; private set; }
        private WaitForEndOfFrame w = new WaitForEndOfFrame();
        private List<Action<float>> OnLateUpdateList = new List<Action<float>>();
        private List<Action<float>> OnUpdateList = new List<Action<float>>();
        private List<Action<float>> OnFixedUpdateList = new List<Action<float>>();
        private List<Action<float>> OnEndOfFrameUpdateList = new List<Action<float>>();
        private List<Action> OnApplicationQuitEventList = new List<Action>();
        private List<Action<bool>> OnApplicationFocusEventList = new List<Action<bool>>();
        private List<Action<bool>> OnApplicationPauseEventList = new List<Action<bool>>();

        public void AddUpdate(Action<float> value) { OnUpdateList.Add(value); }
        public void RemoveUpdate(Action<float> value) { OnUpdateList.Remove(value); }

        public void AddLateUpdate(Action<float> value) { OnLateUpdateList.Add(value); }
        public void RemoveLateUpdate(Action<float> value) { OnLateUpdateList.Remove(value); }

        public void AddFixedUpdate(Action<float> value) { OnFixedUpdateList.Add(value); }
        public void RemoveFixedUpdate(Action<float> value) { OnFixedUpdateList.Remove(value); }


        public void AddEndOfFrameUpdate(Action<float> value) { OnEndOfFrameUpdateList.Add(value); }
        public void RemoveEndOfFrameUpdate(Action<float> value) { OnEndOfFrameUpdateList.Remove(value); }


        public void AddOnApplicationQuitEvent(Action value) { OnApplicationQuitEventList.Add(value); }
        public void RemoveOnApplicationQuitEvent(Action value) { OnApplicationQuitEventList.Remove(value); }

        public void AddOnApplicationFocusEvent(Action<bool> value) { OnApplicationFocusEventList.Add(value); }
        public void RemoveOnApplicationFocusEvent(Action<bool> value) { OnApplicationFocusEventList.Remove(value); }

        public void AddOnApplicationPauseEvent(Action<bool> value) { OnApplicationPauseEventList.Add(value); }
        public void RemoveOnApplicationPauseEvent(Action<bool> value) { OnApplicationPauseEventList.Remove(value); }

        private IEnumerator endOfFrame()
        {
            while (true)
            {
                yield return w;
                for (int i = 0; i < OnEndOfFrameUpdateList.Count; i++)
                {
                    OnEndOfFrameUpdateList[i]?.Invoke(Time.deltaTime);
                }
            }
        }


        private void Update()
        {
            for (int i = 0; i < OnUpdateList.Count; i++)
            {
                OnUpdateList[i]?.Invoke(Time.deltaTime);
            }
        }

        private void FixedUpdate()
        {
            for (int i = 0; i < OnFixedUpdateList.Count; i++)
            {
                OnFixedUpdateList[i]?.Invoke(Time.fixedDeltaTime);
            }
        }

        private void LateUpdate()
        {
            for (int i = 0; i < OnLateUpdateList.Count; i++)
            {
                OnLateUpdateList[i]?.Invoke(Time.deltaTime);
            }
        }

        private void OnApplicationQuit()
        {
            for (int i = 0; i < OnApplicationQuitEventList.Count; i++)
            {
                OnApplicationQuitEventList[i]?.Invoke();
            }
        }

        private void OnApplicationFocus(bool hasFocus)
        {
            for (int i = 0; i < OnApplicationFocusEventList.Count; i++)
            {
                OnApplicationFocusEventList[i]?.Invoke(hasFocus);
            }
        }

        private void OnApplicationPause(bool pauseStatus)
        {
            for (int i = 0; i < OnApplicationPauseEventList.Count; i++)
            {
                OnApplicationPauseEventList[i]?.Invoke(pauseStatus);
            }
        }

    }

}
