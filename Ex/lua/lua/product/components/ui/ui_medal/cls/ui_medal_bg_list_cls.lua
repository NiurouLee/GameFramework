--对server medal board进行统一处理
---@class UIMedalBgListData : Object
_class("UIMedalBgListData", Object)
UIMedalBgListData = UIMedalBgListData

function UIMedalBgListData:Constructor()  
    self.defMedalID = nil --默认勋章id
    self.medalList = {}
    self.totalMedal = 0
    self.collectMedal = 0
end

function UIMedalBgListData:Init(server_medal_info)
    self.visit = visit

    for i,v in pairs(server_medal_info) do
        if Cfg.cfg_item_medal_board[v.medal_id].IsDefault then
            self.defMedalID = v.medal_id
        end
        if v.status == RewardStatus.E_MEDAL_REWARD_LOCK and not Cfg.cfg_item_medal_board[v.medal_id].IsShow then
            --如果未解锁切禁止显示则不加入
        else
            if v.status ~= RewardStatus.E_MEDAL_REWARD_LOCK and v.status ~= RewardStatus.E_MEDAL_REWARD_FUNCTION_LOCK then
                self.collectMedal = self.collectMedal + 1
            end
            self.totalMedal = self.totalMedal + 1
            self.medalList[v.medal_id] = v
        end
    end
end

--获得所有数�?
--@return number
function UIMedalBgListData:GetTotalNum()
    return self.totalMedal
end

--获得已经解锁的数�?
--@return number
function UIMedalBgListData:GetUnLockNum()
    return self.collectMedal
end

--获得默认的勋章ID
--@return id
function UIMedalBgListData:GetDefMedalID()
    return self.defMedalID
end

--获得排序后的勋章列表
function UIMedalBgListData:GetSortMedals()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local tb,newList,commentList,lockList = {},{},{},{}

    for i,v in pairs(self.medalList) do
        local item_data,is_new
        local items = itemModule:GetItemByTempId(v.medal_id)
        if items and table.count(items)>0 then
            for _, value in pairs(items) do
                item_data = value
                break
            end
        end
        if item_data then
            is_new = item_data:IsNewOverlay()
        end
        if v.status == RewardStatus.E_MEDAL_REWARD_LOCK then
            table.insert(lockList,i)
        elseif is_new then
            table.insert(newList,i)
        else
            table.insert(commentList,i)
        end
    end
    table.sort(newList)
    table.sort(commentList)
    table.sort(lockList)
    for _,v in pairs(newList) do
        table.insert(tb,self.medalList[v])
    end
    for _,v in pairs(commentList) do
        table.insert(tb,self.medalList[v])
    end
    for _,v in pairs(lockList) do
        table.insert(tb,self.medalList[v])
    end

    return tb
end

--通过medalID获得medalBoard表数�?
function UIMedalBgListData:GetMedalDataByID(medalID)
    return Cfg.cfg_item_medal_board[medalID]
end
