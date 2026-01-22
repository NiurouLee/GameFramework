using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities.Editor;
using System.IO;
using System.Text;

namespace NFramework.Module.UIModule
{
    /// <summary>
    /// UIFacade工具栏绘制器
    /// </summary>
    public static class UIFacadeToolsDrawer
    {
        /// <summary>
        /// 绘制工具栏区域
        /// </summary>
        public static void DrawToolButtons(UIFacade facade, ref bool foldout, System.Action onDataChanged)
        {
            SirenixEditorGUI.BeginBox();
            SirenixEditorGUI.BeginBoxHeader();
            foldout = EditorGUILayout.Foldout(foldout, "工具栏", true);
            SirenixEditorGUI.EndBoxHeader();

            if (foldout)
            {
                SirenixEditorGUI.InfoMessageBox("使用以下工具来管理UI元素和配置");

                EditorGUILayout.Space(3);

                // 第一行工具按钮
                EditorGUILayout.BeginHorizontal();
                {
                    // 自动收集按钮
                    GUI.backgroundColor = new Color(0.7f, 1f, 0.7f);
                    if (GUILayout.Button(new GUIContent("自动收集子对象", "自动收集GameObject下的所有IUIComponent组件"),
                            GUILayout.Height(22)))
                    {
                        AutoCollectChildComponents(facade, onDataChanged);
                    }

                    // 清空按钮
                    GUI.backgroundColor = new Color(1f, 0.7f, 0.7f);
                    if (GUILayout.Button(new GUIContent("清空列表", "清空所有UI元素"), GUILayout.Height(22)))
                    {
                        ClearUIElements(facade, onDataChanged);
                    }

                    GUI.backgroundColor = Color.white;
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(3);

                // 第二行工具按钮
                EditorGUILayout.BeginHorizontal();
                {
                    // 验证配置按钮
                    GUI.backgroundColor = new Color(0.9f, 0.9f, 0.7f);
                    if (GUILayout.Button(new GUIContent("验证配置", "验证当前配置是否正确"), GUILayout.Height(22)))
                    {
                        ValidateConfiguration(facade);
                    }

                    // 生成脚本按钮
                    GUI.backgroundColor = new Color(0.7f, 0.9f, 1f);
                    if (GUILayout.Button(new GUIContent("生成脚本", "根据配置生成UI脚本"), GUILayout.Height(22)))
                    {
                        GenerateScript(facade);
                    }

                    GUI.backgroundColor = Color.white;
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(3);

                // 第三行工具按钮
                EditorGUILayout.BeginHorizontal();
                {
                    // 保存配置按钮
                    GUI.backgroundColor = new Color(0.8f, 0.8f, 1f);
                    if (GUILayout.Button(new GUIContent("保存配置", "保存当前配置到Prefab"), GUILayout.Height(22)))
                    {
                        SaveComponent(facade);
                    }

                    GUI.backgroundColor = Color.white;
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(3);

                // 第四行工具按钮
                EditorGUILayout.BeginHorizontal();
                {
                    // 打开脚本按钮
                    if (!string.IsNullOrEmpty(facade.m_ScriptName))
                    {
                        string logicFolderPath = "Assets/Scripts/UI";
                        string logicFilePath = Path.Combine(logicFolderPath, facade.m_ScriptName + ".cs");
                        bool logicFileExists = File.Exists(logicFilePath);

                        EditorGUI.BeginDisabledGroup(!logicFileExists);
                        GUI.backgroundColor = new Color(0.7f, 1f, 1f);
                        if (GUILayout.Button(new GUIContent("打开 Logic 脚本", "打开对应的逻辑脚本文件"), GUILayout.Height(22)))
                        {
                            Object scriptAsset = AssetDatabase.LoadAssetAtPath<Object>(logicFilePath);
                            if (scriptAsset != null)
                            {
                                AssetDatabase.OpenAsset(scriptAsset);
                            }
                            else
                            {
                                Debug.LogError($"找不到脚本文件: {logicFilePath}");
                            }
                        }

                        GUI.backgroundColor = Color.white;
                        EditorGUI.EndDisabledGroup();
                    }
                }
                EditorGUILayout.EndHorizontal();
            }

            SirenixEditorGUI.EndBox();
        }

        private static void AutoCollectChildComponents(UIFacade facade, System.Action onDataChanged)
        {
            if (facade == null || facade.gameObject == null) return;

            if (facade.m_UIElements == null)
            {
                facade.m_UIElements = new List<UIFacade.UIElement>();
            }

            // 收集所有子对象中的IUIComponent组件
            // 先获取所有Component，然后过滤出实现了IUIComponent的
            Component[] allComponents = facade.GetComponentsInChildren<Component>(true);
            var uiComponents = allComponents.Where(c => c != null && c is IUIComponent).Cast<IUIComponent>().ToArray();

            int addedCount = 0;
            foreach (var uiComponent in uiComponents)
            {
                // 将IUIComponent转换为Component以访问gameObject
                Component component = uiComponent as Component;
                if (component == null) continue;

                // 检查是否已存在
                bool exists = false;
                foreach (var element in facade.m_UIElements)
                {
                    if (element != null && element.Component == uiComponent)
                    {
                        exists = true;
                        break;
                    }
                }

                if (!exists)
                {
                    var newElement = new UIFacade.UIElement
                    {
                        Name = component.gameObject.name,
                        Component = uiComponent,
                        Desc = ""
                    };
                    facade.m_UIElements.Add(newElement);
                    addedCount++;
                }
            }

            EditorUtility.SetDirty(facade);
            onDataChanged?.Invoke();

            if (addedCount > 0)
            {
                EditorUtility.DisplayDialog("成功", $"已自动收集 {addedCount} 个UI组件", "确定");
            }
            else
            {
                EditorUtility.DisplayDialog("提示", "没有找到新的UI组件", "确定");
            }
        }

        private static void ClearUIElements(UIFacade facade, System.Action onDataChanged)
        {
            if (EditorUtility.DisplayDialog("确认", "确定要清空所有UI元素吗？", "确定", "取消"))
            {
                if (facade.m_UIElements != null)
                {
                    facade.m_UIElements.Clear();
                }

                EditorUtility.SetDirty(facade);
                onDataChanged?.Invoke();
            }
        }

        private static void ValidateConfiguration(UIFacade facade)
        {
            List<string> issues = new List<string>();

            if (string.IsNullOrEmpty(facade.m_ModuleName))
                issues.Add("模块名称不能为空");

            if (string.IsNullOrEmpty(facade.m_UIName))
                issues.Add("UI名称不能为空");

            if (string.IsNullOrEmpty(facade.m_ScriptName))
                issues.Add("脚本名称不能为空");

            if (facade.m_UIElements != null && facade.m_UIElements.Count > 0)
            {
                var duplicateNames = facade.m_UIElements
                    .Where(e => e != null)
                    .GroupBy(e => e.Name)
                    .Where(g => g.Count() > 1)
                    .Select(g => g.Key);

                if (duplicateNames.Any())
                    issues.Add($"发现重复的元素名称: {string.Join(", ", duplicateNames)}");

                var nullComponents = new List<int>();
                for (int i = 0; i < facade.m_UIElements.Count; i++)
                {
                    if (facade.m_UIElements[i] == null || facade.m_UIElements[i].Component == null)
                    {
                        nullComponents.Add(i);
                    }
                }

                if (nullComponents.Any())
                    issues.Add($"以下索引的元素组件为空: {string.Join(", ", nullComponents)}");
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

        private static void GenerateScript(UIFacade facade)
        {
            if (facade == null || string.IsNullOrEmpty(facade.m_ScriptName))
            {
                EditorUtility.DisplayDialog("错误", "脚本名称不能为空，请先配置基本信息", "确定");
                return;
            }

            string scriptName = facade.m_ScriptName;

            // 获取ViewConfig以确定是否是Window
            ViewConfig viewConfig = UIConfigUtilsEditor.GetViewConfig(facade);
            bool isWindow = viewConfig != null && viewConfig.IsWindow;

            // 0. 保存ViewConfig
            UIFacadeViewConfigDrawer.SaveViewConfigToJson(facade, viewConfig);

            // 清理旧的 .Generated.cs 文件 (如果存在)
            string generatedFolderPath = "Assets/Generated/UI";
            string generatedFilePath = Path.Combine(generatedFolderPath, scriptName + ".Generated.cs");
            if (File.Exists(generatedFilePath))
            {
                // 尝试删除
                try
                {
                    AssetDatabase.DeleteAsset(generatedFilePath);
                }
                catch
                {
                    // 如果AssetDatabase删除失败（例如文件未导入），尝试系统删除
                    if (File.Exists(generatedFilePath)) File.Delete(generatedFilePath);
                }
            }

            // 1. 生成 Logic 文件 (包含了属性生成的逻辑)
            string logicFolderPath = "Assets/Scripts/UI";
            if (!Directory.Exists(logicFolderPath)) Directory.CreateDirectory(logicFolderPath);

            string logicFilePath = Path.Combine(logicFolderPath, scriptName + ".cs");
            WriteLogicFile(logicFilePath, scriptName, facade, isWindow);

            AssetDatabase.Refresh();

            string msg = $"脚本生成完毕！\n\n文件: {logicFilePath}";
            EditorUtility.DisplayDialog("成功", msg, "确定");
        }

        private static void WriteLogicFile(string filePath, string scriptName, UIFacade facade, bool isWindow)
        {
            string baseClass = isWindow ? "Window" : "View";
            string componentRegionStart = "        #region UI Components (Auto Generated)";
            string componentRegionEnd = "        #endregion";

            StringBuilder propertiesSb = new StringBuilder();
            if (facade.m_UIElements != null)
            {
                for (int i = 0; i < facade.m_UIElements.Count; i++)
                {
                    var element = facade.m_UIElements[i];
                    if (element != null && element.Component != null && !string.IsNullOrEmpty(element.Name))
                    {
                        string typeName = element.Component.GetType().FullName;
                        propertiesSb.AppendLine(
                            $"        public {typeName} {element.Name} => Facade.Components[{i}] as {typeName};");
                    }
                }
            }

            string propertiesCode = propertiesSb.ToString();

            if (!File.Exists(filePath))
            {
                // 新建文件
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("using UnityEngine;");
                sb.AppendLine("using NFramework.Module.UIModule;");
                sb.AppendLine("");
                sb.AppendLine("namespace NFramework.Module.UIModule");
                sb.AppendLine("{");
                sb.AppendLine($"    public partial class {scriptName} : {baseClass}");
                sb.AppendLine("    {");
                sb.AppendLine(componentRegionStart);
                sb.Append(propertiesCode);
                sb.AppendLine(componentRegionEnd);
                sb.AppendLine("");
                sb.AppendLine("        protected override void OnAwake()");
                sb.AppendLine("        {");
                sb.AppendLine("            base.OnAwake();");
                sb.AppendLine("        }");
                sb.AppendLine("    }");
                sb.AppendLine("}");
                File.WriteAllText(filePath, sb.ToString());
            }
            else
            {
                // 更新现有文件
                string content = File.ReadAllText(filePath);

                // 1. 更新继承关系
                // 简单的正则替换，假设格式是 "class ScriptName : BaseClass"
                string patternInheritance = $@"class\s+{scriptName}\s*:\s*\w+";
                string replacementInheritance = $"class {scriptName} : {baseClass}";

                if (System.Text.RegularExpressions.Regex.IsMatch(content, patternInheritance))
                {
                    content = System.Text.RegularExpressions.Regex.Replace(content, patternInheritance,
                        replacementInheritance);
                }

                // 2. 更新组件属性
                string newBlock = componentRegionStart + "\n" + propertiesCode + componentRegionEnd;
                string regionPattern = @"\s*#region UI Components \(Auto Generated\)[\s\S]*?#endregion";

                if (System.Text.RegularExpressions.Regex.IsMatch(content, regionPattern))
                {
                    content = System.Text.RegularExpressions.Regex.Replace(content, regionPattern, "\n" + newBlock);
                }
                else
                {
                    // 没有Region，尝试插入到类定义开始处
                    int classIndex = content.IndexOf($"class {scriptName}");
                    if (classIndex != -1)
                    {
                        int braceIndex = content.IndexOf('{', classIndex);
                        if (braceIndex != -1)
                        {
                            content = content.Insert(braceIndex + 1, "\n" + newBlock + "\n");
                        }
                    }
                }

                File.WriteAllText(filePath, content);
            }
        }

        private static void SaveComponent(UIFacade facade)
        {
            EditorUtility.SetDirty(facade);
            AssetDatabase.SaveAssets();
            Debug.Log("UI Facade配置已保存");
        }
    }
}
