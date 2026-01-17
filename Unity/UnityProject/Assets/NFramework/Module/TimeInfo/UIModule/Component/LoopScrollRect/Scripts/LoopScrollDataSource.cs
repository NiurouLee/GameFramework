using System;
using UnityEngine;

namespace NFramework.Module.UIModule
{
    public abstract class LoopScrollDataSource
    {
        public abstract void ProvideData(Transform transform, int idx);
        public abstract int GetGameObjectIndex(int idx);

        public abstract void OnEndTopDrag();
    }

    public class LoopScrollCallbackSource : LoopScrollDataSource
    {
        public delegate void Callback(Transform transform, int idx);

        public delegate int OnGetGameObjectIndex(int idx);

        private Callback m_callback;
        private OnGetGameObjectIndex _mGetGameObjectIndex;
        private Action m_onEndTopDrag;

        public LoopScrollCallbackSource(Callback callback, OnGetGameObjectIndex getGameObjectIndex = null,
            Action onEndTopDrag = null)
        {
            m_callback = callback;
            _mGetGameObjectIndex = getGameObjectIndex;
            m_onEndTopDrag = onEndTopDrag;
        }


        public override void ProvideData(Transform transform, int idx)
        {
            m_callback?.Invoke(transform, idx);
        }

        public override int GetGameObjectIndex(int idx)
        {
            if (_mGetGameObjectIndex != null)
            {
                return _mGetGameObjectIndex.Invoke(idx);
            }

            return -1;
        }

        public override void OnEndTopDrag()
        {
            m_onEndTopDrag?.Invoke();
        }
    }


    public class LoopScrollSendIndexSource : LoopScrollDataSource
    {
        public static readonly LoopScrollSendIndexSource Instance = new LoopScrollSendIndexSource();

        LoopScrollSendIndexSource()
        {
        }

        public override void ProvideData(Transform transform, int idx)
        {
            transform.SendMessage("ScrollCellIndex", idx, SendMessageOptions.DontRequireReceiver);
        }

        public override int GetGameObjectIndex(int idx)
        {
            return -1;
        }

        public override void OnEndTopDrag()
        {
        }
    }


    public class LoopScrollArraySource<T> : LoopScrollDataSource
    {
        T[] objectsToFill;

        public LoopScrollArraySource(T[] objectsToFill)
        {
            this.objectsToFill = objectsToFill;
        }

        public override void ProvideData(Transform transform, int idx)
        {
            transform.SendMessage("ScrollCellContent", objectsToFill[idx]);
        }

        public override int GetGameObjectIndex(int idx)
        {
            return -1;
        }

        public override void OnEndTopDrag()
        {
        }
    }
}