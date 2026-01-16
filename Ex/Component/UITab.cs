using System;
using UnityEngine;
using UnityEngine.UI;

namespace Ez.UI
{
    [RequireComponent(typeof(Toggle))]
    public class UITab : MonoBehaviour
    {
        [Header("选中状态")]
        public GameObject ActiveNode;
        [Header("未被选中状态")]
        public GameObject InactiveNode;
        [Header("扩展的绑定数据")]
        public string data;
        public Action<bool,string> onValueChange;
        public Toggle toggle {
            get
            {
                return GetComponent<Toggle>();
            }
        }

#if UNITY_EDITOR
        private void OnValidate()
        {
            // toggle = GetComponent<Toggle>();
            // if (toggle == null)
            // {
            //     toggle = gameObject.AddComponent<Toggle>();
            // }

            if (this.transform.childCount>0)
            {
                for (int i = 0; i < this.transform.childCount; i++)
                {
                    if (this.transform.GetChild(i).name.IndexOf("node_active", StringComparison.Ordinal)!=-1)
                    {
                        ActiveNode = this.transform.GetChild(i).gameObject;
                    }

                    if (this.transform.GetChild(i).name.IndexOf("node_inactive", StringComparison.Ordinal)!=-1)
                    {
                        InactiveNode = this.transform.GetChild(i).gameObject;
                    }
                }
            }
        }
#endif

        // Use this for initialization
        protected virtual void Awake()
        {
            // toggle = GetComponent<Toggle>();
            // if (toggle == null)
            // {
            //     toggle = gameObject.AddComponent<Toggle>();
            //     OnValueChange(toggle.isOn);
            // }
            OnValueChange(toggle.isOn);
            toggle.onValueChanged.AddListener(OnValueChange);
        }
        protected virtual void OnValueChange(bool isOn)
        {
            if (ActiveNode != null)
            {
                ActiveNode.SetActive(isOn);
            }

            if (InactiveNode != null)
            {
                InactiveNode.SetActive(!isOn);
            }
            onValueChange?.Invoke(isOn,data);
        }
        
        public void SetIsOnWithoutNotify(bool value)
        {
            if (ActiveNode != null)
            {
                ActiveNode.SetActive(value);
            }

            if (InactiveNode != null)
            {
                InactiveNode.SetActive(!value);
            }
            toggle.SetIsOnWithoutNotify(value);
            
        }
    }
}


