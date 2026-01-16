using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[RequireComponent(typeof(MeshRenderer))]
public class LightmapInfo : MonoBehaviour {
    public int lightmapIndex = -1;
    public Vector4 lightmapScaleOffset;
    //MeshRenderer render = null;

    // Use this for initialization
    void Start () {
        if (Application.IsPlaying(this))
        {
            MeshRenderer r = GetComponent<MeshRenderer>();
            if (r)
            {
                Apply(r);
            }
        }
    }
    public void Store(MeshRenderer r)
    {
        if (r)
        {
            lightmapIndex = r.lightmapIndex;
            lightmapScaleOffset = r.lightmapScaleOffset;
        }
    }

    public void Apply(MeshRenderer r)
    {
        if (r)
        {
            r.lightmapIndex = lightmapIndex;
            r.lightmapScaleOffset = lightmapScaleOffset;
        }
    }

    public static bool HasLightmap(MeshRenderer mr)
    {
        return mr.lightmapIndex != -1;
    }
}
