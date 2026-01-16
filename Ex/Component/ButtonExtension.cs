
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.Serialization;
using UnityEngine.UI;

namespace Ez.UI
{
    public class ButtonExtension : Button
    {
        #region 单机、双击相关

        public bool singleClickEnabled = true;
        public bool doubleClickEnabled = false;
        public float doubleClickTime = 0.3f;

        private float _longPressWaitInterval = 0.05f;
        private float lastClickTime = float.NegativeInfinity;
        private int clickCount = 0;

        [FormerlySerializedAs("onDoubleClick")] [SerializeField]
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

            if (singleClickEnabled && CanSingleClick())
            {
                //UISystemProfilerApi.AddMarker("Button.onClick", this);
                onClick?.Invoke();
                //Debug.Log("单击");
            }

            if (doubleClickEnabled)
            {
                clickCount++;
                if (clickCount >= 2)
                {
                    if (Time.realtimeSinceStartup - lastClickTime < doubleClickTime)
                    {
                        //UISystemProfilerApi.AddMarker("Button.onDoubleClick", this);
                        onDoubleClick?.Invoke();
                        //Debug.Log("双击");
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

        private bool CanSingleClick()
        {
            return Time.realtimeSinceStartup - _longPressPointerUpTime > _longPressWaitInterval;
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
        private float _longPressPointerUpTime = 0;
        
        
        
        [FormerlySerializedAs("onStartLongPress")] [SerializeField]
        private UnityEvent m_OnStartLongPress = new UnityEvent();

        [FormerlySerializedAs("onExecuteLongPress")] [SerializeField]
        private UnityEvent m_onExecuteLongPress = new();
        
        [FormerlySerializedAs("onFinishLongPress")] [SerializeField]
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

        public override void OnPointerDown(PointerEventData eventData)
        {
            base.OnPointerDown(eventData);
            if (longPressEnabled)
            {
                _isPressing = true;
                _firstPressTime = Time.unscaledTime;
                _lastPressTime = Time.unscaledTime;
            }
        }

        public override void OnPointerUp(PointerEventData eventData)
        {
            base.OnPointerUp(eventData);
            if (_isExecuteLongPress)
            {
                onFinishLongPress?.Invoke();
                _longPressPointerUpTime = Time.unscaledTime;
                //Debug.Log($"长按事件执行结束");
            }
            _isPressing = false;
            _isExecuteLongPress = false;
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
            }
            if (_isPressing)
            {
                if (!_isExecuteLongPress && Time.unscaledTime - _firstPressTime >= longPressDelayTime)
                {
                    _isExecuteLongPress = true;
                    onStartLongPress?.Invoke();
                    //Debug.Log($"开始触发长按事件");
                }
                if (_isExecuteLongPress)
                {
                    if (Time.unscaledTime - _lastPressTime >= longPressExecuteTime)
                    {
                        _lastPressTime = Time.unscaledTime;
                        onExecuteLongPress?.Invoke();
                        //Debug.Log($"执行长按事件");
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
        }
        
        protected override void OnEnable()
        {
            base.OnEnable();
        }

        protected override void OnDisable()
        {
            base.OnDisable();
            SetPointUp();
        }

        #endregion
    }
}