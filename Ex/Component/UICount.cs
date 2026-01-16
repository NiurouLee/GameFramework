using client;
using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
namespace Ez.UI
{
    public enum UICountUpdateType
    {
        /// <summary>
        /// 数值改变 按钮操作触发
        /// </summary>
        countChange,
        /// <summary>
        /// 已经到最大 如果当前已经最大值，数量改变状态
        /// </summary>
        countMax,
        /// <summary>
        /// 已经到最小  如果当前已经最小值，数量改变状态
        /// </summary>
        countMin

    }
    [AddComponentMenu("UI/UICount(数量控制器)", 52)]
    [DisallowMultipleComponent]
    public class UICount : MonoBehaviour
    {
        public delegate string SumDelegate(int values);

        int _max = 10;
        int _min = 0;
        int _count = 0;
        int _stepCount = 1;
        Action<UICountUpdateType, int> _changeCall;


        public GameObject m_plus;
        public GameObject m_minus;
        public GameObject m_min;
        public GameObject m_max;
        public TMP_InputField m_num;
        public Slider slider;
        private void Awake()
        {
            if (m_plus)
            {
                EventTriggerClick.Register(m_plus, OnPlus);
            }
            if (m_minus)
            {
                EventTriggerClick.Register(m_minus, OnMinus);
            }
            if (m_min)
            {
                EventTriggerClick.Register(m_min, OnMin);
            }
            if (m_max)
            {
                EventTriggerClick.Register(m_max, OnMax);
            }

            m_num.textViewport = m_num.transform.GetComponent<RectTransform>();
            m_num.contentType = TMP_InputField.ContentType.IntegerNumber;
            m_num.onValueChanged.AddListener(this.OnInputValueChanged);
            if (slider)
            {
                slider.onValueChanged.AddListener(OnSliderValueChange);
                CalibrateSliderMinValue();
                slider.wholeNumbers = true;
            }
        }

        private void OnInputValueChanged(string str)
        {
            int temp;
            if (int.TryParse(str, out temp))
            {
                int temp_useCount = temp;
                if (temp < min)
                {
                    //MM.Hint.PushText($"InputValue(: {str}) was too small for min(: {uiCount.min})!");
                    temp_useCount = min;
                }
                else if (temp > max)
                {
                    //MM.Hint.PushText($"InputValue(: {str}) was too large for max(: {uiCount.max})!");
                    temp_useCount = max;
                }

                if (temp_useCount != count)
                {
                    OnChangeCount(temp_useCount, true);
                }
                if (temp_useCount != temp)
                {
                    m_num.text = count.ToString();
                }
            }
            else
            {
                //超出int范围，输入无效,重置输入框显示
                m_num.text = count.ToString();
                //MM.Hint.PushText($"InputValue(: {str}) was either too large or too small for an Int32!");
            }
        }

        void OnSliderValueChange(float _count)
        {
            int c_count = (int)_count;
            OnChangeCount(c_count);
        }
        private void OnDestroy()
        {
            DoRelease();
        }
        public void DoRelease()
        {
            if (m_plus)
            {
                EventTriggerClick.UnRegisterButtonClick(m_plus, false);
            }
            if (m_minus)
            {
                EventTriggerClick.UnRegisterButtonClick(m_minus, false);
            }
            if (m_min)
            {
                EventTriggerClick.UnRegisterButtonClick(m_min, false);
            }
            if (m_max)
            {
                EventTriggerClick.UnRegisterButtonClick(m_max, false);
            }
        }

        public int max
        {
            get => _max;
            set
            {
                _max = value;
                if (_count > _max)
                {
                    OnChangeCount(_max, false);
                }
                if (slider)
                {
                    CalibrateSliderMinValue();
                }
            }
        }
        public int min
        {
            get => _min;
            set
            {
                _min = value;
                if (_count < _min)
                {
                    OnChangeCount(_min, false);
                }
                if (slider)
                {
                    CalibrateSliderMinValue();
                }
            }
        }
        public int count
        {
            get => _count;
            set
            {
                OnChangeCount(value, false);
            }
        }
        public int stepCount { get => _stepCount; set => _stepCount = value; }
        /// <summary>
        /// 数量变化回调函数，会返回一个警告类型，和数量
        /// </summary>
        public Action<UICountUpdateType, int> changeCall { get => _changeCall; set => _changeCall = value; }
        /// <summary>
        /// 换算方法 返回值只用于显示
        /// </summary>
        public SumDelegate convertFun = null;
        void OnChangeCount(int _changCount, bool call = true)
        {
            if (_changCount > _max)
            {
                _count = _max;
                if (call)
                    _changeCall?.Invoke(UICountUpdateType.countMax, _count);
            }
            else if (_changCount < _min)
            {
                _count = _min;
                if (call)
                    _changeCall?.Invoke(UICountUpdateType.countMin, _count);
            }
            else
            {
                _count = _changCount;
                if (call)
                    _changeCall?.Invoke(UICountUpdateType.countChange, _count);
            }
            if (convertFun != null)
            {
                this.m_num.text = convertFun(_count).ToString();

            }
            else
            {
                this.m_num.text = _count.ToString();
            }
            if (slider)
            {
                slider.SetValueWithoutNotify(_count);
            }
        }

        private void OnMax(GameObject @object)
        {
            OnChangeCount(_max);
        }

        private void OnMin(GameObject @object)
        {
            OnChangeCount(_min);
        }

        private void OnMinus(GameObject @object)
        {
            OnChangeCount(_count - _stepCount);
        }

        private void OnPlus(GameObject @object)
        {
            OnChangeCount(_count + _stepCount);
        }

        private void CalibrateSliderMinValue()
        {
            if (min == max)
            {
                slider.minValue = max - 1;
                slider.maxValue = max;
                slider.interactable = false;
            }
            else
            {
                slider.minValue = min;
                slider.maxValue = max;
                slider.interactable = true;
            }
        }
    }
}
