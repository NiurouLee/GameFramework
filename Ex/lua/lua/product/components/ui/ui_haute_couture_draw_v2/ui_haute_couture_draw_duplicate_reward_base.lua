--[[
    高级时装复刻奖励重复变更说明界面父类
]]
---@class UIHauteCoutureDrawDuplicateRewardBase : UICustomWidget
_class("UIHauteCoutureDrawDuplicateRewardBase", UICustomWidget)
UIHauteCoutureDrawDuplicateRewardBase = UIHauteCoutureDrawDuplicateRewardBase

function UIHauteCoutureDrawDuplicateRewardBase:OnShow()
    self:InitWidget()
end

--初始化
function UIHauteCoutureDrawDuplicateRewardBase:SetData(uiParams)
    self._prizeCfgs = uiParams[1] --cfg_component_senior_skin_weight
    self._replaceIdxs = uiParams[2] --
    local count = #self._replaceIdxs

    self._itemInfo = {}
    ---@type UIHauteCoutureDuplicateItem[]
    local items = self.items:SpawnObjects(self:GetItemClassName(), count)
    for i = 1, count do
        items[i]:SetData(
            self._prizeCfgs[self._replaceIdxs[i]],
            function(id, pos, count)
                self:OnItemClick(id, pos, count)
            end
        )
    end

    local itemInfo = self:GetUIComponent("UISelectObjectPath", "selectInfoPool")
    ---@type UISelectInfo
    self._selectInfo = itemInfo:SpawnObject("UISelectInfo")
    self._selectInfo:SetType(3)
    local detailObj = self._selectInfo:GetG3CustomPool()
    local prefab, class = self:GetGetItemUIInfo()
    detailObj.dynamicInfoOfEngine:SetObjectName(prefab)
    ---@type UIHauteCoutureDrawGetItemCellDetailGL
    self._selectDetail = detailObj:SpawnObject(class)
end

--获取ui组件
function UIHauteCoutureDrawDuplicateRewardBase:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.bg = self:GetUIComponent("RawImageLoader", "bg")
    ---@type UICustomWidgetPool
    self.items = self:GetUIComponent("UISelectObjectPath", "items")
    --generated end--
end
---Item类,如果有需求可以重写
function UIHauteCoutureDrawDuplicateRewardBase:GetItemClassName()
    return UIHauteCoutureDuplicateItem._className
end
function UIHauteCoutureDrawDuplicateRewardBase:GetGetItemUIInfo()
    Log.exception("子类必须重写此GetGetItemUIInfo方法:", debug.traceback())
end
--按钮点击
function UIHauteCoutureDrawDuplicateRewardBase:CloseBtnOnClick(go)
    self.uiOwner:CloseDialog()
end

function UIHauteCoutureDrawDuplicateRewardBase:OnItemClick(id, pos, count)
    if self._selectInfo then
        local cfg = Cfg.cfg_item[id]
        local info = {
            -- item_index = i,
            item_id = id,
            item_count = count,
            -- item_des = sortItems[i].des,
            -- award_type = sortItems[i].type,
            icon = cfg.Icon,
            item_name = cfg.Name,
            simple_desc = cfg.RpIntro,
            color = cfg.Color
        }
        self._selectDetail:SetData(info)
        self._selectInfo:OnlyShow(pos)
    end
end
