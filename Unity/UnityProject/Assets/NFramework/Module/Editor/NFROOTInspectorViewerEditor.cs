using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using NFramework.Module.EntityModule;

namespace NFramework.Module.Editor
{
    [CustomEditor(typeof(NFROOTInspectorViewer))]
    public class NFROOTInspectorViewerEditor : UnityEditor.Editor
    {
        private NFROOTInspectorViewer viewer;
        private Dictionary<long, bool> entityFoldoutStates = new Dictionary<long, bool>();
        private Dictionary<System.Type, bool> componentFoldoutStates = new Dictionary<System.Type, bool>();
        private Vector2 scrollPosition;
        private bool showChildren = true;
        private bool showComponents = true;

        private void OnEnable()
        {
            viewer = (NFROOTInspectorViewer)target;
        }

        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();
            
            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("NFROOT层级结构", EditorStyles.boldLabel);
            
            if (NFROOT.I == null)
            {
                EditorGUILayout.HelpBox("NFROOT实例不存在，请确保已初始化", MessageType.Warning);
                return;
            }

            // 刷新按钮
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("刷新", GUILayout.Height(25)))
            {
                entityFoldoutStates.Clear();
                componentFoldoutStates.Clear();
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(5);

            // 显示选项
            showChildren = EditorGUILayout.Toggle("显示子实体", showChildren);
            showComponents = EditorGUILayout.Toggle("显示组件", showComponents);

            EditorGUILayout.Space(5);
            EditorGUILayout.LabelField("", GUI.skin.horizontalSlider);

            // 滚动视图
            scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);
            
            // 绘制根节点
            DrawEntity(NFROOT.I, 0, true);
            
            EditorGUILayout.EndScrollView();
        }

        private void DrawEntity(Entity entity, int depth, bool isRoot = false)
        {
            if (entity == null || entity.IsDisposed)
                return;

            // 计算缩进
            float indent = depth * 15f;
            GUILayout.BeginHorizontal();
            GUILayout.Space(indent);

            // 获取或创建折叠状态
            long entityId = entity.Id;
            if (!entityFoldoutStates.ContainsKey(entityId))
            {
                entityFoldoutStates[entityId] = depth < 2; // 默认展开前两层
            }

            // 实体信息
            string entityName = entity.GetType().Name;
            string prefix = isRoot ? "[ROOT] " : "";
            
            bool isExpanded = EditorGUILayout.Foldout(
                entityFoldoutStates[entityId],
                $"{prefix}{entityName} (ID: {entityId})",
                true
            );
            entityFoldoutStates[entityId] = isExpanded;

            GUILayout.EndHorizontal();

            if (!isExpanded)
                return;

            // 显示实体详细信息
            GUILayout.BeginHorizontal();
            GUILayout.Space(indent + 15f);
            GUILayout.BeginVertical();

            // 显示状态信息
            EditorGUI.indentLevel++;
            EditorGUILayout.LabelField("状态:", $"Valid: {entity.IsValid}, Disposed: {entity.IsDisposed}, Enable: {entity.Enable}");
            EditorGUI.indentLevel--;

            // 显示组件
            if (showComponents && entity.Components != null && entity.Components.Count > 0)
            {
                EditorGUILayout.Space(3);
                EditorGUILayout.LabelField($"组件 ({entity.Components.Count}):", EditorStyles.boldLabel);
                
                foreach (var kvp in entity.Components)
                {
                    DrawComponent(kvp.Value, depth + 1);
                }
            }

            // 显示子实体
            if (showChildren && entity.Children != null && entity.Children.Count > 0)
            {
                EditorGUILayout.Space(3);
                EditorGUILayout.LabelField($"子实体 ({entity.Children.Count}):", EditorStyles.boldLabel);
                
                foreach (var kvp in entity.Children)
                {
                    DrawEntity(kvp.Value, depth + 1, false);
                }
            }

            GUILayout.EndVertical();
            GUILayout.EndHorizontal();
        }

        private void DrawComponent(Entity component, int depth)
        {
            if (component == null || component.IsDisposed)
                return;

            float indent = depth * 15f;
            GUILayout.BeginHorizontal();
            GUILayout.Space(indent);

            System.Type componentType = component.GetType();
            if (!componentFoldoutStates.ContainsKey(componentType))
            {
                componentFoldoutStates[componentType] = false;
            }

            // 组件信息
            string componentName = componentType.Name;
            
            bool isExpanded = EditorGUILayout.Foldout(
                componentFoldoutStates[componentType],
                $"[Component] {componentName} (ID: {component.Id})",
                true
            );
            componentFoldoutStates[componentType] = isExpanded;

            GUILayout.EndHorizontal();

            if (isExpanded)
            {
                GUILayout.BeginHorizontal();
                GUILayout.Space(indent + 15f);
                GUILayout.BeginVertical();

                EditorGUI.indentLevel++;
                EditorGUILayout.LabelField("状态:", $"Valid: {component.IsValid}, Disposed: {component.IsDisposed}, Enable: {component.Enable}");
                EditorGUI.indentLevel--;

                // 递归显示组件的子组件和子实体
                if (showComponents && component.Components != null && component.Components.Count > 0)
                {
                    EditorGUILayout.Space(2);
                    EditorGUILayout.LabelField($"子组件 ({component.Components.Count}):", EditorStyles.miniLabel);
                    foreach (var kvp in component.Components)
                    {
                        DrawComponent(kvp.Value, depth + 1);
                    }
                }

                if (showChildren && component.Children != null && component.Children.Count > 0)
                {
                    EditorGUILayout.Space(2);
                    EditorGUILayout.LabelField($"子实体 ({component.Children.Count}):", EditorStyles.miniLabel);
                    foreach (var kvp in component.Children)
                    {
                        DrawEntity(kvp.Value, depth + 1, false);
                    }
                }

                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }
        }
    }
}
