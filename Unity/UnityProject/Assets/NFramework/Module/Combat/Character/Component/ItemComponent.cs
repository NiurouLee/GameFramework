
using System.Collections.Generic;
using NFramework.Core.Collections;
using NFramework.Core.ILiveing;
using NFramework.Module.EntityModule;
using NFramework.Module.ResModule;

namespace NFramework.Module.Combat
{
    public class ItemComponent : Entity
    {
        public Combat Combat => GetParent<Combat>();
        public Dictionary<int, ItemAbility> ItemDict = new Dictionary<int, ItemAbility>();

        public ItemAbility AttachItem(int itemID)
        {
            ItemConfigObject itemConfigObject = Framework.I.G<ResM>().Load<ItemConfigObject>(string.Empty);
            if (itemConfigObject == null)
            {
                return null;
            }
            var item = Combat.AttachAbility<ItemAbility>(itemConfigObject);
            if (!ItemDict.ContainsKey(item.itemConfigObject.Id))
            {
                ItemDict.Add(item.itemConfigObject.Id, item);
            }
            return item;
        }

        public ItemAbility GetItem(int itemID)
        {
            if (ItemDict.ContainsKey(itemID))
            {
                return ItemDict[itemID];
            }
            return null;
        }
    }
}