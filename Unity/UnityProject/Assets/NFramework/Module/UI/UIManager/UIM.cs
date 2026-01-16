using System;
using System.Collections.Generic;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public partial class UIM : IFrameWorkModule
    {
        public ViewConfigServices ConfigServices { get; private set; }

        public void AwakeTypeCfg(List<Tuple<Type, string, ViewConfig>> inCfgList)
        {
            this.ConfigServices = new ViewConfigServices();
            foreach (var item in inCfgList)
            {
                this.ConfigServices.AddViewConfig(item.Item1, item.Item2, item.Item3);
            }
        }

        public Promise<T> Open<T>()
        {
            var result = Promise<T>.NewDeferred();
            return result.Promise;
        }

        public ViewConfig GetViewConfig<T>(T inView) where T : View
        {
            return this.ConfigServices.GetViewConfig(inView);
        }

        public ViewConfig GetViewConfig<T>() where T : View
        {
            return this.ConfigServices.GetViewConfig<T>();
        }

        public ViewConfig GetViewConfig(string inID)
        {
            return this.ConfigServices.GetViewConfig(inID);
        }

        public string GetViewID<T>(T inView) where T : View
        {
            return this.ConfigServices.GetViewConfig(inView).ID;
        }

        public string GetViewID<T>() where T : View
        {
            return this.ConfigServices.GetViewConfig<T>().ID;
        }

        public T CreateView<T>() where T : View, new()
        {
            return new T();
        }

        public View CreateView(ViewConfig inViewConfig)
        {
            var type = this.ConfigServices.GetViewType(inViewConfig.ID);
            if (type == null)
            {
                throw new Exception($"ViewConfig {inViewConfig.ID} not found");
            }
            return Activator.CreateInstance(type) as View;
        }

    }
}