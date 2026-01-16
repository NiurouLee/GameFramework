using System;
using System.Collections.Generic;
using Coffee.UIExtensions;
using Ez.Core;
using Game;
using gen.rawdata;
using UnityEngine;

namespace Ez.UI
{
    public enum UIEffectBindType
    {
        start, //启动后加载
        delay, //延迟加载
        manual //手动加载
    }

    /// <summary>
    /// 特效挂载组件
    /// </summary>
    public class UIEffectBind : MonoBehaviour, Ez.Core.IRelease
    {
        [Header("特效数据表ID")] public string id;
        [Header("加载时机类型，如果不填写ID则不会自动加载")] public UIEffectBindType type = UIEffectBindType.start;
        [Header("延时时间")] public float delayTime = 0.5f;
        [Header("缩放")] public float Scale = 1;
        int _sort = 0;
        GameObject effect;
        private UIParticle particle;
        public Action onPlayEffectEnd;

        public int sort
        {
            get { return _sort; }
            set
            {
                _sort = value;
                if (effect)
                    ChangeObjSorting(effect, _sort);
            }
        }

        TEffectRes rescfg;
        UIControllerBase m_uiController;
        private GameTimerInfo delaytmid;
        private GameTimerInfo oncetmid;

        int _audioPlayID = -1;
        
        /// <summary>
        /// 静态 在界面init的时候会调用这个
        /// </summary>
        /// <param name="uiController"></param>
        /// <param name="immediatelyPlay"></param>
        public void LoadEffect(UIControllerBase uiController,bool immediatelyPlay=true)
        {
            m_uiController = uiController;
            rescfg = gen.conf.Data.GetTEffectRes(id);
            if (rescfg != null)
            {
                if (type == UIEffectBindType.delay)
                {
                    isPlaying = immediatelyPlay;
                    uiController.RemoveTaskTime(delaytmid);
                    delaytmid = uiController.StartTaskTime(delayTime, 1, () => uiController.LoadEffect(rescfg, this));
                }
                else if (type == UIEffectBindType.start)
                {
                    isPlaying = immediatelyPlay;
                    uiController.LoadEffect(rescfg, this);
                }
            }
            else
            {
                //   DevDebuger.LogError("UIEffectBind", $"{uiController.GetType().FullName}_{this.gameObject.name}_{id}");
            }
        }
        /// <summary>
        /// 预加载
        /// </summary>
        /// <param name="uiController"></param>
        public void preloaded(UIControllerBase uiController)
        {
            m_uiController = uiController;
            rescfg = gen.conf.Data.GetTEffectRes(id);
            if (rescfg != null)
            {
                isLoadding = true;
                uiController.LoadEffect(rescfg, this);
            }
            else
            {
                DevDebuger.LogError("UIEffectBind", $"{uiController.GetType().FullName}_{this.gameObject.name}_{id}");
            }
        }

        bool isLoadding = false;
        private bool isPlaying = false;
        public bool IsPlaying => isPlaying;

        /// <summary>
        /// 动态加载预备数据
        /// </summary>
        /// <param name="uiController"></param>
        public void PlayEffect()
        {
            isPlaying = true;
            if (effect)
            {
                effect.SetActive(false);
                effect.SetActive(true);
                PlayeTryOnece();
                return;
            }

            if (isLoadding)
            {
                return;
            }
            if (type == UIEffectBindType.manual)
            {
                if (effect == null && rescfg != null)
                {
                    isLoadding = true;
                    m_uiController.LoadEffect(rescfg, this);
                }
            }
        }

        public void StopEffect(bool destroy = false)
        {
            isPlaying = false;
            if (effect)
            {
                if (destroy)
                {
                    Release();
                }
                else
                {
                    PlayAudio(false);
                    effect.SetActive(false);
                }
            }
        }

        void PlayeTryOnece()
        {
            PlayAudio(true);
            if (this.rescfg != null && this.rescfg.IsOnce == 1)
            {
                m_uiController.RemoveTaskTime(oncetmid);
                oncetmid = m_uiController.StartTaskTime(this.rescfg.Tm / 1000f, 1, OnPlayEffectEnd);
            }
        }

        private void OnPlayEffectEnd()
        {
            if(effect == null)
            {
                return;
            }
            effect.gameObject.ExSetActive(false);
            onPlayEffectEnd?.Invoke();
        }

        /// <summary>
        /// 动态加载使用这个
        /// </summary>
        /// <param name="uiController"></param>
        /// <param name="_id"></param>
        public void LoadEffect(UIControllerBase uiController, string _id)
        {
            id = _id;
            rescfg = gen.conf.Data.GetTEffectRes(_id);
            if (rescfg != null)
            {
                isLoadding = true;
                uiController.LoadEffect(rescfg, this);
            }
            else
            {
                DevDebuger.LogError("UIEffectBind", $"{uiController.GetType().FullName}_{this.gameObject.name}_{id}");
            }
        }

        LoadObject LoadObject;

        //添加一个对象到节点下
        public void AddEffect(LoadObject objdata)
        {
            if (effect)
            {
                DevDebuger.LogError("UIEffectBind", "可能重复加载" + objdata.resid);
                LoadObject?.DoRelease();
                LoadObject = null;
                effect = null;
            }

            LoadObject = objdata;
            effect = objdata.gameObject;
            objdata.gameObject.transform.SetParent(this.transform);
            objdata.gameObject.transform.localPosition = Vector3.zero;
            objdata.gameObject.transform.localScale = Vector3.one;
            objdata.gameObject.transform.localRotation = Quaternion.identity;
            particle = effect.GetOrAddComponent<UIParticle>();
            particle.enabled = true;
            particle.maskable = true;
            particle.meshSharing = UIParticle.MeshSharing.None;
            particle.scale = Scale;
            particle.autoScalingMode = UIParticle.AutoScalingMode.UIParticle;
            isLoadding = false;
            if (isPlaying)
            {
                PlayeTryOnece();
            }
            else
            {
                effect.gameObject.ExSetActive(false);
            }
            // ChangeObjSorting(objdata.gameObject, sort + 1);
        }

        Dictionary<int, int> orgSort = new Dictionary<int, int>();

        void ChangeObjSorting(GameObject go, int sort, int layer = 5)
        {
            foreach (Renderer r in go.GetComponentsInChildren<Renderer>(true))
            {
                //r.sortingLayerID = layer;
                int _id = r.GetInstanceID();
                if (!orgSort.ContainsKey(_id))
                {
                    orgSort.Add(_id, r.sortingOrder);
                }

                r.sortingOrder = orgSort[_id] + sort;
            }
        }

        void RevertSort()
        {
            if (effect)
            {
                foreach (Renderer r in effect.GetComponentsInChildren<Renderer>(true))
                {
                    if (orgSort.TryGetValue(r.GetInstanceID(), out var i))
                    {
                        r.sortingOrder = i;
                    }
                }
            }

            orgSort.Clear();
        }

        private void PlayAudio(bool play)
        {
            if (this.rescfg != null&& !string.IsNullOrEmpty(rescfg.Soundid))
            {
                if (play)
                {
                    _audioPlayID = AudioManager.GetInstance().PlayAudio(rescfg.Soundid);
                }
                else
                {
                    AudioManager.GetInstance().StopAudio(_audioPlayID);
                }
            }
        }
        

        public void SetParticleScale(float scale)
        {
            if (isPlaying && particle != null)
            {
                Scale = scale;
                particle.scale = Scale;
            }
        }
        

        public void Release()
        {
            // RevertSort();
            if (effect)
            {
                LoadObject?.DoRelease();
                //ResPoolLoader.GetInstance().OnRelease(rescfg.Resid, effect);
                effect = null;
                LoadObject = null;
            }
            PlayAudio(false);
        }

        private void OnDestroy()
        {
            Release();
        }
    }
}