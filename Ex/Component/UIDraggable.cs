using UnityEngine;
using UnityEngine.EventSystems;
namespace Ez.UI
{
    // 确保你的类继承自MonoBehaviour并实现IDragHandler和IBeginDragHandler接口。
    /// <summary>
    /// 跟随点击对象拖动
    /// </summary>
    public class UIDraggable : MonoBehaviour, IDragHandler, IBeginDragHandler
    {
        private Vector2 originalLocalPointerPosition;
        private Vector3 originalPanelLocalPosition;
        private RectTransform panelRectTransform;
        private RectTransform parentRectTransform;

        void Awake()
        {
            // 初始化RectTransform组件。
            panelRectTransform = transform as RectTransform;
            parentRectTransform = panelRectTransform.parent as RectTransform;
        }

        public void OnBeginDrag(PointerEventData data)
        {
            // 当拖动开始时，保存原始的位置信息。
            originalPanelLocalPosition = panelRectTransform.localPosition;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(parentRectTransform, data.position, data.pressEventCamera, out originalLocalPointerPosition);
        }

        public void OnDrag(PointerEventData data)
        {
            if (panelRectTransform == null || parentRectTransform == null)
                return;

            Vector2 localPointerPosition;
            // 获取当前指针位置相对于父级RectTransform的本地坐标。
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(parentRectTransform, data.position, data.pressEventCamera, out localPointerPosition))
            {
                // 计算拖动偏移并更新UI元素位置。
                Vector3 offsetToOriginal = localPointerPosition - originalLocalPointerPosition;
                panelRectTransform.localPosition = originalPanelLocalPosition + offsetToOriginal;
            }

            // 保证拖动的UI元素保持在屏幕内。
            ClampToWindow();
        }

        // 限制拖动范围，防止UI元素被拖出屏幕。
        void ClampToWindow()
        {
            Vector3 pos = panelRectTransform.localPosition;

            Vector3 minPosition = parentRectTransform.rect.min - panelRectTransform.rect.min;
            Vector3 maxPosition = parentRectTransform.rect.max - panelRectTransform.rect.max;

            pos.x = Mathf.Clamp(panelRectTransform.localPosition.x, minPosition.x, maxPosition.x);
            pos.y = Mathf.Clamp(panelRectTransform.localPosition.y, minPosition.y, maxPosition.y);

            panelRectTransform.localPosition = pos;
        }
    }
}
