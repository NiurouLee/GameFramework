using System;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;
#if UNITY_EDITOR
using DG.DemiEditor;
#endif

namespace Game
{
    public class FlyEffectComponent : MonoBehaviour
    {
        private class AnimationMoveObject
        {
            public int index;
            public GameObject gameObject;
            public float elapseTime;
            public bool isPlaying;
            public bool isStop;

            public AnimationMoveObject(int index, GameObject go, float originTime, Transform parent = null,
                LayerMasks layer = LayerMasks.Default)
            {
                this.index = index;
                gameObject = go;
                elapseTime = originTime;
                isPlaying = false;
                isStop = false;
                go.transform.SetParent(parent);
                go.SetLayerInt((int)layer, true);
            }

            public void ResetAnimationObject(Vector3 originPos, bool isOneByOne)
            {
                gameObject.transform.position = originPos;
                gameObject.transform.rotation = Quaternion.identity;
                gameObject.transform.localScale = Vector3.zero;
                elapseTime = 0;
                isPlaying = false;
                isStop = false;
                gameObject.SetActive(!isOneByOne);
            }
        }

        public enum ProjectionMode
        {
            Perspective,
            Orthographic,
        }

        public enum AnimationCurveMode
        {
            Bezier,
            Space,
        }
        

        [Header("起始点")]
        public Transform startTrans;
        [Header("起始点相机模式")]
        public bool isUICameraStart;
        [Header("目标点")]
        public Transform endTrans;
        [Header("目标点相机模式")]
        public bool isUICameraEnd;
        [Header("控制点1")]
        public Transform controllerTrans1;
        [Header("控制点1相机模式")]
        public bool isUICameracontroller1;
        [Header("控制点2")]
        public Transform controllerTrans2;
        [Header("控制点2相机模式")]
        public bool isUICameracontroller2;
        [Header("投影模式")] 
        public ProjectionMode projectionMode = ProjectionMode.Perspective;
        [Header("相机跟随")] 
        public bool cameraFollow;
        [Header("移动物体")] 
        public GameObject prefab;
        [Header("移动物体的资源ID")]
        public string prefabResId;
        [Header("动画曲线模式")]
        public AnimationCurveMode animationCurveMode = AnimationCurveMode.Bezier;
        [Header("动画速度曲线（X轴为从0到1,只对控制点模式使用）")] 
        public AnimationCurve animationSpeedCurve; //x轴是移动时间，y轴是移动量
        [Header("动画缩放曲线（X轴为从0到1）")] 
        public AnimationCurve animationScaleCurve; //x轴是移动时间，y轴是移动量
        [Header("动画位置曲线X轴（X轴为从0到1）")] 
        public AnimationCurve animationPositionXCurve; 
        [Header("动画位置曲线Y轴（X轴为从0到1）")] 
        public AnimationCurve animationPositionYCurve; 
        [Header("生成的物体数量")] 
        public int generateNum = 1;
        [Header("生成物体的父节点")] 
        public Transform parentTransform;
        [Header("逐个生成")] 
        public bool isOneByOne;
        [Header("每个物体间的移动时间间隔（单位秒，数值要大于0）")] 
        public float moveIntervalTime = 0.5f;
        [Header("从起始点移动到目标点所需的时间（单位秒，数值要大于0）")]
        public float moveTime = 1.0f;
        [Header("初始化后，自动播放动画")]
        public bool autoPlay;
        [Header("播放完自动销毁")]
        public bool autoDestroy = true;
        [Header("编辑曲线模式")] 
        public bool isEditorMode;
        [HideInInspector][Header("是否执行Start")]
        public bool isIgnoreStart;
        [HideInInspector]
        public Vector3 startPos = Vector3.zero;
        [HideInInspector]
        public Vector3 endPos = Vector3.zero;
        [HideInInspector]
        public Vector3 controllerPos1 = Vector3.zero;
        [HideInInspector]
        public Vector3 controllerPos2 = Vector3.zero;
        [HideInInspector]
        public bool isAlreadySetMovPos;
        [HideInInspector]
        public LayerMasks layerMask = LayerMasks.Default;
        
        //动画初始化完成时的回调
        public Action<List<GameObject>> allPrefabInstantiateFinishedCallback;

        [FormerlySerializedAs("OnSingleAnimationFinishedCallback")] [Header("单个动画播放结束时的回调")] [SerializeField]
        private UnityEvent m_onSingleAnimationFinishedCallback = new();
        public UnityEvent OnSingleAnimationFinishedCallback
        {
            get => m_onSingleAnimationFinishedCallback;
            set => m_onSingleAnimationFinishedCallback = value;
        }

        [FormerlySerializedAs("OnAllAnimationFinishedCallback")] [Header("所有动画播放结束时的回调")] [SerializeField]
        private UnityEvent m_onAllAnimationFinishedCallback = new();
        public UnityEvent OnAllAnimationFinishedCallback
        {
            get => m_onAllAnimationFinishedCallback;
            set => m_onAllAnimationFinishedCallback = value;
        }
        
        
        private bool initialized;
        private bool isLoadFinished;
        private List<AnimationMoveObject> animationMoveObjectList = new List<AnimationMoveObject>();
        private int totalNum;
        private int animationStopNum;
        private LineRenderer lineRenderer;
        private int _segmentNum = 100;
        private Tween _tween;
        private int _tweenNum;
        private Dictionary<int, LoadObject> loadDataDic = new Dictionary<int, LoadObject>();

        public void StartFlyAnimation()
        {
            bool isValidate = CheckValidate();
            if (isValidate)
            {
                InitBaseData();
                InitLineRenderer();
                InitAnimationData();
                if (autoPlay)
                {
                    Play();
                }
            }
        }
        
        void Start()
        {
            if (isIgnoreStart)
            {
                return;
            }
            bool isValidate = CheckValidate();
            if (isValidate)
            {
                InitBaseData();
                InitLineRenderer();
                InitAnimationData();
                if (autoPlay)
                {
                    Play();
                }
            }
        }

        private bool CheckValidate()
        {
            if (!isAlreadySetMovPos)
            {
                if (startTrans==null || endTrans==null)
                {
#if UNITY_EDITOR
                    DevDebuger.LogError("动画飞行曲线", "起始点、目标点 都需要进行赋值！");
#endif
                    return false;
                }
                if (animationCurveMode==AnimationCurveMode.Bezier && (controllerTrans1==null || controllerTrans2==null))
                {
#if UNITY_EDITOR
                    DevDebuger.LogError("动画飞行曲线", "贝塞尔曲线模式下, 控制点1 和 控制点2 都需要进行赋值！");
#endif
                    return false;
                }
            }
            else if (moveTime <= 0)
            {
#if UNITY_EDITOR
                DevDebuger.LogError("动画飞行曲线", string.Format("{0}节点上的动画移动时间要大于0", this.gameObject.name));
#endif
                return false;
            }
            else if (prefab == null && string.IsNullOrEmpty(prefabResId))
            {
#if UNITY_EDITOR
                DevDebuger.LogError("动画飞行曲线", string.Format("移动物体{0} 和 移动物体的资源ID{1} 不能同时为空！", "prefab", "prefabResId"));
#endif
                return false;
            }

            return true;
        }

        private void InitBaseData()
        {
            if (!isAlreadySetMovPos)
            {
                startPos = startTrans.position;
                endPos = endTrans.position;
            }
            controllerPos1 = controllerTrans1!=null?controllerTrans1.position:controllerPos1;
            controllerPos2 = controllerTrans2!=null?controllerTrans2.position:controllerPos2;
            isLoadFinished = false;
            totalNum = generateNum;
        }

        private void InitLineRenderer()
        {
            lineRenderer = this.gameObject.GetComponent<LineRenderer>();
            if (isEditorMode)
            {
                if (lineRenderer == null)
                {
                    lineRenderer = this.gameObject.AddComponent<LineRenderer>();
                    lineRenderer.startWidth = 0.2f;
                    lineRenderer.endWidth = 0.2f;
                    lineRenderer.enabled = true;
                }
            }
            else
            {
                if (lineRenderer != null)
                {
                    lineRenderer.enabled = false;
                    //Destroy(lineRenderer);
                }
            }
        }

        private void InitAnimationData()
        {
            initialized = false;
            animationStopNum = 0;
            if (animationMoveObjectList.Count <= 0)
            {
                if (prefab != null)
                {
                    for (int i = 0; i < generateNum; i++)
                    {
                        GameObject go = Instantiate(prefab);
                        if (go != null)
                        {
                            AnimationMoveObject animationMoveObject = new AnimationMoveObject(i, go, 0, parentTransform, layerMask);
                            animationMoveObjectList.Add(animationMoveObject);
                        }
                    }
                }
                else
                {
                    for (int i = 0; i < generateNum; i++)
                    {
                        ResPoolLoader.GetInstance().LoadGameObjectRes(prefabResId, i, OnLoadFinished, layerMask);
                    }
                    return;
                }
            }

            InitMoveObj();
        }

        void OnLoadFinished(LoadObject objdata)
        {
            GameObject go = objdata.gameObject;
            if (go != null)
            {
                int index = (int)objdata.data;
                animationMoveObjectList.Add(new AnimationMoveObject(index, go, 0, parentTransform, layerMask));
                loadDataDic.Add((int)objdata.data, objdata);
            }
            totalNum--;
            if (totalNum == 0)
            {
                InitMoveObj();
            }
        }

        private void InitMoveObj()
        {
            if (animationMoveObjectList.Count > 0)
            {
                List<GameObject> prefabList = new List<GameObject>();
                foreach (var v in animationMoveObjectList)
                {
                    v.ResetAnimationObject(startPos, isOneByOne);
                    prefabList.Add(v.gameObject);
                }

                isLoadFinished = true;
                allPrefabInstantiateFinishedCallback?.Invoke(prefabList);
            }
            else
            {
                DevDebuger.LogError("动画飞行曲线", "加载的对象有问题，请进行检查！");
            }
        }

        private void ShowNextAnimation()
        {
            foreach (var v in animationMoveObjectList)
            {
                if (!v.isPlaying)
                {
                    v.gameObject.SetActive(true);
                    v.isPlaying = true;
                    break;
                }
            }
        }


        private void FixedUpdate()
        {
            if (initialized && isLoadFinished && animationMoveObjectList.Count > 0)
            {
                if (_tween == null)
                {
                    _tween = DOTween.To(() => _tweenNum, a => _tweenNum = a, 1, moveIntervalTime);
                    _tween.SetLoops(animationMoveObjectList.Count);
                    _tween.OnStepComplete(ShowNextAnimation);
                    _tween.OnComplete(null);
                }
                
                if (isEditorMode)
                {
                    controllerPos1 = controllerTrans1.position;
                    controllerPos2 = controllerTrans2.position;
                    DrawCurve();
                }

                if (animationStopNum >= animationMoveObjectList.Count)
                {
                    return;
                }
                
                for (int i = 0; i < animationMoveObjectList.Count; i++)
                {
                    var v = animationMoveObjectList[i];
                    if (v.isPlaying && !v.isStop)
                    {
                        v.elapseTime += (Time.fixedDeltaTime / moveTime);
                        float scale = animationScaleCurve.Evaluate(v.elapseTime);
                        if (animationCurveMode == AnimationCurveMode.Bezier)
                        {
                            float speed = animationSpeedCurve.Evaluate(v.elapseTime);
                            v.gameObject.transform.position = CalculateCubicBezierPoint(speed, startPos, controllerPos1,
                                controllerPos2, endPos);
                        }
                        else
                        {
                            float moveX = animationPositionXCurve.Evaluate(v.elapseTime);
                            float moveY = animationPositionYCurve.Evaluate(v.elapseTime);
                            Vector3 posX = Vector3.LerpUnclamped(startPos, endPos, moveX);
                            Vector3 posY = Vector3.LerpUnclamped(startPos, endPos, moveY);
                            v.gameObject.transform.position = new Vector3(posX.x, posY.y, v.gameObject.transform.position.z);
                        }
                        if (projectionMode == ProjectionMode.Orthographic)
                        {
                            var localPos = v.gameObject.transform.localPosition;
                            localPos.z = 0;
                            v.gameObject.transform.localPosition = localPos;
                        }
                        v.gameObject.transform.localScale = Vector3.one * scale;
                        if (v.elapseTime >= 1.0f)
                        {
                            //print("单个动画");
                            OnSingleAnimationFinishedCallback?.Invoke();
                            v.isStop = true;
                            animationStopNum++;
                            if (autoDestroy)
                            {
                                if (prefab != null)
                                {
                                    v.gameObject.SetActive(false);
                                }
                                else
                                {
                                    if (loadDataDic.TryGetValue(v.index, out var loadObject))
                                    {
                                        loadObject.DoRelease();
                                    }
                                }
                            }

                            if (animationStopNum >= animationMoveObjectList.Count)
                            {
                                //print("全部动画");
                                OnAllAnimationFinishedCallback?.Invoke();
                                if (autoDestroy)
                                {
                                    if (prefab != null)
                                    {
                                        foreach (var value in animationMoveObjectList)
                                        {
                                            if (value!=null && value.gameObject!=null)
                                            {
                                                value.gameObject.SetActive(false);
                                            }
                                        }
                                    }
                                    else
                                    {
                                        foreach (var value in loadDataDic.Values)
                                        {
                                            value.DoRelease();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        private void DrawCurve()
        {
            for (int i = 1; i <= _segmentNum; i++)
            {
                float t = i / (float)_segmentNum;
                Vector3 position = Vector3.zero;
                if (animationCurveMode == AnimationCurveMode.Bezier)
                {
                    position = CalculateCubicBezierPoint(t, startPos, controllerPos1, controllerPos2, endPos);
                }
                else
                {
                    float moveX = animationPositionXCurve.Evaluate(t);
                    float moveY = animationPositionYCurve.Evaluate(t);
                    Vector3 posX = Vector3.LerpUnclamped(startPos, endPos, moveX);
                    Vector3 posY = Vector3.LerpUnclamped(startPos, endPos, moveY);
                    position = new Vector3(posX.x, posY.y, startPos.z);
                }
                lineRenderer.positionCount = i;
                lineRenderer.SetPosition(i - 1, position);
            }
        }

        //三阶贝塞尔曲线
        private Vector3 CalculateCubicBezierPoint(float t, Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3)
        {
            float u = 1 - t;
            float uu = u * u;
            float uuu = u * u * u;
            float tt = t * t;
            float ttt = t * t * t;
            Vector3 p = p0 * uuu;
            p += 3 * p1 * t * uu;
            p += 3 * p2 * tt * u;
            p += p3 * ttt;
            return p;
        }
        
        public void OnRelease()
        {
            if (prefab != null)
            {
                foreach (var v in animationMoveObjectList)
                {
                    Destroy(v.gameObject);
                }
            }
            else
            {
                foreach (var v in loadDataDic.Values)
                {
                    v.DoRelease();
                }
                loadDataDic.Clear();
            }
            animationMoveObjectList.Clear();
        }

        public void Play()
        {
            _tween.Play();
            initialized = true;
        }

        public void Pause()
        {
            _tween.Pause();
            initialized = false;
        }

        public void Stop()
        {
            StopTween();
            InitAnimationData();
        }

        private void StopTween()
        {
            _tween.Kill();
            _tween = null;
        }

#if UNITY_EDITOR
        void OnGUI()
        {
            if (!isEditorMode)
            {
                return;
            }
            GUIStyle buttonStyle = new GUIStyle(GUI.skin.button);
            buttonStyle.fontSize = 50;
            buttonStyle.Width(200);
            buttonStyle.Height(100);
            
            if (GUILayout.Button("播放", buttonStyle))
            {
                Play();
            }
            if (GUILayout.RepeatButton("暂停", buttonStyle))
            {
                Pause();
            }
            if (GUILayout.RepeatButton("停止", buttonStyle))
            {
                Stop();
            }
        }
#endif
    }
}
