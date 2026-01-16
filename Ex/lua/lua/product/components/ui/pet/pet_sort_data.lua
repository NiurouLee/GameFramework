_class("pet_sort_data", Object)
pet_sort_data = pet_sort_data

function pet_sort_data:Constructor(sortType, name, sortState)
    self.sortType = sortType --排序的类型
    self.Name = name --名字
    self.sortState = sortState --状态 0(未选中)  1(由高到底)  2(由底到高)
end
