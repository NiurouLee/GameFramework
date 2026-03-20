using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

namespace NFramework.GAS
{
    /// <summary>
    /// 游戏标签容器- 可变标签集合（带引用计数）
    /// 用于游戏运行时动态添加/移除标签
    /// </summary>
    [Serializable]
    public class GamePlayTagContainer
    {

        [SerializeField]
        private List<GamePlayTag> _tags = new List<GamePlayTag>();
        /// <summary>
        /// 标签引用计数
        /// </summary>
        public Dictionary<int, int> _tagCounts = new Dictionary<int, int>();

        /// <summary>
        /// 标签变化事件(通用)
        /// </summary>
        public event Action OnTagChanged;


        /// <summary>
        /// 标签首次添加事件， 计数0->1时触发
        /// </summary>
        public event Action<GamePlayTag> OnTagAdded;

        public event Action<GamePlayTag> OnTagRemoved;

        public event Action<GamePlayTag, int, int> OnTagCountChanged;

        public IReadOnlyList<GamePlayTag> Tags => _tags;

        public int Count => Tags.Count;

        public bool IsEmpty => _tags.Count == 0;

        public int GetTagCount(GamePlayTag tag)
        {
            if (!tag.IsValid)
            {
                return 0;
            }
            if (_tagCounts.TryGetValue(tag.HashCode, out int count))
            {
                return count;
            }
            return 0;
        }
        public void AddTag(GamePlayTag tag)
        {
            if (!tag.IsValid) return;
            int hashCode = tag.HashCode;
            int oldCount = _tagCounts.TryGetValue(hashCode, out int count) ? count : 0;
            var newCount = oldCount + 1;
            _tagCounts[hashCode] = newCount;
            if (oldCount == 0)
            {
                _tags.Add(tag);
                OnTagAdded?.Invoke(tag);
            }
            OnTagCountChanged?.Invoke(tag, oldCount, newCount);
            OnTagChanged?.Invoke();
        }

        public void AddTags(GamePlayTagSet tatSet)
        {
        }



    }
}