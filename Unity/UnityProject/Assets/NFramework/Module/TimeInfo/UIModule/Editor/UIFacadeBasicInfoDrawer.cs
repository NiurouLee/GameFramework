using UnityEditor;
using UnityEngine;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities.Editor;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// UIFacade基本信息绘制器
    /// </summary>
    public static class UIFacadeBasicInfoDrawer
    {
        /// <summary>
        /// 绘制基本信息区域
        /// </summary>
        public static void DrawBasicInfo(UIFacade facade, ref bool foldout, System.Action onDataChanged)
        {
            SirenixEditorGUI.BeginBox();
            SirenixEditorGUI.BeginBoxHeader();
            foldout = EditorGUILayout.Foldout(foldout, "基本信息", true);
            SirenixEditorGUI.EndBoxHeader();
            
            if (foldout)
            {
                EditorGUI.BeginChangeCheck();

                // 启用子模块 Toggle
                DrawSubModuleToggle(facade, onDataChanged);

                EditorGUILayout.Space(3);

                // 模块/子模块/UI名称输入
                DrawNameFields(facade, onDataChanged);

                // 脚本名称和 ID (只读)
                DrawScriptNameAndID(facade, onDataChanged);

                // ViewConfig 的 ID 始终使用脚本名称
                if (!string.IsNullOrEmpty(facade.m_ScriptName))
                {
                    var viewConfig = UIConfigUtilsEditor.GetViewConfig(facade);
                    if (viewConfig != null && viewConfig.ID != facade.m_ScriptName)
                    {
                        viewConfig.ID = facade.m_ScriptName;
                    }
                }

                // 生成规则 Box
                DrawGenerationRules();

                if (EditorGUI.EndChangeCheck())
                {
                    EditorUtility.SetDirty(facade);
                    onDataChanged?.Invoke();
                }
            }

            SirenixEditorGUI.EndBox();
        }

        private static void DrawSubModuleToggle(UIFacade facade, System.Action onDataChanged)
        {
            EditorGUILayout.BeginHorizontal();
            {
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.LabelField("启用子模块:", GUILayout.Width(80));
                bool newEnableSubModule = EditorGUILayout.Toggle(facade.m_EnableSubModule, GUILayout.Width(20));
                bool subModuleToggleChanged = EditorGUI.EndChangeCheck();

                if (facade.m_EnableSubModule)
                    GUILayout.Label("(已启用)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(50));
                else GUILayout.Label("(已禁用)", SirenixGUIStyles.RightAlignedGreyMiniLabel, GUILayout.Width(50));

                GUILayout.FlexibleSpace();

                if (subModuleToggleChanged)
                {
                    facade.m_EnableSubModule = newEnableSubModule;
                    if (!facade.m_EnableSubModule && !string.IsNullOrEmpty(facade.m_SubModuleName))
                    {
                        if (EditorUtility.DisplayDialog("确认", "禁用子模块将清空子模块名称，确定继续吗？", "确定", "取消"))
                        {
                            facade.m_SubModuleName = "";
                            EditorUtility.SetDirty(facade);
                            UIFacadeNameGenerator.GenerateScriptNameAndID(facade, out string scriptName, out string id);
                            facade.m_ScriptName = scriptName;
                            facade.ID = id;
                            onDataChanged?.Invoke();
                        }
                        else facade.m_EnableSubModule = true;
                    }
                    else
                    {
                        EditorUtility.SetDirty(facade);
                        UIFacadeNameGenerator.GenerateScriptNameAndID(facade, out string scriptName, out string id);
                        facade.m_ScriptName = scriptName;
                        facade.ID = id;
                        onDataChanged?.Invoke();
                    }
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        private static void DrawNameFields(UIFacade facade, System.Action onDataChanged)
        {
            EditorGUI.BeginChangeCheck();
            facade.m_ModuleName = SirenixEditorFields.TextField("模块名称", facade.m_ModuleName ?? "");
            if (facade.m_EnableSubModule)
                facade.m_SubModuleName = SirenixEditorFields.TextField("子模块名称", facade.m_SubModuleName ?? "");
            facade.m_UIName = SirenixEditorFields.TextField("UI名称", facade.m_UIName ?? "");

            if (EditorGUI.EndChangeCheck())
            {
                EditorUtility.SetDirty(facade);
                UIFacadeNameGenerator.GenerateScriptNameAndID(facade, out string scriptName, out string id);
                facade.m_ScriptName = scriptName;
                facade.ID = id;
                onDataChanged?.Invoke();
            }
        }

        private static void DrawScriptNameAndID(UIFacade facade, System.Action onDataChanged)
        {
            // 脚本名称和 ID (只读)
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("脚本名称:", GUILayout.Width(80));
            EditorGUILayout.LabelField(facade.m_ScriptName ?? "未生成", SirenixGUIStyles.RightAlignedGreyMiniLabel);
            if (GUILayout.Button("重新生成", GUILayout.Width(70)))
            {
                UIFacadeNameGenerator.GenerateScriptNameAndID(facade, out string scriptName, out string id);
                facade.m_ScriptName = scriptName;
                facade.ID = id;
                EditorUtility.SetDirty(facade);
                onDataChanged?.Invoke();
            }
            EditorGUILayout.EndHorizontal();

            // 检查脚本名称是否重复并显示提示
            // 排除当前配置本身（如果已经保存过）
            if (!string.IsNullOrEmpty(facade.m_ScriptName))
            {
                // 检查当前配置是否已经在JSON中保存过
                string excludeConfigID = null;
                ViewConfigManager.ViewConfigData existingConfig = ViewConfigManager.LoadViewConfig(facade.m_ScriptName);
                if (existingConfig != null && existingConfig.ID == facade.m_ScriptName)
                {
                    excludeConfigID = facade.m_ScriptName;
                }

                if (!UIFacadeNameGenerator.CheckScriptNameDuplicate(facade.m_ScriptName, out string duplicateInfo, excludeConfigID))
                {
                    EditorGUILayout.HelpBox($"⚠ 警告：脚本名称 '{facade.m_ScriptName}' 已存在！\n{duplicateInfo}\n请修改UI名称或模块名称以生成不同的脚本名称。", MessageType.Warning);
                }
            }

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("ID:", GUILayout.Width(80));
            string currentID = facade.ID ?? "未生成";
            EditorGUILayout.LabelField(currentID, SirenixGUIStyles.RightAlignedGreyMiniLabel);
            if (GUILayout.Button("复制ID", GUILayout.Width(70)) && !string.IsNullOrEmpty(facade.ID))
            {
                EditorGUIUtility.systemCopyBuffer = facade.ID;
                Debug.Log($"已复制ID: {facade.ID}");
            }
            EditorGUILayout.EndHorizontal();
        }

        private static void DrawGenerationRules()
        {
            SirenixEditorGUI.BeginBox("生成规则");
            EditorGUILayout.LabelField("脚本名称: 模块名 + 子模块名 + UI名称",
                SirenixGUIStyles.LeftAlignedGreyMiniLabel);
            EditorGUILayout.LabelField("ID格式: module_name.sub_module_name.ui_name",
                SirenixGUIStyles.LeftAlignedGreyMiniLabel);
            SirenixEditorGUI.EndBox();
        }
    }
}
