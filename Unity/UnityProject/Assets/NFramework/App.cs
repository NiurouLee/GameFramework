using System;
using NFramework;
using NFramework.Module;
using NFramework.Module.UIModule;
using NFramework.Test;
using UnityEngine;
using System.Collections;

public class APP : MonoBehaviour
{
    private void Awake()
    {
        this.gameObject.AddComponent<EngineLoop>();
        NFROOT.AwakeRoot();

        this.StartCoroutine(this.Test());
    }
    private IEnumerator Test()
    {
        yield return new WaitForSeconds(1);
        NFROOT.I.GetModule<UIM>().OpenAsync<ExWindow>();
    }
}
