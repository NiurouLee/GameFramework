using System.Collections.Generic;
using UnityEngine;


namespace NFramework.Module.UIModule
{
    [System.Serializable]
    public class LoopScrollPrefabSource
    {
        //public string prefabName;
        public GameObject prefabGameObject;
        public List<GameObject> prefabGameObjectList;

        [HideInInspector] public Transform cacheRootTrans;

        //public int poolSize = 5;
        // Implement your own Cache Pool here. The following is just for example.
        Stack<Transform> pool = new Stack<Transform>();
        Dictionary<string, Stack<Transform>> listPool = new Dictionary<string, Stack<Transform>>();

        public virtual GameObject GetObject(int listIndex)
        {
            if (listIndex >= 0 && prefabGameObjectList != null && prefabGameObjectList.Count > 0)
            {
                var go = prefabGameObjectList[0];

                if (listIndex < prefabGameObjectList.Count)
                {
                    go = prefabGameObjectList[listIndex];
                }

                if (!listPool.ContainsKey(go.name))
                {
                    listPool.Add(go.name, new Stack<Transform>());
                }

                if (listPool[go.name].Count == 0)
                {
                    var ret = Object.Instantiate(go);
                    ret.name = go.name;
                    return ret;
                }

                var transform = listPool[go.name].Pop();
                transform.gameObject.SetActive(true);
                return transform.gameObject;
            }

            if (pool.Count == 0)
            {
                return Object.Instantiate(prefabGameObject);
            }

            Transform candidate = pool.Pop();
            candidate.gameObject.SetActive(true);
            return candidate.gameObject;
        }

        public virtual void ReturnObject(Transform trans, Transform cacheRootTrans)
        {
            // Use `DestroyImmediate` here if you don't need Pool
            trans.SendMessage("ScrollCellReturn", SendMessageOptions.DontRequireReceiver);
            trans.gameObject.SetActive(false);
            trans.SetParent(cacheRootTrans, false);

            if (prefabGameObjectList != null && prefabGameObjectList.Count > 0)
            {
                if (listPool.TryGetValue(trans.name, out var stack))
                {
                    stack.Push(trans);
                    return;
                }
            }

            pool.Push(trans);
        }
    }
}