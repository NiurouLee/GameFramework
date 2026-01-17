using System;
using System.Collections;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityEngine;


namespace NFramework.Module.UIModule
{
    public enum Direction
    {
        Horizontal,
        Vertical
    }

    [AddComponentMenu("")]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform))]
    public abstract class LoopScrollRect : UIBehaviour, IInitializePotentialDragHandler, IBeginDragHandler,
        IEndDragHandler, IDragHandler, IScrollHandler, ICanvasElement, ILayoutElement, ILayoutGroup
    {
        public LoopScrollRect parentScorll;

        public float triggerParentValue = 5;

        //[Header("Vector计算时保留的数度")]
        //[Range(-1,4)]
        //public int vectorRoundDigits = -1;
        //==========LoopScrollRect==========
        [Tooltip("Prefab Source")] public LoopScrollPrefabSource prefabSource;

        [Tooltip("Total count, negative means INFINITE mode")]
        public int totalCount;

        //已经被创建完成,防止在没有创建的时候 被触发了一些逻辑
        private bool m_InitFinished = false;


        [Tooltip("IgnoreActiveState,  Ignore Active State to RefreshCells")]
        public bool IgnoreActiveState = false;

        [Header("屏蔽拖拽")]
        //屏蔽拖拽
        public bool IgnoreDragEvent = false;

        //禁止滑动
        public bool IgnoreMove = false;

        [HideInInspector] [NonSerialized] public LoopScrollDataSource dataSource = LoopScrollSendIndexSource.Instance;

        public object[] objectsToFill
        {
            // wrapper for forward compatbility
            set
            {
                if (value != null)
                    dataSource = new LoopScrollArraySource<object>(value);
                else
                    dataSource = LoopScrollSendIndexSource.Instance;
            }
        }

        protected float threshold = 0;

        [Tooltip("Reverse direction for dragging")]
        public bool reverseDirection = false;

        [Tooltip("Rubber scale for outside")] public float rubberScale = 1;

        public int startIndex
        {
            get { return itemTypeStart; }
        }

        public int lastIndex
        {
            get { return itemTypeEnd - 1; }
        }

        protected int itemTypeStart = 0; //开始是totalCount
        protected int itemTypeEnd = 0; //结束的index,不包含

        protected abstract float GetSize(RectTransform item);
        protected abstract float GetDimension(Vector2 vector);
        protected abstract Vector2 GetVector(float value);
        protected int directionSign = 0;

        private float m_ContentSpacing = -1;
        protected GridLayoutGroup m_GridLayout = null;

        protected float contentSpacing
        {
            get
            {
                if (m_ContentSpacing >= 0)
                {
                    return m_ContentSpacing;
                }

                m_ContentSpacing = 0;
                if (content != null)
                {
                    HorizontalOrVerticalLayoutGroup layout1 = content.GetComponent<HorizontalOrVerticalLayoutGroup>();
                    if (layout1 != null)
                    {
                        m_ContentSpacing = layout1.spacing;
                    }

                    m_GridLayout = content.GetComponent<GridLayoutGroup>();
                    if (m_GridLayout != null)
                    {
                        m_ContentSpacing = Mathf.Abs(GetDimension(m_GridLayout.spacing));
                    }
                    // EasyLayout m_EGridLayout = content.GetComponent<EasyLayout>();
                    // if (m_EGridLayout!=null)
                    // {
                    //     m_ContentSpacing = Mathf.Abs(GetDimension(m_EGridLayout.Spacing));
                    //
                    // }
                }

                return m_ContentSpacing;
            }
        }

        private int m_ContentConstraintCount = 0;

        protected int contentConstraintCount //就是GridLayoutGroup的Constratint Count
        {
            get
            {
                if (m_ContentConstraintCount > 0)
                {
                    return m_ContentConstraintCount;
                }

                m_ContentConstraintCount = 1;
                if (content != null)
                {
                    GridLayoutGroup layout2 = content.GetComponent<GridLayoutGroup>();
                    if (layout2 != null)
                    {
                        if (layout2.constraint == GridLayoutGroup.Constraint.Flexible)
                        {
                            LogWarning("[LoopScrollRect] Flexible not supported yet");
                        }

                        m_ContentConstraintCount = layout2.constraintCount;
                    }
                    // EasyLayout layout3 = content.GetComponent<EasyLayout>();
                    // if (layout3 != null)
                    // {
                    //     m_ContentConstraintCount = layout3.ConstraintCount;
                    // }
                }

                return m_ContentConstraintCount;
            }
        }

        // the first line
        int StartLine
        {
            get { return Mathf.CeilToInt((float)(itemTypeStart) / contentConstraintCount); }
        }

        // how many lines we have for now
        int CurrentLines
        {
            get { return Mathf.CeilToInt((float)(itemTypeEnd - itemTypeStart) / contentConstraintCount); }
        }

        // how many lines we have in total
        int TotalLines
        {
            get { return Mathf.CeilToInt((float)(totalCount) / contentConstraintCount); }
        }

        protected virtual bool UpdateItems(Bounds viewBounds, Bounds contentBounds)
        {
            return false;
        }
        //==========LoopScrollRect==========

        public enum MovementType
        {
            Unrestricted, // Unrestricted movement -- can scroll forever
            Elastic, // Restricted but flexible -- can go past the edges, but springs back in place
            Clamped, // Restricted movement where it's not possible to go past the edges
        }

        public enum ScrollbarVisibility
        {
            Permanent,
            AutoHide,
            AutoHideAndExpandViewport,
        }

        [Serializable]
        public class ScrollRectEvent : UnityEvent<Vector2>
        {
        }

        [SerializeField] private RectTransform m_Content;

        public RectTransform content
        {
            get { return m_Content; }
            set { m_Content = value; }
        }

        [SerializeField] private bool m_Horizontal = true;

        public bool horizontal
        {
            get { return m_Horizontal; }
            set { m_Horizontal = value; }
        }

        [SerializeField] private bool m_Vertical = true;

        public bool vertical
        {
            get { return m_Vertical; }
            set { m_Vertical = value; }
        }

        [SerializeField] private MovementType m_MovementType = MovementType.Elastic;

        public MovementType movementType
        {
            get { return m_MovementType; }
            set { m_MovementType = value; }
        }

        [SerializeField] private float m_Elasticity = 0.1f; // Only used for MovementType.Elastic

        public float elasticity
        {
            get { return m_Elasticity; }
            set { m_Elasticity = value; }
        }

        [SerializeField] private bool m_Inertia = true;

        public bool inertia
        {
            get { return m_Inertia; }
            set { m_Inertia = value; }
        }

        [SerializeField] private float m_DecelerationRate = 0.135f; // Only used when inertia is enabled

        public float decelerationRate
        {
            get { return m_DecelerationRate; }
            set { m_DecelerationRate = value; }
        }

        [SerializeField] private float m_ScrollSensitivity = 1.0f;

        public float scrollSensitivity
        {
            get { return m_ScrollSensitivity; }
            set { m_ScrollSensitivity = value; }
        }

        [SerializeField] private RectTransform m_Viewport;

        public RectTransform viewport
        {
            get { return m_Viewport; }
            set
            {
                m_Viewport = value;
                SetDirtyCaching();
            }
        }

        [SerializeField] private Scrollbar m_HorizontalScrollbar;

        public Scrollbar horizontalScrollbar
        {
            get { return m_HorizontalScrollbar; }
            set
            {
                if (m_HorizontalScrollbar)
                    m_HorizontalScrollbar.onValueChanged.RemoveListener(SetHorizontalNormalizedPosition);
                m_HorizontalScrollbar = value;
                if (m_HorizontalScrollbar)
                    m_HorizontalScrollbar.onValueChanged.AddListener(SetHorizontalNormalizedPosition);
                SetDirtyCaching();
            }
        }

        [SerializeField] private Scrollbar m_VerticalScrollbar;

        public Scrollbar verticalScrollbar
        {
            get { return m_VerticalScrollbar; }
            set
            {
                if (m_VerticalScrollbar)
                    m_VerticalScrollbar.onValueChanged.RemoveListener(SetVerticalNormalizedPosition);
                m_VerticalScrollbar = value;
                if (m_VerticalScrollbar)
                    m_VerticalScrollbar.onValueChanged.AddListener(SetVerticalNormalizedPosition);
                SetDirtyCaching();
            }
        }

        [SerializeField] private ScrollbarVisibility m_HorizontalScrollbarVisibility;

        public ScrollbarVisibility horizontalScrollbarVisibility
        {
            get { return m_HorizontalScrollbarVisibility; }
            set
            {
                m_HorizontalScrollbarVisibility = value;
                SetDirtyCaching();
            }
        }

        [SerializeField] private ScrollbarVisibility m_VerticalScrollbarVisibility;

        public ScrollbarVisibility verticalScrollbarVisibility
        {
            get { return m_VerticalScrollbarVisibility; }
            set
            {
                m_VerticalScrollbarVisibility = value;
                SetDirtyCaching();
            }
        }

        [SerializeField] private float m_HorizontalScrollbarSpacing;

        public float horizontalScrollbarSpacing
        {
            get { return m_HorizontalScrollbarSpacing; }
            set
            {
                m_HorizontalScrollbarSpacing = value;
                SetDirty();
            }
        }

        [SerializeField] private float m_VerticalScrollbarSpacing;

        public float verticalScrollbarSpacing
        {
            get { return m_VerticalScrollbarSpacing; }
            set
            {
                m_VerticalScrollbarSpacing = value;
                SetDirty();
            }
        }

        [SerializeField] private ScrollRectEvent m_OnValueChanged = new ScrollRectEvent();

        public ScrollRectEvent onValueChanged
        {
            get { return m_OnValueChanged; }
            set { m_OnValueChanged = value; }
        }

        public Action OnStopMoveEvent;
        public Action OnEndDragEvent;

        // The offset from handle position to mouse down position
        private Vector2 m_PointerStartLocalCursor = Vector2.zero;
        private Vector2 m_ContentStartPosition = Vector2.zero;

        private RectTransform m_ViewRect;

        protected RectTransform viewRect
        {
            get
            {
                if (m_ViewRect == null)
                    m_ViewRect = m_Viewport;
                if (m_ViewRect == null)
                    m_ViewRect = (RectTransform)transform;
                return m_ViewRect;
            }
        }

        private Bounds m_ContentBounds;
        private Bounds m_ViewBounds;

        private Vector2 m_Velocity;

        public Vector2 velocity
        {
            get { return m_Velocity; }
            set { m_Velocity = value; }
        }

        private bool m_Dragging;

        private Vector2 m_PrevPosition = Vector2.zero;
        private Bounds m_PrevContentBounds;
        private Bounds m_PrevViewBounds;
        [NonSerialized] private bool m_HasRebuiltLayout = false;

        private bool m_HSliderExpand;
        private bool m_VSliderExpand;
        private float m_HSliderHeight;
        private float m_VSliderWidth;
        private UnityEngine.Coroutine m_Coroutine;

        [System.NonSerialized] private RectTransform m_Rect;

        private RectTransform rectTransform
        {
            get
            {
                if (m_Rect == null)
                    m_Rect = GetComponent<RectTransform>();
                return m_Rect;
            }
        }

        private RectTransform m_HorizontalScrollbarRect;
        private RectTransform m_VerticalScrollbarRect;

        private DrivenRectTransformTracker m_Tracker;

        protected LoopScrollRect()
        {
            flexibleWidth = -1;
        }

        protected override void Start()
        {
            m_InitFinished = true;
        }

        //==========LoopScrollRect==========


        public void ClearCells()
        {
            if (Application.isPlaying)
            {
                itemTypeStart = 0;
                itemTypeEnd = 0;
                totalCount = 0;
                objectsToFill = null;
                for (int i = content.childCount - 1; i >= 0; i--)
                {
                    prefabSource.ReturnObject(content.GetChild(i), transform);
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="index"></param>
        /// <param name="speed"></param>
        /// <param name="pos">移动的位置 -1为左(上) 0为居中 1 为右(下) </param>
        public void SrollToCell(int index, float speed, int pos = -1)
        {
            if (totalCount >= 0 && (index < 0 || index >= totalCount))
            {
                LogWarning(string.Format("invalid index {0}", index));
                return;
            }

            if (speed <= 0)
            {
                LogWarning(string.Format("invalid speed {0}", index));
                return;
            }

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefreshCells: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            if (m_Coroutine != null)
            {
                NFROOT.Instance.GetModule<NFramework.Module.Coroutine.co>().StopCoroutine(m_Coroutine);
            }

            m_Coroutine =
                CoroutineM.Instance.StartCoroutine(
                    ScrollToCellCoroutine(index, speed, pos));
        }

        IEnumerator ScrollToCellCoroutine(int index, float speed, int pos)
        {
            bool needMoving = true;
            while (needMoving)
            {
                yield return null;
                if (!m_Dragging)
                {
                    float move = 0;
                    if (index < itemTypeStart)
                    {
                        move = -Time.deltaTime * speed;
                    }
                    else if (index >= itemTypeEnd)
                    {
                        move = Time.deltaTime * speed;
                    }
                    else
                    {
                        m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
                        var m_ItemBounds = GetBounds4Item(index);
                        var offset = 0.0f;
                        if (directionSign == -1)
                        {
                            switch (pos)
                            {
                                case -1: //定位到上
                                    offset = (m_ViewBounds.max.y - m_ItemBounds.max.y);
                                    break;
                                case 0: //定位到中
                                    var viewBoundsY = (m_ViewBounds.max.y - m_ViewBounds.min.y) * 0.5f +
                                                      m_ViewBounds.min.y;
                                    var itemBoundsY = (m_ItemBounds.max.y - m_ItemBounds.min.y) * 0.5f +
                                                      m_ItemBounds.min.y;
                                    offset = viewBoundsY - itemBoundsY;
                                    break;
                                case 1: //定位到下
                                    offset = (m_ViewBounds.min.y - m_ItemBounds.min.y);
                                    break;
                            }
                            //offset = reverseDirection ? (m_ViewBounds.min.y - m_ItemBounds.min.y) : (m_ViewBounds.max.y - m_ItemBounds.max.y);
                        }
                        else if (directionSign == 1)
                        {
                            offset = reverseDirection
                                ? (m_ItemBounds.max.x - m_ViewBounds.max.x)
                                : (m_ItemBounds.min.x - m_ViewBounds.min.x);
                            switch (pos)
                            {
                                case -1: //定位到左
                                    offset = (m_ItemBounds.min.x - m_ViewBounds.min.x);
                                    break;
                                case 0: //定位到中
                                    var viewBoundsX = (m_ViewBounds.max.x - m_ViewBounds.min.x) * 0.5f +
                                                      m_ViewBounds.min.x;
                                    var itemBoundsX = (m_ItemBounds.max.x - m_ItemBounds.min.x) * 0.5f +
                                                      m_ItemBounds.min.x;
                                    offset = viewBoundsX - itemBoundsX;
                                    break;
                                case 1: //定位到右
                                    offset = (m_ItemBounds.max.x - m_ViewBounds.max.x);
                                    break;
                            }
                        }

                        // check if we cannot move on
                        if (totalCount >= 0)
                        {
                            if (offset > 0 && itemTypeEnd == totalCount && !reverseDirection)
                            {
                                m_ItemBounds = GetBounds4Item(totalCount - 1);
                                // reach bottom
                                if ((directionSign == -1 && m_ItemBounds.min.y > m_ViewBounds.min.y) ||
                                    (directionSign == 1 && m_ItemBounds.max.x < m_ViewBounds.max.x))
                                {
                                    needMoving = false;
                                    break;
                                }
                            }
                            else if (offset < 0 && itemTypeStart == 0 && reverseDirection)
                            {
                                m_ItemBounds = GetBounds4Item(0);
                                if ((directionSign == -1 && m_ItemBounds.max.y < m_ViewBounds.max.y) ||
                                    (directionSign == 1 && m_ItemBounds.min.x > m_ViewBounds.min.x))
                                {
                                    needMoving = false;
                                    break;
                                }
                            }
                        }

                        float maxMove = Time.deltaTime * speed;
                        if (Mathf.Abs(offset) < maxMove)
                        {
                            needMoving = false;
                            move = offset;
                        }
                        else
                            move = Mathf.Sign(offset) * maxMove;
                    }

                    if (move != 0)
                    {
                        Vector2 offset = GetVector(move);
                        content.anchoredPosition += offset;
                        m_PrevPosition += offset;
                        m_ContentStartPosition += offset;
                        UpdateBounds(true);
                    }
                }
            }

            StopMovement();
            UpdatePrevData();
        }

        /// <summary>
        /// 移动到节点 没有动画
        /// </summary>
        /// <param name="idx"></param>
        public void SrollToCell(int idx, int pos = -1)
        {
            if (vertical)
                SetLayoutVertical();
            else
                SetLayoutHorizontal();

            UpdateBounds(true);
            var tmpItemBounds = GetBounds4Item(itemTypeStart);

            float offset = 0.0f;

            // 计算偏移量
            if (vertical)
            {
                // 竖直方向滚动
                switch (pos)
                {
                    case -1: // 定位到顶部
                        offset = 0;
                        break;
                    case 0: // 定位到中间
                        var viewBoundsY = (m_ViewBounds.max.y - m_ViewBounds.min.y) * 0.5f + m_ViewBounds.min.y;
                        var itemBoundsY = (tmpItemBounds.max.y - tmpItemBounds.min.y) * 0.5f + tmpItemBounds.min.y;
                        offset = viewBoundsY - itemBoundsY;
                        break;
                    case 1: // 定位到底部
                        offset = (m_ViewBounds.min.y - tmpItemBounds.min.y);
                        break;
                }
            }
            else
            {
                // 水平方向滚动
                switch (pos)
                {
                    case -1: // 定位到左边
                        offset = 0;
                        break;
                    case 0: // 定位到中间
                        var viewBoundsX = (m_ViewBounds.max.x - m_ViewBounds.min.x) * 0.5f + m_ViewBounds.min.x;
                        var itemBoundsX = (tmpItemBounds.max.x - tmpItemBounds.min.x) * 0.5f + tmpItemBounds.min.x;
                        offset = viewBoundsX - itemBoundsX;
                        break;
                    case 1: // 定位到右边
                        offset = (tmpItemBounds.max.x - m_ViewBounds.max.x);
                        break;
                }
            }

            float off = vertical
                ? ((tmpItemBounds.size.y + contentSpacing) * idx + offset) / (tmpItemBounds.size.y * totalCount +
                    contentSpacing * (totalCount - 1) - m_ViewBounds.size.y)
                : ((tmpItemBounds.size.x + contentSpacing) * idx + offset) / (tmpItemBounds.size.x * totalCount +
                    contentSpacing * (totalCount - 1) - m_ViewBounds.size.x);

            off = Mathf.Min(off, 1f);

            if (vertical)
                SetVerticalNormalizedPosition(off);
            else
                SetHorizontalNormalizedPosition(off);
        }


        /// <summary>
        /// 立即到达这个位置
        /// </summary>
        /// <param name="index"></param>
        /// <param name="pos">移动的位置 -1为左(上) 0为居中 1 为右(下) </param>
        public void SrollToCellImmediate(int index, int pos = -1, bool ignoreScroll = false)
        {
            if (totalCount >= 0 && (index < 0 || index >= totalCount))
            {
                LogWarning(string.Format("invalid index {0}", index));
                return;
            }

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefreshCells: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            ScrollToCellImmediate(index, pos, ignoreScroll);
        }

        void ScrollToCellImmediate(int index, int pos, bool ignoreScroll = false)
        {
            // 确保指定索引在有效范围内
            if (index < 0 || index >= totalCount)
            {
                Debug.LogError("Index out of range.");
                return;
            }

            // 计算视图的边界
            m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
            var m_ItemBounds = GetBounds4Item(index);
            float offset = 0.0f;

            // 计算偏移量
            if (directionSign == -1)
            {
                // 竖直方向滚动
                switch (pos)
                {
                    case -1: // 定位到顶部
                        offset = (m_ViewBounds.max.y - m_ItemBounds.max.y);
                        break;
                    case 0: // 定位到中间
                        var viewBoundsY = (m_ViewBounds.max.y - m_ViewBounds.min.y) * 0.5f + m_ViewBounds.min.y;
                        var itemBoundsY = (m_ItemBounds.max.y - m_ItemBounds.min.y) * 0.5f + m_ItemBounds.min.y;
                        offset = viewBoundsY - itemBoundsY;
                        break;
                    case 1: // 定位到底部
                        offset = (m_ViewBounds.min.y - m_ItemBounds.min.y);
                        break;
                }
            }
            else if (directionSign == 1)
            {
                // 水平方向滚动
                switch (pos)
                {
                    case -1: // 定位到左边
                        offset = (m_ItemBounds.min.x - m_ViewBounds.min.x);
                        break;
                    case 0: // 定位到中间
                        var viewBoundsX = (m_ViewBounds.max.x - m_ViewBounds.min.x) * 0.5f + m_ViewBounds.min.x;
                        var itemBoundsX = (m_ItemBounds.max.x - m_ItemBounds.min.x) * 0.5f + m_ItemBounds.min.x;
                        offset = viewBoundsX - itemBoundsX;
                        break;
                    case 1: // 定位到右边
                        offset = (m_ItemBounds.max.x - m_ViewBounds.max.x);
                        break;
                }
            }

            // 计算新的锚点位置
            Vector2 newPosition = content.anchoredPosition + GetVector(offset);

            // 设置锚点位置
            content.anchoredPosition = newPosition;
            //m_PrevPosition = newPosition;
            //m_ContentStartPosition = newPosition;

            // 更新滚动视图的边界
            UpdateBounds(true);
            UpdatePrevData();

            if (ignoreScroll)
            {
                var vector2 = CalculateOffset(Vector2.zero);
                m_Content.anchoredPosition += vector2;
                SetContentAnchoredPosition(m_Content.anchoredPosition);
            }

            // 停止滚动
            StopMovement();
        }

        public void RefreshCells()
        {
            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefreshCells: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            if (Application.isPlaying)
            {
                itemTypeEnd = itemTypeStart;
                // recycle items if we can
                for (int i = 0; i < content.childCount; i++)
                {
                    if (itemTypeEnd < totalCount)
                    {
                        dataSource.ProvideData(content.GetChild(i), itemTypeEnd);
                        itemTypeEnd++;
                    }
                    else
                    {
                        prefabSource.ReturnObject(content.GetChild(i), transform);
                        i--;
                    }
                }
            }
        }

        //如果是lua传的值，记得index要从0开始计算
        public void RefreshCellByIndex(int index)
        {
            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefreshCellByIndex: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            if (Application.isPlaying)
            {
                if (index >= totalCount)
                {
                    return;
                }

                var pos = index - itemTypeStart;
                if (pos >= 0 && pos < content.childCount)
                {
                    RectTransform oldItem = content.GetChild(pos) as RectTransform;
                    var oldSize = GetSize(oldItem);
                    //size = Mathf.Max(GetSize(oldItem), size);
                    prefabSource.ReturnObject(oldItem, transform);

                    RectTransform nextItem =
                        prefabSource.GetObject(dataSource.GetGameObjectIndex(index)).transform as RectTransform;
                    nextItem.SetParent(content, false);
                    nextItem.SetSiblingIndex(pos);
                    nextItem.gameObject.SetActive(true);
                    var newSize = GetSize(oldItem);
                    dataSource.ProvideData(nextItem, index);

                    // Vector2 anchoredPosition = m_Content.anchoredPosition;
                    // float dist = newSize - oldSize;
                    // if (reverseDirection)
                    //     dist = -dist;
                    // if (directionSign == -1)
                    //     anchoredPosition.y += dist;
                    // else if (directionSign == 1)
                    //     anchoredPosition.x += -dist;
                    // m_Content.anchoredPosition = anchoredPosition;
                }
#if UNITY_EDITOR
                else
                {
                    Debug.Log($"index overlay content:{index}-{itemTypeStart} {pos}/{content.childCount}");
                }
#endif
            }
        }

        //如果是lua传的值，记得index要从0开始计算
        public Transform GetCellByIndex(int index)
        {
            if (index >= totalCount)
            {
                return null;
            }

            var pos = index - itemTypeStart;
            if (pos >= 0 && pos < content.childCount)
            {
                return content.GetChild(pos);
            }
#if UNITY_EDITOR
            else
            {
                Debug.Log($"index overlay content:{index}-{itemTypeStart} {pos}/{content.childCount}");
            }
#endif
            return null;
        }

        public void RefillCellsFromEnd(int offset = 0)
        {
            if (!Application.isPlaying || prefabSource == null)
                return;

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefillCellsFromEnd: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            StopMovement();
            itemTypeEnd = reverseDirection ? offset : totalCount - offset;
            itemTypeStart = itemTypeEnd;

            if (totalCount >= 0 && itemTypeStart % contentConstraintCount != 0)
                LogWarning("Grid will become strange since we can't fill items in the last line");

            for (int i = m_Content.childCount - 1; i >= 0; i--)
            {
                prefabSource.ReturnObject(m_Content.GetChild(i), transform);
            }

            float sizeToFill = 0, sizeFilled = 0;
            if (directionSign == -1)
                sizeToFill = viewRect.rect.size.y;
            else
                sizeToFill = viewRect.rect.size.x;

            while (sizeToFill > sizeFilled)
            {
                float size = reverseDirection ? NewItemAtEnd() : NewItemAtStart();
                if (size <= 0) break;
                sizeFilled += size;
            }

            Vector2 pos = m_Content.anchoredPosition;
            float dist = Mathf.Max(0, sizeFilled - sizeToFill);
            if (reverseDirection)
                dist = -dist;
            if (directionSign == -1)
                pos.y = dist;
            else if (directionSign == 1)
                pos.x = -dist;
            m_Content.anchoredPosition = pos;
        }

        public void RefillCells(int offset = 0)
        {
            if (!Application.isPlaying || prefabSource == null)
                return;

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefillCells: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            StopMovement();
            itemTypeStart = reverseDirection ? totalCount - offset : offset;
            itemTypeEnd = itemTypeStart;

            if (totalCount >= 0 && itemTypeStart % contentConstraintCount != 0)
                LogWarning("Grid will become strange since we can't fill items in the first line");

            // Don't `Canvas.ForceUpdateCanvases();` here, or it will new/delete cells to change itemTypeStart/End
            for (int i = m_Content.childCount - 1; i >= 0; i--) //先回池所有条目
            {
                prefabSource.ReturnObject(m_Content.GetChild(i), transform);
            }

            float sizeToFill = 0, sizeFilled = 0; //sizeFiled:是当前已经填充了的条目总高度和
            // m_ViewBounds may be not ready when RefillCells on Start
            if (directionSign == -1)
                sizeToFill = viewRect.rect.size.y;
            else
                sizeToFill = viewRect.rect.size.x;

            while (sizeToFill > sizeFilled) //sizeToFill:漏出来的列表条目遮罩区域
            {
                float size = reverseDirection ? NewItemAtStart() : NewItemAtEnd();
                if (size <= 0) break;
                sizeFilled += size;
            }

            Vector2 pos = m_Content.anchoredPosition;
            if (directionSign == -1)
                pos.y = 0;
            else if (directionSign == 1)
                pos.x = 0;
            m_Content.anchoredPosition = pos;
        }

        public void Append(bool forceAdd = true, int count = 1)
        {
            if (!Application.isPlaying || prefabSource == null)
                return;

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("RefillCells: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            totalCount += count;
            //StopMovement();

            if (totalCount >= 0 && itemTypeStart % contentConstraintCount != 0)
                LogWarning("Grid will become strange since we can't fill items in the first line");
            float sizeToFill = 0, sizeFilled = 0; //sizeFiled:是当前已经填充了的条目总高度和
            // m_ViewBounds may be not ready when RefillCells on Start
            if (directionSign == -1)
            {
                sizeToFill = viewRect.rect.size.y * count;

                sizeFilled = m_Content.rect.size.y;
            }
            else
            {
                sizeToFill = viewRect.rect.size.x * count;
                sizeFilled = m_Content.rect.size.x;
            }

            if (itemTypeEnd == totalCount - 1)
            {
                while (sizeToFill > sizeFilled || forceAdd) //sizeToFill:漏出来的列表条目遮罩区域
                {
                    float size = reverseDirection ? NewItemAtStart() : NewItemAtEnd();
                    if (size <= 0) break;
                    sizeFilled += size;
                }
            }


            // Vector2 pos = m_Content.anchoredPosition;
            // if (directionSign == -1)
            //     pos.y = 0;
            // else if (directionSign == 1)
            //     pos.x = 0;
            // m_Content.anchoredPosition = pos;
        }

        public void InsertBegin(int count)
        {
            if (!Application.isPlaying || prefabSource == null)
                return;

            if (m_InitFinished && !this.isActiveAndEnabled && !IgnoreActiveState)
            {
                LogWarning("InsertAddBegin: the game object '" + this.gameObject.name + "' is inactive!");
                return;
            }

            totalCount += count;
            //StopMovement();
            itemTypeStart += count;
            itemTypeEnd += count;
            UpdateBounds(true);
            // Vector2 pos = m_Content.anchoredPosition;
            // if (directionSign == -1)
            //     pos.y = 0;
            // else if (directionSign == 1)
            //     pos.x = 0;
            // m_Content.anchoredPosition = pos;
        }

        protected float NewItemAtStart()
        {
            if (totalCount >= 0 && itemTypeStart - contentConstraintCount < 0)
            {
                return 0;
            }

            float size = 0;
            for (int i = 0; i < contentConstraintCount; i++)
            {
                itemTypeStart--;
                RectTransform newItem = InstantiateNextItem(itemTypeStart);
                newItem.SetAsFirstSibling();
                size = Mathf.Max(GetSize(newItem), size);
            }

            threshold = Mathf.Max(threshold, size * 1.5f);

            if (!reverseDirection)
            {
                Vector2 offset = GetVector(size);
                content.anchoredPosition += offset;
                m_PrevPosition += offset;
                m_ContentStartPosition += offset;
            }

            return size;
        }

        protected float DeleteItemAtStart()
        {
            // special case: when moving or dragging, we cannot simply delete start when we've reached the end
            if (((m_Dragging || m_Velocity != Vector2.zero) && totalCount >= 0 && itemTypeEnd >= totalCount - 1)
                || content.childCount == 0)
            {
                return 0;
            }

            float size = 0;
            for (int i = 0; i < contentConstraintCount; i++)
            {
                RectTransform oldItem = content.GetChild(0) as RectTransform;
                size = Mathf.Max(GetSize(oldItem), size);
                prefabSource.ReturnObject(oldItem, transform);

                itemTypeStart++;

                if (content.childCount == 0)
                {
                    break;
                }
            }

            if (!reverseDirection)
            {
                Vector2 offset = GetVector(size);
                content.anchoredPosition -= offset;
                m_PrevPosition -= offset;
                m_ContentStartPosition -= offset;
            }

            return size;
        }


        protected float NewItemAtEnd()
        {
            if (totalCount >= 0 && itemTypeEnd >= totalCount)
            {
                return 0;
            }

            float size = 0;
            // issue 4: fill lines to end first
            int count = contentConstraintCount - (content.childCount % contentConstraintCount); //最后一行可能不满，做单独处理
            for (int i = 0; i < count; i++)
            {
                RectTransform newItem = InstantiateNextItem(itemTypeEnd);
                size = Mathf.Max(GetSize(newItem), size);
                itemTypeEnd++;
                if (totalCount >= 0 && itemTypeEnd >= totalCount)
                {
                    break;
                }
            }

            threshold = Mathf.Max(threshold, size * 1.5f); //临界点：是单个条目的高度的1.5倍高

            if (reverseDirection)
            {
                Vector2 offset = GetVector(size);
                content.anchoredPosition -= offset;
                m_PrevPosition -= offset;
                m_ContentStartPosition -= offset;
            }

            return size;
        }

        protected float DeleteItemAtEnd()
        {
            if (((m_Dragging || m_Velocity != Vector2.zero) && totalCount >= 0 &&
                 itemTypeStart < contentConstraintCount)
                || content.childCount == 0)
            {
                return 0;
            }

            float size = 0;
            for (int i = 0; i < contentConstraintCount; i++)
            {
                RectTransform oldItem = content.GetChild(content.childCount - 1) as RectTransform;
                size = Mathf.Max(GetSize(oldItem), size);
                prefabSource.ReturnObject(oldItem, transform);

                itemTypeEnd--;
                if (itemTypeEnd % contentConstraintCount == 0 || content.childCount == 0)
                {
                    break; //just delete the whole row
                }
            }

            if (reverseDirection)
            {
                Vector2 offset = GetVector(size);
                content.anchoredPosition += offset;
                m_PrevPosition += offset;
                m_ContentStartPosition += offset;
            }

            return size;
        }

        private RectTransform InstantiateNextItem(int itemIdx)
        {
            RectTransform nextItem =
                prefabSource.GetObject(dataSource.GetGameObjectIndex(itemIdx)).transform as RectTransform;
            nextItem.transform.SetParent(content, false);
            nextItem.gameObject.SetActive(true);
            dataSource.ProvideData(nextItem, itemIdx);
            return nextItem;
        }
        //==========LoopScrollRect==========

        public virtual void Rebuild(CanvasUpdate executing)
        {
            if (executing == CanvasUpdate.Prelayout)
            {
                UpdateCachedData();
            }

            if (executing == CanvasUpdate.PostLayout)
            {
                UpdateBounds();
                UpdateScrollbars(Vector2.zero);
                UpdatePrevData();

                m_HasRebuiltLayout = true;
            }
        }

        public virtual void LayoutComplete()
        {
        }

        public virtual void GraphicUpdateComplete()
        {
        }

        void UpdateCachedData()
        {
            Transform transform = this.transform;
            m_HorizontalScrollbarRect =
                m_HorizontalScrollbar == null ? null : m_HorizontalScrollbar.transform as RectTransform;
            m_VerticalScrollbarRect =
                m_VerticalScrollbar == null ? null : m_VerticalScrollbar.transform as RectTransform;

            // These are true if either the elements are children, or they don't exist at all.
            bool viewIsChild = (viewRect.parent == transform);
            bool hScrollbarIsChild = (!m_HorizontalScrollbarRect || m_HorizontalScrollbarRect.parent == transform);
            bool vScrollbarIsChild = (!m_VerticalScrollbarRect || m_VerticalScrollbarRect.parent == transform);
            bool allAreChildren = (viewIsChild && hScrollbarIsChild && vScrollbarIsChild);

            m_HSliderExpand = allAreChildren && m_HorizontalScrollbarRect &&
                              horizontalScrollbarVisibility == ScrollbarVisibility.AutoHideAndExpandViewport;
            m_VSliderExpand = allAreChildren && m_VerticalScrollbarRect &&
                              verticalScrollbarVisibility == ScrollbarVisibility.AutoHideAndExpandViewport;
            m_HSliderHeight = (m_HorizontalScrollbarRect == null ? 0 : m_HorizontalScrollbarRect.rect.height);
            m_VSliderWidth = (m_VerticalScrollbarRect == null ? 0 : m_VerticalScrollbarRect.rect.width);
        }

        private Direction direction;
        private Direction m_curDirection = Direction.Horizontal;

        protected override void OnEnable()
        {
            base.OnEnable();

            if (m_Horizontal)
            {
                direction = Direction.Horizontal;
            }
            else
            {
                direction = Direction.Vertical;
            }

            if (m_HorizontalScrollbar)
                m_HorizontalScrollbar.onValueChanged.AddListener(SetHorizontalNormalizedPosition);
            if (m_VerticalScrollbar)
                m_VerticalScrollbar.onValueChanged.AddListener(SetVerticalNormalizedPosition);

            CanvasUpdateRegistry.RegisterCanvasElementForLayoutRebuild(this);
        }

        protected override void OnDisable()
        {
            CanvasUpdateRegistry.UnRegisterCanvasElementForRebuild(this);

            if (m_HorizontalScrollbar)
                m_HorizontalScrollbar.onValueChanged.RemoveListener(SetHorizontalNormalizedPosition);
            if (m_VerticalScrollbar)
                m_VerticalScrollbar.onValueChanged.RemoveListener(SetVerticalNormalizedPosition);

            m_HasRebuiltLayout = false;
            m_Tracker.Clear();
            m_Velocity = Vector2.zero;
            LayoutRebuilder.MarkLayoutForRebuild(rectTransform);
            base.OnDisable();
        }

        public override bool IsActive()
        {
            return base.IsActive() && m_Content != null;
        }

        private void EnsureLayoutHasRebuilt()
        {
            if (!m_HasRebuiltLayout && !CanvasUpdateRegistry.IsRebuildingLayout())
                Canvas.ForceUpdateCanvases();
        }

        public virtual void StopMovement()
        {
            m_Velocity = Vector2.zero;
            if (m_Coroutine != null)
            {
                CoroutineManager.StopCoroutine(m_Coroutine);
                m_Coroutine = null;
            }
        }

        public virtual void OnScroll(PointerEventData data)
        {
            if (!IsActive())
                return;

            EnsureLayoutHasRebuilt();
            UpdateBounds();

            Vector2 delta = data.scrollDelta;
            // Down is positive for scroll events, while in UI system up is positive.
            delta.y *= -1;
            if (vertical && !horizontal)
            {
                if (Mathf.Abs(delta.x) > Mathf.Abs(delta.y))
                    delta.y = delta.x;
                delta.x = 0;
            }

            if (horizontal && !vertical)
            {
                if (Mathf.Abs(delta.y) > Mathf.Abs(delta.x))
                    delta.x = delta.y;
                delta.y = 0;
            }

            Vector2 position = m_Content.anchoredPosition;
            position += delta * m_ScrollSensitivity;
            if (m_MovementType == MovementType.Clamped)
                position += CalculateOffset(position - m_Content.anchoredPosition);

            SetContentAnchoredPosition(position);
            UpdateBounds();
        }

        public virtual void OnInitializePotentialDrag(PointerEventData eventData)
        {
            if (this.IgnoreDragEvent || eventData.button != PointerEventData.InputButton.Left)
            {
                eventData.pointerDrag = null;
                return;
            }

            m_Velocity = Vector2.zero;
        }

        public virtual void OnBeginDrag(PointerEventData eventData)
        {
            if (this.IgnoreDragEvent || eventData.button != PointerEventData.InputButton.Left)
                return;

            if (!IsActive())
                return;

            //解决横纵列表嵌套滑动 by BigBing 2022.6.24
            if (parentScorll)
            {
                if (Mathf.Abs(eventData.delta.x) - Mathf.Abs(eventData.delta.y) > triggerParentValue)
                {
                    m_curDirection = Direction.Horizontal;
                }

                if (Mathf.Abs(eventData.delta.y) - Mathf.Abs(eventData.delta.x) > triggerParentValue)
                {
                    m_curDirection = Direction.Vertical;
                }

                if (m_curDirection != direction)
                {
                    //当前操作方向不等于滑动方向，将事件传给父对象
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.beginDragHandler);
                    }

                    return;
                }

                if (IgnoreMove)
                {
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.beginDragHandler);
                    }

                    return;
                }
            }

            //End
            StopMovement();
            UpdateBounds();

            m_PointerStartLocalCursor = Vector2.zero;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(viewRect, eventData.position,
                eventData.pressEventCamera, out m_PointerStartLocalCursor);
            m_ContentStartPosition = m_Content.anchoredPosition;
            m_Dragging = true;
        }

        public virtual void OnEndDrag(PointerEventData eventData)
        {
            if (this.IgnoreDragEvent || eventData.button != PointerEventData.InputButton.Left)
                return;

            //解决横纵列表嵌套滑动 by BigBing 2022.6.24
            if (parentScorll)
            {
                if (Mathf.Abs(eventData.delta.x) - Mathf.Abs(eventData.delta.y) > triggerParentValue)
                {
                    m_curDirection = Direction.Horizontal;
                }

                if (Mathf.Abs(eventData.delta.y) - Mathf.Abs(eventData.delta.x) > triggerParentValue)
                {
                    m_curDirection = Direction.Vertical;
                }

                if (m_curDirection != direction)
                {
                    //当前操作方向不等于滑动方向，将事件传给父对象
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.endDragHandler);
                    }

                    return;
                }

                if (IgnoreMove)
                {
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.endDragHandler);
                    }

                    return;
                }
            }

            //End
            m_Dragging = false;

            if (vertical && verticalNormalizedPosition <= 0)
            {
                dataSource.OnEndTopDrag();
            }

            if (horizontal && horizontalNormalizedPosition <= 0)
            {
                dataSource.OnEndTopDrag();
            }

            OnEndDragEvent?.Invoke();
        }

        private LoopScrollRect _childScroll;

        protected override void Awake()
        {
            base.Awake();
            if (parentScorll != null)
            {
                parentScorll._childScroll = this;
            }
        }

        public void SetParentScroll(LoopScrollRect parent)
        {
            parentScorll = parent;
            parentScorll._childScroll = this;
        }

        public virtual void OnDrag(PointerEventData eventData)
        {
            if (this.IgnoreDragEvent || eventData.button != PointerEventData.InputButton.Left)
                return;

            if (!IsActive())
                return;

            //解决横纵列表嵌套滑动 by BigBing 2022.6.24
            if (parentScorll)
            {
                if (parentScorll.m_Dragging)
                {
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.dragHandler);
                    }

                    return;
                }

                if (Mathf.Abs(eventData.delta.x) - Mathf.Abs(eventData.delta.y) > triggerParentValue)
                {
                    m_curDirection = Direction.Horizontal;
                }

                if (Mathf.Abs(eventData.delta.y) - Mathf.Abs(eventData.delta.x) > triggerParentValue)
                {
                    m_curDirection = Direction.Vertical;
                }

                if (m_curDirection != direction)
                {
                    //当前操作方向不等于滑动方向，将事件传给父对象
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.dragHandler);
                    }

                    return;
                }

                if (IgnoreMove)
                {
                    //当Parent是自己的时候会死循环StackOverflow
                    if (parentScorll.gameObject != this.gameObject)
                    {
                        ExecuteEvents.Execute(parentScorll.gameObject, eventData, ExecuteEvents.dragHandler);
                    }

                    return;
                }
            }
            //End

            Vector2 localCursor;
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(viewRect, eventData.position,
                    eventData.pressEventCamera, out localCursor))
                return;

            UpdateBounds();

            var pointerDelta = localCursor - m_PointerStartLocalCursor;
            Vector2 position = m_ContentStartPosition + pointerDelta;

            // Offset to get content into place in the view.
            Vector2 offset = CalculateOffset(position - m_Content.anchoredPosition);
            position += offset;
            if (m_MovementType == MovementType.Elastic)
            {
                //==========LoopScrollRect==========
                if (offset.x != 0)
                    position.x = position.x - RubberDelta(offset.x, m_ViewBounds.size.x) * rubberScale;
                if (offset.y != 0)
                    position.y = position.y - RubberDelta(offset.y, m_ViewBounds.size.y) * rubberScale;
                //==========LoopScrollRect==========
            }

            SetContentAnchoredPosition(position);
        }

        protected virtual void SetContentAnchoredPosition(Vector2 position)
        {
            if (!m_Horizontal)
                position.x = m_Content.anchoredPosition.x;
            if (!m_Vertical)
                position.y = m_Content.anchoredPosition.y;

            if (position != m_Content.anchoredPosition)
            {
                m_Content.anchoredPosition = position;
                UpdateBounds(true);
            }
        }

        protected virtual void LateUpdate()
        {
            if (!m_Content)
                return;

            EnsureLayoutHasRebuilt();
            UpdateScrollbarVisibility();
            UpdateBounds();
            float deltaTime = Time.unscaledDeltaTime;
            Vector2 offset = CalculateOffset(Vector2.zero);
            if (!m_Dragging && (offset != Vector2.zero || m_Velocity != Vector2.zero))
            {
                Vector2 position = m_Content.anchoredPosition;
                for (int axis = 0; axis < 2; axis++)
                {
                    // Apply spring physics if movement is elastic and content has an offset from the view.
                    if (m_MovementType == MovementType.Elastic && offset[axis] != 0)
                    {
                        float speed = m_Velocity[axis];
                        position[axis] = Mathf.SmoothDamp(m_Content.anchoredPosition[axis],
                            m_Content.anchoredPosition[axis] + offset[axis], ref speed, m_Elasticity, Mathf.Infinity,
                            deltaTime);
                        m_Velocity[axis] = speed;
                    }
                    // Else move content according to velocity with deceleration applied.
                    else if (m_Inertia)
                    {
                        m_Velocity[axis] *= Mathf.Pow(m_DecelerationRate, deltaTime);
                        if (Mathf.Abs(m_Velocity[axis]) < 1)
                            m_Velocity[axis] = 0;
                        position[axis] += m_Velocity[axis] * deltaTime;
                    }
                    // If we have neither elaticity or friction, there shouldn't be any velocity.
                    else
                    {
                        m_Velocity[axis] = 0;
                    }
                }


                if (m_MovementType == MovementType.Clamped)
                {
                    offset = CalculateOffset(position - m_Content.anchoredPosition);
                    position += offset;
                }

                SetContentAnchoredPosition(position);

                if (m_Velocity == Vector2.zero)
                {
                    OnStopMoveEvent?.Invoke();
                }
            }

            if (m_Dragging && m_Inertia)
            {
                Vector3 newVelocity = (m_Content.anchoredPosition - m_PrevPosition) / deltaTime;
                m_Velocity = Vector3.Lerp(m_Velocity, newVelocity, deltaTime * 10);
            }

            if (m_ViewBounds != m_PrevViewBounds || m_ContentBounds != m_PrevContentBounds ||
                m_Content.anchoredPosition != m_PrevPosition)
            {
                UpdateScrollbars(offset);
                m_OnValueChanged.Invoke(normalizedPosition);
                UpdatePrevData();
            }
        }

        private void UpdatePrevData()
        {
            if (m_Content == null)
                m_PrevPosition = Vector2.zero;
            else
                m_PrevPosition = m_Content.anchoredPosition;
            m_PrevViewBounds = m_ViewBounds;
            m_PrevContentBounds = m_ContentBounds;
        }

        private void UpdateScrollbars(Vector2 offset)
        {
            if (m_HorizontalScrollbar)
            {
                //==========LoopScrollRect==========
                if (m_ContentBounds.size.x > 0 && totalCount > 0)
                {
                    m_HorizontalScrollbar.size = Mathf.Clamp01((m_ViewBounds.size.x - Mathf.Abs(offset.x)) /
                        m_ContentBounds.size.x * CurrentLines / TotalLines);
                }
                //==========LoopScrollRect==========
                else
                    m_HorizontalScrollbar.size = 1;

                m_HorizontalScrollbar.value = horizontalNormalizedPosition;
            }

            if (m_VerticalScrollbar)
            {
                //==========LoopScrollRect==========
                if (m_ContentBounds.size.y > 0 && totalCount > 0)
                {
                    m_VerticalScrollbar.size = Mathf.Clamp01((m_ViewBounds.size.y - Mathf.Abs(offset.y)) /
                        m_ContentBounds.size.y * CurrentLines / TotalLines);
                }
                //==========LoopScrollRect==========
                else
                    m_VerticalScrollbar.size = 1;

                m_VerticalScrollbar.value = verticalNormalizedPosition;
            }
        }

        public Vector2 normalizedPosition
        {
            get { return new Vector2(horizontalNormalizedPosition, verticalNormalizedPosition); }
            set
            {
                SetNormalizedPosition(value.x, 0);
                SetNormalizedPosition(value.y, 1);
            }
        }

        public float horizontalNormalizedPosition
        {
            get
            {
                UpdateBounds();
                //==========LoopScrollRect==========
                if (totalCount > 0 && itemTypeEnd > itemTypeStart)
                {
                    //TODO: consider contentSpacing
                    float elementSize = m_ContentBounds.size.x / CurrentLines;
                    float totalSize = elementSize * TotalLines;
                    float offset = m_ContentBounds.min.x - elementSize * StartLine;

                    if (totalSize <= m_ViewBounds.size.x)
                        return (m_ViewBounds.min.x > offset) ? 1 : 0;
                    return (m_ViewBounds.min.x - offset) / (totalSize - m_ViewBounds.size.x);
                }
                else
                    return 0.5f;
                //==========LoopScrollRect==========
            }
            set { SetNormalizedPosition(value, 0); }
        }

        public bool IsShowAll()
        {
            if (totalCount == 0)
            {
                return true;
            }

            if (itemTypeStart > 0)
            {
                return false;
            }

            if (itemTypeEnd < totalCount)
            {
                return false;
            }

            m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
            var itemBounds = GetBounds4Item(totalCount - 1);

            if ((directionSign == -1 && itemBounds.min.y > m_ViewBounds.min.y - 5) ||
                (directionSign == 1 && itemBounds.max.x < m_ViewBounds.max.x + 5))
            {
                var itemBoundBegin = GetBounds4Item(0);
                if ((directionSign == -1 && itemBoundBegin.max.y < m_ViewBounds.max.y + 5) ||
                    (directionSign == 1 && itemBoundBegin.min.x > m_ViewBounds.min.x - 5))
                    return true;
            }

            return false;
        }

        public bool IsShowBegin()
        {
            if (totalCount == 0)
            {
                return true;
            }

            if (itemTypeStart > 0)
            {
                return false;
            }


            m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);

            var itemBoundBegin = GetBounds4Item(0);
            if ((directionSign == -1 && itemBoundBegin.max.y < m_ViewBounds.max.y + 5) ||
                (directionSign == 1 && itemBoundBegin.min.x > m_ViewBounds.min.x - 5))
                return true;


            return false;
        }

        public bool IsAtEnd()
        {
            if (totalCount >= 0)
            {
                if (itemTypeEnd >= totalCount)
                {
                    if (m_Dragging)
                    {
                        return false;
                    }

                    m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
                    var itemBounds = GetBounds4Item(totalCount - 1);
                    // reach bottom
                    if ((directionSign == -1 && itemBounds.min.y > m_ViewBounds.min.y - 5) ||
                        (directionSign == 1 && itemBounds.max.x < m_ViewBounds.max.x + 5))
                    {
                        return true;
                    }
                }

                return false;
            }
            else
            {
                return true;
            }
        }

        public float verticalNormalizedPosition
        {
            get
            {
                UpdateBounds();
                //==========LoopScrollRect==========
                if (totalCount > 0 && itemTypeEnd > itemTypeStart)
                {
                    //TODO: consider contentSpacinge
                    float elementSize = m_ContentBounds.size.y / CurrentLines;
                    float totalSize = elementSize * TotalLines;
                    float offset = m_ContentBounds.max.y + elementSize * StartLine;

                    if (totalSize <= m_ViewBounds.size.y)
                        return (offset > m_ViewBounds.max.y) ? 1 : 0;
                    return (offset - m_ViewBounds.max.y) / (totalSize - m_ViewBounds.size.y);
                }
                else
                    return 0.5f;
                //==========LoopScrollRect==========
            }
            set { SetNormalizedPosition(value, 1); }
        }

        private void SetHorizontalNormalizedPosition(float value)
        {
            SetNormalizedPosition(value, 0);
        }

        private void SetVerticalNormalizedPosition(float value)
        {
            SetNormalizedPosition(value, 1);
        }

        private void SetNormalizedPosition(float value, int axis)
        {
            //==========LoopScrollRect==========
            if (totalCount <= 0 || itemTypeEnd <= itemTypeStart)
                return;
            //==========LoopScrollRect==========

            EnsureLayoutHasRebuilt();
            UpdateBounds();

            //==========LoopScrollRect==========
            Vector3 localPosition = m_Content.localPosition;
            float newLocalPosition = localPosition[axis];
            if (axis == 0)
            {
                float elementSize = m_ContentBounds.size.x / CurrentLines;
                float totalSize = elementSize * TotalLines;
                float offset = m_ContentBounds.min.x - elementSize * StartLine;

                newLocalPosition += m_ViewBounds.min.x - value * (totalSize - m_ViewBounds.size[axis]) - offset;
            }
            else if (axis == 1)
            {
                float elementSize = m_ContentBounds.size.y / CurrentLines;
                float totalSize = elementSize * TotalLines;
                float offset = m_ContentBounds.max.y + elementSize * StartLine;

                newLocalPosition -= offset - value * (totalSize - m_ViewBounds.size.y) - m_ViewBounds.max.y;
            }
            //==========LoopScrollRect==========

            if (Mathf.Abs(localPosition[axis] - newLocalPosition) > 0.01f)
            {
                localPosition[axis] = newLocalPosition;
                m_Content.localPosition = localPosition;
                m_Velocity[axis] = 0;
                UpdateBounds(true);
            }
        }

        private static float RubberDelta(float overStretching, float viewSize)
        {
            return (1 - (1 / ((Mathf.Abs(overStretching) * 0.55f / viewSize) + 1))) * viewSize *
                   Mathf.Sign(overStretching);
        }

        protected override void OnRectTransformDimensionsChange()
        {
            SetDirty();
        }

        public bool hScrollingNeeded
        {
            get
            {
                if (Application.isPlaying)
                    return m_ContentBounds.size.x > m_ViewBounds.size.x + 0.01f;
                return true;
            }
        }

        public bool vScrollingNeeded
        {
            get
            {
                if (Application.isPlaying)
                    return m_ContentBounds.size.y > m_ViewBounds.size.y + 0.01f;
                return true;
            }
        }

        public virtual void CalculateLayoutInputHorizontal()
        {
        }

        public virtual void CalculateLayoutInputVertical()
        {
        }

        public virtual float minWidth
        {
            get { return -1; }
        }

        public virtual float preferredWidth
        {
            get { return -1; }
        }

        public virtual float flexibleWidth { get; private set; }

        public virtual float minHeight
        {
            get { return -1; }
        }

        public virtual float preferredHeight
        {
            get { return -1; }
        }

        public virtual float flexibleHeight
        {
            get { return -1; }
        }

        public virtual int layoutPriority
        {
            get { return -1; }
        }

        public virtual void SetLayoutHorizontal()
        {
            m_Tracker.Clear();

            if (m_HSliderExpand || m_VSliderExpand)
            {
                m_Tracker.Add(this, viewRect,
                    DrivenTransformProperties.Anchors |
                    DrivenTransformProperties.SizeDelta |
                    DrivenTransformProperties.AnchoredPosition);

                // Make view full size to see if content fits.
                viewRect.anchorMin = Vector2.zero;
                viewRect.anchorMax = Vector2.one;
                viewRect.sizeDelta = Vector2.zero;
                viewRect.anchoredPosition = Vector2.zero;

                // Recalculate content layout with this size to see if it fits when there are no scrollbars.
                LayoutRebuilder.ForceRebuildLayoutImmediate(content);
                m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
                m_ContentBounds = GetBounds();
            }

            // If it doesn't fit vertically, enable vertical scrollbar and shrink view horizontally to make room for it.
            if (m_VSliderExpand && vScrollingNeeded)
            {
                viewRect.sizeDelta = new Vector2(-(m_VSliderWidth + m_VerticalScrollbarSpacing), viewRect.sizeDelta.y);

                // Recalculate content layout with this size to see if it fits vertically
                // when there is a vertical scrollbar (which may reflowed the content to make it taller).
                LayoutRebuilder.ForceRebuildLayoutImmediate(content);
                m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
                m_ContentBounds = GetBounds();
            }

            // If it doesn't fit horizontally, enable horizontal scrollbar and shrink view vertically to make room for it.
            if (m_HSliderExpand && hScrollingNeeded)
            {
                viewRect.sizeDelta =
                    new Vector2(viewRect.sizeDelta.x, -(m_HSliderHeight + m_HorizontalScrollbarSpacing));
                m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
                m_ContentBounds = GetBounds();
            }

            // If the vertical slider didn't kick in the first time, and the horizontal one did,
            // we need to check again if the vertical slider now needs to kick in.
            // If it doesn't fit vertically, enable vertical scrollbar and shrink view horizontally to make room for it.
            if (m_VSliderExpand && vScrollingNeeded && viewRect.sizeDelta.x == 0 && viewRect.sizeDelta.y < 0)
            {
                viewRect.sizeDelta = new Vector2(-(m_VSliderWidth + m_VerticalScrollbarSpacing), viewRect.sizeDelta.y);
            }
        }

        public virtual void SetLayoutVertical()
        {
            UpdateScrollbarLayout();
            m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
            m_ContentBounds = GetBounds();
        }

        void UpdateScrollbarVisibility()
        {
            if (m_VerticalScrollbar && m_VerticalScrollbarVisibility != ScrollbarVisibility.Permanent &&
                m_VerticalScrollbar.gameObject.activeSelf != vScrollingNeeded)
                m_VerticalScrollbar.gameObject.SetActive(vScrollingNeeded);

            if (m_HorizontalScrollbar && m_HorizontalScrollbarVisibility != ScrollbarVisibility.Permanent &&
                m_HorizontalScrollbar.gameObject.activeSelf != hScrollingNeeded)
                m_HorizontalScrollbar.gameObject.SetActive(hScrollingNeeded);
        }

        void UpdateScrollbarLayout()
        {
            if (m_VSliderExpand && m_HorizontalScrollbar)
            {
                m_Tracker.Add(this, m_HorizontalScrollbarRect,
                    DrivenTransformProperties.AnchorMinX |
                    DrivenTransformProperties.AnchorMaxX |
                    DrivenTransformProperties.SizeDeltaX |
                    DrivenTransformProperties.AnchoredPositionX);
                m_HorizontalScrollbarRect.anchorMin = new Vector2(0, m_HorizontalScrollbarRect.anchorMin.y);
                m_HorizontalScrollbarRect.anchorMax = new Vector2(1, m_HorizontalScrollbarRect.anchorMax.y);
                m_HorizontalScrollbarRect.anchoredPosition =
                    new Vector2(0, m_HorizontalScrollbarRect.anchoredPosition.y);
                if (vScrollingNeeded)
                    m_HorizontalScrollbarRect.sizeDelta = new Vector2(-(m_VSliderWidth + m_VerticalScrollbarSpacing),
                        m_HorizontalScrollbarRect.sizeDelta.y);
                else
                    m_HorizontalScrollbarRect.sizeDelta = new Vector2(0, m_HorizontalScrollbarRect.sizeDelta.y);
            }

            if (m_HSliderExpand && m_VerticalScrollbar)
            {
                m_Tracker.Add(this, m_VerticalScrollbarRect,
                    DrivenTransformProperties.AnchorMinY |
                    DrivenTransformProperties.AnchorMaxY |
                    DrivenTransformProperties.SizeDeltaY |
                    DrivenTransformProperties.AnchoredPositionY);
                m_VerticalScrollbarRect.anchorMin = new Vector2(m_VerticalScrollbarRect.anchorMin.x, 0);
                m_VerticalScrollbarRect.anchorMax = new Vector2(m_VerticalScrollbarRect.anchorMax.x, 1);
                m_VerticalScrollbarRect.anchoredPosition = new Vector2(m_VerticalScrollbarRect.anchoredPosition.x, 0);
                if (hScrollingNeeded)
                    m_VerticalScrollbarRect.sizeDelta = new Vector2(m_VerticalScrollbarRect.sizeDelta.x,
                        -(m_HSliderHeight + m_HorizontalScrollbarSpacing));
                else
                    m_VerticalScrollbarRect.sizeDelta = new Vector2(m_VerticalScrollbarRect.sizeDelta.x, 0);
            }
        }

        private void UpdateBounds(bool updateItems = false)
        {
            m_ViewBounds = new Bounds(viewRect.rect.center, viewRect.rect.size);
            m_ContentBounds = GetBounds();

            if (m_Content == null)
                return;

            // ============LoopScrollRect============
            // Don't do this in Rebuild
            if (Application.isPlaying && updateItems && UpdateItems(m_ViewBounds, m_ContentBounds))
            {
                Canvas.ForceUpdateCanvases();
                m_ContentBounds = GetBounds();
            }
            // ============LoopScrollRect============

            // Make sure content bounds are at least as large as view by adding padding if not.
            // One might think at first that if the content is smaller than the view, scrolling should be allowed.
            // However, that's not how scroll views normally work.
            // Scrolling is *only* possible when content is *larger* than view.
            // We use the pivot of the content rect to decide in which directions the content bounds should be expanded.
            // E.g. if pivot is at top, bounds are expanded downwards.
            // This also works nicely when ContentSizeFitter is used on the content.
            Vector3 contentSize = m_ContentBounds.size;
            Vector3 contentPos = m_ContentBounds.center;
            Vector3 excess = m_ViewBounds.size - contentSize;
            if (excess.x > 0)
            {
                contentPos.x -= excess.x * (m_Content.pivot.x - 0.5f);
                contentSize.x = m_ViewBounds.size.x;
            }

            if (excess.y > 0)
            {
                contentPos.y -= excess.y * (m_Content.pivot.y - 0.5f);
                contentSize.y = m_ViewBounds.size.y;
            }

            //contentSize.Round(vectorRoundDigits);
            //contentPos.Round(vectorRoundDigits);
            m_ContentBounds.size = contentSize;
            m_ContentBounds.center = contentPos;
        }

        private readonly Vector3[] m_Corners = new Vector3[4];

        private Bounds GetBounds()
        {
            if (m_Content == null)
                return new Bounds();

            var vMin = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
            var vMax = new Vector3(float.MinValue, float.MinValue, float.MinValue);

            var toLocal = viewRect.worldToLocalMatrix;
            m_Content.GetWorldCorners(m_Corners);
            for (int j = 0; j < 4; j++)
            {
                Vector3 v = toLocal.MultiplyPoint3x4(m_Corners[j]);
                vMin = Vector3.Min(v, vMin);
                vMax = Vector3.Max(v, vMax);
            }

            var bounds = new Bounds(vMin, Vector3.zero);
            bounds.Encapsulate(vMax);
            return bounds;
        }

        private Bounds GetBounds4Item(int index)
        {
            if (m_Content == null)
                return new Bounds();

            var vMin = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
            var vMax = new Vector3(float.MinValue, float.MinValue, float.MinValue);

            var toLocal = viewRect.worldToLocalMatrix;
            int offset = index - itemTypeStart;
            if (offset < 0 || offset >= m_Content.childCount)
                return new Bounds();
            var rt = m_Content.GetChild(offset) as RectTransform;
            if (rt == null)
                return new Bounds();
            rt.GetWorldCorners(m_Corners);
            for (int j = 0; j < 4; j++)
            {
                Vector3 v = toLocal.MultiplyPoint3x4(m_Corners[j]);
                vMin = Vector3.Min(v, vMin);
                vMax = Vector3.Max(v, vMax);
            }

            var bounds = new Bounds(vMin, Vector3.zero);
            bounds.Encapsulate(vMax);
            return bounds;
        }

        private Vector2 CalculateOffset(Vector2 delta)
        {
            if (totalCount < 0 || movementType == MovementType.Unrestricted)
                return delta;

            if (m_MovementType == MovementType.Elastic)
                return CalculateOffset_Elastic(delta);

            return CalculateOffset_Clamped(delta);
        }


        private Vector2 CalculateOffset_Elastic(Vector2 delta)
        {
            Vector2 offset = Vector2.zero;
            Vector2 min = m_ContentBounds.min;
            Vector2 max = m_ContentBounds.max;

            if (m_Horizontal)
            {
                min.x += delta.x;
                max.x += delta.x;
                if (min.x > m_ViewBounds.min.x)
                    offset.x = m_ViewBounds.min.x - min.x;
                else if (max.x < m_ViewBounds.max.x)
                    offset.x = m_ViewBounds.max.x - max.x;
            }

            if (m_Vertical)
            {
                min.y += delta.y;
                max.y += delta.y;
                if (max.y < m_ViewBounds.max.y)
                    offset.y = m_ViewBounds.max.y - max.y;
                else if (min.y > m_ViewBounds.min.y)
                    offset.y = m_ViewBounds.min.y - min.y;
            }

            return offset;
        }

        private Vector2 CalculateOffset_Clamped(Vector2 delta)
        {
            Bounds contentBound = m_ContentBounds;
            if (m_Horizontal)
            {
                float totalSize, offset;
                GetHorizonalOffsetAndSize(out totalSize, out offset);

                Vector3 center = contentBound.center;
                center.x = offset;
                contentBound.Encapsulate(center);
                center.x = offset + totalSize;
                contentBound.Encapsulate(center);
            }

            if (m_Vertical)
            {
                float totalSize, offset;
                GetVerticalOffsetAndSize(out totalSize, out offset);

                Vector3 center = contentBound.center;
                center.y = offset;
                contentBound.Encapsulate(center);
                center.y = offset - totalSize;
                contentBound.Encapsulate(center);
            }

            //==========LoopScrollRect==========
            return InternalCalculateOffset(ref m_ViewBounds, ref contentBound, m_Horizontal, m_Vertical, m_MovementType,
                ref delta);
        }

        internal static Vector2 InternalCalculateOffset(ref Bounds viewBounds, ref Bounds contentBounds,
            bool horizontal, bool vertical, MovementType movementType, ref Vector2 delta)
        {
            Vector2 offset = Vector2.zero;
            if (movementType == MovementType.Unrestricted)
                return offset;

            Vector2 min = contentBounds.min;
            Vector2 max = contentBounds.max;

            // min/max offset extracted to check if approximately 0 and avoid recalculating layout every frame (case 1010178)

            if (horizontal)
            {
                min.x += delta.x;
                max.x += delta.x;

                float maxOffset = viewBounds.max.x - max.x;
                float minOffset = viewBounds.min.x - min.x;

                if (minOffset < -0.001f)
                    offset.x = minOffset;
                else if (maxOffset > 0.001f)
                    offset.x = maxOffset;
            }

            if (vertical)
            {
                min.y += delta.y;
                max.y += delta.y;

                float maxOffset = viewBounds.max.y - max.y;
                float minOffset = viewBounds.min.y - min.y;

                if (maxOffset > 0.001f)
                    offset.y = maxOffset;
                else if (minOffset < -0.001f)
                    offset.y = minOffset;
            }

            return offset;
        }


        //==========LoopScrollRect==========
        public void GetVerticalOffsetAndSize(out float totalSize, out float offset)
        {
            float elementSize = (m_ContentBounds.size.y - contentSpacing * (CurrentLines - 1)) / CurrentLines;
            totalSize = elementSize * TotalLines + contentSpacing * (TotalLines - 1);
            offset = m_ContentBounds.max.y + elementSize * StartLine + contentSpacing * StartLine;
        }

        public void GetHorizonalOffsetAndSize(out float totalSize, out float offset)
        {
            float elementSize = (m_ContentBounds.size.x - contentSpacing * (CurrentLines - 1)) / CurrentLines;
            totalSize = elementSize * TotalLines + contentSpacing * (TotalLines - 1);
            offset = m_ContentBounds.min.x - elementSize * StartLine - contentSpacing * StartLine;
        }

        protected void SetDirty()
        {
            if (!IsActive())
                return;

            LayoutRebuilder.MarkLayoutForRebuild(rectTransform);
        }

        protected void SetDirtyCaching()
        {
            if (!IsActive())
                return;

            CanvasUpdateRegistry.RegisterCanvasElementForLayoutRebuild(this);
            LayoutRebuilder.MarkLayoutForRebuild(rectTransform);
        }

        protected override void OnDestroy()
        {
            // add by bao~ 23/1/4 销毁时，此协程可能还会被调用
            if (m_Coroutine != null)
            {
                Nframwork.module..StopCoroutine(m_Coroutine);
                //Debug.Log($"{nameof(LoopScrollRect)} ----> {Ez.Core.TransformUtil.GetTransformPath(transform)}");
            }

            //prefabSource.Destroy();
            base.OnDestroy();
        }

#if UNITY_EDITOR
        protected override void OnValidate()
        {
            SetDirtyCaching();
        }
#endif


        public void OnRefillOtherCells()
        {
            float sizeToFill = 0, sizeFilled = 0;
            // m_ViewBounds may be not ready when RefillCells on Start
            if (directionSign == -1)
                sizeToFill = viewRect.rect.size.y;
            else
                sizeToFill = viewRect.rect.size.x;

            while (sizeToFill > sizeFilled)
            {
                float size = reverseDirection ? NewItemAtStart() : NewItemAtEnd();
                if (size <= 0) break;
                sizeFilled += size;
            }

            RefreshCells();
        }

        public void RefillOtherCellCount(int count)
        {
            for (int i = 0; i < count; i++)
            {
                float size = reverseDirection ? NewItemAtStart() : NewItemAtEnd();
                if (size <= 0) break;
            }
        }

        /// <summary>
        /// 可视范围往外扩大5 容错
        /// </summary>
        private int BoundsRangeOffset = 5;

        /// <summary>
        /// 获取cell所在的方位
        /// -2 是左(上)框外
        /// -1 是与左(上)框相交
        /// 0  是框内
        /// 1  是与右(下)框相交
        /// 2  是与右(下)框外
        /// </summary>
        /// <param name="index"></param>
        /// <returns></returns>
        public int GetItemDirect(int index)
        {
            //默认放在外面
            int dir = index < (itemTypeStart + itemTypeEnd) / 2 ? -2 : 2;

            if (index < itemTypeStart)
            {
                dir = -2;
            }
            else if (index >= itemTypeEnd)
            {
                dir = 2;
            }
            else
            {
                var itemBounds = GetBounds4Item(index);
                //如果获取的bounds是空的 
                if (itemBounds.max.y == 0 && itemBounds.min.y == 0 && itemBounds.max.x == 0 && itemBounds.min.x == 0)
                {
                    return reverseDirection ? -dir : dir;
                }

                //竖向
                if (directionSign == -1)
                {
                    if (m_ViewBounds.min.y - BoundsRangeOffset >= itemBounds.max.y)
                    {
                        dir = 2; // 下
                    }
                    else if (m_ViewBounds.max.y + BoundsRangeOffset <= itemBounds.min.y)
                    {
                        dir = -2; //上
                    }
                    else if (m_ViewBounds.max.y + BoundsRangeOffset >= itemBounds.max.y &&
                             m_ViewBounds.min.y - BoundsRangeOffset <= itemBounds.min.y)
                    {
                        dir = 0; //中
                    }
                    else if (m_ViewBounds.max.y + BoundsRangeOffset < itemBounds.max.y)
                    {
                        dir = -1; // 上 出去一部分
                    }
                    else if (m_ViewBounds.min.y - BoundsRangeOffset > itemBounds.min.y)
                    {
                        dir = 1; // 下 出去一部分
                    }
                }
                else if (directionSign == 1)
                {
                    if (m_ViewBounds.min.x - BoundsRangeOffset >= itemBounds.max.x)
                    {
                        dir = -2; // 左
                    }
                    else if (m_ViewBounds.max.x + BoundsRangeOffset <= itemBounds.min.x)
                    {
                        dir = 2; //右
                    }
                    else if (m_ViewBounds.max.x + BoundsRangeOffset >= itemBounds.max.x &&
                             m_ViewBounds.min.x - BoundsRangeOffset <= itemBounds.min.x)
                    {
                        dir = 0; //中
                    }
                    else if (m_ViewBounds.max.x + BoundsRangeOffset < itemBounds.max.x)
                    {
                        dir = 1; // 右 出去一部分
                    }
                    else if (m_ViewBounds.min.x - BoundsRangeOffset > itemBounds.min.x)
                    {
                        dir = -1; // 左 出去一部分
                    }
                }
            }

            return reverseDirection ? -dir : dir;
        }

        /// <summary>
        /// 从Lua中获取 index从1开始
        /// </summary>
        /// <param name="index"></param>
        /// <returns></returns>
        public int GetItemDirectFromLua(int index)
        {
            index = index - 1; //lua里面从1开始
            return GetItemDirect(index);
        }


        /// <summary>
        /// lua中滚动到某个位置 index从1开始
        /// </summary>
        /// <param name="index"></param>
        /// <param name="speed"></param>
        /// <param name="pos">移动的位置 -1为左(上) 0为居中 1 为右(下) </param>
        public void ScrollToCellFromLua(int index, float speed, int pos = -1)
        {
            SrollToCell(index, speed, pos);
        }

        /// <summary>
        /// 刷新此loop绑定的GridLayoutGroup的constraintCount属性
        /// </summary>
        public void RefreshContentConstraintCount()
        {
            m_ContentConstraintCount = 1;
            if (content != null)
            {
                GridLayoutGroup layout2 = content.GetComponent<GridLayoutGroup>();
                if (layout2 != null)
                {
                    if (layout2.constraint == GridLayoutGroup.Constraint.Flexible)
                    {
                        LogWarning("[LoopScrollRect] Flexible not supported yet");
                    }

                    m_ContentConstraintCount = layout2.constraintCount;
                }
                // EasyLayout layout3 = content.GetComponent<EasyLayout>();
                // if (layout3 != null)
                // {
                //     m_ContentConstraintCount = layout3.ConstraintCount;
                // }
            }
        }

        protected void LogWarning(string message)
        {
            Debug.LogWarning(message + " , path: " + Ez.Core.TransformUtil.GetTransformPath(this.transform));
        }
    }
}