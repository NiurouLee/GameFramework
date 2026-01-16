
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using Palmmedia.ReportGenerator.Core.Parser.Filtering;
using Palmmedia.ReportGenerator.Core.Reporting.Builders;
using Proto.Promises;
using Proto.Promises.Threading;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Networking;
using UnityEngine.Rendering;
using UnityEngine.UIElements;
public static class ProtoPromiseEx
{

    private static MonoBehaviour _monoBehaviour;

    /// <summary>
    /// unity webRequest 转ProtoPromise
    /// </summary>
    /// <param name="inUrl"></param>
    /// <returns></returns>
    public static async Promise<Texture2D> DownLoadTexture(string inUrl)
    {
        using (var www = UnityWebRequestTexture.GetTexture(inUrl))
        {
            await PromiseYielder.WaitFor(www.SendWebRequest());
            if (www.result != UnityWebRequest.Result.Success)
            {
                throw Promise.RejectException(www.error);
            }
            return ((DownloadHandlerTexture)www.downloadHandler).texture;
        }
    }

    public static void MyPromiseStudy()
    {
        var p= DownLoadTexture("https://www.google.com");

    }


    /// <summary>
    /// 使用 协程加载texture 并制作成Sprite
    /// </summary>
    /// <param name="inUrl"></param>
    /// <returns></returns>
    public static IEnumerator GetAndAssignTexture(string inUrl)
    {
        using (var textureYieldInstruction = DownLoadTexture(inUrl).ToYieldInstruction())
        {
            yield return textureYieldInstruction;
            var texture = textureYieldInstruction.GetResult();
            var sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
            //doing something
        }
    }

    #region  异步锁
    public static readonly AsyncLock _mutex = new AsyncLock();
    public static async Promise DoStuffAsync()
    {
        using (await _mutex.LockAsync())
        {
            //Do mutually exclusive async work here
            await Task.Delay(TimeSpan.FromSeconds(1));
        }
    }
    public static async Promise DoStuffAsync1()
    {
        using (var key = await _mutex.LockAsync())
        {
            //wait for a pulse
            await AsyncMonitor.WaitAsync(key);
            //continue after another context has pulsed the lock
        }
    }

    public static readonly AsyncReaderWriterLock _rwl = new AsyncReaderWriterLock();
    public static async Promise DoStuffAsync2()
    {
        using (await _rwl.ReaderLockAsync())
        {
            // Reader lock is shared,Multiple readers can enter at the same time.
        }

        using (await _rwl.WriterLockAsync())
        {
            // Writer lock is mutually exclusive ,only one writer can enter at a time ,and not readers can enter while a writer is entered.

        }

        using (var upgradeableReaderKey = await _rwl.UpgradeableReaderLockAsync())
        {
            //Upgradeable lock is shared with regular reader locks ,but is mutually exclusive with respect ot regular writer locks and Other upgradeable reader locks.
            //Only one upgradeable reader can enter at a time ,and no regular writers can enter while an upgradeable reader is entered.
            //Regular readers can enter while an upgradeable reader is entered.
            using (await _rwl.UpgradeToWriterLockAsync(upgradeableReaderKey))
            {
                //Upgraded writer lock is mutually Exclusive ,only one writer can enter at a time ,and no  readers cna enter while a writer is entered.
            }
        }
    }

    public static readonly AsyncSemaphore _sem = new AsyncSemaphore(4);

    public static async Promise<string> DownLoadConstrained(string url)
    {
        using (await _sem.EnterScopeAsync())
        {
            //Up to 4 consumers can enter this protected region at a time;
            // return await DownLoad(url);
            return string.Empty;
        }
    }


    #endregion

    #region AsyncLazy

    public static readonly AsyncLazy<int> lazy = new AsyncLazy<int>(async () =>
    {
        await Task.Delay(1000);
        return 1;
    });

    #endregion

    #region  AsyncLocal Support
    public static readonly AsyncLocal<int> _asyncLocal = new AsyncLocal<int>();
    public static async Promise Func()
    {
        _asyncLocal.Value = 1;
        await FuncNested();
        Assert.AreEqual(1, _asyncLocal.Value);
    }

    public static async Promise FuncNested()
    {
        Assert.AreEqual(1, _asyncLocal.Value);
        _asyncLocal.Value = 2;
        // await _promise;
        Assert.AreEqual(2, _asyncLocal.Value);
    }

    #endregion

    #region  Cancelations

    //you can register a callback to the token  that will be invoked  when the source is canceled:
    public static void Func(CancelationToken token)
    {
        token.Register(() => { Debug.Log("token was canceled"); });
    }

    //if the source is disposed without being canceled,the callback will not be invoked.
    //you can check whether the token is already canceled:

    public static IEnumerable FuncEnumerator(CancelationToken token)
    {
        using (token.GetRetainer())
        {
            while (!token.IsCancelationRequested)
            {
                Debug.Log("doing something");
                // if (DoSomething())
                {
                    yield break;
                }
                yield return null;
            }
            Debug.Log("token was canceled");
        }
    }


    //Cancelation Registration
    //when you register a callback to token,it returns a  CancelationRegistration which can be used to unregister the callback.

    //Canceling Promise
    //Promise implementations usually do not allow cancelations, but it has proven to bo invaluable to  asynchronous libraries ,and ProtoPromise is 
    //no exception.

    //Promises can be canceled 3 ways : passing a CancelationToken into Paomise.{then,catch,continueWith},calling Promise.Deferred.Cancel(),
    //or by throwing a Cancelation Exception. When a promise is canceled ,all  Promise  that have been  chained form it will be canceled ,until a CatchCancelation.

    public static void CancelationEx1()
    {
        CancelationSource cancelationSource = CancelationSource.New();
        // DownLoad("https://www.google.com")
        // .CatchCancelation(() => { Debug.Log("google download canceled"); })
        // .then(html => Debug.Log(html), cancelationSource.Token)
        // .then(() => DownLoad("https://www.bing.com"))
        // .then(html => Debug.Log(html))
        // .Finally(cancelationSource.Dispose)
        // .Forget();

        //later before the first  download is completed 
        cancelationSource.Cancel();
        //this will stop the callbacks  from beng ran ,but will not stop the googleDownload
    }

    public static Promise<string> DownLoad(string v)
    {
        var deferred = Promise.NewDeferred<string>();
        using (var client = UnityWebRequest.Get(v))
        {
            var request = client.SendWebRequest();
            request.completed += (s) =>
            {
                if (client.result != UnityWebRequest.Result.Success)
                {
                    deferred.Reject(client.error);
                }
                else
                {
                    deferred.Resolve(client.downloadedBytes.ToString());
                }
            };
        }
        return deferred.Promise;
    }

    //Cancelations always propagate downwards and never upwards:
    public static void CancelationEx2()
    {
        // CancelationSource cancelationSource = CancelationSource.New();
        // DownLoad("https://www.google.com")
        // .CatchCancelation(() => { Debug.Log("google download canceled"); })
        // .then(html => Debug.Log(html), cancelationSource.Token)
        // .then(() => DownLoad("https://www.bing.com"))
        // .CatchCancelation(() => { Debug.Log("bing download canceled"); })
        // .then(html => Debug.Log(html))
        // .Finally(cancelationSource.Dispose)
        // .Forget();

    }

    #endregion


    #region  Combining multiple async Operations
    public static void CombineAsyncOperation()
    {
        // Promise.All(DownLoadTexture("https://www.google.com"), DownLoadTexture("https://www.bing.com")).Then(pages =>
        // {
        //     var links = pages.SelectMany(page =>
        //     {
        //     });
        // }).Then(links =>
        // {
        //     foreach (var link in links)
        //     {
        //         Debug.Log(link);
        //     }
        // });
    }

    #endregion

    #region  Parallel Executions
    public static Promise IterateAsync<T>(this IEnumerable<T> enumerable, Action<T> action)
    {
        return Promise.ParallelForEach(enumerable, (item, CancelationToken) =>
        {
            action(item);
            return Promise.Resolved();
        });
    }



    #endregion

    #region  progress

    public static Promise WaitForSeconds(double seconds, ProgressToken progressToken = default)
    {
        var deferred = Promise.NewDeferred();
        _monoBehaviour.StartCoroutine(_Countup());
        return deferred.Promise;

        IEnumerator _Countup()
        {
            for (double current = 0; current < seconds; current += Time.deltaTime)
            {
                progressToken.Report(current / seconds);
                yield return null;
            }
            progressToken.Report(1);
            deferred.Resolve();
        }

    }
    #endregion


    #region  Err Retries and Async Recursion


    #endregion


    #region  Basic
    public static Promise<string> BasicEx()
    {
        //Crate a deferred before you start the async operation:
        var deferred = Promise.NewDeferred<string>();
        //the type of the deferred should reflect the result of the asynchronous operation.
        //the initiate your async operation and return the promise to the caller.
        return deferred.Promise;

        //Upon completion of the  async op the  promise id resolved via the deferred:
        deferred.Resolve("1");
        //the promise re rejected on error/exception:
        deferred.Reject("err");
    }

    public static Promise<string> Download(string url)
    {
        var deferred = Promise.NewDeferred<string>();
        using (var client = UnityWebRequest.Get(url))
        {
            var request = client.SendWebRequest();
            request.completed += (s) =>
            {
                if (client.result != UnityWebRequest.Result.Success)
                {
                    deferred.Reject(client.error);
                }
                else
                {
                    deferred.Resolve(client.downloadedBytes.ToString());
                }
            };
        }
        return deferred.Promise;
    }


    //wait for an Async operation to complete
    static async void func3()
    {
        string html = await Download("https://www.google.com");
        Debug.Log(html);
    }

    static async void func4()
    {
        Download("https://www.google.com").
        Then(html =>
        {
            Debug.Log(html);
        }).Forget();
    }
    static async void func5()
    {
        try
        {
            string html = await Download("https://www.google.com");
            Debug.Log(html);
        }
        catch (Exception e)
        {
            Debug.LogError(e);
        }
    }

    static void func6()
    {
        Download("https://www.google.com")
        .Then(html =>
        {
            Debug.Log(html);
        })
        .Catch((Exception e) =>
        {
            Debug.LogError(e);
        })
        .Forget();
    }


    //chaining  async operations can be  chained one  after the using await or .Then
    static async void func7()
    {
        Download("https://www.google.com")
        .Then(html =>
        {
            return Download("https://www.bing.com");
        })
        .Then(html =>
        {
            Debug.Log(html);
        })
        .Catch((Exception e) =>
        {
            Debug.LogError(e);
        })
        .Forget();
    }

    //transform the result
    //someTimes you will want to simply transform or modify the resulting value without chaining 
    //another async operation.
    static async Promise<string[]> GetAllLinks(string url)
    {
        string html = await Download(url);
        return html.Split(".");
    }

    static async Promise<string[]> GetAllLinks2(string url)
    {
        return await Download(url).Then(a =>
        {
            return a.Split(".");
        });
    }


    //Finally
    //Finally adds an onFinally delegate that will be invoked when the promise
    //is resolved ,rejected,or canceled. if the promise is rejected,that rejection will
    //not be handled by finally callback .that way it works just like finally clauses in 
    //normal synchronous code .Finally therefore,should be used to clean up resources like IDisposeable

    //ContinueWith 
    //continueWith adds an  onContinue delegate  that will be invoked when the promise is resolved,
    //rejected,or canceled..
    //A Promise.ResultContainer or Promise<T>.ResultContainer  will be passed into the delegate that can
    //be used to check the promise's state and result or reject reason .the  promise returned form continue with
    //will be resolved /Rejected/Canceled with the same rules as the in Understanding then.
    //promise.Rethrow is an invalid operation  during an onContinue invocation ,instead you can use 
    //resultConation.RethrowIfRejected() and  resultContainer.RethrowIfCanceled().

    //Forget 
    //All  promise and Promise<T> object must either be awaited (using the await keyword or .then or .Cache
    // etc or passing into promise.All,Race , etc). returned. or forgotten. promise.Forget() means you are done 
    //with the promise and no more operations will be performed on it . it is the call that allow the backing object
    //to be repooled and uncaugth rejections to reported.The c# compiler will warn wen you do not await or use and awaitbale
    // object and calling forect() si the proper way to fix the waring.

    //promise that are already settled

    public static void SettledEx()
    {
        var promise = Promise.NewDeferred().Promise;

        var resolved = Promise.Resolved("that was fast");

        var rejected = Promise.Rejected("something went wrong");

        var rejectedNoneValuePromise = Promise.Rejected("Something went wrong");

        var canceledNonValuePromise = Promise.Canceled();
        var canceledIntPromise = Promise<int>.Canceled();

    }

    #endregion

    #region  Additional  Information
    //then must  always be give at  least 1 delegate
    //then 必须至少有一个委托

    //the first delegate is onResolved
    //第一个委托是onResolved

    //onResolved will be invoked if the promise is resolved
    //onResolved 如果promise被resolved，则会被调用

    //if the promise provides a value(promise<T>), onResolved may take that value as an argument
    //如果promise是有参数的，那么OnResolved 有参数

    //if a capture value is  provided to onResolved  the capture value must be  the first argument to then and the first argument to OnResolved.
    //如果promise 是有参数的，那么Then 的第一个参数就是 结果值.

    //A Second delegate is optional .If it  is Provided, it is Onrejected
    //第二个委托是可选的 ，如果提供，则是OnRejected.

    //If onRejected accepts an arguments,it will  be invoked if the promise is rejected for ane reason.
    // 如果不接受让任何参数，则如果promise 因任何原因被拒绝，则将调用 OnRejected

    //if onRejected accept an argument without a  capture value , it will be invoked if the promise is rejected 
    //with a reason that is convertible to  that argument's type.
    //如果 onRejected 有参数 并且拒绝参数与参数类型一致，则将调用OnRejected.

    //if a capture value is provided to onRejected it must come after onRejected in the then arguments and it must
    //be the first argument to OnRejected.
    //如果为 onRejected 提供了捕获值，它必须位于 Then 参数中 onResolved 之后、onRejected 之前，并且必须是 onRejected 的第一个参数。s


    #endregion

}
