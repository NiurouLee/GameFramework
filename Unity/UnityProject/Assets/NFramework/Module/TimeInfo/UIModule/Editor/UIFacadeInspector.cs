using NFramework.Module.UIModule;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities.Editor;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(UIFacade))]
public class UIFacadeInspector : OdinEditor
{
    private UIFacade m_UIFacade;
    private ViewConfig m_ViewConfig;

    // 全局折叠状态
    private bool m_FoldBasicInfo = true;
    private bool m_FoldUIElementsList = true;
    private bool m_FoldTools = true;
    private bool m_FoldViewConfig = false;

    // 跟踪当前target的实例ID，用于检测prefab切换
    private int m_LastTargetInstanceID = -1;

    protected override void OnEnable()
    {
        base.OnEnable();
        m_UIFacade = (UIFacade)target;
        Initialize();
    }

    protected override void OnDisable()
    {
        base.OnDisable();

        if (m_UIFacade == null) return;

        // 保存折叠状态
        SaveFoldoutStates();

        // 确保数据已保存到UIFacade
        EditorUtility.SetDirty(m_UIFacade);
    }

    public override void OnInspectorGUI()
    {
        // 检测target是否变化（切换prefab时）
        if (target == null) return;

        int currentInstanceID = target.GetInstanceID();
        if (currentInstanceID != m_LastTargetInstanceID)
        {
            // Target已变化，重新初始化
            m_LastTargetInstanceID = currentInstanceID;
            m_UIFacade = (UIFacade)target;
            Initialize();
        }

        if (m_UIFacade == null) return;

        // 绘制标题
        SirenixEditorGUI.Title("UI Facade Configuration", "配置UI门面组件", TextAlignment.Center, true);
        EditorGUILayout.Space(5);

        // 使用绘制器绘制各个区域
        UIFacadeBasicInfoDrawer.DrawBasicInfo(m_UIFacade, ref m_FoldBasicInfo, OnDataChanged);
        EditorGUILayout.Space(2);

        UIFacadeUIElementsDrawer.DrawUIElementsList(m_UIFacade, ref m_FoldUIElementsList, OnDataChanged);
        EditorGUILayout.Space(2);

        UIFacadeViewConfigDrawer.DrawViewConfig(m_UIFacade, m_ViewConfig, ref m_FoldViewConfig);
        EditorGUILayout.Space(2);

        UIFacadeToolsDrawer.DrawToolButtons(m_UIFacade, ref m_FoldTools, OnDataChanged);

        // 应用修改
        if (GUI.changed) EditorUtility.SetDirty(m_UIFacade);
    }

    /// <summary>
    /// 初始化
    /// </summary>
    private void Initialize()
    {
        // 加载折叠状态
        LoadFoldoutStates();

        // 确保脚本名称和ID是最新的
        GenerateScriptNameAndID();

        // 初始化 ViewConfig
        m_ViewConfig = UIConfigUtilsEditor.GetViewConfig(m_UIFacade);
        InitializeViewConfig();

        // 从JSON文件加载配置（如果存在）
        LoadViewConfigFromJson();
    }

    /// <summary>
    /// 数据变化回调
    /// </summary>
    private void OnDataChanged()
    {
        GenerateScriptNameAndID();
        UpdateViewConfigID();
    }

    /// <summary>
    /// 生成脚本名称和ID
    /// </summary>
    private void GenerateScriptNameAndID()
    {
        if (m_UIFacade == null) return;

        UIFacadeNameGenerator.GenerateScriptNameAndID(m_UIFacade, out string scriptName, out string id);
        m_UIFacade.m_ScriptName = scriptName;
        m_UIFacade.ID = id;

        EditorUtility.SetDirty(m_UIFacade);

        // 同步更新 ViewConfig 的 ID（使用脚本名称）
        if (m_ViewConfig != null && !string.IsNullOrEmpty(m_UIFacade.m_ScriptName))
        {
            m_ViewConfig.ID = m_UIFacade.m_ScriptName;
        }
    }

    /// <summary>
    /// 初始化ViewConfig
    /// </summary>
    private void InitializeViewConfig()
    {
        if (m_ViewConfig == null) return;

        // 设置配置ID（使用脚本名称）
        if (!string.IsNullOrEmpty(m_UIFacade.m_ScriptName))
        {
            m_ViewConfig.ID = m_UIFacade.m_ScriptName;
        }

        // 设置默认配置（如果还没有设置过）
        if (m_ViewConfig.Layer == 0 && !m_ViewConfig.IsWindow && !m_ViewConfig.IsFixedLayer)
        {
            m_ViewConfig.SetLayer(0);
            m_ViewConfig.SetWindow(false);
        }
    }

    /// <summary>
    /// 更新ViewConfig的ID（使用脚本名称）
    /// </summary>
    private void UpdateViewConfigID()
    {
        if (m_ViewConfig == null) return;

        if (!string.IsNullOrEmpty(m_UIFacade.m_ScriptName))
        {
            if (m_ViewConfig.ID != m_UIFacade.m_ScriptName)
            {
                m_ViewConfig.ID = m_UIFacade.m_ScriptName;
            }
        }
    }

    /// <summary>
    /// 从JSON文件加载ViewConfig配置
    /// </summary>
    private void LoadViewConfigFromJson()
    {
        if (m_ViewConfig == null) return;

        string configID = !string.IsNullOrEmpty(m_UIFacade.m_ScriptName) ? m_UIFacade.m_ScriptName : m_UIFacade.ID;
        if (string.IsNullOrEmpty(configID)) return;

        ViewConfigManager.ViewConfigData data = ViewConfigManager.LoadViewConfig(configID);
        if (data != null)
        {
            m_ViewConfig.ID = data.ID;
            m_ViewConfig.AssetID = data.AssetID;
            m_ViewConfig.SetLayer(data.Layer);
            m_ViewConfig.SetWindow(data.IsWindow);
            m_ViewConfig.SetFixedLayer(data.IsFixedLayer);
        }
    }

    /// <summary>
    /// 加载折叠状态
    /// </summary>
    private void LoadFoldoutStates()
    {
        if (m_UIFacade == null) return;

        string foldKey = $"UIFacadeFolds_{m_UIFacade.GetInstanceID()}";
        m_FoldBasicInfo = EditorPrefs.GetBool(foldKey + "_Basic", true);
        m_FoldUIElementsList = EditorPrefs.GetBool(foldKey + "_UIElements", true);
        m_FoldTools = EditorPrefs.GetBool(foldKey + "_Tools", true);
        m_FoldViewConfig = EditorPrefs.GetBool(foldKey + "_View", false);
    }

    /// <summary>
    /// 保存折叠状态
    /// </summary>
    private void SaveFoldoutStates()
    {
        if (m_UIFacade == null) return;

        string foldKey = $"UIFacadeFolds_{m_UIFacade.GetInstanceID()}";
        EditorPrefs.SetBool(foldKey + "_Basic", m_FoldBasicInfo);
        EditorPrefs.SetBool(foldKey + "_UIElements", m_FoldUIElementsList);
        EditorPrefs.SetBool(foldKey + "_Tools", m_FoldTools);
        EditorPrefs.SetBool(foldKey + "_View", m_FoldViewConfig);
    }

    /// <summary>
    /// 获取编辑器数据（供外部使用）
    /// </summary>
    [System.Serializable]
    public class EditorData
    {
        public string ModuleName = "";
        public string SubModuleName = "";
        public string UIName = "";
        public string ScriptName = "";
        public string ID = "";
    }

    public static EditorData GetEditorData(UIFacade facade)
    {
        if (facade == null) return null;

        EditorData data = new EditorData();
        data.ModuleName = facade.m_ModuleName ?? "";
        data.SubModuleName = facade.m_SubModuleName ?? "";
        data.UIName = facade.m_UIName ?? "";
        data.ScriptName = facade.m_ScriptName ?? "";
        data.ID = facade.ID ?? "";
        return data;
    }
}
