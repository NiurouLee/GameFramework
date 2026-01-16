using System;
using System.Collections.Generic;
using NFramework.Module.LogModule;
using NFramework.Core.Collections;
using UnityEngine;

namespace NFramework.Module.UIModule.ScrollView
{
    public class ScrollListSwift<D, V> where V : Module.UIModule.View, IViewSetData<D> where D : class
    {
        private IReadOnlyList<D> _dataList;
        private Func<D, String> _dataToPrefabNameFunc;
        private Func<D, V> _dataToViewFunc;
        private LoopList _loopListView;
        private Module.UIModule.View _container;
        private IUIFacadeProvider _provider;
        private Dictionary<Module.UIModule.View, string> _viewToPrefabNameDict;
        private Dictionary<Module.UIModule.View, int> _viewToIndexDict;
        private Dictionary<int, Module.UIModule.View> _indexToViewDict;
        private Dictionary<Module.UIModule.View, float> _viewToCreatedCheckFrameCountDict;
        private Dictionary<Module.UIModule.View, float> _viewToDistanceWithViewPortSnapCenterDict;

        public ScrollListSwift(Module.UIModule.View container, LoopList loopListView)
        {
            _viewToPrefabNameDict = DictionaryPool.Alloc<Module.UIModule.View, string>();
            _viewToIndexDict = DictionaryPool.Alloc<Module.UIModule.View, int>();
            _indexToViewDict = DictionaryPool.Alloc<int, Module.UIModule.View>();
            _viewToDistanceWithViewPortSnapCenterDict = DictionaryPool.Alloc<Module.UIModule.View, float>();

            _container = container;
            _loopListView = loopListView;

            //1
            _loopListView.mInitItemPool = this.InitPrefabPool;
            //2
            _loopListView.mOnGetNewItemByDataIndex = this.GetNewItemByDataIndex;
            //3
            _loopListView.mOnGetItemByIndex = this.GetItemByIndex;
            //4
            _loopListView.mOnGetItemIndexByView = this.GetItemIndexByView;
            //5
            _loopListView.mOnRecycleItemTemp = this.RecycleItemTemp;
            //6
            _loopListView.mOnRecycleItemReal = this.RecycleItemReal;
            //7
            _loopListView.mOnRecycleItemImmediately = this.RecycleItemImmediately;
            //8
            _loopListView.mOnClearAllTmpRecycledItem = this.ClearAllTmpRecycledItem;
            //9
            _loopListView.mOnGetItemStartPosOffset = this.GetItemStartPosOffset;
            //10
            _loopListView.mOnGetItemCreatedCheckFrameCount = this.GetItemCreatedCheckFrameCount;
            //11
            _loopListView.mOnSetItemCreatedCheckFrameCount = this.SetItemCreatedCheckFrameCount;
            //12
            _loopListView.mOnGetItemSize = this.GetItemSize;
            //13
            _loopListView.mOnGetItemPadding = this.GetItemPadding;
            //14
            _loopListView.mOnGetItemSizeWithPadding = this.GetItemSizeWithPadding;
            //15
            _loopListView.mOnGetItemTopY = this.GetItemTopY;
            //16
            _loopListView.mOnGetItemBottomY = this.GetItemBottomY;
            //17
            _loopListView.mOnGetItemRightX = this.GetItemRightX;
            //18
            _loopListView.mOnGetItemLeftX = this.GetItemLeftX;
            //19
            _loopListView.mOnGetItemDistanceWithViewPortSnapCenter = this.GetItemDistanceWithViewPortSnapCenter;
            //20
            _loopListView.mOnSetItemDistanceWithViewPortSnapCenter = this.SetItemDistanceWithViewPortSnapCenter;

            loopListView.InitListView();
        }



        public void BindList(IReadOnlyList<D> list)
        {
            _dataList = list;
        }

        public void BindDataToPrefabNameFunc(Func<D, String> func)
        {
            _dataToPrefabNameFunc = func;
        }

        public void BindDataToViewFunc(Func<D, V> func)
        {
            _dataToViewFunc = func;
        }

        #region  LoopListFunc

        Dictionary<string, LoopViewItemPool> mItemPoolDict = new Dictionary<string, LoopViewItemPool>();
        List<LoopViewItemPool> mItemPoolList = new List<LoopViewItemPool>();

        public virtual void InitPrefabPool(List<ItemPrefabConfData> list)
        {
            foreach (ItemPrefabConfData data in list)
            {
                if (data.mItemPrefab == null)
                {
                    Framework.Instance.GetModule<LoggerM>()?.Err("A item prefab is null ");
                    continue;
                }
                string prefabName = data.mItemPrefab.name;
                if (mItemPoolDict.ContainsKey(prefabName))
                {
                    Framework.Instance.GetModule<LoggerM>()?.Err("A item prefab with name " + prefabName + " has existed!");
                    continue;
                }
                RectTransform rtf = data.mItemPrefab.GetComponent<RectTransform>();
                if (rtf == null)
                {
                    Framework.Instance.GetModule<LoggerM>()?.Err("RectTransform component is not found in the prefab " + prefabName);
                    continue;
                }
                _loopListView.AdjustAnchor(rtf);
                _loopListView.AdjustPivot(rtf);
                LoopViewItemPool pool = new LoopViewItemPool();
                pool.Init(data.mItemPrefab, data.mPadding, data.mStartPosOffset, data.mInitCreateCount, this._container.RectTransform, this.CreateItem, this._container);
                mItemPoolDict.Add(prefabName, pool);
                mItemPoolList.Add(pool);
            }
        }

        private Module.UIModule.View CreateItem(GameObject go)
        {
            return null;
        }



        private Module.UIModule.View GetNewItemByDataIndex(int index)
        {
            var data = _dataList[index];
            //todo: 这里不能每次new
            var prefabName = _dataToPrefabNameFunc(data);
            if (string.IsNullOrEmpty(prefabName))
            {
                Framework.Instance.GetModule<LoggerM>()?.Err("A item prefab with name " + prefabName + " is null!");
                return null;
            }
            var pool = mItemPoolDict[prefabName];
            var item = pool.GetItem(index);
            if (item == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.Err("A item prefab with name " + prefabName + " is null!");
                return null;
            }

            _viewToPrefabNameDict.Add(item, prefabName);

            var outView = item;
            // var facade = item.GetComponent<UIFacade>();
            // if (facade == null)
            // {
            //     Framework.Instance.GetModule<LoggerModule>()?.Err("A item prefab with name " + prefabName + " is null!");
            //     return null;
            // }

            // var outView = _container.AddSubViewByFacade(view, facade, _provider);
            if (outView == null)
            {
                Framework.Instance.GetModule<LoggerM>()?.Err("A item prefab with name " + prefabName + " is null!");
                return null;
            }
            if (outView is IViewSetData<D> viewSetData)
            {
                viewSetData.SetData(data);
            }
            outView.Show();

            _viewToIndexDict.Add(outView, index);
            _indexToViewDict.Add(index, outView);

            return outView;
        }
        private Module.UIModule.View GetItemByIndex(int arg)
        {
            if (_indexToViewDict.TryGetValue(arg, out var view))
            {
                return view;
            }
            return null;
        }
        private int GetItemIndexByView(Module.UIModule.View view)
        {
            if (_viewToIndexDict.TryGetValue(view, out var index))
            {
                return index;
            }
            return -1;
        }

        public virtual float GetItemSize(Module.UIModule.View inView)
        {
            if (_loopListView.IsVertList)
            {
                return inView.RectTransform.rect.height;
            }
            else
            {
                return inView.RectTransform.rect.width;
            }
        }
        private void RecycleItemTemp(Module.UIModule.View view)
        {
            if (view == null)
            {
                return;
            }

            var name = _viewToPrefabNameDict[view];
            if (string.IsNullOrEmpty(name))
            {
                return;
            }
            LoopViewItemPool pool = null;
            if (mItemPoolDict.TryGetValue(name, out pool) == false)
            {
                return;
            }
            this._viewToPrefabNameDict.Remove(view);
            pool.RecycleItem(view);
        }

        private void RecycleItemReal(Module.UIModule.View view)
        {
        }
        private void RecycleItemImmediately(Module.UIModule.View view)
        {
            var prefabName = _viewToPrefabNameDict[view];
            if (string.IsNullOrEmpty(prefabName))
            {
                return;
            }
            LoopViewItemPool pool = null;
            if (mItemPoolDict.TryGetValue(prefabName, out pool) == false)
            {
                return;
            }
            pool.RecycleItemReal(view);
        }
        private void ClearAllTmpRecycledItem()
        {
            int count = mItemPoolList.Count;
            for (int i = 0; i < count; ++i)
            {
                mItemPoolList[i].ClearTmpRecycledItem();
            }
        }
        private float GetItemStartPosOffset(Module.UIModule.View view)
        {
            return 0;
        }

        private float GetItemCreatedCheckFrameCount(Module.UIModule.View view)
        {
            return _viewToCreatedCheckFrameCountDict[view];
        }

        private void SetItemCreatedCheckFrameCount(Module.UIModule.View view, float createdCheckFrameCount)
        {
            _viewToCreatedCheckFrameCountDict[view] = createdCheckFrameCount;
        }

        private float GetItemPadding(Module.UIModule.View view)
        {
            return 0;

        }

        private float GetItemSizeWithPadding(Module.UIModule.View view)
        {
            return GetItemSize(view) + GetItemPadding(view);
        }

        private float GetItemDistanceWithViewPortSnapCenter(Module.UIModule.View view)
        {
            return _viewToDistanceWithViewPortSnapCenterDict[view];
        }

        private void SetItemDistanceWithViewPortSnapCenter(Module.UIModule.View view, float arg2)
        {
            _viewToDistanceWithViewPortSnapCenterDict[view] = arg2;
        }
        private float GetItemTopY(Module.UIModule.View view)
        {
            ListItemArrangeType arrageType = _loopListView.ArrangeType;
            if (arrageType == ListItemArrangeType.TopToBottom)
            {
                return view.RectTransform.anchoredPosition3D.y;
            }
            else if (arrageType == ListItemArrangeType.BottomToTop)
            {
                return view.RectTransform.anchoredPosition3D.y + view.RectTransform.rect.height;
            }
            return 0;
        }

        private float GetItemBottomY(Module.UIModule.View view)
        {
            ListItemArrangeType arrageType = _loopListView.ArrangeType;
            if (arrageType == ListItemArrangeType.TopToBottom)
            {
                return view.RectTransform.anchoredPosition3D.y - view.RectTransform.rect.height;
            }
            else if (arrageType == ListItemArrangeType.BottomToTop)
            {
                return view.RectTransform.anchoredPosition3D.y;
            }
            return 0;
        }

        private float GetItemLeftX(Module.UIModule.View view)
        {
            ListItemArrangeType arrageType = _loopListView.ArrangeType;
            if (arrageType == ListItemArrangeType.LeftToRight)
            {
                return view.RectTransform.anchoredPosition3D.x;
            }
            else if (arrageType == ListItemArrangeType.RightToLeft)
            {
                return view.RectTransform.anchoredPosition3D.x - view.RectTransform.rect.width;
            }
            return 0;
        }

        private float GetItemRightX(Module.UIModule.View view)
        {
            ListItemArrangeType arrageType = _loopListView.ArrangeType;
            if (arrageType == ListItemArrangeType.LeftToRight)
            {
                return view.RectTransform.anchoredPosition3D.x + view.RectTransform.rect.width;
            }
            else if (arrageType == ListItemArrangeType.RightToLeft)
            {
                return view.RectTransform.anchoredPosition3D.x;
            }
            return 0;
        }
        #endregion

    }
}


