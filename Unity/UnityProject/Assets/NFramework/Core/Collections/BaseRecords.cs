using System.Collections.Generic;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;

namespace NFramework.Core.Collections
{
    public interface IRecordsSet<T>
    {
        public HashSet<T> Records { get; set; }
    }

    public interface IRecordsMap<K, V>
    {
        public Dictionary<K, V> Records { get; set; }
    }


    /// <summary>
    /// 只记录
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public abstract partial class BaseRecordsSet<T> : Entity, IRecordsSet<T>, IAwakeSystem, IDestroySystem
    {
        public HashSet<T> Records { get; set; }

        public void Awake()
        {
            if (this.Records == null)
            {
                this.Records = HashSetPool.Alloc<T>();
            }
            this.OnAwake();
        }

        protected virtual void OnAwake()
        {
        }

        public bool TryAdd(T inT)
        {
            if (this.Records.Contains(inT))
            {
                return false;
            }

            this.Records.Add(inT);
            return true;
        }

        public bool TryRemove(T inT)
        {
            if (this.Records.Contains(inT))
            {
                this.Records.Remove(inT);
                return true;
            }

            return false;
        }

        public void Destroy()
        {
            this.OnDestroy();
            if (this.Records != null)
            {
                this.Records.Clear();
                HashSetPool.Free(this.Records);
                this.Records = null;
            }
        }
        protected virtual void OnDestroy()
        {
        }
    }
}