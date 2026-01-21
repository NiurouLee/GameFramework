using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using NFramework.Module.EntityModule;
using NFramework.Module.IDGeneratorModule;
using NFramework.Module.TimeInfoModule;

namespace NFramework.Module
{
    public class NFROOT : Entity
    {
        private static NFROOT m_Instance;
        public static NFROOT I => Instance;

        private List<Action<float>> OnLateUpdateList = new();
        private List<Action<float>> OnUpdateList = new();
        private List<Action<float>> OnFixedUpdateList = new();
        private List<Action<float>> OnEndOfFrameUpdateList = new();
        private List<Action> OnApplicationQuitEventList = new();
        private List<Action<bool>> OnApplicationFocusEventList = new();
        private List<Action<bool>> OnApplicationPauseEventList = new();

        public void AddLateUpdateCallback(Action<float> callback)
        {
            OnLateUpdateList.Add(callback);
        }

        public void AddUpdateCallback(Action<float> callback)
        {
            OnUpdateList.Add(callback);
        }

        public void AddFixedUpdateCallback(Action<float> callback)
        {
            OnFixedUpdateList.Add(callback);
        }

        public void AddEndOfFrameCallback(Action<float> callback)
        {
            OnEndOfFrameUpdateList.Add(callback);
        }

        public void AddApplicationQuitCallback(Action<bool> callback)
        {
        }

        public UnityEngine.Coroutine StartCoroutine(IEnumerator enumerator)
        {
            return EngineLoop.Instance.StartCoroutine(enumerator);
        }

        public void StopCoroutine(UnityEngine.Coroutine coroutine)
        {
            EngineLoop.Instance.StopCoroutine(coroutine);
        }


        public static void AwakeRoot()
        {
            m_Instance = Entity.CreateRoot<NFROOT>();
            m_Instance.RegisterEngineLoop();
            var ins = Instance;
            NFROOT.Instance.Awake();
        }

        /// <summary>
        /// 按类型存储
        /// </summary>
        public Dictionary<Type, FrameworkModule> m_modulesDict;

        public HashSet<FrameworkModule> m_modules;

        public void Awake()
        {
            this.m_modulesDict = new Dictionary<Type, FrameworkModule>();
            this.m_modules = new HashSet<FrameworkModule>()
            {
                new EntitySystemM(),
                new TimeInfoM(),
                new IDGeneratorM(),
            };
            foreach (var module in this.m_modules)
            {
                this.m_modulesDict.Add(module.GetType(), module);
            }

            EngineLoop.Instance.OnEndOfFrameUpdateList.Add(this.LateAddChild);
        }

        private void LateAddChild(float deltaTime)
        {
            foreach (var module in this.m_modules)
            {
                this.AddChild(module);
            }

            EngineLoop.Instance.OnEndOfFrameUpdateList.Remove(this.LateAddChild);
        }

        public static NFROOT Instance
        {
            get
            {
                if (m_Instance == null)
                {
                    m_Instance = Entity.CreateRoot<NFROOT>();
                    m_Instance.RegisterEngineLoop();
                }

                return m_Instance;
            }
        }


        public T G<T>() where T : FrameworkModule, new()
        {
            return GetModule<T>();
        }

        public T GetModule<T>() where T : FrameworkModule, new()
        {
            var type = typeof(T);
            if (m_modulesDict.TryGetValue(type, out var module))
            {
                return (T)module;
            }
            module = this.AddChild<T>();
            m_modulesDict.Add(type, module);
            return (T)module;
        }

        private void RegisterEngineLoop()
        {
            EngineLoop.Instance.OnEndOfFrameUpdateList = this.OnEndOfFrameUpdateList;
            EngineLoop.Instance.OnLateUpdateList = this.OnLateUpdateList;
            EngineLoop.Instance.OnUpdateList = this.OnUpdateList;
            EngineLoop.Instance.OnFixedUpdateList = this.OnFixedUpdateList;
            EngineLoop.Instance.OnApplicationQuitEventList = this.OnApplicationQuitEventList;
            EngineLoop.Instance.OnApplicationFocusEventList = this.OnApplicationFocusEventList;
            EngineLoop.Instance.OnApplicationPauseEventList = this.OnApplicationPauseEventList;
        }
    }
}