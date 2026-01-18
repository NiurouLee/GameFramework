using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities.Editor;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// UIFacade UI元素列表绘制器
    /// </summary>
    public static class UIFacadeUIElementsDrawer
    {
        /// <summary>
        /// 绘制UI元素列表区域
        /// </summary>
        public static void DrawUIElementsList(UIFacade facade, ref bool foldout, System.Action onDataChanged)
        {
            SirenixEditorGUI.BeginBox();
            SirenixEditorGUI.BeginBoxHeader();
            foldout = EditorGUILayout.Foldout(foldout, "UI元素列表", true);
            SirenixEditorGUI.EndBoxHeader();
            
            if (foldout)
            {
                if (facade.m_UIElements == null)
                {
                    facade.m_UIElements = new List<UIFacade.UIElement>();
                }

                // 列表标题和添加按钮
                DrawToolbar(facade, onDataChanged);

                EditorGUILayout.Space(3);

                // 如果列表为空，显示提示
                if (facade.m_UIElements.Count == 0)
                {
                    SirenixEditorGUI.InfoMessageBox("暂无UI元素，点击上方的 + 按钮添加新元素，或使用下方的\"自动收集子对象\"功能。");
                }
                else
                {
                    // 绘制元素列表
                    for (int i = 0; i < facade.m_UIElements.Count; i++)
                    {
                        DrawUIElement(facade, i, onDataChanged);
                    }
                }
            }

            SirenixEditorGUI.EndBox();
        }

        private static void DrawToolbar(UIFacade facade, System.Action onDataChanged)
        {
            SirenixEditorGUI.BeginHorizontalToolbar();
            {
                GUILayout.Label($"元素数量: {facade.m_UIElements.Count}", SirenixGUIStyles.LeftAlignedGreyMiniLabel);
                GUILayout.FlexibleSpace();

                // 添加按钮
                GUI.backgroundColor = Color.green;
                if (GUILayout.Button(new GUIContent("+", "添加新UI元素"),
                        GUILayout.Width(25), GUILayout.Height(18)))
                {
                    AddNewUIElement(facade, onDataChanged);
                }

                GUI.backgroundColor = Color.white;

                // 刷新按钮
                if (GUILayout.Button(new GUIContent("↻", "刷新并清理无效元素"),
                        GUILayout.Width(25), GUILayout.Height(18)))
                {
                    RefreshUIElements(facade, onDataChanged);
                }
            }
            SirenixEditorGUI.EndHorizontalToolbar();
        }

        private static void DrawUIElement(UIFacade facade, int index, System.Action onDataChanged)
        {
            if (facade.m_UIElements == null || index < 0 || index >= facade.m_UIElements.Count)
                return;

            var element = facade.m_UIElements[index];
            if (element == null)
            {
                element = new UIFacade.UIElement();
                facade.m_UIElements[index] = element;
            }

            SirenixEditorGUI.BeginBox();
            {
                // 第一行：标题栏（折叠开关 + 索引 + 名称 + 删除按钮）
                SirenixEditorGUI.BeginHorizontalToolbar();
                {
                    // 使用 Foldout 控制展开/折叠
                    bool isExpanded = EditorPrefs.GetBool($"UIElement_{facade.GetInstanceID()}_{index}", true);
                    isExpanded = EditorGUILayout.Foldout(isExpanded, $"[{index}] {element.Name ?? "未命名"}", true);
                    EditorPrefs.SetBool($"UIElement_{facade.GetInstanceID()}_{index}", isExpanded);

                    GUILayout.FlexibleSpace();

                    // 删除按钮
                    GUI.color = Color.red;
                    if (GUILayout.Button("×", GUILayout.Width(18), GUILayout.Height(16)))
                    {
                        if (EditorUtility.DisplayDialog("确认删除", $"确定要删除元素 '{element.Name}' 吗？", "确定", "取消"))
                        {
                            RemoveUIElement(facade, index, onDataChanged);
                            return;
                        }
                    }

                    GUI.color = Color.white;
                }
                SirenixEditorGUI.EndHorizontalToolbar();

                // 如果处于展开状态，显示详细信息
                bool showDetails = EditorPrefs.GetBool($"UIElement_{facade.GetInstanceID()}_{index}", true);
                if (showDetails)
                {
                    EditorGUILayout.Space(2);

                    // 详细信息第一行：名称
                    DrawElementName(facade, element, index, onDataChanged);

                    EditorGUILayout.Space(2);

                    // 详细信息第二行：组件
                    DrawElementComponent(facade, element, onDataChanged);

                    EditorGUILayout.Space(2);

                    // 详细信息第三行：描述
                    DrawElementDesc(facade, element, onDataChanged);
                }
            }
            SirenixEditorGUI.EndBox();
        }

        private static void DrawElementName(UIFacade facade, UIFacade.UIElement element, int index, System.Action onDataChanged)
        {
            EditorGUILayout.BeginHorizontal();
            {
                GUILayout.Space(15); // 缩进

                // 名称字段
                EditorGUI.BeginChangeCheck();
                GUILayout.Label("名称:", GUILayout.Width(30));
                string newName = EditorGUILayout.TextField(element.Name ?? "", GUILayout.MinWidth(80));
                if (EditorGUI.EndChangeCheck())
                {
                    if (UIFacadeUtils.CheckName(facade, index, newName))
                    {
                        element.Name = newName;
                        EditorUtility.SetDirty(facade);
                        onDataChanged?.Invoke();
                    }
                    else
                    {
                        EditorUtility.DisplayDialog("错误", "元素名称重复或无效！", "确定");
                    }
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        private static void DrawElementComponent(UIFacade facade, UIFacade.UIElement element, System.Action onDataChanged)
        {
            EditorGUILayout.BeginHorizontal();
            {
                GUILayout.Space(15); // 缩进

                // 组件选择字段
                GUILayout.Label("组件:", GUILayout.Width(35));
                Component currentComponent = element.Component as Component;

                EditorGUI.BeginChangeCheck();
                float fieldWidth = EditorGUIUtility.currentViewWidth - 200;
                Component selectedComponent = (Component)EditorGUILayout.ObjectField(
                    currentComponent, typeof(Component), true, GUILayout.Width(fieldWidth));
                if (EditorGUI.EndChangeCheck() && selectedComponent != currentComponent)
                {
                    if (selectedComponent == null)
                    {
                        element.Component = null;
                        if (string.IsNullOrEmpty(element.Name))
                            element.Name = "";
                        EditorUtility.SetDirty(facade);
                        onDataChanged?.Invoke();
                    }
                    else
                    {
                        // 检查是否实现了IUIComponent接口
                        if (selectedComponent is IUIComponent)
                        {
                            element.Component = selectedComponent as IUIComponent;
                            if (string.IsNullOrEmpty(element.Name))
                                element.Name = selectedComponent.gameObject.name;
                            EditorUtility.SetDirty(facade);
                            onDataChanged?.Invoke();
                        }
                        else
                        {
                            EditorUtility.DisplayDialog("错误", "组件必须实现IUIComponent接口！", "确定");
                        }
                    }
                }

                // 显示组件类型
                if (element.Component != null)
                {
                    GUILayout.Label($"({element.Component.GetType().Name})", SirenixGUIStyles.RightAlignedGreyMiniLabel);
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        private static void DrawElementDesc(UIFacade facade, UIFacade.UIElement element, System.Action onDataChanged)
        {
            EditorGUILayout.BeginHorizontal();
            {
                GUILayout.Space(15); // 缩进
                GUILayout.Label("描述:", GUILayout.Width(35));
                EditorGUI.BeginChangeCheck();
                string newDesc = EditorGUILayout.TextArea(element.Desc ?? "", GUILayout.Height(40));
                if (EditorGUI.EndChangeCheck())
                {
                    element.Desc = newDesc;
                    EditorUtility.SetDirty(facade);
                    onDataChanged?.Invoke();
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        private static void AddNewUIElement(UIFacade facade, System.Action onDataChanged)
        {
            if (facade.m_UIElements == null)
            {
                facade.m_UIElements = new List<UIFacade.UIElement>();
            }

            var newElement = new UIFacade.UIElement();
            facade.m_UIElements.Add(newElement);
            EditorUtility.SetDirty(facade);
            onDataChanged?.Invoke();
        }

        private static void RemoveUIElement(UIFacade facade, int index, System.Action onDataChanged)
        {
            if (facade.m_UIElements == null || index < 0 || index >= facade.m_UIElements.Count)
                return;

            facade.m_UIElements.RemoveAt(index);
            EditorUtility.SetDirty(facade);
            onDataChanged?.Invoke();
        }

        private static void RefreshUIElements(UIFacade facade, System.Action onDataChanged)
        {
            if (facade.m_UIElements == null)
            {
                facade.m_UIElements = new List<UIFacade.UIElement>();
            }

            // 清理无效的元素（组件为空的）
            for (int i = facade.m_UIElements.Count - 1; i >= 0; i--)
            {
                if (facade.m_UIElements[i] == null || facade.m_UIElements[i].Component == null)
                {
                    facade.m_UIElements.RemoveAt(i);
                }
            }

            EditorUtility.SetDirty(facade);
            onDataChanged?.Invoke();
        }
    }
}
