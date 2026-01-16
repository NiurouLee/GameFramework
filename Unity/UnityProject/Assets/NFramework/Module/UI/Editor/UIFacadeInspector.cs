using System.Collections.Generic;
using System.Linq;
using NFramework.Module.UIModule;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities.Editor;
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Text;

[CustomEditor(typeof(UIFacade))]
public class UIFacadeInspector : OdinEditor
{
    [System.Serializable]
    public class EditorData
    {
        public string ModuleName = "";
        public string SubModuleName = "";
        public string UIName = "";
        public string ScriptName = "";
        public string ID = "";
        public UIComponent[] Components = new UIComponent[0];
    }

    private UIFacade m_UIFacade;
    private ViewConfig m_ViewConfig;
    private bool m_EnableSubModule = false;
    
    // 全局折叠状态
    private bool m_FoldBasicInfo = true;
    private bool m_FoldComponentsList = true;
    private bool m_FoldTools = true;
    private bool m_FoldViewConfig = false; // 默认关闭，因为通常不改

    // 编辑器数据（存储在 Inspector 中，不序列化到 UIFacade）
    private EditorData m_EditorData = new EditorData();
    private string m_EditorDataKey;

    public List<UIComponent> m_UIComponents = new List<UIComponent>();

    protected override void OnEnable()
    {
        base.OnEnable();
        m_UIFacade = (UIFacade)target;
        
        // 使用实例 ID 作为 EditorPrefs 的 key
        m_EditorDataKey = $"UIFacadeEditorData_{m_UIFacade.GetInstanceID()}";
        
        // 加载折叠状态
        string foldKey = $"UIFacadeFolds_{m_UIFacade.GetInstanceID()}";
        m_FoldBasicInfo = EditorPrefs.GetBool(foldKey + "_Basic", true);
        m_FoldComponentsList = EditorPrefs.GetBool(foldKey + "_Components", true);
        m_FoldTools = EditorPrefs.GetBool(foldKey + "_Tools", true);
        m_FoldViewConfig = EditorPrefs.GetBool(foldKey + "_View", false);

        // 从 EditorPrefs 加载编辑器数据
        LoadEditorData();
        // ... 后续代码保持不变
    }

    private void OnDisable()
    {
        // 保存折叠状态
        string foldKey = $"UIFacadeFolds_{m_UIFacade.GetInstanceID()}";
        EditorPrefs.SetBool(foldKey + "_Basic", m_FoldBasicInfo);
        EditorPrefs.SetBool(foldKey + "_Components", m_FoldComponentsList);
        EditorPrefs.SetBool(foldKey + "_Tools", m_FoldTools);
        EditorPrefs.SetBool(foldKey + "_View", m_FoldViewConfig);

        // 保存编辑器数据到 EditorPrefs
        SaveEditorData();
    }
    
    private void LoadEditorData()
    {
        string json = EditorPrefs.GetString(m_EditorDataKey, "");
        if (!string.IsNullOrEmpty(json))
        {
            try
            {
                m_EditorData = JsonUtility.FromJson<EditorData>(json);
            }
            catch
            {
                m_EditorData = new EditorData();
            }
        }
        else
        {
            m_EditorData = new EditorData();
        }
    }
    
    private void SaveEditorData()
    {
        string json = JsonUtility.ToJson(m_EditorData);
        EditorPrefs.SetString(m_EditorDataKey, json);
        
        // 同时同步数据到 UIFacade 实例
        SyncToFacade();
    }

    private void SyncToFacade()
    {
        if (m_UIFacade == null || m_EditorData == null) return;

        m_UIFacade.ID = m_EditorData.ID;

        // 将编辑器列表中的 Component 引用提取到数组中
        if (m_EditorData.Components != null)
        {
            m_UIFacade.m_RuntimeInputComponents = m_EditorData.Components
                .Select(c => c != null ? c.Component : null)
                .ToArray();
        }
        else
        {
            m_UIFacade.m_RuntimeInputComponents = new Component[0];
        }

        EditorUtility.SetDirty(m_UIFacade);
    }
    
    /// <summary>
    /// 获取编辑器数据（供 UIFacade 在运行时使用）
    /// </summary>
    public static EditorData GetEditorData(UIFacade facade)
    {
        if (facade == null) return null;
        
        string key = $"UIFacadeEditorData_{facade.GetInstanceID()}";
        string json = EditorPrefs.GetString(key, "");
        
        if (!string.IsNullOrEmpty(json))
        {
            try
            {
                return JsonUtility.FromJson<EditorData>(json);
            }
            catch
            {
                return null;
            }
        }
        
        return null;
    }

    public override void OnInspectorGUI()
    {
        if (m_UIFacade == null) return;

        // 绘制标题
        SirenixEditorGUI.Title("UI Facade Configuration", "配置UI门面组件", TextAlignment.Center, true);

        EditorGUILayout.Space(5);

        // 1. 基本信息组
        SirenixEditorGUI.BeginBox();
        SirenixEditorGUI.BeginBoxHeader();
        m_FoldBasicInfo = EditorGUILayout.Foldout(m_FoldBasicInfo, "基本信息", true);
        SirenixEditorGUI.EndBoxHeader();
        if (m_FoldBasicInfo)
        {
            EditorGUI.BeginChangeCheck();

            // 第一行：两个toggle开关横向排列
            SirenixEditorGUI.BeginHorizontalToolbar();
            {
                // 启用子模块 Toggle
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.LabelField("启用子模块:", GUILayout.Width(80));
                bool newEnableSubModule = EditorGUILayout.Toggle(m_EnableSubModule, GUILayout.Width(20));
                bool subModuleToggleChanged = EditorGUI.EndChangeCheck();
                
                if (m_EnableSubModule) GUILayout.Label("(已启用)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(50));
                else GUILayout.Label("(已禁用)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(50));
                
                GUILayout.Space(10);
                
                // 是否Window Toggle
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.LabelField("是否Window:", GUILayout.Width(80));
                if (m_ViewConfig != null)
                {
                    bool currentIsWindow = m_ViewConfig.IsWindow;
                    bool newIsWindow = EditorGUILayout.Toggle(currentIsWindow, GUILayout.Width(20));
                    if (currentIsWindow) GUILayout.Label("(窗口)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(40));
                    else GUILayout.Label("(视图)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(40));

                    if (EditorGUI.EndChangeCheck() && currentIsWindow != newIsWindow)
                    {
                        m_ViewConfig.SetWindow(newIsWindow);
                        GenerateScriptNameAndID();
                        EditorUtility.SetDirty(target);
                    }
                }
                else
                {
                    GUI.enabled = false;
                    EditorGUILayout.Toggle(false, GUILayout.Width(20));
                    GUI.enabled = true;
                    GUILayout.Label("(未初始化)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(60));
                    EditorGUI.EndChangeCheck();
                }
                
                GUILayout.FlexibleSpace();
                
                if (subModuleToggleChanged)
                {
                    m_EnableSubModule = newEnableSubModule;
                    if (!m_EnableSubModule && !string.IsNullOrEmpty(m_EditorData.SubModuleName))
                    {
                        if (EditorUtility.DisplayDialog("确认", "禁用子模块将清空子模块名称，确定继续吗？", "确定", "取消"))
                        {
                            m_EditorData.SubModuleName = "";
                            SaveEditorData();
                            GenerateScriptNameAndID();
                        }
                        else m_EnableSubModule = true;
                    }
                    else GenerateScriptNameAndID();
                }
            }
            SirenixEditorGUI.EndHorizontalToolbar();
            
            EditorGUILayout.Space(3);

            // 模块/子模块/UI名称输入
            EditorGUI.BeginChangeCheck();
            m_EditorData.ModuleName = SirenixEditorFields.TextField("模块名称", m_EditorData.ModuleName);
            if (m_EnableSubModule) m_EditorData.SubModuleName = SirenixEditorFields.TextField("子模块名称", m_EditorData.SubModuleName);
            m_EditorData.UIName = SirenixEditorFields.TextField("UI名称", m_EditorData.UIName);
            
            if (EditorGUI.EndChangeCheck())
            {
                SaveEditorData();
                GenerateScriptNameAndID();
            }

            // 脚本名称和 ID (只读)
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("脚本名称:", GUILayout.Width(80));
            EditorGUILayout.LabelField(m_EditorData.ScriptName ?? "未生成", SirenixGUIStyles.RightAlignedGreyMiniLabel);
            if (GUILayout.Button("重新生成", GUILayout.Width(70))) GenerateScriptNameAndID();
            EditorGUILayout.EndHorizontal();
            
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("ID:", GUILayout.Width(80));
            EditorGUILayout.LabelField(m_EditorData.ID ?? "未生成", SirenixGUIStyles.RightAlignedGreyMiniLabel);
            if (GUILayout.Button("复制ID", GUILayout.Width(70)) && !string.IsNullOrEmpty(m_EditorData.ID))
            {
                EditorGUIUtility.systemCopyBuffer = m_EditorData.ID;
                Debug.Log($"已复制ID: {m_EditorData.ID}");
            }
            EditorGUILayout.EndHorizontal();

            // 生成规则 Box
            SirenixEditorGUI.BeginBox("生成规则");
            EditorGUILayout.LabelField("脚本名称: 模块名 + 子模块名 + UI名称 + Window/View", SirenixGUIStyles.LeftAlignedGreyMiniLabel);
            EditorGUILayout.LabelField("ID格式: module_name.sub_module_name.ui_name", SirenixGUIStyles.LeftAlignedGreyMiniLabel);
            SirenixEditorGUI.EndBox();

            if (EditorGUI.EndChangeCheck()) EditorUtility.SetDirty(m_UIFacade);
        }
        SirenixEditorGUI.EndBox();

        EditorGUILayout.Space(2);

        // 2. UI组件列表
        SirenixEditorGUI.BeginBox();
        SirenixEditorGUI.BeginBoxHeader();
        m_FoldComponentsList = EditorGUILayout.Foldout(m_FoldComponentsList, "UI组件列表", true);
        SirenixEditorGUI.EndBoxHeader();
        if (m_FoldComponentsList)
        {
            DrawUIComponentsList();
        }
        SirenixEditorGUI.EndBox();

        EditorGUILayout.Space(2);

        // 3. 工具按钮组
        SirenixEditorGUI.BeginBox();
        SirenixEditorGUI.BeginBoxHeader();
        m_FoldTools = EditorGUILayout.Foldout(m_FoldTools, "工具栏", true);
        SirenixEditorGUI.EndBoxHeader();
        if (m_FoldTools)
        {
            DrawToolButtons();
        }
        SirenixEditorGUI.EndBox();

        EditorGUILayout.Space(2);

        // 4. ViewConfig配置组
        SirenixEditorGUI.BeginBox();
        SirenixEditorGUI.BeginBoxHeader();
        m_FoldViewConfig = EditorGUILayout.Foldout(m_FoldViewConfig, "View配置", true);
        SirenixEditorGUI.EndBoxHeader();
        if (m_FoldViewConfig)
        {
            DrawViewConfig();
        }
        SirenixEditorGUI.EndBox();

        // 应用修改
        if (GUI.changed) EditorUtility.SetDirty(m_UIFacade);
    }

    private void DrawUIComponentsList()
    {
        if (m_EditorData.Components == null)
        {
            m_EditorData.Components = new UIComponent[0];
        }

        // 列表标题和添加按钮
        SirenixEditorGUI.BeginHorizontalToolbar();
        {
            GUILayout.Label($"组件数量: {m_EditorData.Components.Length}", SirenixGUIStyles.LeftAlignedGreyMiniLabel);
            GUILayout.FlexibleSpace();

            // 添加按钮 - 使用更明显的样式
            GUI.backgroundColor = Color.green;
            if (GUILayout.Button(new GUIContent("+", "添加新UI组件"),
                GUILayout.Width(25), GUILayout.Height(18)))
            {
                AddNewUIComponent();
            }
            GUI.backgroundColor = Color.white;

            // 刷新按钮
            if (GUILayout.Button(new GUIContent("↻", "刷新并清理无效组件"),
                GUILayout.Width(25), GUILayout.Height(18)))
            {
                RefreshUIComponents();
            }
        }
        SirenixEditorGUI.EndHorizontalToolbar();

        EditorGUILayout.Space(3);

        // 如果列表为空，显示提示
        if (m_EditorData.Components.Length == 0)
        {
            SirenixEditorGUI.InfoMessageBox("暂无UI组件，点击上方的 + 按钮添加新组件，或使用下方的\"自动收集子对象\"功能。");
        }
        else
        {
            // 绘制组件列表
            for (int i = 0; i < m_EditorData.Components.Length; i++)
            {
                DrawUIComponent(i);
            }
        }
    }

    private void DrawUIComponent(int index)
    {
        if (m_EditorData.Components == null || index < 0 || index >= m_EditorData.Components.Length)
            return;

        var component = m_EditorData.Components[index];
        if (component == null)
        {
            component = new UIComponent();
            m_EditorData.Components[index] = component;
        }

        SirenixEditorGUI.BeginBox();
        {
            // 第一行：标题栏（折叠开关 + 索引 + 名称简预览 + 删除按钮）
            SirenixEditorGUI.BeginHorizontalToolbar();
            {
                // 使用 Foldout 控制展开/折叠
                component.IsExpanded = EditorGUILayout.Foldout(component.IsExpanded, $"[{index}] {component.Name}", true);

                GUILayout.FlexibleSpace();

                // 删除按钮
                GUI.color = Color.red;
                if (GUILayout.Button("×", GUILayout.Width(18), GUILayout.Height(16)))
                {
                    if (EditorUtility.DisplayDialog("确认删除", $"确定要删除组件 '{component.Name}' 吗？", "确定", "取消"))
                    {
                        RemoveUIComponent(index);
                        return;
                    }
                }
                GUI.color = Color.white;
            }
            SirenixEditorGUI.EndHorizontalToolbar();

            // 如果处于展开状态，显示详细信息
            if (component.IsExpanded)
            {
                EditorGUILayout.Space(2);

                // 详细信息第一行：名称、状态
                EditorGUILayout.BeginHorizontal();
                {
                    GUILayout.Space(15); // 缩进

                    // 名称字段
                    EditorGUI.BeginChangeCheck();
                    GUILayout.Label("名称:", GUILayout.Width(30));
                    string newName = EditorGUILayout.TextField(component.Name, GUILayout.MinWidth(80));
                    if (EditorGUI.EndChangeCheck())
                    {
                        if (ValidateComponentName(index, newName))
                        {
                            component.Name = newName;
                            SaveEditorData();
                        }
                        else
                        {
                            EditorUtility.DisplayDialog("错误", "组件名称重复或无效！", "确定");
                        }
                    }

                    GUILayout.Space(10);

                    // 状态下拉
                    GUILayout.Label("状态:", GUILayout.Width(30));
                    component.ActiveDefault = (ElementActiveDefault)EditorGUILayout.EnumPopup(
                        component.ActiveDefault, GUILayout.Width(60));
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(2);

                // 详细信息第二行：对象、组件
                EditorGUILayout.BeginHorizontal();
                {
                    GUILayout.Space(15); // 缩进

                    // 对象选择字段
                    GUILayout.Label("对象:", GUILayout.Width(35));
                    GameObject currentGO = component.Component != null ? component.Component.gameObject : null;

                    EditorGUI.BeginChangeCheck();
                    float fieldWidth = 100;//(EditorGUIUtility.currentViewWidth - 150) / 2f;
                    GameObject selectedGO = (GameObject)EditorGUILayout.ObjectField(currentGO, typeof(GameObject), true, GUILayout.Width(fieldWidth));
                    if (EditorGUI.EndChangeCheck() && selectedGO != currentGO)
                    {
                        // ... 对象改变逻辑保持不变 ...
                        if (selectedGO == null)
                        {
                            component.Component = null;
                            component.SelectedInputTypes.Clear();
                            SaveEditorData();
                        }
                        else
                        {
                            Component[] allComponents = selectedGO.GetComponents<Component>();
                            Component[] validComponents = allComponents.Where(c => c != null && !(c is Transform)).ToArray();
                            if (validComponents.Length > 0)
                            {
                                component.Component = validComponents[0];
                                if (string.IsNullOrEmpty(component.Name)) component.Name = selectedGO.name;
                                component.SelectedInputTypes.Clear();
                                SaveEditorData();
                            }
                        }
                    }

                    GUILayout.Label("组件:", GUILayout.Width(35));
                    GameObject targetGO = selectedGO != null ? selectedGO : currentGO;

                    if (targetGO != null)
                    {
                        Component[] allComponents = targetGO.GetComponents<Component>();
                        Component[] validComponents = allComponents.Where(c => c != null && !(c is Transform)).ToArray();

                        if (validComponents.Length > 0)
                        {
                            string[] componentNames = validComponents.Select(c => c.GetType().Name).ToArray();
                            int selectedIndex = System.Array.IndexOf(validComponents, component.Component);

                            EditorGUI.BeginChangeCheck();
                            int newIndex = EditorGUILayout.Popup(selectedIndex, componentNames, GUILayout.Width(fieldWidth));
                            if (EditorGUI.EndChangeCheck() && newIndex >= 0)
                            {
                                component.Component = validComponents[newIndex];
                                SaveEditorData();
                            }
                        }
                        else
                        {
                            EditorGUILayout.LabelField("无组件", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(fieldWidth));
                        }
                    }
                    else
                    {
                        EditorGUILayout.LabelField("请选择对象", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(fieldWidth));
                    }
                }
                EditorGUILayout.EndHorizontal();

                // 详细信息第三行：Input类型
                if (component.Component != null && IsUIInputComponent(component.Component))
                {
                    EditorGUILayout.BeginHorizontal();
                    GUILayout.Space(15); // 缩进
                    DrawInputTypesMultiSelect(component);
                    EditorGUILayout.EndHorizontal();
                }
            }
        }
        SirenixEditorGUI.EndBox();
    }

    // 检测组件是否实现了 IUIInputComponent
    private bool IsUIInputComponent(Component component)
    {
        if (component == null) return false;

        Type componentType = component.GetType();
        return typeof(IUIInputComponent).IsAssignableFrom(componentType);
    }

    // 获取组件可注册的 Input 类型列表
    private List<InputEnum> GetAvailableInputTypes(Component component)
    {
        if (component == null) return new List<InputEnum>();

        Type componentType = component.GetType();
        List<InputEnum> availableTypes = new List<InputEnum>();

        // 遍历 InputMapComponent，查找匹配的接口类型
        foreach (var kvp in InputMap.InputMapComponent)
        {
            Type interfaceType = kvp.Key;

            // 检查组件类型是否实现了该接口
            if (interfaceType.IsAssignableFrom(componentType))
            {
                // 添加该接口对应的所有 Input 类型
                foreach (var inputType in kvp.Value)
                {
                    if (!availableTypes.Contains(inputType))
                    {
                        availableTypes.Add(inputType);
                    }
                }
            }
        }

        return availableTypes;
    }

    // 绘制 Input 类型多选下拉
    private void DrawInputTypesMultiSelect(UIComponent component)
    {
        if (component.Component == null) return;

        List<InputEnum> availableTypes = GetAvailableInputTypes(component.Component);

        if (availableTypes.Count == 0)
        {
            EditorGUILayout.LabelField("该组件无可注册的 Input 类型", SirenixGUIStyles.RightAlignedGreyMiniLabel);
            return;
        }

        EditorGUILayout.BeginHorizontal();
        {
            GUILayout.Label("Input类型:", GUILayout.Width(70));

            // 创建选项数组
            string[] options = availableTypes.Select(t => t.ToString()).ToArray();

            // 创建选中标记数组（用于多选）
            bool[] selectedFlags = new bool[availableTypes.Count];
            for (int i = 0; i < availableTypes.Count; i++)
            {
                selectedFlags[i] = component.SelectedInputTypes.Contains(availableTypes[i]);
            }

            // 使用 MaskField 实现多选
            EditorGUI.BeginChangeCheck();

            int maskValue = 0;
            for (int i = 0; i < availableTypes.Count; i++)
            {
                if (selectedFlags[i])
                {
                    maskValue |= (1 << i);
                }
            }

            int newMaskValue = EditorGUILayout.MaskField(maskValue, options, GUILayout.MinWidth(150));

            if (EditorGUI.EndChangeCheck())
            {
                component.SelectedInputTypes.Clear();
                for (int i = 0; i < availableTypes.Count; i++)
                {
                    if ((newMaskValue & (1 << i)) != 0)
                    {
                        component.SelectedInputTypes.Add(availableTypes[i]);
                    }
                }
                SaveEditorData();
            }

            // 显示已选中的类型
            if (component.SelectedInputTypes.Count > 0)
            {
                string selectedText = string.Join(", ", component.SelectedInputTypes);
                GUILayout.Label($"({selectedText})", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.MaxWidth(200));
            }
        }
        EditorGUILayout.EndHorizontal();
    }

    private void DrawToolButtons()
    {
        SirenixEditorGUI.InfoMessageBox("使用以下工具来管理UI元素和配置");

        EditorGUILayout.Space(3);

        // 第一行工具按钮
        EditorGUILayout.BeginHorizontal();
        {
            // 自动收集按钮
            GUI.backgroundColor = new Color(0.7f, 1f, 0.7f);
            if (GUILayout.Button(new GUIContent("自动收集子对象", "自动收集GameObject下的所有组件"), GUILayout.Height(22)))
            {
                AutoCollectChildComponents();
            }

            // 清空按钮
            GUI.backgroundColor = new Color(1f, 0.7f, 0.7f);
            if (GUILayout.Button(new GUIContent("清空列表", "清空所有UI组件"), GUILayout.Height(22)))
            {
                if (EditorUtility.DisplayDialog("确认", "确定要清空所有UI组件吗？", "确定", "取消"))
                {
                    ClearUIComponents();
                }
            }

            // 保存按钮
            GUI.backgroundColor = new Color(0.7f, 0.9f, 1f);
            if (GUILayout.Button(new GUIContent("保存配置", "保存当前配置到文件"), GUILayout.Height(22)))
            {
                SaveComponent();
            }
            GUI.backgroundColor = Color.white;
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(3);

        // 第二行工具按钮
        EditorGUILayout.BeginHorizontal();
        {
            // 验证按钮
            GUI.backgroundColor = new Color(1f, 0.9f, 0.7f);
            if (GUILayout.Button(new GUIContent("验证配置", "检查配置的完整性和有效性"), GUILayout.Height(22)))
            {
                ValidateConfiguration();
            }

            // 生成脚本按钮
            GUI.backgroundColor = new Color(0.9f, 0.7f, 1f);
            if (GUILayout.Button(new GUIContent("生成脚本", "根据配置生成相关脚本代码"), GUILayout.Height(22)))
            {
                GenerateScript();
            }
            GUI.backgroundColor = Color.white;
        }
        EditorGUILayout.EndHorizontal();
    }

    private void AddNewUIComponent()
    {
        if (m_EditorData.Components == null)
        {
            m_EditorData.Components = new UIComponent[0];
        }

        var newArray = new UIComponent[m_EditorData.Components.Length + 1];
        System.Array.Copy(m_EditorData.Components, newArray, m_EditorData.Components.Length);
        newArray[m_EditorData.Components.Length] = new UIComponent
        {
            Name = $"Component_{m_EditorData.Components.Length}",
            Component = null,
            ActiveDefault = ElementActiveDefault.Default
        };
        m_EditorData.Components = newArray;
        SaveEditorData();
    }

    private void RemoveUIComponent(int index)
    {
        if (m_EditorData.Components == null || index < 0 || index >= m_EditorData.Components.Length)
            return;

        var newArray = new UIComponent[m_EditorData.Components.Length - 1];
        for (int i = 0, j = 0; i < m_EditorData.Components.Length; i++)
        {
            if (i != index)
            {
                newArray[j++] = m_EditorData.Components[i];
            }
        }
        m_EditorData.Components = newArray;
        SaveEditorData();
    }

    private void RefreshUIComponents()
    {
        if (m_EditorData.Components == null) return;

        // 移除空的组件
        var validComponents = m_EditorData.Components
            .Where(c => c != null && c.Component != null)
            .ToArray();

        m_EditorData.Components = validComponents;
        SaveEditorData();
    }

    private bool ValidateComponentName(int index, string name)
    {
        if (string.IsNullOrEmpty(name)) return false;
        if (m_EditorData.Components == null) return true;

        // 检查是否有重复的名称
        for (int i = 0; i < m_EditorData.Components.Length; i++)
        {
            if (i != index && m_EditorData.Components[i] != null && m_EditorData.Components[i].Name == name)
            {
                return false;
            }
        }

        return true;
    }

    private void AutoCollectChildComponents()
    {
        if (m_EditorData.Components == null)
        {
            m_EditorData.Components = new UIComponent[0];
        }

        // 获取所有子GameObject（包括自己）
        var allGameObjects = m_UIFacade.GetComponentsInChildren<Transform>(true)
            .Select(t => t.gameObject)
            .Where(go => go != m_UIFacade.gameObject) // 排除自己
            .ToArray();

        var newComponents = new List<UIComponent>(m_EditorData.Components);

        foreach (var go in allGameObjects)
        {
            // 获取GameObject上的所有组件，排除Transform和UIFacade
            var components = go.GetComponents<Component>()
                .Where(c => c != null && !(c is Transform) && !(c is UIFacade))
                .ToArray();

            if (components.Length > 0)
            {
                // 优先选择UI相关的组件
                Component selectedComponent = SelectBestComponent(components);

                string componentName = go.name;

                // 检查是否已存在同名组件
                if (!newComponents.Any(c => c != null && c.Name == componentName))
                {
                    newComponents.Add(new UIComponent
                    {
                        Name = componentName,
                        Component = selectedComponent,
                        ActiveDefault = go.activeInHierarchy ?
                            ElementActiveDefault.Active : ElementActiveDefault.DeActive
                    });
                }
            }
        }

        m_EditorData.Components = newComponents.ToArray();
        SaveEditorData();
        Debug.Log($"自动收集完成，添加了 {m_EditorData.Components.Length} 个UI组件");
    }

    private Component SelectBestComponent(Component[] components)
    {
        // 定义组件优先级（从高到低）
        System.Type[] priorityTypes = new System.Type[]
        {
            typeof(UnityEngine.UI.Button),
            typeof(UnityEngine.UI.Image),
            typeof(UnityEngine.UI.Text),
            typeof(UnityEngine.UI.InputField),
            typeof(UnityEngine.UI.Slider),
            typeof(UnityEngine.UI.Toggle),
            typeof(UnityEngine.UI.Dropdown),
            typeof(UnityEngine.UI.ScrollRect),
            typeof(UnityEngine.UI.Scrollbar),
            typeof(UnityEngine.CanvasGroup),
            typeof(UnityEngine.Canvas),
            typeof(UnityEngine.UI.GraphicRaycaster),
            typeof(UnityEngine.RectTransform)
        };

        // 按优先级查找组件
        foreach (var priorityType in priorityTypes)
        {
            var component = components.FirstOrDefault(c => priorityType.IsAssignableFrom(c.GetType()));
            if (component != null)
            {
                return component;
            }
        }

        // 如果没有找到优先级组件，返回第一个
        return components[0];
    }

    private void ClearUIComponents()
    {
        m_EditorData.Components = new UIComponent[0];
        SaveEditorData();
    }

    private void ValidateConfiguration()
    {
        var issues = new List<string>();

        if (string.IsNullOrEmpty(m_EditorData.UIName))
            issues.Add("UI名称不能为空");

        if (string.IsNullOrEmpty(m_EditorData.ScriptName))
            issues.Add("脚本名称不能为空");

        if (m_EditorData.Components != null && m_EditorData.Components.Length > 0)
        {
            var duplicateNames = m_EditorData.Components
                .Where(c => c != null)
                .GroupBy(c => c.Name)
                .Where(g => g.Count() > 1)
                .Select(g => g.Key);

            if (duplicateNames.Any())
                issues.Add($"发现重复的组件名称: {string.Join(", ", duplicateNames)}");

            var nullComponents = new List<int>();
            for (int i = 0; i < m_EditorData.Components.Length; i++)
            {
                if (m_EditorData.Components[i] == null || m_EditorData.Components[i].Component == null)
                {
                    nullComponents.Add(i);
                }
            }

            if (nullComponents.Any())
                issues.Add($"以下索引的组件为空: {string.Join(", ", nullComponents)}");
        }

        if (issues.Any())
        {
            EditorUtility.DisplayDialog("配置验证",
                $"发现以下问题:\n{string.Join("\n", issues)}", "确定");
        }
        else
        {
            EditorUtility.DisplayDialog("配置验证", "配置验证通过！", "确定");
        }
    }

    private void GenerateScript()
    {
        if (m_UIFacade == null || m_EditorData == null || string.IsNullOrEmpty(m_EditorData.ScriptName))
        {
            EditorUtility.DisplayDialog("错误", "脚本名称不能为空，请先配置基本信息", "确定");
            return;
        }

        string scriptName = m_EditorData.ScriptName;
        
        // 1. 生成 Generated 文件 (总是覆盖)
        string generatedFolderPath = "Assets/Generated/UI";
        if (!Directory.Exists(generatedFolderPath)) Directory.CreateDirectory(generatedFolderPath);
        
        string generatedFilePath = Path.Combine(generatedFolderPath, scriptName + ".Generated.cs");
        WriteGeneratedFile(generatedFilePath, scriptName);

        // 2. 生成 Logic 文件 (如果不存在)
        string logicFolderPath = "Assets/Scripts/UI"; 
        if (!Directory.Exists(logicFolderPath)) Directory.CreateDirectory(logicFolderPath);
        
        string logicFilePath = Path.Combine(logicFolderPath, scriptName + ".cs");
        bool logicFileExists = File.Exists(logicFilePath);
        if (!logicFileExists)
        {
            WriteLogicFile(logicFilePath, scriptName);
        }

        AssetDatabase.Refresh();
        
        string msg = $"脚本生成完毕！\n\n生成文件: {generatedFilePath}";
        if (!logicFileExists) msg += $"\n逻辑文件: {logicFilePath}";
        else msg += $"\n逻辑文件已存在，未跳过。";
        
        EditorUtility.DisplayDialog("成功", msg, "确定");
    }

    private void WriteGeneratedFile(string filePath, string scriptName)
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("using UnityEngine;");
        sb.AppendLine("using UnityEngine.UI;");
        sb.AppendLine("using NFramework.Module.UIModule;");
        sb.AppendLine("using TMPro;");
        sb.AppendLine("");
        sb.AppendLine("// 自动生成代码，请勿手动修改");
        sb.AppendLine("namespace NFramework.Module.UIModule");
        sb.AppendLine("{");
        sb.AppendLine($"    public partial class {scriptName}");
        sb.AppendLine("    {");

        if (m_EditorData.Components != null)
        {
            for (int i = 0; i < m_EditorData.Components.Length; i++)
            {
                var comp = m_EditorData.Components[i];
                if (comp != null && comp.Component != null && !string.IsNullOrEmpty(comp.Name))
                {
                    string typeName = comp.Component.GetType().FullName;
                    sb.AppendLine($"        public {typeName} {comp.Name} => Facade.m_RuntimeInputComponents[{i}] as {typeName};");
                }
            }
        }

        sb.AppendLine("    }");
        sb.AppendLine("}");
        File.WriteAllText(filePath, sb.ToString());
    }

    private void WriteLogicFile(string filePath, string scriptName)
    {
        bool isWindow = m_ViewConfig != null && m_ViewConfig.IsWindow;
        string baseClass = isWindow ? "Window" : "View";

        StringBuilder sb = new StringBuilder();
        sb.AppendLine("using UnityEngine;");
        sb.AppendLine("using UnityEngine.UI;");
        sb.AppendLine("using NFramework.Module.UIModule;");
        sb.AppendLine("using TMPro;");
        sb.AppendLine("");
        sb.AppendLine("namespace NFramework.Module.UIModule");
        sb.AppendLine("{");
        sb.AppendLine($"    public partial class {scriptName} : {baseClass}");
        sb.AppendLine("    {");
        sb.AppendLine("        protected override void OnAwake()");
        sb.AppendLine("        {");
        sb.AppendLine("            base.OnAwake();");
        sb.AppendLine("        }");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        File.WriteAllText(filePath, sb.ToString());
    }

    private void SaveComponent()
    {
        EditorUtility.SetDirty(m_UIFacade);
        AssetDatabase.SaveAssets();
        Debug.Log("UI Facade配置已保存");
    }

    private void DrawViewConfig()
    {
        if (m_ViewConfig == null)
        {
            // 尝试重新初始化ViewConfig
            m_ViewConfig = UIConfigUtilsEditor.GetViewConfig(m_UIFacade);
            
            if (m_ViewConfig == null)
            {
                SirenixEditorGUI.ErrorMessageBox("ViewConfig初始化失败！");
                return;
            }
        }

        // 配置说明
        SirenixEditorGUI.InfoMessageBox("配置UI视图的显示层级和窗口属性");

        EditorGUILayout.Space(5);

        EditorGUI.BeginChangeCheck();

        // ID字段（只读显示）
        EditorGUILayout.BeginHorizontal();
        {
            EditorGUILayout.LabelField("配置ID:", GUILayout.Width(80));
            EditorGUILayout.LabelField(m_ViewConfig.ID ?? "未设置", SirenixGUIStyles.RightAlignedGreyMiniLabel);
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(2);

        // AssetID字段
        string newAssetID = SirenixEditorFields.TextField("资源ID", m_ViewConfig.AssetID ?? "");
        if (m_ViewConfig.AssetID != newAssetID)
        {
            m_ViewConfig.AssetID = newAssetID;
        }

        EditorGUILayout.Space(8);

        // UI层级设置
        UIlayer currentLayer = m_ViewConfig.Layer;
        UIlayer newLayer = (UIlayer)SirenixEditorFields.EnumDropdown("UI层级", currentLayer);
        if (currentLayer != newLayer)
        {
            m_ViewConfig.SetLayer(newLayer);
        }

        // 显示层级数值和说明
        SirenixEditorGUI.BeginIndentedHorizontal();
        {
            EditorGUILayout.LabelField("层级值:", $"{(int)newLayer}", SirenixGUIStyles.RightAlignedGreyMiniLabel);
            EditorGUILayout.LabelField("说明:", GetLayerDescription(newLayer), SirenixGUIStyles.RightAlignedGreyMiniLabel);
        }
        SirenixEditorGUI.EndIndentedHorizontal();

        EditorGUILayout.Space(5);

        // 显示窗口模式说明
        SirenixEditorGUI.BeginIndentedHorizontal();
        {
            bool isWindow = m_ViewConfig != null && m_ViewConfig.IsWindow;
            string modeText = isWindow ? "窗口模式 - 可独立管理的UI窗口" : "视图模式 - 普通UI视图";
            EditorGUILayout.LabelField("当前模式:", modeText, SirenixGUIStyles.RightAlignedGreyMiniLabel);
        }
        SirenixEditorGUI.EndIndentedHorizontal();

        if (EditorGUI.EndChangeCheck())
        {
            EditorUtility.SetDirty(target);
        }

        EditorGUILayout.Space(5);

        // ViewConfig工具按钮
        DrawViewConfigTools();
    }



    private string GetLayerDescription(UIlayer layer)
    {
        return layer switch
        {
            UIlayer.BackGround => "背景层 - 用于背景UI元素",
            UIlayer.Hud => "HUD层 - 游戏界面HUD元素",
            UIlayer.Common => "通用层 - 普通UI界面",
            UIlayer.CommonH => "通用高层 - 高优先级通用界面",
            UIlayer.Pop => "弹窗层 - 弹出窗口",
            UIlayer.PopH => "弹窗高层 - 高优先级弹窗",
            UIlayer.Guide => "引导层 - 新手引导界面",
            UIlayer.Toast => "提示层 - 消息提示",
            UIlayer.ToastH => "提示高层 - 高优先级提示",
            UIlayer.loading => "加载层 - 加载界面",
            UIlayer.Lock => "锁定层 - 锁屏界面",
            UIlayer.SystemToast => "系统提示层 - 系统级提示",
            _ => "未知层级"
        };
    }

    private void DrawViewConfigTools()
    {
        SirenixEditorGUI.BeginBox("ViewConfig工具");
        {
            EditorGUILayout.BeginHorizontal();
            {
                // 同步ID按钮
                GUI.backgroundColor = new Color(0.8f, 0.9f, 1f);
                if (GUILayout.Button(new GUIContent("同步ID", "将UIFacade的ID同步到ViewConfig"), GUILayout.Height(25)))
                {
                    SyncIDToViewConfig();
                }

                // 重置配置按钮
                GUI.backgroundColor = new Color(1f, 0.8f, 0.8f);
                if (GUILayout.Button(new GUIContent("重置配置", "重置ViewConfig到默认状态"), GUILayout.Height(25)))
                {
                    if (EditorUtility.DisplayDialog("确认重置", "确定要重置ViewConfig配置吗？", "确定", "取消"))
                    {
                        ResetViewConfig();
                    }
                }

                // 保存配置按钮
                GUI.backgroundColor = new Color(0.8f, 1f, 0.8f);
                if (GUILayout.Button(new GUIContent("保存配置", "保存ViewConfig配置"), GUILayout.Height(25)))
                {
                    SaveViewConfig();
                }
                GUI.backgroundColor = Color.white;
            }
            EditorGUILayout.EndHorizontal();
        }
        SirenixEditorGUI.EndBox();
    }

    private void SyncIDToViewConfig()
    {
        if (!string.IsNullOrEmpty(m_EditorData.ID))
        {
            m_ViewConfig.ID = m_EditorData.ID;
            EditorUtility.SetDirty(target);
            Debug.Log($"已同步ID: {m_EditorData.ID}");
        }
        else
        {
            EditorUtility.DisplayDialog("错误", "UIFacade的ID为空，无法同步", "确定");
        }
    }

    private void ResetViewConfig()
    {
        m_ViewConfig.SetLayer(UIlayer.Common);
        m_ViewConfig.SetWindow(false);
        m_ViewConfig.AssetID = "";
        EditorUtility.SetDirty(target);
        Debug.Log("ViewConfig已重置到默认状态");
    }

    private void SaveViewConfig()
    {
        UIConfigUtilsEditor.SaveViewConfig(m_UIFacade);
        EditorUtility.SetDirty(target);
        Debug.Log("ViewConfig配置已保存");
    }

    private void GenerateScriptNameAndID()
    {
        if (m_UIFacade == null) return;

        // 获取各个组件
        string moduleName = CleanName(m_EditorData.ModuleName);
        string subModuleName = m_EnableSubModule ? CleanName(m_EditorData.SubModuleName) : "";
        string uiName = CleanName(m_EditorData.UIName);

        // 生成脚本名称 (PascalCase)
        // 规则: ModuleNameSubModuleNameUINameWindow/View
        if (!string.IsNullOrEmpty(uiName))
        {
            string scriptName = "";

            // 添加模块名
            if (!string.IsNullOrEmpty(moduleName))
            {
                scriptName += ToPascalCase(moduleName);
            }

            // 添加子模块名（如果启用）
            if (!string.IsNullOrEmpty(subModuleName))
            {
                scriptName += ToPascalCase(subModuleName);
            }

            // 添加UI名称
            scriptName += ToPascalCase(uiName);

            // 添加后缀（根据是否为窗口模式）
            bool isWindow = m_ViewConfig != null && m_ViewConfig.IsWindow;
            scriptName += isWindow ? "Window" : "View";

            m_EditorData.ScriptName = scriptName;
        }
        else
        {
            m_EditorData.ScriptName = "";
        }

        // 生成ID (snake_case)
        // 规则: module_name.sub_module_name.ui_name
        if (!string.IsNullOrEmpty(uiName))
        {
            List<string> idParts = new List<string>();

            // 添加模块名
            if (!string.IsNullOrEmpty(moduleName))
            {
                idParts.Add(ToSnakeCase(moduleName));
            }

            // 添加子模块名（如果启用）
            if (!string.IsNullOrEmpty(subModuleName))
            {
                idParts.Add(ToSnakeCase(subModuleName));
            }

            // 添加UI名称
            idParts.Add(ToSnakeCase(uiName));

            m_EditorData.ID = string.Join(".", idParts);
        }
        else
        {
            m_EditorData.ID = "";
        }

        // 更新ViewConfig的ID
        if (m_ViewConfig != null && !string.IsNullOrEmpty(m_EditorData.ID))
        {
            m_ViewConfig.ID = m_EditorData.ID;
        }

        SaveEditorData();
    }

    private string CleanName(string name)
    {
        if (string.IsNullOrEmpty(name)) return "";

        // 移除特殊字符，只保留字母数字和空格
        return System.Text.RegularExpressions.Regex.Replace(name.Trim(), @"[^a-zA-Z0-9\s]", "");
    }

    private string ToPascalCase(string input)
    {
        if (string.IsNullOrEmpty(input)) return "";

        // 分割单词（按空格、下划线、连字符）
        string[] words = System.Text.RegularExpressions.Regex.Split(input, @"[\s_-]+");

        string result = "";
        foreach (string word in words)
        {
            if (!string.IsNullOrEmpty(word))
            {
                result += char.ToUpper(word[0]) + word.Substring(1).ToLower();
            }
        }

        return result;
    }

    private string ToSnakeCase(string input)
    {
        if (string.IsNullOrEmpty(input)) return "";

        // 分割单词（按空格、下划线、连字符、驼峰命名）
        string[] words = System.Text.RegularExpressions.Regex.Split(input, @"[\s_-]+|(?=[A-Z])");

        List<string> cleanWords = new List<string>();
        foreach (string word in words)
        {
            if (!string.IsNullOrEmpty(word))
            {
                cleanWords.Add(word.ToLower());
            }
        }

        return string.Join("_", cleanWords);
    }

    private string GenerateExampleScriptName()
    {
        // 使用当前输入生成示例
        string moduleName = CleanName(m_EditorData.ModuleName);
        string subModuleName = m_EnableSubModule ? CleanName(m_EditorData.SubModuleName) : "";
        string uiName = CleanName(m_EditorData.UIName);

        if (string.IsNullOrEmpty(moduleName) && string.IsNullOrEmpty(subModuleName) && string.IsNullOrEmpty(uiName))
        {
            // 显示默认示例
            return "GameUILoginView";
        }

        string scriptName = "";

        if (!string.IsNullOrEmpty(moduleName))
        {
            scriptName += ToPascalCase(moduleName);
        }
        else
        {
            scriptName += "Game"; // 默认示例
        }

        if (!string.IsNullOrEmpty(subModuleName))
        {
            scriptName += ToPascalCase(subModuleName);
        }
        else if (string.IsNullOrEmpty(moduleName) && string.IsNullOrEmpty(uiName))
        {
            scriptName += "UI"; // 默认示例
        }

        if (!string.IsNullOrEmpty(uiName))
        {
            scriptName += ToPascalCase(uiName);
        }
        else
        {
            scriptName += "Login"; // 默认示例
        }

        bool isWindow = m_ViewConfig != null && m_ViewConfig.IsWindow;
        scriptName += isWindow ? "Window" : "View";

        return scriptName;
    }

    private string GenerateExampleID()
    {
        // 使用当前输入生成示例
        string moduleName = CleanName(m_EditorData.ModuleName);
        string subModuleName = m_EnableSubModule ? CleanName(m_EditorData.SubModuleName) : "";
        string uiName = CleanName(m_EditorData.UIName);

        if (string.IsNullOrEmpty(moduleName) && string.IsNullOrEmpty(subModuleName) && string.IsNullOrEmpty(uiName))
        {
            // 显示默认示例
            return "game.ui.login";
        }

        List<string> idParts = new List<string>();

        if (!string.IsNullOrEmpty(moduleName))
        {
            idParts.Add(ToSnakeCase(moduleName));
        }
        else
        {
            idParts.Add("game"); // 默认示例
        }

        if (!string.IsNullOrEmpty(subModuleName))
        {
            idParts.Add(ToSnakeCase(subModuleName));
        }
        else if (string.IsNullOrEmpty(moduleName) && string.IsNullOrEmpty(uiName))
        {
            idParts.Add("ui"); // 默认示例
        }

        if (!string.IsNullOrEmpty(uiName))
        {
            idParts.Add(ToSnakeCase(uiName));
        }
        else
        {
            idParts.Add("login"); // 默认示例
        }

        return string.Join(".", idParts);
    }

    private string GetGameObjectPath(GameObject obj)
    {
        if (obj == null) return "";

        string path = obj.name;
        Transform parent = obj.transform.parent;

        while (parent != null && parent != m_UIFacade.transform)
        {
            path = parent.name + "/" + path;
            parent = parent.parent;
        }

        return path;
    }
}
