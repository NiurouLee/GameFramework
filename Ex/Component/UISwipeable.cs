using System;
using System.Collections;

using UnityEngine;
using UnityEngine.EventSystems;

namespace Game.Logic
{
    public class UISwipeable : MonoBehaviour, IEndDragHandler, IBeginDragHandler, IDragHandler,
        IPointerClickHandler
    {
        [Header("滑动多少距离后触发切换效果")] [SerializeField]
        private float m_SwipeThreshold = 100f;

        //开始拖拽时的位置
        private Vector2 startEventDataPosition;

        //结束拖拽时的回调
        public event Action<bool> OnDragEndAction;

        //点击事件
        public event Action OnClickAction;



        private bool isDragging;



        public void OnBeginDrag(PointerEventData eventData)
        {
            isDragging = true;
            startEventDataPosition = eventData.position;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            StopCoroutine(nameof(WaitForEndDrag));
            StartCoroutine(WaitForEndDrag());
            Vector2 direction = eventData.position - startEventDataPosition;
            if (direction.x > m_SwipeThreshold)
            {
                OnDragEndAction?.Invoke(true);
            }
            else if (direction.x < -m_SwipeThreshold)
            {
                OnDragEndAction?.Invoke(false);
            }
        }

        // 等待一帧，因为OnPointClick会在OnEndDrag之前触发，确保滑动的时候不会触发点击事件
        IEnumerator WaitForEndDrag()
        {
            yield return new WaitForEndOfFrame();
            isDragging = false;
        }

        public void OnDrag(PointerEventData eventData)
        {
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (isDragging)
            {
                return;
            }

            OnClickAction?.Invoke();
        }
    }
}