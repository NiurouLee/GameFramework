using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace NFramework.Module.UIModule.ScrollView
{

    [System.Serializable]
    public class ItemPrefabConfData
    {
        public GameObject mItemPrefab = null;
        public float mPadding = 0;
        public int mInitCreateCount = 0;
        public float mStartPosOffset = 0;
    }


    public class LoopListViewInitParam
    {
        // all the default values
        public float mDistanceForRecycle0 = 300; //mDistanceForRecycle0 should be larger than mDistanceForNew0
        public float mDistanceForNew0 = 200;
        public float mDistanceForRecycle1 = 300;//mDistanceForRecycle1 should be larger than mDistanceForNew1
        public float mDistanceForNew1 = 200;
        public float mSmoothDumpRate = 0.3f;
        public float mSnapFinishThreshold = 0.01f;
        public float mSnapVecThreshold = 145;
        public float mItemDefaultWithPaddingSize = 100;//item's default size (with padding)

        public static LoopListViewInitParam CopyDefaultInitParam()
        {
            return new LoopListViewInitParam();
        }
    }


    public struct ItemPosStruct
    {
        public int mItemIndex;
        public float mItemOffset;
    }


    public class LoopList : MonoBehaviour, IBeginDragHandler, IEndDragHandler, IDragHandler
    {

        class SnapData
        {
            public SnapStatus mSnapStatus = SnapStatus.NoTargetSet;
            public int mSnapTargetIndex = 0;
            public float mTargetSnapVal = 0;
            public float mCurSnapVal = 0;
            public bool mIsForceSnapTo = false;
            public bool mIsTempTarget = false;
            public int mTempTargetIndex = -1;
            public float mMoveMaxAbsVec = -1;
            public void Clear()
            {
                mSnapStatus = SnapStatus.NoTargetSet;
                mTempTargetIndex = -1;
                mIsForceSnapTo = false;
                mMoveMaxAbsVec = -1;
            }
        }

        Dictionary<string, LoopViewItemPool> mItemPoolDict = new Dictionary<string, LoopViewItemPool>();
        List<LoopViewItemPool> mItemPoolList = new List<LoopViewItemPool>();
        [SerializeField]
        List<ItemPrefabConfData> mItemPrefabDataList = new List<ItemPrefabConfData>();

        [SerializeField]
        private ListItemArrangeType mArrangeType = ListItemArrangeType.TopToBottom;
        public ListItemArrangeType ArrangeType { get { return mArrangeType; } set { mArrangeType = value; } }

        List<View> mItemList = new List<View>();
        RectTransform mContainerTrans;
        ScrollRect mScrollRect = null;
        RectTransform mScrollRectTransform = null;
        RectTransform mViewPortRectTransform = null;
        float mItemDefaultWithPaddingSize = 20;
        int mItemTotalCount = 0;
        bool mIsVertList = false;


        #region  Action

        //-------------must not null start----------------

        /// <summary>
        /// 1.初始化Item池
        /// </summary>
        public System.Action<List<ItemPrefabConfData>> mInitItemPool;
        /// <summary>
        /// 2.获取新Item
        /// </summary>
        public System.Func<int, Module.UIModule.View> mOnGetNewItemByDataIndex;
        /// <summary>
        /// 3.获取Item
        /// </summary>
        public System.Func<int, Module.UIModule.View> mOnGetItemByIndex;
        /// <summary>
        /// 4.获取Item索引
        /// </summary>
        public System.Func<Module.UIModule.View, int> mOnGetItemIndexByView;
        /// <summary>
        /// 5.回收Item temp
        /// </summary>
        public System.Action<Module.UIModule.View> mOnRecycleItemTemp;
        /// <summary>
        /// 6.回收Item Real
        /// </summary>
        public System.Action<Module.UIModule.View> mOnRecycleItemReal;
        /// <summary>
        /// 7.回收Item Immediately
        /// </summary>
        public System.Action<Module.UIModule.View> mOnRecycleItemImmediately;

        /// <summary>
        /// 8.清空所有临时回收的Item
        /// </summary>
        public System.Action mOnClearAllTmpRecycledItem;
        /// <summary>
        /// 9.获取Item起始位置偏移
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemStartPosOffset;
        /// <summary>
        /// 10.获取Item创建检查帧数
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemCreatedCheckFrameCount;
        /// <summary>
        /// 11.
        /// </summary>
        public System.Action<Module.UIModule.View, float> mOnSetItemCreatedCheckFrameCount;
        /// <summary>
        /// 12.获取Item大小
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemSize;
        /// <summary>
        /// 13.获取Item内边距
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemPadding;
        /// <summary>
        /// 14.获取Item大小（包含内边距）
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemSizeWithPadding;
        /// <summary>
        /// 15.获取Item与视口中心距离
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemTopY;
        /// <summary>
        /// 16.获取Item底部Y
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemBottomY;
        /// <summary>
        /// 17.获取Item左边X
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemRightX;
        /// <summary>
        /// 18.获取Item左边X
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemLeftX;

        /// <summary>
        /// 19.获取Item与视口中心距离
        /// </summary>
        public System.Func<Module.UIModule.View, float> mOnGetItemDistanceWithViewPortSnapCenter;

        /// <summary>
        /// 20.存储Item与视口中心距离
        /// </summary>
        public System.Action<Module.UIModule.View, float> mOnSetItemDistanceWithViewPortSnapCenter;


        //------------  end  ----------------------------
        public System.Action<LoopList> OnListViewStart = null;
        public System.Action<LoopList, Module.UIModule.View> mOnSnapItemFinished = null;
        public System.Action<LoopList, Module.UIModule.View> mOnSnapNearestChanged = null;
        public System.Action mOnBeginDragAction = null;
        public System.Action mOnDragingAction = null;
        public System.Action mOnEndDragAction = null;

        #endregion

        Vector3[] mItemWorldCorners = new Vector3[4];
        Vector3[] mViewPortRectLocalCorners = new Vector3[4];
        int mCurReadyMinItemIndex = 0;
        int mCurReadyMaxItemIndex = 0;
        bool mNeedCheckNextMinItem = true;
        bool mNeedCheckNextMaxItem = true;
        ItemPosMgr mItemPosMgr = null;
        float mDistanceForRecycle0 = 300;
        float mDistanceForNew0 = 200;
        float mDistanceForRecycle1 = 300;
        float mDistanceForNew1 = 200;
        [SerializeField]
        bool mSupportScrollBar = true;
        bool mIsDraging = false;
        PointerEventData mPointerEventData = null;
        int mLastItemIndex = 0;
        float mLastItemPadding = 0;
        float mSmoothDumpVel = 0;
        float mSmoothDumpRate = 0.3f;
        float mSnapFinishThreshold = 0.1f;
        float mSnapVecThreshold = 145;
        float mSnapMoveDefaultMaxAbsVec = 3400f;
        [SerializeField]
        bool mItemSnapEnable = false;
        Vector3 mLastFrameContainerPos = Vector3.zero;
        int mCurSnapNearestItemIndex = -1;
        Vector2 mAdjustedVec;
        bool mNeedAdjustVec = false;
        int mLeftSnapUpdateExtraCount = 1;
        [SerializeField]
        Vector2 mViewPortSnapPivot = Vector2.zero;
        [SerializeField]
        Vector2 mItemSnapPivot = Vector2.zero;
        ClickEventListener mScrollBarClickEventListener = null;
        SnapData mCurSnapData = new SnapData();
        Vector3 mLastSnapCheckPos = Vector3.zero;
        bool mListViewInited = false;
        int mListUpdateCheckFrameCount = 0;
        bool mIsPointerDownInScrollBar = false;
        bool mNeedReplaceScrollbarEventHandler = true;
        int mCurCreatingItemIndex = -1;

        public List<ItemPrefabConfData> ItemPrefabDataList
        {
            get
            {
                return mItemPrefabDataList;
            }
        }

        public List<View> ItemList
        {
            get
            {
                return mItemList;
            }
        }

        public bool IsVertList
        {
            get
            {
                return mIsVertList;
            }
        }
        public int ItemTotalCount
        {
            get
            {
                return mItemTotalCount;
            }
        }

        public RectTransform ContainerTrans
        {
            get
            {
                return mContainerTrans;
            }
        }

        public RectTransform ViewPortTrans
        {
            get
            {
                return mViewPortRectTransform;
            }
        }

        public ScrollRect ScrollRect
        {
            get
            {
                return mScrollRect;
            }
        }

        public bool IsDraging
        {
            get
            {
                return mIsDraging;
            }
        }

        public bool ItemSnapEnable
        {
            get { return mItemSnapEnable; }
            set { mItemSnapEnable = value; }
        }

        public bool SupportScrollBar
        {
            get { return mSupportScrollBar; }
            set { mSupportScrollBar = value; }
        }

        public float SnapMoveDefaultMaxAbsVec
        {
            get { return mSnapMoveDefaultMaxAbsVec; }
            set { mSnapMoveDefaultMaxAbsVec = value; }
        }

        public ItemPrefabConfData GetItemPrefabConfData(string prefabName)
        {
            foreach (ItemPrefabConfData data in mItemPrefabDataList)
            {
                if (data.mItemPrefab == null)
                {
                    Debug.LogError("A item prefab is null ");
                    continue;
                }
                if (prefabName == data.mItemPrefab.name)
                {
                    return data;
                }

            }
            return null;
        }

        /*
        InitListView method is to initiate the LoopListView2 component. There are 3 parameters:
        itemTotalCount: the total item count in the listview. If this parameter is set -1, then means there are infinite items, and scrollbar would not be supported, and the ItemIndex can be from –MaxInt to +MaxInt. If this parameter is set a value >=0 , then the ItemIndex can only be from 0 to itemTotalCount -1.
        onGetItemByIndex: when a item is getting in the scrollrect viewport, and this Action will be called with the item’ index as a parameter, to let you create the item and update its content.
        */
        public void InitListView(LoopListViewInitParam initParam = null)
        {
            if (initParam != null)
            {
                mDistanceForRecycle0 = initParam.mDistanceForRecycle0;
                mDistanceForNew0 = initParam.mDistanceForNew0;
                mDistanceForRecycle1 = initParam.mDistanceForRecycle1;
                mDistanceForNew1 = initParam.mDistanceForNew1;
                mSmoothDumpRate = initParam.mSmoothDumpRate;
                mSnapFinishThreshold = initParam.mSnapFinishThreshold;
                mSnapVecThreshold = initParam.mSnapVecThreshold;
                mItemDefaultWithPaddingSize = initParam.mItemDefaultWithPaddingSize;
            }
            mScrollRect = gameObject.GetComponent<ScrollRect>();
            mScrollRectTransform = mScrollRect.GetComponent<RectTransform>();

            if (mScrollRect == null)
            {
                Debug.LogError("ListView Init Failed! ScrollRect component not found!");
                return;
            }
            if (mDistanceForRecycle0 <= mDistanceForNew0)
            {
                Debug.LogError("mDistanceForRecycle0 should be bigger than mDistanceForNew0");
            }
            if (mDistanceForRecycle1 <= mDistanceForNew1)
            {
                Debug.LogError("mDistanceForRecycle1 should be bigger than mDistanceForNew1");
            }
            mCurSnapData.Clear();
            mItemPosMgr = new ItemPosMgr(mItemDefaultWithPaddingSize);
            mContainerTrans = mScrollRect.content;
            mViewPortRectTransform = mScrollRect.viewport;
            if (mViewPortRectTransform == null)
            {
                mViewPortRectTransform = mScrollRectTransform;
            }
            if (mScrollRect.horizontalScrollbarVisibility == ScrollRect.ScrollbarVisibility.AutoHideAndExpandViewport && mScrollRect.horizontalScrollbar != null)
            {
                Debug.LogError("ScrollRect.horizontalScrollbarVisibility cannot be set to AutoHideAndExpandViewport");
            }
            if (mScrollRect.verticalScrollbarVisibility == ScrollRect.ScrollbarVisibility.AutoHideAndExpandViewport && mScrollRect.verticalScrollbar != null)
            {
                Debug.LogError("ScrollRect.verticalScrollbarVisibility cannot be set to AutoHideAndExpandViewport");
            }
            mIsVertList = (mArrangeType == ListItemArrangeType.TopToBottom || mArrangeType == ListItemArrangeType.BottomToTop);
            if (mIsVertList)
            {
                mScrollRect.vertical = true;
            }
            else
            {
                mScrollRect.horizontal = true;
            }
            SetScrollbarListener();
            AdjustPivot(mViewPortRectTransform);
            AdjustAnchor(mContainerTrans);
            AdjustContainerPivot(mContainerTrans);
            InitItemPool();
            if (mListViewInited == true)
            {
                Debug.LogError("LoopListView2.InitListView method can be called only once.");
            }
            mListViewInited = true;
            ResetListView();
            mCurSnapData.Clear();
            if (mItemTotalCount < 0)
            {
                mSupportScrollBar = false;
            }
            if (mSupportScrollBar)
            {
                mItemPosMgr.SetItemMaxCount(mItemTotalCount);
            }
            else
            {
                mItemPosMgr.SetItemMaxCount(0);
            }
            if (mNeedReplaceScrollbarEventHandler && mSupportScrollBar)
            {
                ReplaceScrollbarEventHandlerForSmoothMove();
            }
            mCurReadyMaxItemIndex = 0;
            mCurReadyMinItemIndex = 0;
            mLeftSnapUpdateExtraCount = 1;
            mNeedCheckNextMaxItem = true;
            mNeedCheckNextMinItem = true;
            UpdateContentSize();
        }

        void Start()
        {
            if (OnListViewStart != null)
            {
                OnListViewStart(this);
            }
        }

        void SetScrollbarListener()
        {
            mScrollBarClickEventListener = null;
            Scrollbar curScrollBar = null;
            if (mIsVertList && mScrollRect.verticalScrollbar != null)
            {
                curScrollBar = mScrollRect.verticalScrollbar;

            }
            if (!mIsVertList && mScrollRect.horizontalScrollbar != null)
            {
                curScrollBar = mScrollRect.horizontalScrollbar;
            }
            if (curScrollBar == null)
            {
                return;
            }
            ClickEventListener listener = ClickEventListener.Get(curScrollBar.gameObject);
            mScrollBarClickEventListener = listener;
            listener.SetPointerUpHandler(OnPointerUpInScrollBar);
            listener.SetPointerDownHandler(OnPointerDownInScrollBar);
        }

        void OnPointerDownInScrollBar(GameObject obj)
        {
            mIsPointerDownInScrollBar = true;
            mCurSnapData.Clear();
        }

        void OnPointerUpInScrollBar(GameObject obj)
        {
            mIsPointerDownInScrollBar = false;
            ForceSnapUpdateCheck();
        }


        void ReplaceScrollbarEventHandlerForSmoothMove()
        {
            if (mIsVertList && mScrollRect.verticalScrollbar != null)
            {
                Scrollbar curScrollBar = mScrollRect.verticalScrollbar;
                curScrollBar.onValueChanged.RemoveAllListeners();
                curScrollBar.onValueChanged.AddListener(OnScrollBarValueChanged);
            }
            if (!mIsVertList && mScrollRect.horizontalScrollbar != null)
            {
                Scrollbar curScrollBar = mScrollRect.horizontalScrollbar;
                curScrollBar.onValueChanged.RemoveAllListeners();
                curScrollBar.onValueChanged.AddListener(OnScrollBarValueChanged);
            }
        }

        void OnScrollBarValueChanged(float value)
        {
            if (mIsPointerDownInScrollBar)
            {
                if (mIsVertList)
                {
                    mScrollRect.verticalNormalizedPosition = value;
                }
                else
                {
                    mScrollRect.horizontalNormalizedPosition = value;
                }

            }
        }


        public void ResetListView(bool resetPos = true)
        {
            mViewPortRectTransform.GetLocalCorners(mViewPortRectLocalCorners);
            if (resetPos)
            {
                mContainerTrans.anchoredPosition3D = Vector3.zero;
            }
            ForceSnapUpdateCheck();
        }


        /*
        This method may use to set the item total count of the scrollview at runtime. 
        If this parameter is set -1, then means there are infinite items,
        and scrollbar would not be supported, and the ItemIndex can be from –MaxInt to +MaxInt. 
        If this parameter is set a value >=0 , then the ItemIndex can only be from 0 to itemTotalCount -1.  
        If resetPos is set false, then the scrollrect’s content position will not changed after this method finished.
        */
        public void SetListItemCount(int itemCount, bool resetPos = true)
        {
            if (itemCount == mItemTotalCount)
            {
                return;
            }
            mCurSnapData.Clear();
            mItemTotalCount = itemCount;
            if (mItemTotalCount < 0)
            {
                mSupportScrollBar = false;
            }
            if (mSupportScrollBar)
            {
                mItemPosMgr.SetItemMaxCount(mItemTotalCount);
            }
            else
            {
                mItemPosMgr.SetItemMaxCount(0);
            }
            if (mItemTotalCount == 0)
            {
                mCurReadyMaxItemIndex = 0;
                mCurReadyMinItemIndex = 0;
                mNeedCheckNextMaxItem = false;
                mNeedCheckNextMinItem = false;
                mScrollRect.StopMovement();
                RecycleAllItem();
                ClearAllTmpRecycledItem();
                UpdateContentSize();
                if (IsVertList)
                {
                    SetAnchoredPositionY(mContainerTrans, 0f);
                }
                else
                {
                    SetAnchoredPositionX(mContainerTrans, 0f);
                }
                return;
            }
            if (mCurReadyMaxItemIndex >= mItemTotalCount)
            {
                mCurReadyMaxItemIndex = mItemTotalCount - 1;
            }
            mLeftSnapUpdateExtraCount = 1;
            mNeedCheckNextMaxItem = true;
            mNeedCheckNextMinItem = true;
            if (resetPos)
            {
                MovePanelToItemIndex(0, 0);
                return;
            }
            if (mItemList.Count == 0)
            {
                MovePanelToItemIndex(0, 0);
                return;
            }
            int maxItemIndex = mItemTotalCount - 1;
            var lastItem = mItemList[mItemList.Count - 1];
            int lastItemIndex = mOnGetItemIndexByView(lastItem);
            if (lastItemIndex <= maxItemIndex)
            {
                UpdateContentSize();
                UpdateAllShownItemsPos();
                return;
            }
            MovePanelToItemIndex(maxItemIndex, 0);

        }

        //To get the visible item by itemIndex. If the item is not visible, then this method return null.
        public View GetShownItemByItemIndex(int itemIndex)
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return null;
            }
            var _firstItem = mItemList[0];
            var _lastItem = mItemList[count - 1];
            var _firstItemIndex = mOnGetItemIndexByView(_firstItem);
            var _lastItemIndex = mOnGetItemIndexByView(_lastItem);
            if (itemIndex < _firstItemIndex || itemIndex > _lastItemIndex)
            {
                return null;
            }
            int i = itemIndex - _firstItemIndex;
            return mItemList[i];
        }


        public View GetShownItemNearestItemIndex(int itemIndex)
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return null;
            }
            var _firstItem = mItemList[0];
            var _firstItemIndex = mOnGetItemIndexByView(_firstItem);
            if (itemIndex < _firstItemIndex)
            {
                return mItemList[0];
            }
            var _lastItem = mItemList[count - 1];
            var _lastItemIndex = mOnGetItemIndexByView(_lastItem);
            if (itemIndex > _lastItemIndex)
            {
                return mItemList[count - 1];
            }
            int i = itemIndex - _firstItemIndex;
            return mItemList[i];
        }

        public int ShownItemCount
        {
            get
            {
                return mItemList.Count;
            }
        }

        public float ViewPortSize
        {
            get
            {
                if (mIsVertList)
                {
                    return mViewPortRectTransform.rect.height;
                }
                else
                {
                    return mViewPortRectTransform.rect.width;
                }
            }
        }

        public float ViewPortWidth
        {
            get { return mViewPortRectTransform.rect.width; }
        }
        public float ViewPortHeight
        {
            get { return mViewPortRectTransform.rect.height; }
        }


        /*
         All visible items is stored in a List<LoopListViewItem2> , which is named mItemList;
         this method is to get the visible item by the index in visible items list. The parameter index is from 0 to mItemList.Count.
        */
        public View GetShownItemByIndex(int index)
        {
            int count = mItemList.Count;
            if (index < 0 || index >= count)
            {
                return null;
            }
            return mItemList[index];
        }

        //directly set the value of the index'th shown item.
        public void SetShownItemByIndex(int index, View item)
        {
            int count = mItemList.Count;
            if (index < 0 || index >= count)
            {
                return;
            }
            View cur = mItemList[index];
            item.RectTransform.localEulerAngles = cur.RectTransform.localEulerAngles;
            item.RectTransform.localScale = cur.RectTransform.localScale;
            item.RectTransform.anchoredPosition3D = cur.RectTransform.anchoredPosition3D;
            mItemList[index] = item;
        }


        public View GetShownItemByIndexWithoutCheck(int index)
        {
            return mItemList[index];
        }

        public int GetIndexInShownItemList(View item)
        {
            if (item == null)
            {
                return -1;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return -1;
            }
            for (int i = 0; i < count; ++i)
            {
                if (mItemList[i] == item)
                {
                    return i;
                }
            }
            return -1;
        }


        public void DoActionForEachShownItem(System.Action<View, object> action, object param)
        {
            if (action == null)
            {
                return;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            for (int i = 0; i < count; ++i)
            {
                action(mItemList[i], param);
            }
        }


        public View NewListViewItem(string itemPrefabName)
        {
            LoopViewItemPool pool = null;
            if (mItemPoolDict.TryGetValue(itemPrefabName, out pool) == false)
            {
                return null;
            }
            View item = pool.GetItem(0);
            RectTransform rf = item.RectTransform;
            rf.SetParent(mContainerTrans);
            rf.localScale = Vector3.one;
            rf.anchoredPosition3D = Vector3.zero;
            rf.localEulerAngles = Vector3.zero;
            // item.ParentListView = this;
            return item;
        }

        /*
        For a vertical scrollrect, when a visible item’s height changed at runtime, then this method should be called to let the LoopListView2 component reposition all visible items’ position.
        For a horizontal scrollrect, when a visible item’s width changed at runtime, then this method should be called to let the LoopListView2 component reposition all visible items’ position.
        */
        public void OnItemSizeChanged(int itemIndex)
        {
            View item = GetShownItemByItemIndex(itemIndex);
            if (item == null)
            {
                return;
            }
            if (mSupportScrollBar)
            {
                var _itemPadding = mOnGetItemPadding(item);
                if (mIsVertList)
                {
                    SetItemSize(itemIndex, item.RectTransform.rect.height, _itemPadding);
                }
                else
                {
                    SetItemSize(itemIndex, item.RectTransform.rect.width, _itemPadding);
                }
            }
            UpdateContentSize();
            UpdateAllShownItemsPos();
        }


        /*
        To update a item by itemIndex.if the itemIndex-th item is not visible, then this method will do nothing.
        Otherwise this method will first call onGetItemByIndex(itemIndex) to get a updated item and then reposition all visible items'position. 
        */
        public void RefreshItemByItemIndex(int itemIndex)
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            var _firstItem = mItemList[0];
            var _lastItem = mItemList[count - 1];
            var _firstItemIndex = mOnGetItemIndexByView(_firstItem);
            var _lastItemIndex = mOnGetItemIndexByView(_lastItem);
            if (itemIndex < _firstItemIndex || itemIndex > _lastItemIndex)
            {
                return;
            }
            int i = itemIndex - _firstItemIndex;
            View curItem = mItemList[i];
            Vector3 pos = curItem.RectTransform.anchoredPosition3D;
            RecycleItemTmp(curItem);
            View newItem = GetNewItemByIndex(itemIndex);
            if (newItem == null)
            {
                RefreshAllShownItemWithFirstIndex(_firstItemIndex);
                return;
            }
            mItemList[i] = newItem;
            if (mIsVertList)
            {
                pos.x = mOnGetItemStartPosOffset(newItem);
            }
            else
            {
                pos.y = mOnGetItemStartPosOffset(newItem);
            }
            newItem.RectTransform.anchoredPosition3D = pos;
            OnItemSizeChanged(itemIndex);
            ClearAllTmpRecycledItem();
        }

        //snap move will finish at once.
        public void FinishSnapImmediately()
        {
            UpdateSnapMove(true);
        }

        /*
        This method will move the scrollrect content’s position to ( the positon of itemIndex-th item + offset ),
        and offset is from 0 to scrollrect viewport size. 
        */
        public void MovePanelToItemIndex(int itemIndex, float offset)
        {
            mScrollRect.StopMovement();
            mCurSnapData.Clear();
            if (mItemTotalCount == 0)
            {
                return;
            }
            if (itemIndex < 0 && mItemTotalCount > 0)
            {
                return;
            }
            if (mItemTotalCount > 0 && itemIndex >= mItemTotalCount)
            {
                itemIndex = mItemTotalCount - 1;
            }
            Vector3 pos = Vector3.zero;
            float viewPortSize = ViewPortSize;
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                float containerPos = mContainerTrans.anchoredPosition3D.y;
                if (containerPos < 0)
                {
                    containerPos = 0;
                }
                pos.y = -containerPos - offset;
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                float containerPos = mContainerTrans.anchoredPosition3D.y;
                if (containerPos > 0)
                {
                    containerPos = 0;
                }
                pos.y = -containerPos + offset;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                float containerPos = mContainerTrans.anchoredPosition3D.x;
                if (containerPos > 0)
                {
                    containerPos = 0;
                }
                pos.x = -containerPos + offset;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                float containerPos = mContainerTrans.anchoredPosition3D.x;
                if (containerPos < 0)
                {
                    containerPos = 0;
                }
                pos.x = -containerPos - offset;
            }

            RecycleAllItem();
            View newItem = GetNewItemByIndex(itemIndex);
            if (newItem == null)
            {
                ClearAllTmpRecycledItem();
                return;
            }
            if (mIsVertList)
            {
                pos.x = mOnGetItemStartPosOffset(newItem);
            }
            else
            {
                pos.y = mOnGetItemStartPosOffset(newItem);
            }
            newItem.RectTransform.anchoredPosition3D = pos;
            if (mSupportScrollBar)
            {
                var _itemPadding = mOnGetItemPadding(newItem);
                if (mIsVertList)
                {
                    SetItemSize(itemIndex, newItem.RectTransform.rect.height, _itemPadding);
                }
                else
                {
                    SetItemSize(itemIndex, newItem.RectTransform.rect.width, _itemPadding);
                }
            }
            mItemList.Add(newItem);
            UpdateContentSize();
            UpdateListView(viewPortSize + 100, viewPortSize + 100, viewPortSize, viewPortSize);
            AdjustPanelPos();
            ClearAllTmpRecycledItem();
            ForceSnapUpdateCheck();
            UpdateSnapMove(false, true);
        }

        //update all visible items.
        public void RefreshAllShownItem()
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            var _firstItem = mItemList[0];
            var _firstItemIndex = mOnGetItemIndexByView(_firstItem);
            RefreshAllShownItemWithFirstIndex(_firstItemIndex);
        }

        /*
       This method will move the scrollrect content’s position by the offset value.
       For a vertical listview, the offset would move the anchoredPosition3D.y.
       For a horizonal listview, the offset would move the anchoredPosition3D.x.
       */
        public void MovePanelByOffset(float offset)
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            if (offset == 0)
            {
                return;
            }
            float viewPortSize = ViewPortSize;
            float contentSize = GetContentPanelSize();
            float d = contentSize - viewPortSize;
            if (d <= 0)
            {
                return;
            }
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                Vector3 pos = mContainerTrans.anchoredPosition3D;
                pos.y = pos.y + offset;
                pos.y = Mathf.Clamp(pos.y, 0, d);
                mContainerTrans.anchoredPosition3D = pos;
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                Vector3 pos = mContainerTrans.anchoredPosition3D;
                pos.y = pos.y + offset;
                pos.y = Mathf.Clamp(pos.y, -d, 0);
                mContainerTrans.anchoredPosition3D = pos;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                Vector3 pos = mContainerTrans.anchoredPosition3D;
                pos.x = pos.x + offset;
                pos.x = Mathf.Clamp(pos.x, -d, 0);
                mContainerTrans.anchoredPosition3D = pos;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                Vector3 pos = mContainerTrans.anchoredPosition3D;
                pos.x = pos.x + offset;
                pos.x = Mathf.Clamp(pos.x, 0, d);
                mContainerTrans.anchoredPosition3D = pos;
            }

        }


        //get the itemIndex and the offset of the first shown item.
        public ItemPosStruct GetFirstShownItemIndexAndOffset()
        {
            ItemPosStruct ret = new ItemPosStruct();
            ret.mItemIndex = 0;
            ret.mItemOffset = 0;
            int count = mItemList.Count;
            if (count == 0)
            {
                return ret;
            }
            Vector3[] viewPortWorldCorners = new Vector3[4];
            ViewPortTrans.GetWorldCorners(viewPortWorldCorners);

            if (ArrangeType == ListItemArrangeType.TopToBottom)
            {
                float viewPortTopY = ContainerTrans.InverseTransformPoint(viewPortWorldCorners[1]).y;
                View item = mItemList[0];
                var _itemIndex = mOnGetItemIndexByView(item);
                ret.mItemIndex = _itemIndex;
                ret.mItemOffset = viewPortTopY - mOnGetItemTopY(item);

            }
            else if (ArrangeType == ListItemArrangeType.BottomToTop)
            {
                float viewPortBottomY = ContainerTrans.InverseTransformPoint(viewPortWorldCorners[0]).y;
                View item = mItemList[0];
                var _itemIndex = mOnGetItemIndexByView(item);
                ret.mItemIndex = _itemIndex;
                ret.mItemOffset = mOnGetItemBottomY(item) - viewPortBottomY;

            }
            else if (ArrangeType == ListItemArrangeType.LeftToRight)
            {
                float viewPortLeftX = ContainerTrans.InverseTransformPoint(viewPortWorldCorners[1]).x;
                View item = mItemList[0];
                var _itemIndex = mOnGetItemIndexByView(item);
                ret.mItemIndex = _itemIndex;
                ret.mItemOffset = mOnGetItemLeftX(item) - viewPortLeftX;

            }
            else if (ArrangeType == ListItemArrangeType.RightToLeft)
            {
                float viewPortRightX = ContainerTrans.InverseTransformPoint(viewPortWorldCorners[2]).x;
                View item = mItemList[0];
                var _itemIndex = mOnGetItemIndexByView(item);
                ret.mItemIndex = _itemIndex;
                ret.mItemOffset = viewPortRightX - mOnGetItemRightX(item);
            }
            return ret;

        }


        public void RefreshAllShownItemWithFirstIndex(int firstItemIndex)
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            View firstItem = mItemList[0];
            Vector3 pos = firstItem.RectTransform.anchoredPosition3D;
            RecycleAllItem();
            for (int i = 0; i < count; ++i)
            {
                int curIndex = firstItemIndex + i;
                View newItem = GetNewItemByIndex(curIndex);
                if (newItem == null)
                {
                    break;
                }
                if (mIsVertList)
                {
                    pos.x = mOnGetItemStartPosOffset(newItem);
                }
                else
                {
                    pos.y = mOnGetItemStartPosOffset(newItem);
                }
                newItem.RectTransform.anchoredPosition3D = pos;
                if (mSupportScrollBar)
                {
                    var _itemPadding = mOnGetItemPadding(newItem);
                    if (mIsVertList)
                    {
                        SetItemSize(curIndex, newItem.RectTransform.rect.height, _itemPadding);
                    }
                    else
                    {
                        SetItemSize(curIndex, newItem.RectTransform.rect.width, _itemPadding);
                    }
                }

                mItemList.Add(newItem);
            }
            UpdateContentSize();
            UpdateAllShownItemsPos();
            ClearAllTmpRecycledItem();
        }


        public void RefreshAllShownItemWithFirstIndexAndPos(int firstItemIndex, Vector3 pos)
        {
            RecycleAllItem();
            View newItem = GetNewItemByIndex(firstItemIndex);
            if (newItem == null)
            {
                return;
            }
            if (mIsVertList)
            {
                pos.x = mOnGetItemStartPosOffset(newItem);
            }
            else
            {
                pos.y = mOnGetItemStartPosOffset(newItem);
            }
            newItem.RectTransform.anchoredPosition3D = pos;
            if (mSupportScrollBar)
            {
                var _itemPadding = mOnGetItemPadding(newItem);
                if (mIsVertList)
                {
                    SetItemSize(firstItemIndex, newItem.RectTransform.rect.height, _itemPadding);
                }
                else
                {
                    SetItemSize(firstItemIndex, newItem.RectTransform.rect.width, _itemPadding);
                }
            }
            mItemList.Add(newItem);
            UpdateContentSize();
            UpdateAllShownItemsPos();
            UpdateListView(mDistanceForRecycle0, mDistanceForRecycle1, mDistanceForNew0, mDistanceForNew1);
            ClearAllTmpRecycledItem();
        }

        public void RecycleItemImmediately(View item)
        {
            if (item == null)
            {
                return;
            }
            this.mOnRecycleItemImmediately(item);

        }

        void RecycleItemTmp(View item)
        {
            mOnRecycleItemTemp(item);

        }

        void ClearAllTmpRecycledItem()
        {
            this.mOnClearAllTmpRecycledItem();
        }

        void RecycleAllItem()
        {
            foreach (View item in mItemList)
            {
                mOnRecycleItemTemp(item);
                RecycleItemTmp(item);
            }
            mItemList.Clear();
        }


        void AdjustContainerPivot(RectTransform rtf)
        {
            Vector2 pivot = rtf.pivot;
            if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                pivot.y = 0;
            }
            else if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                pivot.y = 1;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                pivot.x = 0;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                pivot.x = 1;
            }
            rtf.pivot = pivot;
        }


        public void AdjustPivot(RectTransform rtf)
        {
            Vector2 pivot = rtf.pivot;

            if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                pivot.y = 0;
            }
            else if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                pivot.y = 1;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                pivot.x = 0;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                pivot.x = 1;
            }
            rtf.pivot = pivot;
        }

        void AdjustContainerAnchor(RectTransform rtf)
        {
            Vector2 anchorMin = rtf.anchorMin;
            Vector2 anchorMax = rtf.anchorMax;
            if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                anchorMin.y = 0;
                anchorMax.y = 0;
            }
            else if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                anchorMin.y = 1;
                anchorMax.y = 1;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                anchorMin.x = 0;
                anchorMax.x = 0;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                anchorMin.x = 1;
                anchorMax.x = 1;
            }
            rtf.anchorMin = anchorMin;
            rtf.anchorMax = anchorMax;
        }


        public void AdjustAnchor(RectTransform rtf)
        {
            Vector2 anchorMin = rtf.anchorMin;
            Vector2 anchorMax = rtf.anchorMax;
            if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                anchorMin.y = 0;
                anchorMax.y = 0;
            }
            else if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                anchorMin.y = 1;
                anchorMax.y = 1;
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                anchorMin.x = 0;
                anchorMax.x = 0;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                anchorMin.x = 1;
                anchorMax.x = 1;
            }
            rtf.anchorMin = anchorMin;
            rtf.anchorMax = anchorMax;
        }

        void InitItemPool()
        {
            mInitItemPool(mItemPrefabDataList);
        }


        public virtual void OnBeginDrag(PointerEventData eventData)
        {
            if (eventData.button != PointerEventData.InputButton.Left)
            {
                return;
            }
            mIsDraging = true;
            CacheDragPointerEventData(eventData);
            mCurSnapData.Clear();
            if (mOnBeginDragAction != null)
            {
                mOnBeginDragAction();
            }
        }

        public virtual void OnEndDrag(PointerEventData eventData)
        {
            if (eventData.button != PointerEventData.InputButton.Left)
            {
                return;
            }
            mIsDraging = false;
            mPointerEventData = null;
            if (mOnEndDragAction != null)
            {
                mOnEndDragAction();
            }
            ForceSnapUpdateCheck();
        }

        public virtual void OnDrag(PointerEventData eventData)
        {
            if (eventData.button != PointerEventData.InputButton.Left)
            {
                return;
            }
            CacheDragPointerEventData(eventData);
            if (mOnDragingAction != null)
            {
                mOnDragingAction();
            }
        }

        void CacheDragPointerEventData(PointerEventData eventData)
        {
            if (mPointerEventData == null)
            {
                mPointerEventData = new PointerEventData(EventSystem.current);
            }
            mPointerEventData.button = eventData.button;
            mPointerEventData.position = eventData.position;
            mPointerEventData.pointerPressRaycast = eventData.pointerPressRaycast;
            mPointerEventData.pointerCurrentRaycast = eventData.pointerCurrentRaycast;
        }

        View GetNewItemByIndex(int index)
        {
            if (mSupportScrollBar && index < 0)
            {
                return null;
            }
            if (mItemTotalCount > 0 && index >= mItemTotalCount)
            {
                return null;
            }
            var newItem = mOnGetNewItemByDataIndex(index);
            if (newItem == null)
            {
                return null;
            }
            this.mOnSetItemCreatedCheckFrameCount(newItem, mListUpdateCheckFrameCount);
            return newItem;
        }


        void SetItemSize(int itemIndex, float itemSize, float padding)
        {
            mItemPosMgr.SetItemSize(itemIndex, itemSize + padding);
            if (itemIndex >= mLastItemIndex)
            {
                mLastItemIndex = itemIndex;
                mLastItemPadding = padding;
            }
        }

        bool GetPlusItemIndexAndPosAtGivenPos(float pos, ref int index, ref float itemPos)
        {
            return mItemPosMgr.GetItemIndexAndPosAtGivenPos(pos, ref index, ref itemPos);
        }


        float GetItemPos(int itemIndex)
        {
            return mItemPosMgr.GetItemPos(itemIndex);
        }


        public Vector3 GetItemCornerPosInViewPort(View item, ItemCornerEnum corner = ItemCornerEnum.LeftBottom)
        {
            item.RectTransform.GetWorldCorners(mItemWorldCorners);
            return mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[(int)corner]);
        }


        void AdjustPanelPos()
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            UpdateAllShownItemsPos();
            float viewPortSize = ViewPortSize;
            float contentSize = GetContentPanelSize();
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                if (contentSize <= viewPortSize)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.y = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, 0, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                if (topPos0.y < mViewPortRectLocalCorners[1].y)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.y = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, 0, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 downPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                float d = downPos1.y - mViewPortRectLocalCorners[0].y;
                if (d > 0)
                {
                    Vector3 pos = mItemList[0].RectTransform.anchoredPosition3D;
                    pos.y = pos.y - d;
                    mItemList[0].RectTransform.anchoredPosition3D = pos;
                    UpdateAllShownItemsPos();
                    return;
                }
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                if (contentSize <= viewPortSize)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.y = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, 0, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 downPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                if (downPos0.y > mViewPortRectLocalCorners[0].y)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.y = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, 0, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                float d = mViewPortRectLocalCorners[1].y - topPos1.y;
                if (d > 0)
                {
                    Vector3 pos = mItemList[0].RectTransform.anchoredPosition3D;
                    pos.y = pos.y + d;
                    mItemList[0].RectTransform.anchoredPosition3D = pos;
                    UpdateAllShownItemsPos();
                    return;
                }
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                if (contentSize <= viewPortSize)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.x = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(0, _startPosOffset, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                if (leftPos0.x > mViewPortRectLocalCorners[1].x)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.x = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(0, _startPosOffset, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 rightPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                float d = mViewPortRectLocalCorners[2].x - rightPos1.x;
                if (d > 0)
                {
                    Vector3 pos = mItemList[0].RectTransform.anchoredPosition3D;
                    pos.x = pos.x + d;
                    mItemList[0].RectTransform.anchoredPosition3D = pos;
                    UpdateAllShownItemsPos();
                    return;
                }
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                if (contentSize <= viewPortSize)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.x = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(0, _startPosOffset, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 rightPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                if (rightPos0.x < mViewPortRectLocalCorners[2].x)
                {
                    Vector3 pos = mContainerTrans.anchoredPosition3D;
                    pos.x = 0;
                    mContainerTrans.anchoredPosition3D = pos;
                    var _startPosOffset = mOnGetItemStartPosOffset(mItemList[0]);
                    mItemList[0].RectTransform.anchoredPosition3D = new Vector3(0, _startPosOffset, 0);
                    UpdateAllShownItemsPos();
                    return;
                }
                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                float d = leftPos1.x - mViewPortRectLocalCorners[1].x;
                if (d > 0)
                {
                    Vector3 pos = mItemList[0].RectTransform.anchoredPosition3D;
                    pos.x = pos.x - d;
                    mItemList[0].RectTransform.anchoredPosition3D = pos;
                    UpdateAllShownItemsPos();
                    return;
                }
            }



        }


        void Update()
        {
            if (mListViewInited == false)
            {
                return;
            }
            if (mNeedAdjustVec)
            {
                mNeedAdjustVec = false;
                if (mIsVertList)
                {
                    if (mScrollRect.velocity.y * mAdjustedVec.y > 0)
                    {
                        mScrollRect.velocity = mAdjustedVec;
                    }
                }
                else
                {
                    if (mScrollRect.velocity.x * mAdjustedVec.x > 0)
                    {
                        mScrollRect.velocity = mAdjustedVec;
                    }
                }

            }
            if (mSupportScrollBar)
            {
                mItemPosMgr.Update(false);
            }
            UpdateSnapMove();
            UpdateListView(mDistanceForRecycle0, mDistanceForRecycle1, mDistanceForNew0, mDistanceForNew1);
            ClearAllTmpRecycledItem();
            mLastFrameContainerPos = mContainerTrans.anchoredPosition3D;
        }

        //update snap move. if immediate is set true, then the snap move will finish at once.
        void UpdateSnapMove(bool immediate = false, bool forceSendEvent = false)
        {
            if (mItemSnapEnable == false)
            {
                return;
            }
            if (mIsVertList)
            {
                UpdateSnapVertical(immediate, forceSendEvent);
            }
            else
            {
                UpdateSnapHorizontal(immediate, forceSendEvent);
            }
        }



        public void UpdateAllShownItemSnapData()
        {
            if (mItemSnapEnable == false)
            {
                return;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            Vector3 pos = mContainerTrans.anchoredPosition3D;
            View tViewItem0 = mItemList[0];
            tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
            float start = 0;
            float end = 0;
            float itemSnapCenter = 0;
            float snapCenter = 0;
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                snapCenter = -(1 - mViewPortSnapPivot.y) * mViewPortRectTransform.rect.height;
                Vector3 topPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                start = topPos1.y;
                end = start - mOnGetItemSizeWithPadding(tViewItem0);
                var size = this.mOnGetItemSize(tViewItem0);
                itemSnapCenter = start - size * (1 - mItemSnapPivot.y);
                for (int i = 0; i < count; ++i)
                {
                    var _item = mItemList[i];
                    var _distanceWithViewPortSnapCenter = snapCenter - itemSnapCenter;
                    mOnSetItemDistanceWithViewPortSnapCenter(_item, _distanceWithViewPortSnapCenter);
                    if ((i + 1) < count)
                    {
                        start = end;
                        end = end - mOnGetItemSizeWithPadding(mItemList[i + 1]);
                        var item1 = mItemList[i + 1];
                        var size1 = this.mOnGetItemSize(item1);
                        itemSnapCenter = start - size1 * (1 - mItemSnapPivot.y);
                    }
                }
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                snapCenter = mViewPortSnapPivot.y * mViewPortRectTransform.rect.height;
                Vector3 bottomPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                start = bottomPos1.y;
                end = start + mOnGetItemSizeWithPadding(tViewItem0);
                var size = this.mOnGetItemSize(tViewItem0);
                itemSnapCenter = start + size * mItemSnapPivot.y;
                for (int i = 0; i < count; ++i)
                {
                    var _item = mItemList[i];
                    var _distanceWithViewPortSnapCenter = snapCenter - itemSnapCenter;
                    mOnSetItemDistanceWithViewPortSnapCenter(_item, _distanceWithViewPortSnapCenter);
                    if ((i + 1) < count)
                    {
                        start = end;
                        end = end + mOnGetItemSizeWithPadding(mItemList[i + 1]);
                        var item1 = mItemList[i + 1];
                        var size1 = this.mOnGetItemSize(item1);
                        itemSnapCenter = start + size1 * mItemSnapPivot.y;
                    }
                }
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                snapCenter = -(1 - mViewPortSnapPivot.x) * mViewPortRectTransform.rect.width;
                Vector3 rightPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                start = rightPos1.x;
                end = start - mOnGetItemSizeWithPadding(tViewItem0);
                var size = this.mOnGetItemSize(tViewItem0);
                itemSnapCenter = start - size * (1 - mItemSnapPivot.x);
                for (int i = 0; i < count; ++i)
                {
                    var _item = mItemList[i];
                    var _distanceWithViewPortSnapCenter = snapCenter - itemSnapCenter;
                    mOnSetItemDistanceWithViewPortSnapCenter(_item, _distanceWithViewPortSnapCenter);
                    if ((i + 1) < count)
                    {
                        start = end;
                        var item1 = mItemList[i + 1];
                        end = end - mOnGetItemSizeWithPadding(item1);
                        var size1 = this.mOnGetItemSize(item1);
                        itemSnapCenter = start - size1 * (1 - mItemSnapPivot.x);
                    }
                }
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                snapCenter = mViewPortSnapPivot.x * mViewPortRectTransform.rect.width;
                Vector3 leftPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                start = leftPos1.x;
                end = start + mOnGetItemSizeWithPadding(tViewItem0);
                var size = this.mOnGetItemSize(tViewItem0);
                itemSnapCenter = start + size * mItemSnapPivot.x;
                for (int i = 0; i < count; ++i)
                {
                    var _item = mItemList[i];
                    var _distanceWithViewPortSnapCenter = snapCenter - itemSnapCenter;
                    mOnSetItemDistanceWithViewPortSnapCenter(_item, _distanceWithViewPortSnapCenter);
                    if ((i + 1) < count)
                    {
                        start = end;
                        var item1 = mItemList[i + 1];
                        end = end + mOnGetItemSizeWithPadding(item1);
                        var size1 = this.mOnGetItemSize(item1);
                        itemSnapCenter = start + size1 * mItemSnapPivot.x;
                    }
                }
            }
        }



        void UpdateSnapVertical(bool immediate = false, bool forceSendEvent = false)
        {
            if (mItemSnapEnable == false)
            {
                return;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            Vector3 pos = mContainerTrans.anchoredPosition3D;
            bool needCheck = (pos.y != mLastSnapCheckPos.y);
            mLastSnapCheckPos = pos;
            if (!needCheck)
            {
                if (mLeftSnapUpdateExtraCount > 0)
                {
                    mLeftSnapUpdateExtraCount--;
                    needCheck = true;
                }
            }
            if (needCheck)
            {
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                int curIndex = -1;
                float start = 0;
                float end = 0;
                float itemSnapCenter = 0;
                float curMinDist = float.MaxValue;
                float curDist = 0;
                float curDistAbs = 0;
                float snapCenter = 0;
                if (mArrangeType == ListItemArrangeType.TopToBottom)
                {
                    snapCenter = -(1 - mViewPortSnapPivot.y) * mViewPortRectTransform.rect.height;
                    Vector3 topPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                    start = topPos1.y;
                    end = start - mOnGetItemSizeWithPadding(tViewItem0);
                    var size = this.mOnGetItemSize(tViewItem0);
                    itemSnapCenter = start - size * (1 - mItemSnapPivot.y);
                    for (int i = 0; i < count; ++i)
                    {
                        curDist = snapCenter - itemSnapCenter;
                        curDistAbs = Mathf.Abs(curDist);
                        if (curDistAbs < curMinDist)
                        {
                            curMinDist = curDistAbs;
                            curIndex = i;
                        }
                        else
                        {
                            break;
                        }

                        if ((i + 1) < count)
                        {
                            start = end;
                            var item1 = mItemList[i + 1];
                            end = end - mOnGetItemSizeWithPadding(item1);
                            var size1 = this.mOnGetItemSize(item1);
                            itemSnapCenter = start - size1 * (1 - mItemSnapPivot.y);
                        }
                    }
                }
                else if (mArrangeType == ListItemArrangeType.BottomToTop)
                {
                    snapCenter = mViewPortSnapPivot.y * mViewPortRectTransform.rect.height;
                    Vector3 bottomPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                    start = bottomPos1.y;
                    end = start + mOnGetItemSizeWithPadding(tViewItem0);
                    var size = this.mOnGetItemSize(tViewItem0);
                    itemSnapCenter = start + size * mItemSnapPivot.y;
                    for (int i = 0; i < count; ++i)
                    {
                        curDist = snapCenter - itemSnapCenter;
                        curDistAbs = Mathf.Abs(curDist);
                        if (curDistAbs < curMinDist)
                        {
                            curMinDist = curDistAbs;
                            curIndex = i;
                        }
                        else
                        {
                            break;
                        }

                        if ((i + 1) < count)
                        {
                            start = end;
                            var item1 = mItemList[i + 1];
                            end = end + mOnGetItemSizeWithPadding(item1);
                            var size1 = this.mOnGetItemSize(item1);
                            itemSnapCenter = start + size1 * mItemSnapPivot.y;
                        }
                    }
                }

                if (curIndex >= 0)
                {
                    int oldNearestItemIndex = mCurSnapNearestItemIndex;
                    var _item = mItemList[curIndex];
                    var _itemIndex = mOnGetItemIndexByView(_item);
                    mCurSnapNearestItemIndex = _itemIndex;
                    if (forceSendEvent || _itemIndex != oldNearestItemIndex)
                    {
                        if (mOnSnapNearestChanged != null)
                        {
                            mOnSnapNearestChanged(this, mItemList[curIndex]);
                        }
                    }
                }
                else
                {
                    mCurSnapNearestItemIndex = -1;
                }
            }
            if (CanSnap() == false)
            {
                ClearSnapData();
                return;
            }
            float v = Mathf.Abs(mScrollRect.velocity.y);
            UpdateCurSnapData();
            if (mCurSnapData.mSnapStatus != SnapStatus.SnapMoving)
            {
                return;
            }
            if (v > 0)
            {
                mScrollRect.StopMovement();
            }
            float old = mCurSnapData.mCurSnapVal;
            if (mCurSnapData.mIsTempTarget == false)
            {
                if (mSmoothDumpVel * mCurSnapData.mTargetSnapVal < 0)
                {
                    mSmoothDumpVel = 0;
                }
                mCurSnapData.mCurSnapVal = Mathf.SmoothDamp(mCurSnapData.mCurSnapVal, mCurSnapData.mTargetSnapVal, ref mSmoothDumpVel, mSmoothDumpRate);
            }
            else
            {
                float maxAbsVec = mCurSnapData.mMoveMaxAbsVec;
                if (maxAbsVec <= 0)
                {
                    maxAbsVec = mSnapMoveDefaultMaxAbsVec;
                }
                mSmoothDumpVel = maxAbsVec * Mathf.Sign(mCurSnapData.mTargetSnapVal);
                mCurSnapData.mCurSnapVal = Mathf.MoveTowards(mCurSnapData.mCurSnapVal, mCurSnapData.mTargetSnapVal, maxAbsVec * UnityEngine.Time.deltaTime);
            }
            float dt = mCurSnapData.mCurSnapVal - old;

            if (immediate || Mathf.Abs(mCurSnapData.mTargetSnapVal - mCurSnapData.mCurSnapVal) < mSnapFinishThreshold)
            {
                pos.y = pos.y + mCurSnapData.mTargetSnapVal - old;
                mCurSnapData.mSnapStatus = SnapStatus.SnapMoveFinish;
                if (mOnSnapItemFinished != null)
                {
                    View targetItem = GetShownItemByItemIndex(mCurSnapNearestItemIndex);
                    if (targetItem != null)
                    {
                        mOnSnapItemFinished(this, targetItem);
                    }
                }
            }
            else
            {
                pos.y = pos.y + dt;
            }

            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                float maxY = mViewPortRectLocalCorners[0].y + mContainerTrans.rect.height;
                pos.y = Mathf.Clamp(pos.y, 0, maxY);
                mContainerTrans.anchoredPosition3D = pos;
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                float minY = mViewPortRectLocalCorners[1].y - mContainerTrans.rect.height;
                pos.y = Mathf.Clamp(pos.y, minY, 0);
                mContainerTrans.anchoredPosition3D = pos;
            }

        }

        void UpdateCurSnapData()
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                mCurSnapData.Clear();
                return;
            }

            if (mCurSnapData.mSnapStatus == SnapStatus.SnapMoveFinish)
            {
                if (mCurSnapData.mSnapTargetIndex == mCurSnapNearestItemIndex)
                {
                    return;
                }
                mCurSnapData.mSnapStatus = SnapStatus.NoTargetSet;
            }
            if (mCurSnapData.mSnapStatus == SnapStatus.SnapMoving)
            {
                if (mCurSnapData.mIsForceSnapTo)
                {
                    if (mCurSnapData.mIsTempTarget == true)
                    {
                        View targetItem = GetShownItemNearestItemIndex(mCurSnapData.mSnapTargetIndex);
                        if (targetItem == null)
                        {
                            mCurSnapData.Clear();
                            return;
                        }
                        var _targetItemIndex = mOnGetItemIndexByView(targetItem);
                        if (_targetItemIndex == mCurSnapData.mSnapTargetIndex)
                        {
                            UpdateAllShownItemSnapData();
                            var _distanceWithViewPortSnapCenter = mOnGetItemDistanceWithViewPortSnapCenter(targetItem);
                            mCurSnapData.mTargetSnapVal = _distanceWithViewPortSnapCenter;
                            mCurSnapData.mCurSnapVal = 0;
                            mCurSnapData.mIsTempTarget = false;
                            mCurSnapData.mSnapStatus = SnapStatus.SnapMoving;
                            return;
                        }
                        if (mCurSnapData.mTempTargetIndex != _targetItemIndex)
                        {
                            UpdateAllShownItemSnapData();
                            var _distanceWithViewPortSnapCenter = mOnGetItemDistanceWithViewPortSnapCenter(targetItem);
                            mCurSnapData.mTargetSnapVal = _distanceWithViewPortSnapCenter;
                            mCurSnapData.mCurSnapVal = 0;
                            mCurSnapData.mSnapStatus = SnapStatus.SnapMoving;
                            mCurSnapData.mIsTempTarget = true;
                            mCurSnapData.mTempTargetIndex = _targetItemIndex;
                            return;
                        }
                    }
                    return;
                }
                if ((mCurSnapData.mSnapTargetIndex == mCurSnapNearestItemIndex))
                {
                    return;
                }
                mCurSnapData.mSnapStatus = SnapStatus.NoTargetSet;
            }
            if (mCurSnapData.mSnapStatus == SnapStatus.NoTargetSet)
            {
                View nearestItem = GetShownItemByItemIndex(mCurSnapNearestItemIndex);
                if (nearestItem == null)
                {
                    return;
                }
                mCurSnapData.mSnapTargetIndex = mCurSnapNearestItemIndex;
                mCurSnapData.mSnapStatus = SnapStatus.TargetHasSet;
                mCurSnapData.mIsForceSnapTo = false;
            }
            if (mCurSnapData.mSnapStatus == SnapStatus.TargetHasSet)
            {
                View targetItem = GetShownItemNearestItemIndex(mCurSnapData.mSnapTargetIndex);
                var _targetItemIndex = mOnGetItemIndexByView(targetItem);
                if (targetItem == null)
                {
                    mCurSnapData.Clear();
                    return;
                }
                if (_targetItemIndex == mCurSnapData.mSnapTargetIndex)
                {
                    UpdateAllShownItemSnapData();
                    var _distanceWithViewPortSnapCenter = mOnGetItemDistanceWithViewPortSnapCenter(targetItem);
                    mCurSnapData.mTargetSnapVal = _distanceWithViewPortSnapCenter;
                    mCurSnapData.mCurSnapVal = 0;
                    mCurSnapData.mIsTempTarget = false;
                    mCurSnapData.mSnapStatus = SnapStatus.SnapMoving;
                }
                else
                {
                    UpdateAllShownItemSnapData();
                    var _distanceWithViewPortSnapCenter = mOnGetItemDistanceWithViewPortSnapCenter(targetItem);
                    mCurSnapData.mTargetSnapVal = _distanceWithViewPortSnapCenter;
                    mCurSnapData.mCurSnapVal = 0;
                    mCurSnapData.mSnapStatus = SnapStatus.SnapMoving;
                    mCurSnapData.mIsTempTarget = true;
                    mCurSnapData.mTempTargetIndex = _targetItemIndex;
                }

            }

        }
        //Clear current snap target and then the LoopScrollView2 will auto snap to the CurSnapNearestItemIndex.
        public void ClearSnapData()
        {
            mCurSnapData.Clear();
        }

        //moveMaxAbsVec param is the max abs snap move speed, if the value <= 0 then LoopListView2 would use SnapMoveDefaultMaxAbsVec
        public void SetSnapTargetItemIndex(int itemIndex, float moveMaxAbsVec = -1)
        {
            if (mItemTotalCount > 0)
            {
                if (itemIndex >= mItemTotalCount)
                {
                    itemIndex = mItemTotalCount - 1;
                }
                if (itemIndex < 0)
                {
                    itemIndex = 0;
                }
            }
            mScrollRect.StopMovement();
            mCurSnapData.mSnapTargetIndex = itemIndex;
            mCurSnapData.mSnapStatus = SnapStatus.TargetHasSet;
            mCurSnapData.mIsForceSnapTo = true;
            mCurSnapData.mMoveMaxAbsVec = moveMaxAbsVec;
        }

        //Get the nearest item index with the viewport snap point.
        public int CurSnapNearestItemIndex
        {
            get { return mCurSnapNearestItemIndex; }
        }

        public void ForceSnapUpdateCheck()
        {
            if (mLeftSnapUpdateExtraCount <= 0)
            {
                mLeftSnapUpdateExtraCount = 1;
            }
        }

        void UpdateSnapHorizontal(bool immediate = false, bool forceSendEvent = false)
        {
            if (mItemSnapEnable == false)
            {
                return;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            Vector3 pos = mContainerTrans.anchoredPosition3D;
            bool needCheck = (pos.x != mLastSnapCheckPos.x);
            mLastSnapCheckPos = pos;
            if (!needCheck)
            {
                if (mLeftSnapUpdateExtraCount > 0)
                {
                    mLeftSnapUpdateExtraCount--;
                    needCheck = true;
                }
            }
            if (needCheck)
            {
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                int curIndex = -1;
                float start = 0;
                float end = 0;
                float itemSnapCenter = 0;
                float curMinDist = float.MaxValue;
                float curDist = 0;
                float curDistAbs = 0;
                float snapCenter = 0;
                if (mArrangeType == ListItemArrangeType.RightToLeft)
                {
                    snapCenter = -(1 - mViewPortSnapPivot.x) * mViewPortRectTransform.rect.width;
                    Vector3 rightPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                    start = rightPos1.x;
                    end = start - mOnGetItemSizeWithPadding(tViewItem0);
                    var size = this.mOnGetItemSize(tViewItem0);
                    itemSnapCenter = start - size * (1 - mItemSnapPivot.x);
                    for (int i = 0; i < count; ++i)
                    {
                        curDist = snapCenter - itemSnapCenter;
                        curDistAbs = Mathf.Abs(curDist);
                        if (curDistAbs < curMinDist)
                        {
                            curMinDist = curDistAbs;
                            curIndex = i;
                        }
                        else
                        {
                            break;
                        }

                        if ((i + 1) < count)
                        {
                            start = end;
                            var item1 = mItemList[i + 1];
                            end = end - mOnGetItemSizeWithPadding(item1);
                            var size1 = this.mOnGetItemSize(item1);
                            itemSnapCenter = start - size1 * (1 - mItemSnapPivot.x);
                        }
                    }
                }
                else if (mArrangeType == ListItemArrangeType.LeftToRight)
                {
                    snapCenter = mViewPortSnapPivot.x * mViewPortRectTransform.rect.width;
                    Vector3 leftPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                    start = leftPos1.x;
                    end = start + mOnGetItemSizeWithPadding(tViewItem0);
                    var size = this.mOnGetItemSize(tViewItem0);
                    itemSnapCenter = start + size * mItemSnapPivot.x;
                    for (int i = 0; i < count; ++i)
                    {
                        curDist = snapCenter - itemSnapCenter;
                        curDistAbs = Mathf.Abs(curDist);
                        if (curDistAbs < curMinDist)
                        {
                            curMinDist = curDistAbs;
                            curIndex = i;
                        }
                        else
                        {
                            break;
                        }

                        if ((i + 1) < count)
                        {
                            start = end;
                            var item1 = mItemList[i + 1];
                            end = end + mOnGetItemSizeWithPadding(item1);
                            var size1 = this.mOnGetItemSize(item1);
                            itemSnapCenter = start + size1 * mItemSnapPivot.x;
                        }
                    }
                }


                if (curIndex >= 0)
                {
                    int oldNearestItemIndex = mCurSnapNearestItemIndex;
                    var _item = mItemList[curIndex];
                    var _itemIndex = mOnGetItemIndexByView(_item);
                    mCurSnapNearestItemIndex = _itemIndex;
                    if (forceSendEvent || _itemIndex != oldNearestItemIndex)
                    {
                        if (mOnSnapNearestChanged != null)
                        {
                            mOnSnapNearestChanged(this, mItemList[curIndex]);
                        }
                    }
                }
                else
                {
                    mCurSnapNearestItemIndex = -1;
                }
            }
            if (CanSnap() == false)
            {
                ClearSnapData();
                return;
            }
            float v = Mathf.Abs(mScrollRect.velocity.x);
            UpdateCurSnapData();
            if (mCurSnapData.mSnapStatus != SnapStatus.SnapMoving)
            {
                return;
            }
            if (v > 0)
            {
                mScrollRect.StopMovement();
            }
            float old = mCurSnapData.mCurSnapVal;
            if (mCurSnapData.mIsTempTarget == false)
            {
                if (mSmoothDumpVel * mCurSnapData.mTargetSnapVal < 0)
                {
                    mSmoothDumpVel = 0;
                }
                mCurSnapData.mCurSnapVal = Mathf.SmoothDamp(mCurSnapData.mCurSnapVal, mCurSnapData.mTargetSnapVal, ref mSmoothDumpVel, mSmoothDumpRate);
            }
            else
            {
                float maxAbsVec = mCurSnapData.mMoveMaxAbsVec;
                if (maxAbsVec <= 0)
                {
                    maxAbsVec = mSnapMoveDefaultMaxAbsVec;
                }
                mSmoothDumpVel = maxAbsVec * Mathf.Sign(mCurSnapData.mTargetSnapVal);
                mCurSnapData.mCurSnapVal = Mathf.MoveTowards(mCurSnapData.mCurSnapVal, mCurSnapData.mTargetSnapVal, maxAbsVec * UnityEngine.Time.deltaTime);
            }
            float dt = mCurSnapData.mCurSnapVal - old;

            if (immediate || Mathf.Abs(mCurSnapData.mTargetSnapVal - mCurSnapData.mCurSnapVal) < mSnapFinishThreshold)
            {
                pos.x = pos.x + mCurSnapData.mTargetSnapVal - old;
                mCurSnapData.mSnapStatus = SnapStatus.SnapMoveFinish;
                if (mOnSnapItemFinished != null)
                {
                    View targetItem = GetShownItemByItemIndex(mCurSnapNearestItemIndex);
                    if (targetItem != null)
                    {
                        mOnSnapItemFinished(this, targetItem);
                    }
                }
            }
            else
            {
                pos.x = pos.x + dt;
            }

            if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                float minX = mViewPortRectLocalCorners[2].x - mContainerTrans.rect.width;
                pos.x = Mathf.Clamp(pos.x, minX, 0);
                mContainerTrans.anchoredPosition3D = pos;
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                float maxX = mViewPortRectLocalCorners[1].x + mContainerTrans.rect.width;
                pos.x = Mathf.Clamp(pos.x, 0, maxX);
                mContainerTrans.anchoredPosition3D = pos;
            }
        }

        bool CanSnap()
        {
            if (mIsDraging)
            {
                return false;
            }
            if (mScrollBarClickEventListener != null)
            {
                if (mScrollBarClickEventListener.IsPressd)
                {
                    return false;
                }
            }

            if (mIsVertList)
            {
                if (mContainerTrans.rect.height <= ViewPortHeight)
                {
                    return false;
                }
            }
            else
            {
                if (mContainerTrans.rect.width <= ViewPortWidth)
                {
                    return false;
                }
            }

            float v = 0;
            if (mIsVertList)
            {
                v = Mathf.Abs(mScrollRect.velocity.y);
            }
            else
            {
                v = Mathf.Abs(mScrollRect.velocity.x);
            }
            if (v > mSnapVecThreshold)
            {
                return false;
            }
            float diff = 3;
            Vector3 pos = mContainerTrans.anchoredPosition3D;
            if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                float minX = mViewPortRectLocalCorners[2].x - mContainerTrans.rect.width;
                if (pos.x < (minX - diff) || pos.x > diff)
                {
                    return false;
                }
            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                float maxX = mViewPortRectLocalCorners[1].x + mContainerTrans.rect.width;
                if (pos.x > (maxX + diff) || pos.x < -diff)
                {
                    return false;
                }
            }
            else if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                float maxY = mViewPortRectLocalCorners[0].y + mContainerTrans.rect.height;
                if (pos.y > (maxY + diff) || pos.y < -diff)
                {
                    return false;
                }
            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                float minY = mViewPortRectLocalCorners[1].y - mContainerTrans.rect.height;
                if (pos.y < (minY - diff) || pos.y > diff)
                {
                    return false;
                }
            }
            return true;
        }

        void SetAnchoredPositionX(RectTransform rtf, float x)
        {
            Vector3 pos = rtf.anchoredPosition3D;
            pos.x = x;
            rtf.anchoredPosition3D = pos;
        }

        void SetAnchoredPositionY(RectTransform rtf, float y)
        {
            Vector3 pos = rtf.anchoredPosition3D;
            pos.y = y;
            rtf.anchoredPosition3D = pos;
        }

        public void UpdateListView(float distanceForRecycle0, float distanceForRecycle1, float distanceForNew0, float distanceForNew1)
        {
            mListUpdateCheckFrameCount++;
            if (mIsVertList)
            {
                bool needContinueCheck = true;
                int checkCount = 0;
                int maxCount = 9999;
                while (needContinueCheck)
                {
                    checkCount++;
                    if (checkCount >= maxCount)
                    {
                        Debug.LogError("UpdateListView Vertical while loop " + checkCount + " times! something is wrong!");
                        break;
                    }
                    needContinueCheck = UpdateForVertList(distanceForRecycle0, distanceForRecycle1, distanceForNew0, distanceForNew1);
                }
            }
            else
            {
                bool needContinueCheck = true;
                int checkCount = 0;
                int maxCount = 9999;
                while (needContinueCheck)
                {
                    checkCount++;
                    if (checkCount >= maxCount)
                    {
                        Debug.LogError("UpdateListView  Horizontal while loop " + checkCount + " times! something is wrong!");
                        break;
                    }
                    needContinueCheck = UpdateForHorizontalList(distanceForRecycle0, distanceForRecycle1, distanceForNew0, distanceForNew1);
                }
            }

        }



        bool UpdateForVertList(float distanceForRecycle0, float distanceForRecycle1, float distanceForNew0, float distanceForNew1)
        {
            if (mItemTotalCount == 0)
            {
                if (mItemList.Count > 0)
                {
                    RecycleAllItem();
                }
                return false;
            }
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                int itemListCount = mItemList.Count;
                if (itemListCount == 0)
                {
                    float curY = mContainerTrans.anchoredPosition3D.y;
                    if (curY < 0)
                    {
                        curY = 0;
                    }
                    int index = 0;
                    float pos = -curY;
                    if (mSupportScrollBar)
                    {
                        if (GetPlusItemIndexAndPosAtGivenPos(curY, ref index, ref pos) == false)
                        {
                            return false;
                        }
                        pos = -pos;
                    }
                    View newItem = GetNewItemByIndex(index);
                    if (newItem == null)
                    {
                        return false;
                    }
                    if (mSupportScrollBar)
                    {
                        var _itemPadding = mOnGetItemPadding(newItem);
                        SetItemSize(index, newItem.RectTransform.rect.height, _itemPadding);
                    }
                    mItemList.Add(newItem);
                    var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                    newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, pos, 0);
                    UpdateContentSize();
                    return true;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 downPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);

                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem0) != mListUpdateCheckFrameCount
                    && downPos0.y - mViewPortRectLocalCorners[1].y > distanceForRecycle0)
                {
                    mItemList.RemoveAt(0);
                    RecycleItemTmp(tViewItem0);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }

                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 downPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem1) != mListUpdateCheckFrameCount
                    && mViewPortRectLocalCorners[0].y - topPos1.y > distanceForRecycle1)
                {
                    mItemList.RemoveAt(mItemList.Count - 1);
                    RecycleItemTmp(tViewItem1);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }



                if (mViewPortRectLocalCorners[0].y - downPos1.y < distanceForNew1)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem1);
                    if (_itemIndex > mCurReadyMaxItemIndex)
                    {
                        mCurReadyMaxItemIndex = _itemIndex;
                        mNeedCheckNextMaxItem = true;
                    }
                    int nIndex = _itemIndex + 1;
                    if (nIndex <= mCurReadyMaxItemIndex || mNeedCheckNextMaxItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMaxItemIndex = _itemIndex;
                            mNeedCheckNextMaxItem = false;
                            CheckIfNeedUpdataItemPos();
                        }
                        else
                        {
                            if (mSupportScrollBar)
                            {
                                var _itemPadding = mOnGetItemPadding(newItem);
                                SetItemSize(nIndex, newItem.RectTransform.rect.height, _itemPadding);
                            }
                            mItemList.Add(newItem);
                            var _tViewItem1Padding = mOnGetItemPadding(tViewItem1);
                            float y = tViewItem1.RectTransform.anchoredPosition3D.y - tViewItem1.RectTransform.rect.height - _tViewItem1Padding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, y, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();

                            if (nIndex > mCurReadyMaxItemIndex)
                            {
                                mCurReadyMaxItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

                if (topPos0.y - mViewPortRectLocalCorners[1].y < distanceForNew0)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem0);
                    if (_itemIndex < mCurReadyMinItemIndex)
                    {
                        mCurReadyMinItemIndex = _itemIndex;
                        mNeedCheckNextMinItem = true;
                    }
                    var _tViewItem0Index = mOnGetItemIndexByView(tViewItem0);
                    int nIndex = _tViewItem0Index - 1;
                    if (nIndex >= mCurReadyMinItemIndex || mNeedCheckNextMinItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMinItemIndex = _tViewItem0Index;
                            mNeedCheckNextMinItem = false;
                        }
                        else
                        {
                            var _newItemPadding = mOnGetItemPadding(newItem);
                            if (mSupportScrollBar)
                            {
                                SetItemSize(nIndex, newItem.RectTransform.rect.height, _newItemPadding);
                            }
                            mItemList.Insert(0, newItem);
                            float y = tViewItem0.RectTransform.anchoredPosition3D.y + newItem.RectTransform.rect.height + _newItemPadding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, y, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();
                            if (nIndex < mCurReadyMinItemIndex)
                            {
                                mCurReadyMinItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

            }
            else
            {

                if (mItemList.Count == 0)
                {
                    float curY = mContainerTrans.anchoredPosition3D.y;
                    if (curY > 0)
                    {
                        curY = 0;
                    }
                    int index = 0;
                    float pos = -curY;
                    if (mSupportScrollBar)
                    {
                        if (GetPlusItemIndexAndPosAtGivenPos(-curY, ref index, ref pos) == false)
                        {
                            return false;
                        }
                    }
                    View newItem = GetNewItemByIndex(index);
                    if (newItem == null)
                    {
                        return false;
                    }
                    if (mSupportScrollBar)
                    {
                        var _itemPadding = mOnGetItemPadding(newItem);
                        SetItemSize(index, newItem.RectTransform.rect.height, _itemPadding);
                    }
                    mItemList.Add(newItem);
                    var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                    newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, pos, 0);
                    UpdateContentSize();
                    return true;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 downPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);

                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem0) != mListUpdateCheckFrameCount
                    && mViewPortRectLocalCorners[0].y - topPos0.y > distanceForRecycle0)
                {
                    mItemList.RemoveAt(0);
                    RecycleItemTmp(tViewItem0);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }

                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 topPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 downPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[0]);
                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem1) != mListUpdateCheckFrameCount
                     && downPos1.y - mViewPortRectLocalCorners[1].y > distanceForRecycle1)
                {
                    mItemList.RemoveAt(mItemList.Count - 1);
                    RecycleItemTmp(tViewItem1);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }

                if (topPos1.y - mViewPortRectLocalCorners[1].y < distanceForNew1)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem1);
                    if (_itemIndex > mCurReadyMaxItemIndex)
                    {
                        mCurReadyMaxItemIndex = _itemIndex;
                        mNeedCheckNextMaxItem = true;
                    }
                    int nIndex = _itemIndex + 1;
                    if (nIndex <= mCurReadyMaxItemIndex || mNeedCheckNextMaxItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mNeedCheckNextMaxItem = false;
                            CheckIfNeedUpdataItemPos();
                        }
                        else
                        {
                            if (mSupportScrollBar)
                            {
                                var _newItemPadding = mOnGetItemPadding(newItem);
                                SetItemSize(nIndex, newItem.RectTransform.rect.height, _newItemPadding);
                            }
                            mItemList.Add(newItem);
                            var _tViewItem1Padding = mOnGetItemPadding(tViewItem1);
                            float y = tViewItem1.RectTransform.anchoredPosition3D.y + tViewItem1.RectTransform.rect.height + _tViewItem1Padding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, y, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();
                            if (nIndex > mCurReadyMaxItemIndex)
                            {
                                mCurReadyMaxItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }


                if (mViewPortRectLocalCorners[0].y - downPos0.y < distanceForNew0)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem0);
                    if (_itemIndex < mCurReadyMinItemIndex)
                    {
                        mCurReadyMinItemIndex = _itemIndex;
                        mNeedCheckNextMinItem = true;
                    }
                    var _tViewItem0Index = mOnGetItemIndexByView(tViewItem0);
                    int nIndex = _tViewItem0Index - 1;
                    if (nIndex >= mCurReadyMinItemIndex || mNeedCheckNextMinItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mNeedCheckNextMinItem = false;
                            return false;
                        }
                        else
                        {
                            var _newItemPadding = mOnGetItemPadding(newItem);
                            if (mSupportScrollBar)
                            {
                                SetItemSize(nIndex, newItem.RectTransform.rect.height, _newItemPadding);
                            }
                            mItemList.Insert(0, newItem);
                            float y = tViewItem0.RectTransform.anchoredPosition3D.y - newItem.RectTransform.rect.height - _newItemPadding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, y, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();
                            if (nIndex < mCurReadyMinItemIndex)
                            {
                                mCurReadyMinItemIndex = nIndex;
                            }
                            return true;
                        }

                    }
                }


            }

            return false;

        }





        bool UpdateForHorizontalList(float distanceForRecycle0, float distanceForRecycle1, float distanceForNew0, float distanceForNew1)
        {
            if (mItemTotalCount == 0)
            {
                if (mItemList.Count > 0)
                {
                    RecycleAllItem();
                }
                return false;
            }
            if (mArrangeType == ListItemArrangeType.LeftToRight)
            {

                if (mItemList.Count == 0)
                {
                    float curX = mContainerTrans.anchoredPosition3D.x;
                    if (curX > 0)
                    {
                        curX = 0;
                    }
                    int index = 0;
                    float pos = -curX;
                    if (mSupportScrollBar)
                    {
                        if (GetPlusItemIndexAndPosAtGivenPos(-curX, ref index, ref pos) == false)
                        {
                            return false;
                        }
                    }
                    View newItem = GetNewItemByIndex(index);
                    if (newItem == null)
                    {
                        return false;
                    }
                    if (mSupportScrollBar)
                    {
                        var _itemPadding = mOnGetItemPadding(newItem);
                        SetItemSize(index, newItem.RectTransform.rect.width, _itemPadding);
                    }
                    mItemList.Add(newItem);
                    var _newItemStartPosOffset = mOnGetItemStartPosOffset(newItem);
                    newItem.RectTransform.anchoredPosition3D = new Vector3(pos, _newItemStartPosOffset, 0);
                    UpdateContentSize();
                    return true;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 rightPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);

                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem0) != mListUpdateCheckFrameCount
                    && mViewPortRectLocalCorners[1].x - rightPos0.x > distanceForRecycle0)
                {
                    mItemList.RemoveAt(0);
                    RecycleItemTmp(tViewItem0);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }

                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 rightPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem1) != mListUpdateCheckFrameCount
                    && leftPos1.x - mViewPortRectLocalCorners[2].x > distanceForRecycle1)
                {
                    mItemList.RemoveAt(mItemList.Count - 1);
                    RecycleItemTmp(tViewItem1);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }



                if (rightPos1.x - mViewPortRectLocalCorners[2].x < distanceForNew1)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem1);
                    if (_itemIndex > mCurReadyMaxItemIndex)
                    {
                        mCurReadyMaxItemIndex = _itemIndex;
                        mNeedCheckNextMaxItem = true;
                    }
                    int nIndex = _itemIndex + 1;
                    if (nIndex <= mCurReadyMaxItemIndex || mNeedCheckNextMaxItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMaxItemIndex = _itemIndex;
                            mNeedCheckNextMaxItem = false;
                            CheckIfNeedUpdataItemPos();
                        }
                        else
                        {
                            if (mSupportScrollBar)
                            {
                                var _newItemPadding = mOnGetItemPadding(newItem);
                                SetItemSize(nIndex, newItem.RectTransform.rect.width, _newItemPadding);
                            }
                            mItemList.Add(newItem);
                            var _tViewItem1Padding = mOnGetItemPadding(tViewItem1);
                            float x = tViewItem1.RectTransform.anchoredPosition3D.x + tViewItem1.RectTransform.rect.width + _tViewItem1Padding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(x, _startPosOffset, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();

                            if (nIndex > mCurReadyMaxItemIndex)
                            {
                                mCurReadyMaxItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

                if (mViewPortRectLocalCorners[1].x - leftPos0.x < distanceForNew0)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem0);
                    if (_itemIndex < mCurReadyMinItemIndex)
                    {
                        mCurReadyMinItemIndex = _itemIndex;
                        mNeedCheckNextMinItem = true;
                    }
                    var _tViewItem0Index = mOnGetItemIndexByView(tViewItem0);
                    int nIndex = _tViewItem0Index - 1;
                    if (nIndex >= mCurReadyMinItemIndex || mNeedCheckNextMinItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMinItemIndex = _tViewItem0Index;
                            mNeedCheckNextMinItem = false;
                        }
                        else
                        {
                            var _newItemPadding = mOnGetItemPadding(newItem);
                            if (mSupportScrollBar)
                            {
                                SetItemSize(nIndex, newItem.RectTransform.rect.width, _newItemPadding);
                            }
                            mItemList.Insert(0, newItem);
                            float x = tViewItem0.RectTransform.anchoredPosition3D.x - newItem.RectTransform.rect.width - _newItemPadding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(x, _startPosOffset, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();
                            if (nIndex < mCurReadyMinItemIndex)
                            {
                                mCurReadyMinItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

            }
            else
            {

                if (mItemList.Count == 0)
                {
                    float curX = mContainerTrans.anchoredPosition3D.x;
                    if (curX < 0)
                    {
                        curX = 0;
                    }
                    int index = 0;
                    float pos = -curX;
                    if (mSupportScrollBar)
                    {
                        if (GetPlusItemIndexAndPosAtGivenPos(curX, ref index, ref pos) == false)
                        {
                            return false;
                        }
                        pos = -pos;
                    }
                    View newItem = GetNewItemByIndex(index);
                    if (newItem == null)
                    {
                        return false;
                    }
                    if (mSupportScrollBar)
                    {
                        var _itemPadding = mOnGetItemPadding(newItem);
                        SetItemSize(index, newItem.RectTransform.rect.width, _itemPadding);
                    }
                    mItemList.Add(newItem);
                    var _newItemStartPosOffset = mOnGetItemStartPosOffset(newItem);
                    newItem.RectTransform.anchoredPosition3D = new Vector3(pos, _newItemStartPosOffset, 0);
                    UpdateContentSize();
                    return true;
                }
                View tViewItem0 = mItemList[0];
                tViewItem0.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 rightPos0 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);

                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem0) != mListUpdateCheckFrameCount
                    && leftPos0.x - mViewPortRectLocalCorners[2].x > distanceForRecycle0)
                {
                    mItemList.RemoveAt(0);
                    RecycleItemTmp(tViewItem0);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }

                View tViewItem1 = mItemList[mItemList.Count - 1];
                tViewItem1.RectTransform.GetWorldCorners(mItemWorldCorners);
                Vector3 leftPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[1]);
                Vector3 rightPos1 = mViewPortRectTransform.InverseTransformPoint(mItemWorldCorners[2]);
                if (!mIsDraging && mOnGetItemCreatedCheckFrameCount(tViewItem1) != mListUpdateCheckFrameCount
                    && mViewPortRectLocalCorners[1].x - rightPos1.x > distanceForRecycle1)
                {
                    mItemList.RemoveAt(mItemList.Count - 1);
                    RecycleItemTmp(tViewItem1);
                    if (!mSupportScrollBar)
                    {
                        UpdateContentSize();
                        CheckIfNeedUpdataItemPos();
                    }
                    return true;
                }



                if (mViewPortRectLocalCorners[1].x - leftPos1.x < distanceForNew1)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem1);
                    if (_itemIndex > mCurReadyMaxItemIndex)
                    {
                        mCurReadyMaxItemIndex = _itemIndex;
                        mNeedCheckNextMaxItem = true;
                    }
                    int nIndex = _itemIndex + 1;
                    if (nIndex <= mCurReadyMaxItemIndex || mNeedCheckNextMaxItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMaxItemIndex = _itemIndex;
                            mNeedCheckNextMaxItem = false;
                            CheckIfNeedUpdataItemPos();
                        }
                        else
                        {
                            if (mSupportScrollBar)
                            {
                                var _newItemPadding = mOnGetItemPadding(newItem);
                                SetItemSize(nIndex, newItem.RectTransform.rect.width, _newItemPadding);
                            }
                            mItemList.Add(newItem);
                            var _tViewItem1Padding = mOnGetItemPadding(tViewItem1);
                            float x = tViewItem1.RectTransform.anchoredPosition3D.x - tViewItem1.RectTransform.rect.width - _tViewItem1Padding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(x, _startPosOffset, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();

                            if (nIndex > mCurReadyMaxItemIndex)
                            {
                                mCurReadyMaxItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

                if (rightPos0.x - mViewPortRectLocalCorners[2].x < distanceForNew0)
                {
                    var _itemIndex = mOnGetItemIndexByView(tViewItem0);
                    if (_itemIndex < mCurReadyMinItemIndex)
                    {
                        mCurReadyMinItemIndex = _itemIndex;
                        mNeedCheckNextMinItem = true;
                    }
                    var _tViewItem0Index = mOnGetItemIndexByView(tViewItem0);
                    int nIndex = _tViewItem0Index - 1;
                    if (nIndex >= mCurReadyMinItemIndex || mNeedCheckNextMinItem)
                    {
                        View newItem = GetNewItemByIndex(nIndex);
                        if (newItem == null)
                        {
                            mCurReadyMinItemIndex = _tViewItem0Index;
                            mNeedCheckNextMinItem = false;
                        }
                        else
                        {
                            var _newItemPadding = mOnGetItemPadding(newItem);
                            if (mSupportScrollBar)
                            {
                                SetItemSize(nIndex, newItem.RectTransform.rect.width, _newItemPadding);
                            }
                            mItemList.Insert(0, newItem);
                            float x = tViewItem0.RectTransform.anchoredPosition3D.x + newItem.RectTransform.rect.width + _newItemPadding;
                            var _startPosOffset = mOnGetItemStartPosOffset(newItem);
                            newItem.RectTransform.anchoredPosition3D = new Vector3(x, _startPosOffset, 0);
                            UpdateContentSize();
                            CheckIfNeedUpdataItemPos();
                            if (nIndex < mCurReadyMinItemIndex)
                            {
                                mCurReadyMinItemIndex = nIndex;
                            }
                            return true;
                        }

                    }

                }

            }

            return false;

        }






        float GetContentPanelSize()
        {
            if (mSupportScrollBar)
            {
                float tTotalSize = mItemPosMgr.mTotalSize > 0 ? (mItemPosMgr.mTotalSize - mLastItemPadding) : 0;
                if (tTotalSize < 0)
                {
                    tTotalSize = 0;
                }
                return tTotalSize;
            }
            int count = mItemList.Count;
            if (count == 0)
            {
                return 0;
            }
            if (count == 1)
            {
                return this.mOnGetItemSize(mItemList[0]);
            }
            if (count == 2)
            {
                var item0 = mItemList[0];
                var size0 = this.mOnGetItemSizeWithPadding(item0);
                var item1 = mItemList[1];
                var size1 = this.mOnGetItemSize(item1);
                return size0 + size1;
            }
            float s = 0;
            for (int i = 0; i < count - 1; ++i)
            {
                s += mOnGetItemSizeWithPadding(mItemList[i]);
            }
            var item = mItemList[count - 1];
            s += this.mOnGetItemSize(item);
            return s;
        }


        void CheckIfNeedUpdataItemPos()
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                View firstItem = mItemList[0];
                View lastItem = mItemList[mItemList.Count - 1];
                float viewMaxY = GetContentPanelSize();
                var _firstItemIndex = mOnGetItemIndexByView(firstItem);
                var _lastItemIndex = mOnGetItemIndexByView(lastItem);
                if (mOnGetItemTopY(firstItem) > 0 || (_firstItemIndex == mCurReadyMinItemIndex && mOnGetItemTopY(firstItem) != 0))
                {
                    UpdateAllShownItemsPos();
                    return;
                }
                if ((-mOnGetItemBottomY(lastItem)) > viewMaxY || (_lastItemIndex == mCurReadyMaxItemIndex && (-mOnGetItemBottomY(lastItem)) != viewMaxY))
                {
                    UpdateAllShownItemsPos();
                    return;
                }

            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                View firstItem = mItemList[0];
                View lastItem = mItemList[mItemList.Count - 1];
                float viewMaxY = GetContentPanelSize();
                var _firstItemIndex = mOnGetItemIndexByView(firstItem);
                var _lastItemIndex = mOnGetItemIndexByView(lastItem);

                if (mOnGetItemBottomY(firstItem) < 0 || (_firstItemIndex == mCurReadyMinItemIndex && mOnGetItemBottomY(firstItem) != 0))
                {
                    UpdateAllShownItemsPos();
                    return;
                }
                if (mOnGetItemTopY(lastItem) > viewMaxY || (_lastItemIndex == mCurReadyMaxItemIndex && mOnGetItemTopY(lastItem) != viewMaxY))
                {
                    UpdateAllShownItemsPos();
                    return;
                }
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                View firstItem = mItemList[0];
                View lastItem = mItemList[mItemList.Count - 1];
                float viewMaxX = GetContentPanelSize();
                var _firstItemIndex = mOnGetItemIndexByView(firstItem);
                var _lastItemIndex = mOnGetItemIndexByView(lastItem);
                if (mOnGetItemLeftX(firstItem) < 0 || (_firstItemIndex == mCurReadyMinItemIndex && mOnGetItemLeftX(firstItem) != 0))
                {
                    UpdateAllShownItemsPos();
                    return;
                }
                if ((mOnGetItemRightX(lastItem)) > viewMaxX || (_lastItemIndex == mCurReadyMaxItemIndex && mOnGetItemRightX(lastItem) != viewMaxX))
                {
                    UpdateAllShownItemsPos();
                    return;
                }

            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                View firstItem = mItemList[0];
                View lastItem = mItemList[mItemList.Count - 1];
                float viewMaxX = GetContentPanelSize();
                var _firstItemIndex = mOnGetItemIndexByView(firstItem);
                var _lastItemIndex = mOnGetItemIndexByView(lastItem);

                if (mOnGetItemRightX(firstItem) > 0 || (_firstItemIndex == mCurReadyMinItemIndex && mOnGetItemRightX(firstItem) != 0))
                {
                    UpdateAllShownItemsPos();
                    return;
                }
                if ((-mOnGetItemLeftX(lastItem)) > viewMaxX || (_lastItemIndex == mCurReadyMaxItemIndex && (-mOnGetItemLeftX(lastItem)) != viewMaxX))
                {
                    UpdateAllShownItemsPos();
                    return;
                }

            }

        }


        void UpdateAllShownItemsPos()
        {
            int count = mItemList.Count;
            if (count == 0)
            {
                return;
            }
            float deltaTime = UnityEngine.Time.deltaTime;
            const float minDeltaTime = 1.0f / 120.0f;
            if (deltaTime < minDeltaTime)
            {
                deltaTime = minDeltaTime;
            }
            mAdjustedVec = (mContainerTrans.anchoredPosition3D - mLastFrameContainerPos) / deltaTime;

            if (mArrangeType == ListItemArrangeType.TopToBottom)
            {
                float pos = 0;
                if (mSupportScrollBar)
                {
                    var _itemIndex = mOnGetItemIndexByView(mItemList[0]);
                    pos = -GetItemPos(_itemIndex);
                }
                float pos1 = mItemList[0].RectTransform.anchoredPosition3D.y;
                float d = pos - pos1;
                float curY = pos;
                for (int i = 0; i < count; ++i)
                {
                    View item = mItemList[i];
                    var _startPosOffset = mOnGetItemStartPosOffset(item);
                    item.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, curY, 0);
                    var _itemPadding = mOnGetItemPadding(item);
                    curY = curY - item.RectTransform.rect.height - _itemPadding;
                }
                if (d != 0)
                {
                    Vector2 p = mContainerTrans.anchoredPosition3D;
                    p.y = p.y - d;
                    mContainerTrans.anchoredPosition3D = p;
                }

            }
            else if (mArrangeType == ListItemArrangeType.BottomToTop)
            {
                float pos = 0;
                if (mSupportScrollBar)
                {
                    var _itemIndex = mOnGetItemIndexByView(mItemList[0]);
                    pos = GetItemPos(_itemIndex);
                }
                float pos1 = mItemList[0].RectTransform.anchoredPosition3D.y;
                float d = pos - pos1;
                float curY = pos;
                for (int i = 0; i < count; ++i)
                {
                    View item = mItemList[i];
                    var _startPosOffset = mOnGetItemStartPosOffset(item);
                    item.RectTransform.anchoredPosition3D = new Vector3(_startPosOffset, curY, 0);
                    var _itemPadding = mOnGetItemPadding(item);
                    curY = curY + item.RectTransform.rect.height + _itemPadding;
                }
                if (d != 0)
                {
                    Vector3 p = mContainerTrans.anchoredPosition3D;
                    p.y = p.y - d;
                    mContainerTrans.anchoredPosition3D = p;
                }
            }
            else if (mArrangeType == ListItemArrangeType.LeftToRight)
            {
                float pos = 0;
                if (mSupportScrollBar)
                {
                    var _itemIndex = mOnGetItemIndexByView(mItemList[0]);
                    pos = GetItemPos(_itemIndex);
                }
                float pos1 = mItemList[0].RectTransform.anchoredPosition3D.x;
                float d = pos - pos1;
                float curX = pos;
                for (int i = 0; i < count; ++i)
                {
                    View item = mItemList[i];
                    var _startPosOffset = mOnGetItemStartPosOffset(item);
                    item.RectTransform.anchoredPosition3D = new Vector3(curX, _startPosOffset, 0);
                    var _itemPadding = mOnGetItemPadding(item);
                    curX = curX + item.RectTransform.rect.width + _itemPadding;
                }
                if (d != 0)
                {
                    Vector3 p = mContainerTrans.anchoredPosition3D;
                    p.x = p.x - d;
                    mContainerTrans.anchoredPosition3D = p;
                }

            }
            else if (mArrangeType == ListItemArrangeType.RightToLeft)
            {
                float pos = 0;
                if (mSupportScrollBar)
                {
                    var _itemIndex = mOnGetItemIndexByView(mItemList[0]);
                    pos = -GetItemPos(_itemIndex);
                }
                float pos1 = mItemList[0].RectTransform.anchoredPosition3D.x;
                float d = pos - pos1;
                float curX = pos;
                for (int i = 0; i < count; ++i)
                {
                    View item = mItemList[i];
                    var _startPosOffset = mOnGetItemStartPosOffset(item);
                    item.RectTransform.anchoredPosition3D = new Vector3(curX, _startPosOffset, 0);
                    var _itemPadding = mOnGetItemPadding(item);
                    curX = curX - item.RectTransform.rect.width - _itemPadding;
                }
                if (d != 0)
                {
                    Vector3 p = mContainerTrans.anchoredPosition3D;
                    p.x = p.x - d;
                    mContainerTrans.anchoredPosition3D = p;
                }

            }
            if (mIsDraging)
            {
                mScrollRect.OnBeginDrag(mPointerEventData);
                mScrollRect.Rebuild(CanvasUpdate.PostLayout);
                mScrollRect.velocity = mAdjustedVec;
                mNeedAdjustVec = true;
            }
        }
        void UpdateContentSize()
        {
            float size = GetContentPanelSize();
            if (mIsVertList)
            {
                if (mContainerTrans.rect.height != size)
                {
                    mContainerTrans.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, size);
                }
            }
            else
            {
                if (mContainerTrans.rect.width != size)
                {
                    mContainerTrans.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, size);
                }
            }
        }
    }

}
