using System;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using Ez.Core;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

namespace Game
{
    [System.Serializable]
    public enum FlyStyle
    {
        None = 0,
        DoubleFlyStyleOne = 1,
        DoubleFlyStyleTwo = 2,
        DoubleFlyStyleThree = 3,
        DoubleFlyStyleFour = 4,
        DoubleFlyStyleFive = 5,
        DoubleFlyStyleSix= 6,
    }

    [System.Serializable]
    public class FlyStyleParam 
    {
        [Header("飞行Style")] public FlyStyle flyStyle;
        [Header("前段比例变化")] public Vector2 flyStyleOneScale;
        [Header("后段比例变化")] public Vector2 flyStyleTwoScale;
        [Header("父节点左右方向的范围")] public Vector2 flyStyleRangeX;
        [Header("父节点上下方向的范围")] public Vector2 flyStyleRangeY;
        [Header("前段飞行时间")] public float flyStyleSectionOneFlyTime = 0.3f;
        [Header("后端飞行时间")] public float flyStyleSSectionTwoFlyTime = 0.6f;
        [Header("中间停留时间")] public float flyStyleStayTime = 0.3f;
    }

    public class MultiSegmentFlyController : MonoBehaviour
    {
        [Header("飞行物体")] public GameObject prefab;
        [Header("生成数量")] public int generateNum;
        [Header("起始位置")] public Transform startTransform;
        [Header("最终目的地")] public Transform endTransform;
        [Header("前段飞行时间")] private float sectionOneFlyTime = 0.3f;
        [Header("停留时间")] private float stayTime = 0.3f;
        [Header("后段飞行时间")] private float sectionTwoFlyTime = 0.6f;
        [Header("前段比例变化")] private Vector2 sectionOneFlyScale;
        [Header("后段比例变化")] private Vector2 sectionTwoFlyScale;
        [Header("父节点左右方向的范围")] private Vector2 rangeX;
        [Header("父节点上下方向的范围")] private Vector2 rangeY;
        [Space(50)]
        [Header("飞行轨迹")] public List<FlyStyleParam> flyStylePaLsts = new List<FlyStyleParam>();
        private Dictionary<FlyStyle, FlyStyleParam> flyStyleParams = null;
        [HideInInspector]
        public bool isAlreadySetMovPos;
        [HideInInspector]
        public Vector3 startPos = Vector3.zero;
        [HideInInspector]
        public Vector3 endPos = Vector3.zero;
        [HideInInspector]
        public string prefabName;
        [HideInInspector]
        public FlyStyle flyStyle = FlyStyle.None;
        //动画初始化完成时的回调
        public Action<List<GameObject>> allPrefabInstantiateFinishedCallback;
        //所有动画播放结束时的回调
        public Action<object> allAnimationFinishedCallback;
        // [Range(-800.0f, 0.0f)]
        // public float rangeLeftX;
        // [Range(0.0f, 800.0f)]
        // public float rangeRightX;
        // [Range(0.0f, 80.0f)]
        // public float rangeTopY;
        // [Range(-800.0f, 0.0f)]
        // public float rangeBottomY;
        public object allAnimFinishedCbParam;
        
        [FormerlySerializedAs("OnAllAnimationFinishedCallback")] [Header("所有动画播放结束时的回调")] [SerializeField]
        private UnityEvent m_onAllAnimationFinishedCallback = new();
        public UnityEvent OnAllAnimationFinishedCallback
        {
            get => m_onAllAnimationFinishedCallback;
            set => m_onAllAnimationFinishedCallback = value;
        }
        
        private List<MultiSegmentFlyComponent> flyComponentList = new List<MultiSegmentFlyComponent>();
        private int _tweenNum;
        private int _reachTargetNum;

        private Coroutine _coroutine;

        private void Start()
        {
            flyStyleParams = new Dictionary<FlyStyle, FlyStyleParam>();
            flyStylePaLsts.ForEach(styleParam =>
            {
                if (!flyStyleParams.ContainsKey(styleParam.flyStyle))
                {
                    flyStyleParams.Add(styleParam.flyStyle, styleParam);
                }
                else 
                {
#if UNITY_EDITOR
                    DevDebuger.LogError("多段飞行动画", string.Format("飞行曲线设置与飞行style重复！"));
#endif
                }
            });            
        }
        private void FlyEffectOne()
        {
            List<GameObject> prefabList = new List<GameObject>();
            for (int i = 0; i < generateNum; i++)
            {
                GameObject go = null;
                if (string.IsNullOrEmpty(prefabName))
                { 
                    go = Instantiate(prefab, Vector3.zero, Quaternion.identity);
                }
                else
                {
                    go = GameObjectPoolEx.Instance.Get(prefabName, prefab);
                }

                go.transform.SetParent(transform);
                //go.transform.localPosition = new Vector3(0, 0, 0);
                go.transform.position = startPos;
                go.transform.localScale = sectionOneFlyScale.x * Vector3.one;
                MultiSegmentFlyComponent flyComponent = go.GetComponent<MultiSegmentFlyComponent>();
                if (flyComponent == null)
                {
                    flyComponent = go.AddComponent<MultiSegmentFlyComponent>();
                }
                prefabList.Add(go);
                flyComponentList.Add(flyComponent);
                
            }
            allPrefabInstantiateFinishedCallback?.Invoke(prefabList);
            for (int i = 0; i < flyComponentList.Count; i++)
            {
                flyComponentList[i].FlyToOne(sectionOneFlyTime, sectionOneFlyScale.y, rangeX, rangeY);
            }
        }

        private IEnumerator FlyEffect()
        {
            //第一次飞行
            FlyEffectOne();
            yield return new WaitForSeconds(stayTime);
            //第二次飞行
            if (flyComponentList != null && flyComponentList.Count > 0)
            {
                while (flyComponentList.Count > 0)
                {
                    ShowNextAnimation();
                    yield return new WaitForSeconds(0.01f);
                }
            }
        }
        
        private void ShowNextAnimation()
        {
            var rm = Random.Range(0, flyComponentList.Count);
            flyComponentList[rm].FlyToTwo(endPos, sectionTwoFlyTime, sectionTwoFlyScale, prefabName, ReachTargetCallBack);
            flyComponentList.Remove(flyComponentList[rm]);
        }

        private void ReachTargetCallBack()
        {
            _reachTargetNum++;
            if (_reachTargetNum == generateNum)
            {
                AllAnimationFinished();
            }
        }
        
        private void AllAnimationFinished()
        {
            allAnimationFinishedCallback?.Invoke(allAnimFinishedCbParam);
            OnAllAnimationFinishedCallback?.Invoke();
        }
        
        private void SetBaseInfo()
        {
            if (!isAlreadySetMovPos)
            {
                startPos = startTransform.position;
                endPos = endTransform.position;
            }
            if (flyStyleParams == null)
            {
                flyStyleParams = new Dictionary<FlyStyle, FlyStyleParam>();
                for (int i = 0; i < flyStylePaLsts.Count; i++)
                {
                    if (!flyStyleParams.ContainsKey(flyStylePaLsts[i].flyStyle))
                    {
                        flyStyleParams.Add(flyStylePaLsts[i].flyStyle, flyStylePaLsts[i]);
                    }
                    else
                    {
#if UNITY_EDITOR
                        DevDebuger.LogError("多段飞行动画", string.Format("飞行曲线设置与飞行style重复！"));
#endif
                    }
                }
            }

            if (!flyStyleParams.ContainsKey(flyStyle))
            {
#if UNITY_EDITOR
                DevDebuger.LogError("多段飞行动画", string.Format("飞行曲线设置与飞行style不能为空！"));
#endif
            }
            else
            {
                sectionOneFlyScale = flyStyleParams[flyStyle].flyStyleOneScale;
                sectionTwoFlyScale = flyStyleParams[flyStyle].flyStyleTwoScale;
                rangeX = flyStyleParams[flyStyle].flyStyleRangeX;
                rangeY = flyStyleParams[flyStyle].flyStyleRangeY;
                sectionOneFlyTime = flyStyleParams[flyStyle].flyStyleSectionOneFlyTime;
                sectionTwoFlyTime = flyStyleParams[flyStyle].flyStyleSSectionTwoFlyTime;
                stayTime = flyStyleParams[flyStyle].flyStyleStayTime;
            }
            _reachTargetNum = 0;

            //异常情况下没有播放完成的先处理完再进行新的播放，保证不存留
            if (flyComponentList != null && flyComponentList.Count > 0)
            {
                while (flyComponentList.Count > 0)
                {
                    ShowNextAnimation();
                }
            }

            flyComponentList.Clear();
            if (_coroutine != null) 
            {
                StopCoroutine(_coroutine);
            }
        }

        public void PlayFlyEffect()
        {
            if (CheckValidate())
            {
                SetBaseInfo();
                //第二次飞行
                _coroutine = StartCoroutine(FlyEffect());
            }
        }

        private bool CheckValidate()
        {
            if (!isAlreadySetMovPos)
            {
                if (startTransform == null)
                {
#if UNITY_EDITOR
                    DevDebuger.LogError("多段飞行动画", string.Format("飞行的起始位置不能为空！"));
#endif
                    return false;
                }
                else if (endTransform == null)
                {
#if UNITY_EDITOR
                    DevDebuger.LogError("多段飞行动画", string.Format("飞行的最终目的地不能为空！"));
#endif
                    return false;
                }
            }

            if (prefab == null)
            {
#if UNITY_EDITOR
                DevDebuger.LogError("多段飞行动画", string.Format("飞行物体的prefab不能为空！"));
#endif
                return false;
            }
            else if (generateNum <= 0)
            {
#if UNITY_EDITOR
                DevDebuger.LogError("多段飞行动画", string.Format("生成数量应该大于0！"));
#endif
                return false;
            }
            else if (sectionOneFlyTime <= 0 || sectionTwoFlyTime <= 0)
            {
#if UNITY_EDITOR
                DevDebuger.LogError("多段飞行动画", string.Format("前段飞行时间和后段飞行时间应该大于0！"));
#endif
                return false;
            }

            return true;
        }
        
    }
}