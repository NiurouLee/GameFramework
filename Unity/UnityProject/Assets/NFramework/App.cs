using System;
using NFramework.Module;
using NFramework.Module.UIModule;
using NFramework.Test;
using UnityEngine;

public class APP : MonoBehaviour
{
    private void Awake()
    {
        NFROOT.Instance.GetModule<UIM>().Open<ExWindow>();
    }
}