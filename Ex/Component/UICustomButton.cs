using client;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.Serialization;
using UnityEngine.UI;
namespace Ez.UI
{
    [AddComponentMenu("UI/UICustomButton", 53)]
    [DisallowMultipleComponent]
    public class UICustomButton : Button
    {
        #region 绑定文字状态相关
        [System.Serializable]
        public struct TextState
        {
            public Color color;
            public Color outlineColor;
            public float faceDilate; // 新增属性，范围 -1 到 1
            public float outlineThickness; // 新增属性，范围 0 到 1

            // 更新构造函数
            public TextState(Color color, Color outlineColor, float faceDilate, float outlineThickness)
            {
                this.color = color;
                this.outlineColor = outlineColor;
                this.faceDilate = faceDilate;
                this.outlineThickness = outlineThickness;
            }

            // 提供一个带有默认值的静态方法
            public static TextState Default()
            {
                return new TextState(Color.white, Color.white, 0.4f, 0.4f);
            }
        }


        public TextState normalState = TextState.Default();
        public TextState pressedState = TextState.Default();
        public TextState selectedState = TextState.Default();
        public TextState disabledState = TextState.Default();
        public bool applyOutline = false;
        public bool applyBtnScale = true;
        public Transform ApplySacaleTransform;

        Transform SacaleTransform
        {
            get
            {
                if (ApplySacaleTransform)
                {
                    return ApplySacaleTransform;
                }

                return this.transform;
            }
        }


        public List<TMP_Text> textComponents = new List<TMP_Text>();

        protected override void DoStateTransition(Selectable.SelectionState state, bool instant)
        {
            base.DoStateTransition(state, instant);

            TextState currentState = normalState;

            switch (state)
            {
                case Selectable.SelectionState.Normal:
                    currentState = normalState;
                    break;
                case Selectable.SelectionState.Highlighted:
                    currentState = selectedState;
                    break;
                case Selectable.SelectionState.Pressed:
                    currentState = pressedState;
                    break;
                case Selectable.SelectionState.Disabled:
                    currentState = disabledState;
                    break;
                default:
                    currentState = normalState;
                    break;
            }

            ApplyTextState(currentState);
        }

        void ApplyTextState(TextState state)
        {
            foreach (var text in textComponents)
            {
                if (text != null)
                {
                    text.color = state.color;
                    if (applyOutline)
                    {
                        if (text.fontSharedMaterial.name != "main_outline_customlized")
                        {
                            continue;
                        }
                        text.contourColor = state.outlineColor;
                        //text.faceDilate = state.faceDilate;
                        // text.outlineWidth = state.outlineThickness;
                    }
                }
            }
        }
        #endregion

        #region 点击动画相关
        public float pressedScale = 0.95f; // 按下时的缩放值
        public float duration = 0.1f; // 动画持续时间
        Vector3 _originalScale = Vector3.zero; // 原始大小
        // IPointerDownHandler接口的实现
        public override void OnPointerDown(PointerEventData eventData)
        {
            base.OnPointerDown(eventData);
            if (longPressEnabled)
            {
                _isPressing = true;
                _firstPressTime = Time.unscaledTime;
                _lastPressTime = Time.unscaledTime;
            }
            StopAllCoroutines(); // 停止所有可能的动画
            _originalScale = SacaleTransform.localScale;
            if (applyBtnScale && interactable)
            {
                StartCoroutine(ScaleTo(pressedScale, duration)); // 开始缩放动画
            }
        }

        // IPointerUpHandler接口的实现
        public override void OnPointerUp(PointerEventData eventData)
        {
            base.OnPointerUp(eventData);
            if (_isExecuteLongPress)
            {
                onFinishLongPress?.Invoke();
            }
            _isPressing = false;
            _isExecuteLongPress = false;
            StopAllCoroutines(); // 在释放时停止所有动画
            if (applyBtnScale && interactable)
            {
                StartCoroutine(ScaleTo(1f, duration)); // 恢复原始大小的动画

            }
            upClick?.Invoke(this.gameObject);
        }

        IEnumerator ScaleTo(float targetScale, float duration)
        {
            Vector3 startScale = _originalScale;
            Vector3 endScale = new Vector3(targetScale * _originalScale.x, targetScale * _originalScale.x, targetScale * _originalScale.z);
            for (float t = 0; t < 1.0f; t += Time.deltaTime / duration)
            {
                SacaleTransform.localScale = Vector3.Lerp(startScale, endScale, t);
                yield return null;
            }
            SacaleTransform.localScale = endScale;
        }
        #endregion

        #region 状态切换相关
        public void SetEnabled(bool state, bool canClick = true)
        {
            this.interactable = state;
            if (this.clickEvent != null)
            {
                this.clickEvent.IgnoreInteractable = canClick;//disabled下可以相应点击事件
            }
        }


        private MaskableGraphic[] maskableGraphics;
        public void SetGray(bool value, bool includeAllChildren = true)
        {
            if (maskableGraphics == null)
            {
                maskableGraphics = GetComponentsInChildren<MaskableGraphic>(includeAllChildren);
            }
            foreach (var mg in maskableGraphics)
            {
                if (mg != null)
                {
                    mg.material = value ? UIManager.GetInstance().DefaultGrayMaterial : null;
                }
            }
        }
        #endregion

        #region 点击事件相关
        EventTriggerClick m_click;

        EventTriggerClick clickEvent
        {
            get
            {
                if (m_click == null)
                {
                    EventTriggerClick eventclick = this.gameObject.GetComponent<EventTriggerClick>();
                    m_click = eventclick;
                }
                return m_click;
            }
            set
            {
                m_click = value;
            }
        }
        public void AddClick(System.Action<GameObject> callback)
        {
            if (m_click)
            {
                RemoveClick();
            }
            clickEvent = EventTriggerClick.Register(this.gameObject, callback);
        }

        private Action<GameObject> upClick;
        public void AddUpClick(System.Action<GameObject> callback)
        {
            upClick = callback;
        }
        public void RemoveClick()
        {
            EventTriggerClick.UnRegisterButtonClick(this.gameObject, true);
        }
        #endregion

        #region 双击相关
        public bool doubleClickEnabled = false;
        public float doubleClickTime = 0.3f;

        private float lastClickTime = float.NegativeInfinity;
        private int clickCount = 0;

        [FormerlySerializedAs("onDoubleClick")]
        [SerializeField]
        private ButtonClickedEvent m_onDoubleClick = new();

        public ButtonClickedEvent onDoubleClick
        {
            get => m_onDoubleClick;
            set => m_onDoubleClick = value;
        }

        public override void OnPointerClick(PointerEventData eventData)
        {
            if (!IsActive() && !interactable)
                return;

            if (doubleClickEnabled)
            {
                clickCount++;
                if (clickCount >= 2)
                {
                    if (Time.realtimeSinceStartup - lastClickTime < doubleClickTime)
                    {
                        onDoubleClick?.Invoke();
                        lastClickTime = float.NegativeInfinity;
                        clickCount = 0;
                    }
                    else
                    {
                        clickCount = 1;
                        lastClickTime = Time.unscaledTime;
                    }
                }
                else
                {
                    lastClickTime = Time.unscaledTime;
                }
            }
        }
        #endregion

        #region 长按相关

        public bool longPressEnabled = false;
        public float longPressDelayTime = 1.0f;
        public float longPressExecuteTime = 0.5f;

        private bool _isPressing = false;
        private bool _isExecuteLongPress = false;
        private float _firstPressTime = 0;
        private float _lastPressTime = 0;


        [FormerlySerializedAs("onStartLongPress")]
        [SerializeField]
        private UnityEvent m_OnStartLongPress = new UnityEvent();

        [FormerlySerializedAs("onExecuteLongPress")]
        [SerializeField]
        private UnityEvent m_onExecuteLongPress = new();

        [FormerlySerializedAs("onFinishLongPress")]
        [SerializeField]
        private UnityEvent m_onFinishLongPress = new UnityEvent();

        public UnityEvent onStartLongPress
        {
            get => m_OnStartLongPress;
            set => m_OnStartLongPress = value;
        }

        public UnityEvent onExecuteLongPress
        {
            get => m_onExecuteLongPress;
            set => m_onExecuteLongPress = value;
        }

        public UnityEvent onFinishLongPress
        {
            get => m_onFinishLongPress;
            set => m_onFinishLongPress = value;
        }

        private void Update()
        {
            DealLongPress();
        }

        private void DealLongPress()
        {
            if (!this.gameObject.activeSelf)
            {
                _isPressing = false;
                _isExecuteLongPress = false;
                transform.localScale = _originalScale;
            }

            if (_isPressing)
            {
                if (!_isExecuteLongPress && Time.unscaledTime - _firstPressTime >= longPressDelayTime)
                {
                    _isExecuteLongPress = true;
                    onStartLongPress?.Invoke();
                }
                if (_isExecuteLongPress)
                {
                    if (Time.unscaledTime - _lastPressTime >= longPressExecuteTime)
                    {
                        _lastPressTime = Time.unscaledTime;
                        onExecuteLongPress?.Invoke();
                    }
                }
            }
        }

        /// <summary>
        /// 主动调用抬起按钮
        /// </summary>
        /// <param name="state"></param>
        public void SetPointUp()
        {
            _isPressing = false;
            _isExecuteLongPress = false;
            if(_originalScale!=Vector3.zero)
                transform.localScale = _originalScale;
        }


        protected override void OnEnable()
        {
            base.OnEnable();
        }

        protected override void OnDisable()
        {
            base.OnDisable();
            if(Application.isPlaying&&_isPressing)
                SetPointUp();
        }


        #endregion
    }
}