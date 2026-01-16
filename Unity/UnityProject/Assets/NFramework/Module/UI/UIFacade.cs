using UnityEngine;

public class UIFacade : MonoBehaviour
{
    public string ID;

    // 运行时只保留这一个组件引用数组，用于生成的代码通过索引访问
    [SerializeField, HideInInspector]
    public Component[] m_RuntimeInputComponents;

    public void Visible()
    {
        this.gameObject?.SetActive(true);
    }

    public void NotVisible()
    {
        this.gameObject?.SetActive(false);
    }
}