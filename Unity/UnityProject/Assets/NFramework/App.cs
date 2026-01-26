using NFramework;
using NFramework.Module;
using NFramework.Module.UIModule;
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
        var result = NFROOT.I.GetModule<UIM>().OpenAsync<ExchangeWeekcard>();
        yield return result;
        result.Forget();
    }
}
