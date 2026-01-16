using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using UnityEditor.SceneManagement;
[CustomEditor(typeof(CombineItem))]
public class CombineItemEditor : Editor
{
    string meshDir = "Assets/";
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        //GUILayout.BeginHorizontal();
        var citem = (CombineItem)target;
        if (GUILayout.Button("Combine"))
        {
            CombineMesh.CombineGO(citem.gameObject, citem, false, "");
        }
        meshDir = GUILayout.TextField(meshDir);
        if (GUILayout.Button("Combine Save Mesh"))
        {
            CombineMesh.CombineGO(citem.gameObject, citem, true, meshDir);
        }
        if (GUILayout.Button("Combine Save Mesh All"))
        {
            CombineItem[] ciArray = GameObject.FindObjectsOfType<CombineItem>();
            CombineMesh.CombineCombineItems(ciArray, true, meshDir);
        }
        //GUILayout.EndHorizontal();
    }
}
