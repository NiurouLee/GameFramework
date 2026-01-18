using System.Collections.Generic;
using NFramework.Module.UIModule;
using UnityEngine;

public class UIFacade : MonoBehaviour
{
    public string ID;

    // 运行时只保留这一个组件引用数组，用于生成的代码通过索引访问
    [SerializeField, HideInInspector]
    public Component[] Components;


    /// <summary>
    /// 只在编辑器下存储这个信息，运行时没用
    /// </summary>
#if UNITY_EDITOR
    public class UIElement
    {
        //组件名称，用于生成字段或者方法
        public string Name;
        //组件
        public IUIComponent Component;
        // 描述，用于生成备注
        public string Desc;
    }
    public List<UIElement> m_UIElements = new List<UIElement>();

    public void AddUIElement(UIElement inUIElement)
    {
        this.m_UIElements.Add(inUIElement);
    }

    public void RemoveUIElement(UIElement inUIElement)
    {
        this.m_UIElements.Remove(inUIElement);
    }

    public void ClearUIElements()
    {
        this.m_UIElements.Clear();
    }

    // 编辑器配置数据（序列化保存，避免每次打开丢失）
    [SerializeField, HideInInspector]
    public string m_ModuleName = "";
    
    [SerializeField, HideInInspector]
    public string m_SubModuleName = "";
    
    [SerializeField, HideInInspector]
    public string m_UIName = "";
    
    [SerializeField, HideInInspector]
    public bool m_EnableSubModule = false;
    
    [SerializeField, HideInInspector]
    public string m_ScriptName = ""; // 自动生成的脚本名称，用于ViewConfig的ID

#endif

    public void Visible()
    {
        this.gameObject?.SetActive(true);
    }

    public void NotVisible()
    {
        this.gameObject?.SetActive(false);
    }
}