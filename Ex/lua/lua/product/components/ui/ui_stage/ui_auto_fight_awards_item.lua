--
---@class UIAutoFightAwardsItem : UICustomWidget
_class("UIAutoFightAwardsItem", UICustomWidget)
UIAutoFightAwardsItem = UIAutoFightAwardsItem
--初始化
function UIAutoFightAwardsItem:OnShow(uiParams)
    self:InitWidget()

    -- ScrollRectChild not exist
    -- self.awards:RefreshParent()
end

--获取ui组件
function UIAutoFightAwardsItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.times = self:GetUIComponent("UILocalizationText", "times")
    ---@type UILocalizationText
    self.double = self:GetUIComponent("UILocalizationText", "double")
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UnityEngine.GameObject
    self.fighting = self:GetGameObject("fighting")
    ---@type UnityEngine.GameObject
    self.noAwards = self:GetGameObject("noAwards")
    --generated end--
    ---@type ScrollRectChild
    self.awards = self:GetUIComponent("ScrollRect", "awards")
end

--设置数据
---@param count number 战斗次数
---@param doubleCount number 本次消耗的双倍券数量，可能为nil
---@param awards RoleAsset[] 奖励列表，可能为nil
---@param fightingNum number 如果正在局内战斗中，此值为正在打的次数
---@param onItemClick function 物品点击回调
function UIAutoFightAwardsItem:SetData(matchType, count, doubleCount, awards, fightingNum, title, matchResult, onItemClick)
    self._matchType = matchType

    self.times:SetText(title)

    if count == fightingNum then
        self:GetGameObject("fighting"):SetActive(true)
        self:GetGameObject("double"):SetActive(false)
        self:GetGameObject("success"):SetActive(false)
        self:GetGameObject("failed"):SetActive(false)
        self:GetGameObject("noAwards"):SetActive(false)
        self.content:SpawnObjects("UIItem", 0)
    else
        self:GetGameObject("fighting"):SetActive(false)
        if awards and #awards > 0 then
            self:GetGameObject("noAwards"):SetActive(false)
            self:GetGameObject("failed"):SetActive(false)
            if not doubleCount or doubleCount == 0 then
                self:GetGameObject("success"):SetActive(true)
                self:GetGameObject("double"):SetActive(false)
                self:GetGameObject("one"):SetActive(false)
                self:GetGameObject("two"):SetActive(false)
            elseif doubleCount == 1 then
                self:GetGameObject("success"):SetActive(false)
                self:GetGameObject("double"):SetActive(true)
                self:GetGameObject("one"):SetActive(true)
                self:GetGameObject("two"):SetActive(false)
            elseif doubleCount == 2 then
                self:GetGameObject("success"):SetActive(false)
                self:GetGameObject("double"):SetActive(true)
                self:GetGameObject("one"):SetActive(false)
                self:GetGameObject("two"):SetActive(true)
            else
                Log.exception("携行者数量错误:", doubleCount)
            end
            ---@type UIItem[]
            local items = self.content:SpawnObjects("UIItem", #awards)
            for i, asset in ipairs(awards) do
                local award = Award:New()
                local item = items[i]
                award:InitWithCount(asset.assetid, asset.count)
                item:SetForm(UIItemForm.Base)
                local activityText = ""
                if asset.type == StageAwardType.Activity then
                    award.type = asset.type
                    activityText = StringTable.Get("str_item_xianshi")
                end
                item:SetData(
                    {
                        icon = award.icon,
                        text1 = award.count,
                        quality = award.color,
                        itemId = award.id,
                        activityText = activityText
                    }
                )
                item:SetClickCallBack(
                    function(go)
                        onItemClick(award.id, go.transform.position)
                    end
                )
            end
        elseif matchResult and matchType == MatchType.MT_Tower then -- 尖塔挑战成功但无首通奖励时
            self:GetGameObject("double"):SetActive(false)
            self:GetGameObject("noAwards"):SetActive(true)
            self:GetGameObject("success"):SetActive(true)
            self:GetGameObject("failed"):SetActive(false)
            self.content:SpawnObjects("UIItem", 0)
        else
            self:GetGameObject("double"):SetActive(false)
            self:GetGameObject("noAwards"):SetActive(true)
            self:GetGameObject("success"):SetActive(false)
            self:GetGameObject("failed"):SetActive(true)
            self.content:SpawnObjects("UIItem", 0)
        end
    end

    self:FormatAwardsScale()
end

function UIAutoFightAwardsItem:FormatAwardsScale()
    local items = self.content:GetAllSpawnList()
    for k, v in pairs(items) do
        local itemGo = v:GetGameObject()
        itemGo.transform.localScale = Vector3(0.8, 0.8, 1)
    end
end

-- ScrollRectChild not exist
-- self.awards:RefreshParent()
function UIAutoFightAwardsItem:ParentParentSr(ppSr)
    local items = self.content:GetAllSpawnList()
    for k, v in pairs(items) do
        local go = v:GetBtn()
        local uiDrag = go:GetComponent("UIDrag")
        uiDrag.mScrollViewRect = self.awards

        local uiDrag = go:AddComponent(typeof(UIDrag))
        uiDrag.mScrollViewRect = ppSr
    end

    local uiDrag = self.awards.gameObject:AddComponent(typeof(UIDrag))
    uiDrag.mScrollViewRect = ppSr
end