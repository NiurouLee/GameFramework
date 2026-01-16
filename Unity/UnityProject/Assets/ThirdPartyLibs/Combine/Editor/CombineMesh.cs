using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;

public class CombineMesh {

    [MenuItem("PwNgs/Editor/Select MeshRenderer In Children")]
    public static void SelectMeshRendererInChildren()
    {
        GameObject goSel = Selection.activeGameObject;
        if (null == goSel)
            return;

        //取得选中物体下所有MeshRenderer//
        MeshRenderer[] mrArray = goSel.GetComponentsInChildren<MeshRenderer>();
        List<GameObject> goList = new List<GameObject>();
        foreach (MeshRenderer mr in mrArray)
        {
            goList.Add(mr.gameObject);
        }
        Selection.objects = goList.ToArray();
    }

    [MenuItem("PwNgs/Editor/Tell me Lightmap Info")]
    public static void TellmeLightmapInfo()
    {
        GameObject goSel = Selection.activeGameObject;
        if (null == goSel)
            return;

        //取得选中物体下所有MeshRenderer//
        MeshRenderer[] mrArray = goSel.GetComponentsInChildren<MeshRenderer>();
        foreach (MeshRenderer mr in mrArray)
        {
            Debug.Log(mr.name + " lightmapIndex=" + mr.lightmapIndex + " lightmapScaleOffset" + mr.lightmapScaleOffset);
        }
    }

    static bool CanCombine(MeshRenderer mr)
    {
        //if (!mr.enabled)
        //    return false;
        MeshCollider mc = mr.GetComponent<MeshCollider>();
        if (mc)
            return false;//比如行走面，不可以合并和删除
        MeshFilter mf = mr.GetComponent<MeshFilter>();
        if (!mf || !mf.sharedMesh)
            return false;
        if (mf.sharedMesh.subMeshCount > 1)
            return false;

        return true;
    }

    static Vector3 FloorToAlignSize(Vector3 v, Vector3 size)
    {
        var nums = Vector3.zero;
        nums.x = Mathf.Floor(v.x / size.x);
        nums.y = Mathf.Floor(v.y / size.y);
        nums.z = Mathf.Floor(v.z / size.z);
        nums.Scale(size);
        return nums;
    }
    static Vector3 CeilToAlignSize(Vector3 v, Vector3 size)
    {
        var nums = Vector3.zero;
        nums.x = Mathf.Ceil(v.x / size.x);
        nums.y = Mathf.Ceil(v.y / size.y);
        nums.z = Mathf.Ceil(v.z / size.z);
        nums.Scale(size);
        return nums;
    }
    public static void CombineGO(GameObject goSel, CombineItem citem, bool saveMesh,
        string meshDir)
    {
        if (null == goSel)
            return;

        //取得选中物体下所有MeshRenderer//
        MeshRenderer[] mrs = goSel.GetComponentsInChildren<MeshRenderer>();
        if (citem && citem.combineByBlock)
        {
            //分块合并
            Vector3 posMin = mrs[0].transform.position;
            Vector3 posMax = posMin;
            foreach (var mr in mrs)
            {
                posMin = Vector3.Min(posMin, mr.transform.position);
                posMax = Vector3.Max(posMax, mr.transform.position);
            }
            //对齐
            posMin = FloorToAlignSize(posMin, citem.combineBlockSize);
            posMax = CeilToAlignSize(posMax, citem.combineBlockSize);
            Debug.Log("CombineGO posMin=" + posMin + " posMax=" + posMax);
            //List<List<MeshRenderer>> blocks = new List<List<MeshRenderer>>();
            for (float x = posMin.x; x < posMax.x; x += citem.combineBlockSize.x)
            {
                for (float y = posMin.y; y < posMax.y; y += citem.combineBlockSize.y)
                {
                    for (float z = posMin.z; z < posMax.z; z += citem.combineBlockSize.z)
                    {
                        Vector3 boundsMin = new Vector3(x, y, z);
                        Bounds b = new Bounds();
                        b.SetMinMax(boundsMin, boundsMin + citem.combineBlockSize);
                        List<MeshRenderer> blockMRs = new List<MeshRenderer>();
                        foreach (var mr in mrs)
                        {
                            if (mr && b.Contains(mr.transform.position))
                            {
                                blockMRs.Add(mr);
                            }
                        }
                        //blocks.Add(blockGOs);
                        if (blockMRs.Count>1)
                            CombineMesh.CombineGO_MRArray(blockMRs.ToArray(), goSel, citem, saveMesh, meshDir);
                    }
                }
            }
        }
        else
        {
            CombineGO_MRArray(mrs, goSel, citem, saveMesh, meshDir);
        }
        //删除没有MR的物体
        for (int i = goSel.transform.childCount-1; i >= 0; i--)
        {
            var t = goSel.transform.GetChild(i);
            if (t.GetComponentsInChildren<MeshRenderer>().Length == 0)
                GameObject.DestroyImmediate(t.gameObject);
        }
    }
    public static void CombineGO_MRArray(MeshRenderer[] mrArray,
        GameObject goParent, CombineItem citem, bool saveMesh,
        string meshDir)
    {
        if (null == goParent)
            return;

        //材质/Lightmap分组//
        List< List< MeshRenderer > > mrMatClassList = new List<List<MeshRenderer>>();
        foreach (MeshRenderer mr in mrArray)
        {
            if (mr.name == "Sce_LV02_jian01")
            {
                int i = 0;
                i++;
            }

            if (CanCombine(mr))
            {
                List<MeshRenderer> mrList = MatchMatLightmap(mr, mrMatClassList);
                if (null == mrList)
                {
                    mrList = new List<MeshRenderer>();
                    mrMatClassList.Add(mrList);
                }
                mrList.Add(mr);
            }
        }

        //各组分别合并//
        int combineCount = 0;
        foreach (List<MeshRenderer> mrList in mrMatClassList)
        {
            if (mrList.Count == 1)//只有一个的不合并
            {
                combineCount++;
                continue;
            }

            List<CombineInstance> ciList = new List<CombineInstance>();
            var uv2List = new List<Vector2>();
            var uv3List = new List<Vector3>();
            int vertices = 0;
            foreach (MeshRenderer mr in mrList)
            {
                //if (mr.name == "Sce_LV02_jian01")
                //{
                //    int i = 0;
                //    i++;
                //}
                if (null == mr)
                {
                    Debug.LogError("null == mr");
                    continue;
                }
                MeshFilter mf = mr.GetComponent<MeshFilter>();
                if (null != mf)
                {
                    if (null == mf.sharedMesh)
                    {
                        Debug.Log(mr.name + " missing sharedMesh");
                        continue;
                    }
                    Mesh srcMesh = mf.sharedMesh;
                    if (0 == srcMesh.vertexCount)
                    {
                        Debug.Log(mr.name + " missing vertices");
                        continue;
                    }

                    if (srcMesh.vertexCount + vertices > 65536)//超过16位上限无法正常显示//
                    {
                        CreateCombineMeshGO(ciList, uv3List, mrList,
                            goParent, saveMesh, meshDir, citem);
                        combineCount++;
                        ciList.Clear();
                        uv2List.Clear();
                        uv3List.Clear();
                        vertices = 0;
                    }
                    else
                    {
                        vertices += srcMesh.vertexCount;
                    }

                    for (int i = 0; i < srcMesh.subMeshCount; ++i)
                    {
                        CombineInstance ci = new CombineInstance();
                        ci.mesh = srcMesh;
                        ci.subMeshIndex = i;
                        ci.transform = goParent.transform.worldToLocalMatrix * mr.transform.localToWorldMatrix;
                        ci.lightmapScaleOffset = mr.lightmapScaleOffset;
                        ciList.Add(ci);
                    }

                    //uv2变换//
                    Vector2[] uv = srcMesh.uv2;
                    Vector4 lightmapScaleOffset = mr.lightmapScaleOffset;
                    for (int uvIdx = 0; uvIdx < uv.Length; ++uvIdx)
                    {
                        Vector2 newuv = new Vector2();
                        //newuv.x = uv[uvIdx].x * lightmapScaleOffset.x + lightmapScaleOffset.z;
                        //newuv.y = uv[uvIdx].y * lightmapScaleOffset.y + lightmapScaleOffset.w;
                        newuv.x = lightmapScaleOffset.z;
                        newuv.y = lightmapScaleOffset.w;
                        uv2List.Add(newuv);
                        uv3List.Add(srcMesh.vertices[uvIdx]);
                    }
                }
            }
            if (vertices > 0)
            {
                CreateCombineMeshGO(ciList, uv3List, mrList,
                    goParent, saveMesh, meshDir, citem);
                combineCount++;
            }
        }
        //在最后删除，在foreach中会导致未combine的mr被删除
        foreach (List<MeshRenderer> mrList in mrMatClassList)
        {
            if (mrList.Count == 1)//只有一个的不合并
            {
                continue;
            }

            //隐藏原始物体。但这样会不好控制，直接删除//
            foreach (MeshRenderer mr in mrList)
            {
                if (mr)
                {
                    //V1 5.6.4 work well.
                    //GameObject.DestroyImmediate(mr.gameObject);
                    //V2 2018.3.13 prefab instance cannot be destroyed.
                    //var t = PrefabUtility.GetPrefabAssetType(mr.gameObject);
                    //Debug.Log(mr.gameObject.name + " : " + t);
                    ////if (!EditorUtility.IsPersistent(mr.gameObject))
                    //if (PrefabAssetType.NotAPrefab == t)
                    //    GameObject.DestroyImmediate(mr.gameObject);
                    //else
                    //    mr.gameObject.SetActive(false);
                    //V3 unpack and destroy
                    var t = PrefabUtility.GetPrefabAssetType(mr.gameObject);
                    if (PrefabAssetType.Regular != t && PrefabAssetType.NotAPrefab != t)
                    {
                        Debug.Log(mr.gameObject.name + " : " + t);
                    }
                    if (PrefabAssetType.NotAPrefab != t)
                    {
                        GameObject mrRoot = PrefabUtility.GetOutermostPrefabInstanceRoot(mr.gameObject);
                        //Debug.Log("preparing unpack prefab root : " + NGUITools.GetHierarchy(mrRoot));
                        PrefabUtility.UnpackPrefabInstance(mrRoot, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);
                    }
                    GameObject.DestroyImmediate(mr.gameObject);
                }
            }
        }

        Debug.Log(goParent.name + " : " + mrArray.Length + " object -> " + combineCount + " object");
    }
    static bool IsChildOf(Transform ta, Transform tb)
    {
        bool b = false;
        while (ta.parent != null)
        {
            if (ta.parent == tb)
                b = true;
            ta = ta.parent;
        }
        return b;
    }

    [MenuItem("PwNgs/Editor/Combine Selected")]
    public static void CombineSelected()
    {
        GameObject goSel = Selection.activeGameObject;
        CombineGO(goSel, null, false, "");
    }

    [MenuItem("PwNgs/Editor/Combine All Combine Items")]
    public static void CombineAllCombineItems()
    {
        CombineItem[] ciArray = GameObject.FindObjectsOfType<CombineItem>();
        CombineCombineItems(ciArray, false, "");
    }
    public static void CombineCombineItems(CombineItem[] ciArray,
        bool saveMesh, string meshDir)
    {
        if (saveMesh)
            Debug.Log("CombineCombineItems meshDir=" + meshDir);

        //检测重复项
        List<CombineItem> noRepeat = new List<CombineItem>();
        foreach(CombineItem citem in ciArray)
        {
            if (!noRepeat.Contains(citem))
            {
                noRepeat.Add(citem);
            }
        }
        //检测父子关系，忽略子级中的CombineItem
        List<CombineItem> noChild = new List<CombineItem>();
        foreach (CombineItem citem in noRepeat)
        {
            bool isChild = false;
            //bool isParent = false;
            foreach (CombineItem gob in noRepeat)
            {
                bool ab = IsChildOf(citem.transform, gob.transform);
                //bool ba = IsChildOf(gob.transform, goa.transform);
                if (ab)
                    isChild = true;
                //if (ba)
                //    isParent = true;
            }
            if (!isChild)
                noChild.Add(citem);
        }
        foreach (CombineItem citem in noChild)
        {
            CombineGO(citem.gameObject, citem, saveMesh, meshDir);
        }
        foreach (CombineItem citem in ciArray)
        {
            GameObject.DestroyImmediate(citem);
        }
    }

    static void CreateCombineMeshGO(List<CombineInstance> ciList,
        /*List<Vector2> uv2List,*/ List<Vector3> uv3List,
        List<MeshRenderer> mrList, GameObject goParent, bool saveMesh,
        string meshDir, CombineItem citem)
    {
        Mesh newMesh = new Mesh();
        newMesh.CombineMeshes(ciList.ToArray(), true, true, true);
        //if (newMesh.vertexCount != uv2List.Count)
        //{
        //    Debug.LogError("newMesh.vertexCount:" + newMesh.vertexCount + " uv2List.Count:" + uv2List.Count);
        //}
        //newMesh.uv2 = uv2List.ToArray();
        newMesh.uv3 = null;
        //newMesh.SetUVs(3, uv3List);
        newMesh.uv4 = null;
        if (null != newMesh.tangents)
            if (null == newMesh.normals || newMesh.normals.Length == 0)
                newMesh.tangents = null;

        if (saveMesh)
        {
            string format = "yy-MM-dd-HH-mm-ss-fffff";
            string meshName = mrList[0].name + System.DateTime.Now.ToString(format);
            string meshPath = meshDir + "\\" + meshName + ".asset";
            Debug.Log("CreateAsset:" + meshPath);
            AssetDatabase.CreateAsset(newMesh, meshPath);
        }

        //创建新物体//
        GameObject newGo = GameObject.Instantiate<GameObject>(mrList[0].gameObject);
        newGo.name = "combine mesh " + mrList[0].name + " " + ciList.Count;
        MeshFilter newMF = newGo.GetComponent<MeshFilter>();
        newMF.sharedMesh = newMesh;
        newGo.transform.SetParent(goParent.transform, false);
        newGo.transform.localPosition = Vector3.zero;
        newGo.transform.localEulerAngles = Vector3.zero;
        newGo.transform.localScale = Vector3.one;
        MeshRenderer mr = newGo.GetComponent<MeshRenderer>();
        mr.lightmapIndex = mrList[0].lightmapIndex;
        CheckLightmapInfo(mr, true);
        if (citem)
        {
            mr.shadowCastingMode = citem.shadowCastingMode;
            mr.receiveShadows = citem.receiveShadows;
        }
        //删除子物体//
        for (int i = newGo.transform.childCount-1; i >=0 ; --i)
        {
            GameObject.DestroyImmediate(newGo.transform.GetChild(i).gameObject);
        }
        CheckLODGroup(newGo, citem ? citem.lodSize : 5);
    }
    public static void CheckLightmapInfo(MeshRenderer mr, bool logErr)
    {
        //有lightmap的保存参数
        if (-1 == mr.lightmapIndex)
        {
            if (logErr)
            {
                Debug.LogWarning("-1 == mr.lightmapIndex:" + mr.name);
            }
        }
        else
        {
            var li = mr.gameObject.GetComponent<LightmapInfo>();
            if (null == li)
                li = mr.gameObject.AddComponent<LightmapInfo>();
            li.Store(mr);
        }
    }
    [MenuItem("PwNgs/Editor/Check Lightmap Info All")]
    public static void CheckLightmapInfo()
    {
        //if (null == Selection.activeGameObject)
        //{
        //    Debug.LogError("nothing selected!");
        //    return;
        //}
        //GameObject goSel = Selection.activeGameObject;
        ClearLightmapInfo_All(null);
        CheckLightmapInfo_All(null);
        if (!EditorApplication.isPlaying)
            EditorSceneManager.MarkAllScenesDirty();
    }
    public static void CheckLightmapInfo_All(GameObject go)
    {
        var mrs = null == go ? Resources.FindObjectsOfTypeAll<MeshRenderer>()
            : go.GetComponentsInChildren<MeshRenderer>(true);
        foreach(var mr in mrs)
        {
            CheckLightmapInfo(mr, true);
        }
    }
    [MenuItem("PwNgs/Editor/Clear Lightmap Info All")]
    public static void ClearLightmapInfo()
    {
        //if (null == Selection.activeGameObject)
        //{
        //    Debug.LogError("nothing selected!");
        //    return;
        //}
        //GameObject goSel = Selection.activeGameObject;
        ClearLightmapInfo_All(null);
        if (!EditorApplication.isPlaying)
            EditorSceneManager.MarkAllScenesDirty();
    }
    public static void ClearLightmapInfo_All(GameObject go)
    {
        var mrs = null == go ? Resources.FindObjectsOfTypeAll<LightmapInfo>()
            : go.GetComponentsInChildren<LightmapInfo>(true);
        foreach (var mr in mrs)
        {
            GameObject.DestroyImmediate(mr, true);
        }
    }
    public static void CheckLODGroup(GameObject go, float size)
    {
        if (null == go)
            return;
        var lods = go.GetComponentsInChildren<LODGroup>(true);
        foreach (var lod in lods)
        {
            lod.RecalculateBounds();
            lod.size = size;
        }
    }


    static int CalcMeshSize(Mesh mesh)
    {
        int stride = 0;
        if (mesh.boneWeights.Length > 0)
            //stride += sizeof(BoneWeight);
            stride += 16+16;
        if (mesh.colors.Length > 0)
            stride += 16;
        if (mesh.colors32.Length > 0)
            stride += 4;
        if (mesh.normals.Length > 0)
            stride += 12;
        if (mesh.tangents.Length > 0)
        {
            stride += 16;
            //Debug.Log(mesh.name + " has tangents");
        }
        if (mesh.uv.Length > 0)
            stride += 8;
        if (mesh.uv2.Length > 0)
            stride += 8;
        if (mesh.uv3.Length > 0)
            stride += 8;
        if (mesh.uv4.Length > 0)
            stride += 8;
        if (mesh.vertices.Length > 0)
            stride += 12;

        int len = stride * mesh.vertexCount;

        if (mesh.triangles.Length > 0)
            len += 4 * mesh.triangles.Length;

        return len;
    }
    [MenuItem("PwNgs/Editor/Tell me Mesh Size")]
    public static void TellmeMeshSize()
    {
        GameObject goSel = Selection.activeGameObject;
        if (null == goSel)
            return;

        int szTotal = 0;
        //取得选中物体下所有MeshRenderer//
        MeshFilter[] mrArray = goSel.GetComponentsInChildren<MeshFilter>();
        foreach (MeshFilter mf in mrArray)
        {
            int sz = CalcMeshSize(mf.sharedMesh);
            szTotal += sz;
            string log = mf.name + " Mesh Size = " + sz;
            if (mf.sharedMesh.tangents.Length > 0)
            {
                log += " with tangents";
            }
            Debug.Log(log);
        }
        Debug.Log("Total Combine Mesh Size = " + szTotal);
    }
    [MenuItem("PwNgs/Editor/Tell me Mesh Size All")]
    public static void TellmeMeshSizeAll()
    {
        int szTotal = 0;
        LightmapInfo[] lis = GameObject.FindObjectsOfType<LightmapInfo>();
        HashSet<MeshFilter> s = new HashSet<MeshFilter>();
        foreach (LightmapInfo li in lis)
        {
            if (li.GetComponent<MeshRenderer>())
            {
                MeshFilter mf = li.GetComponent<MeshFilter>();
                if (mf)
                {
                    if (s.Contains(mf))
                        continue;
                    s.Add(mf);

                    int sz = CalcMeshSize(mf.sharedMesh);
                    szTotal += sz;
                    string log = mf.name + " Mesh Size = " + sz;
                    if (mf.sharedMesh.tangents.Length > 0)
                    {
                        log += " with tangents";
                    }
                    Debug.Log(log);
                }
            }
        }
        Debug.Log("Total Combine Mesh Size = " + szTotal);
    }


    static List<MeshRenderer> MatchMatLightmap(MeshRenderer mr, List<List<MeshRenderer>> mrMatClassList)
    {
        foreach (List<MeshRenderer> mrList in mrMatClassList)
        {
            if (MaterialsEqual(mr.sharedMaterials, mrList[0].sharedMaterials) && mr.lightmapIndex == mrList[0].lightmapIndex)
            {
                return mrList;
            }
        }
        return null;
    }

    static bool MaterialsEqual(Material[] a, Material[] b)
    {
        if (null == a ^ null == b)
            return false;
        if (a.Length != b.Length)
            return false;

        for (int i = 0; i < a.Length & i < b.Length; ++i)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

	//// Use this for initialization
	//void Start () {
	
	//}
	
	//// Update is called once per frame
	//void Update () {
	
	//}
}
