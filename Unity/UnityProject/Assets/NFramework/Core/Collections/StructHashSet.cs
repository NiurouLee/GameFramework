using System;
using System.Collections.Generic;

namespace NFramework.Core.Collections
{
    public struct StructHashSet<T> : IDisposable //, ISet<T>
    {
        private HashSet<T> _set;

        public StructHashSet(T item)
        {
            _set = HashSetPool.Alloc<T>();
            _set.Add(item);
        }

        public void Dispose()
        {
            if (_set != null)
            {
                _set.Dispose();
                _set = null;
            }
        }

        public bool Add(T item) => _set.Add(item);
        public void Clear() => _set.Clear();
        public bool Contains(T item) => _set.Contains(item);
        public void CopyTo(T[] array, int arrayIndex) => _set.CopyTo(array, arrayIndex);
        public bool Remove(T item) => _set.Remove(item);
        public int Count => _set.Count;
        public bool IsReadOnly => ((ISet<T>)_set).IsReadOnly;
    }

    public static class HashSetExtensions
    {
        public static void Dispose<T>(this HashSet<T> inSet)
        {
            if (inSet == null)
            {
                return;
            }

            HashSetPool.Free(inSet);
        }
    }
}