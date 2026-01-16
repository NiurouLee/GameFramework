--
---@class UISeasonMainLevelListItem : UICustomWidget
_class("UISeasonMainLevelListItem", UICustomWidget)
UISeasonMainLevelListItem = UISeasonMainLevelListItem
--初始化
function UISeasonMainLevelListItem:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonMainLevelListItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.levelName = self:GetUIComponent("UILocalizationText", "levelName")
    ---@type UnityEngine.GameObject
    self.star = self:GetGameObject("star")
    --generated end--
    self._stars = {
        self:GetGameObject("star1"),
        self:GetGameObject("star2"),
        self:GetGameObject("star3"),
    }
    ---@type UICustomWidgetPool
    self.item = self:GetUIComponent("UISelectObjectPath", "item")
    self._lockTip = self:GetGameObject("LockTip")
    self._anim = self:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
    self._root = self:GetGameObject("Root")
    self._atlas = self:GetAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
    self._icon = self:GetUIComponent("Image", "Icon")
end

--设置数据
---@param data UISeasonLevelData
function UISeasonMainLevelListItem:SetData(data, onClick)
    self._data = data
    self._onClick = onClick
    self._lockTip:SetActive(not self._data:IsUnlock()) --解锁状态不受难度影响
end

function UISeasonMainLevelListItem:RefreshByDiff(curDiff)
    ---@param type UISeasonLevelDiff
    self._curDiff = curDiff

    local levelCfg = self._data:GetMissionCfgByDiff(self._curDiff)
    local star = self._data:GetStarByDiff(self._curDiff)
    for i = 1, 3 do
        self._stars[i]:SetActive(i <= star)
    end
    local awards = self._data:GetAwardsByDiff(self._curDiff) --数量最多2个
    local tmp = {}
    for i = 1, #awards do
        tmp[#awards - i + 1] = awards[i] --倒序
    end
    awards = tmp
    ---@type UISeasonMainLevelListAsset[]
    local items = self.item:SpawnObjects("UISeasonMainLevelListAsset", #awards)
    for i = 1, #awards do
        local item  = items[i]
        local award = awards[i]
        local id    = award.ItemID
        local count = award.Count
        item:SetData(id, count)
    end
    self.levelName:SetText(StringTable.Get(levelCfg.Name))

    if self._curDiff == UISeasonLevelDiff.Normal then
        self.levelName.color = Color(206 / 255, 158 / 255, 65 / 255)
        self._icon.sprite = self._atlas:GetSprite("exp_s1_map_icon13")
    elseif self._curDiff == UISeasonLevelDiff.Hard then
        self.levelName.color = Color(203 / 255, 80 / 255, 57 / 255)
        self._icon.sprite = self._atlas:GetSprite("exp_s1_map_icon14")
    end
end

function UISeasonMainLevelListItem:PrepareAnim()
    self._root:SetActive(false)
end

function UISeasonMainLevelListItem:PlayEnterAnim()
    self._root:SetActive(true)
    self._anim:Play("uianim_UISeasonMainLevelListItem_in")
end

function UISeasonMainLevelListItem:PlaySwitchAnim()
    self._root:SetActive(true)
    self._anim:Play("uianim_UISeasonMainLevelListItem_switch_in")
end

--按钮点击
function UISeasonMainLevelListItem:RootOnClick(go)    
    ---@type SeasonManager
    local seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    if seasonManager:LockUI() then
        return
    end
    self._onClick(self._data)
end
