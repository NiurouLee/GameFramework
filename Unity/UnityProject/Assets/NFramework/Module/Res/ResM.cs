using System;
using System.Collections.Generic;
using Proto.Promises;
using UnityEngine;
using YooAsset;

namespace NFramework.Module.ResModule
{
    public class ResM : FrameworkModule
    {
        private ResourcePackage _package;
        public override void Awake()
        {
            YooAssets.Initialize();
            var package = YooAssets.CreatePackage("Res");
        }

        public Dictionary<string, string> AssetID2PathDic = new Dictionary<string, string>();

        public string Address(string inAssetId)
        {
            return inAssetId;
        }

        public ResHandler Createhandler(string inAssetPath)
        {
            return this.AddChild<ResHandler, string>(inAssetPath);
        }

        public void AwakeAssetID2PathMap(List<Tuple<string, string>> inCfgList)
        {
            this.AssetID2PathDic = new Dictionary<string, string>();
            foreach (var item in inCfgList)
            {
                this.AssetID2PathDic.Add(item.Item1, item.Item2);
            }
        }

        public ResHandler Load<T>(string inAssetID) where T : UnityEngine.Object
        {
            var address = this.Address(inAssetID);
            var handle = this.Createhandler(address);
            var yooAssetHandle = this._package.LoadAssetSync<T>(address);
            //都已经是同步了，这里应该阻塞了吧
            if (yooAssetHandle.IsDone && yooAssetHandle.AssetObject != null)
            {
                this.ResloveHander<T>(handle, yooAssetHandle);
                return handle;
            }
            handle.SetFailed(null);
            return handle;
        }

        public ResHandler LoadAsync<T>(string inAssetID) where T : UnityEngine.Object
        {
            var resPath = this.Address(inAssetID);
            var handler = this.Createhandler(resPath);
            var yooAssetHandle = _package.LoadAssetAsync<T>(resPath);
            handler.YooAssetHandle = yooAssetHandle;
            yooAssetHandle.Completed += (handle) =>
            {
                if (handle.IsDone && handle.AssetObject != null)
                {
                    this.ResloveHander<T>(handler, handle);
                }
                else
                {
                    handler.SetFailed(null);
                }
            };
            return handler;
        }

        private void ResloveHander<T>(ResHandler inHandler, AssetHandle inYooAssetHandle) where T : UnityEngine.Object
        {
            if (inYooAssetHandle.IsDone && inYooAssetHandle.AssetObject != null)
            {
                if (inHandler.state == ResHandlerState.Loading)
                {
                    inHandler.SetResult(inYooAssetHandle.AssetObject);
                }
                else if (inHandler.state == ResHandlerState.Cancel)
                {
                    var obj = new string("load is Canceled");
                    inHandler.SetFailed(obj);
                    inYooAssetHandle.Dispose();
                }
            }
            else
            {
                var obj = new string("load is Failed:" + inYooAssetHandle.LastError);
                inHandler.SetFailed(obj);
            }
        }

        public void Free(ResHandler inHandler)
        {

        }

        internal bool HasResID(string inAssetID)
        {
            return this._package.CheckLocationValid(inAssetID);
        }
    }
}