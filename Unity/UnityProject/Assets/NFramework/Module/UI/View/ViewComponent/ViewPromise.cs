using NFramework.Module.ObjectPoolModule;
using Proto.Promises;

namespace NFramework.Module.UIModule
{
    public class ViewPromiseComponent : ViewComponent
    {
        private PromiseRecords m_promiseRecords;
        public PromiseRecords PromiseRecords
        {
            get
            {
                if (m_promiseRecords == null)
                {
                    m_promiseRecords = GetFM<ObjectPoolM>().Alloc<PromiseRecords>();
                    m_promiseRecords.Awake();
                }
                return m_promiseRecords;
            }
        }
    }

    public static class ViewPromiseComponentExtensions
    {
        public static void AddPromise<T>(this View inView, T inPromise) where T : Proto.Promises.ICancelable
        {
            var component = ViewComponentUtils.CheckAndAdd<ViewPromiseComponent>(inView);
            component.PromiseRecords.TryAdd(inPromise);
        }
    }
}