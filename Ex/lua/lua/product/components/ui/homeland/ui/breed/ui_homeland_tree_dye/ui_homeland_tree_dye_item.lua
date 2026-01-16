---@class UIHomelandTreeDyeItem : UICustomWidget
_class("UIHomelandTreeDyeItem", UICustomWidget)
UIHomelandTreeDyeItem = UIHomelandTreeDyeItem

function UIHomelandTreeDyeItem:Constructor()
    ---@type ItemModule
    self.mItem = GameGlobal.GetModule(ItemModule)
end

function UIHomelandTreeDyeItem:OnShow(uiParams)
    ---@type RawImageLoader
    self.imgIconTree = self:GetUIComponent("RawImageLoader", "imgIconTree")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    ---@type RollingText
    self.txtName = self:GetUIComponent("RollingText", "txtName")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self.goIcon = self:GetGameObject("imgIcon")
    ---@type RollingText
    self.txtDesc = self:GetUIComponent("RollingText", "txtDesc")
    self.goDesc = self:GetGameObject("txtDesc")
    self.goDescCur = self:GetGameObject("txtDescCur")
    self.imgSelect = self:GetGameObject("imgSelect")
    self.imgSelect:SetActive(false)
    self.imgGray = self:GetGameObject("imgGray")
end
function UIHomelandTreeDyeItem:OnHide()
    self.imgIconTree:DestoryLastImage()
    self.imgIcon:DestoryLastImage()
end

---@param tplTree table item
---@param tplTreetCur table 当前树木
function UIHomelandTreeDyeItem:Flush(tplTree, index, tplTreeCur, tplItem, callBack)
    self.index = index
    self.callBack = callBack

    local cfgTree = Cfg.cfg_item[tplTree.ID]
    self.imgIconTree:LoadImage(cfgTree.Icon)
    local count = self.mItem:GetItemCount(tplTree.ID)
    self.txtCount:SetText(StringTable.Get("str_homeland_breed_tree_count", count))
    self.txtName:RefreshText(StringTable.Get(cfgTree.Name))
    if tplTree.ID == tplTreeCur.ID then --当前树
        self.goDescCur:SetActive(true)
        self.goIcon:SetActive(false)
        self.goDesc:SetActive(false)
        self.imgGray:SetActive(false)
    else
        self.goDescCur:SetActive(false)
        self.goIcon:SetActive(true)
        self.goDesc:SetActive(true)
        local cfgDye = Cfg.cfg_item[tplItem.ID]
        self.imgIcon:LoadImage(cfgDye.Icon)
        local dyeItemCount = self.mItem:GetItemCount(tplItem.ID)
        local countStr = ""
        if dyeItemCount > 0 then
            countStr = string.format("<color=#939393>:%s/1</color>", dyeItemCount)
        else
            countStr = string.format("<color=#ff0000>:%s/1</color>", dyeItemCount)
        end
        local str = StringTable.Get(cfgDye.Name)
        self.txtDesc:RefreshText(str .. countStr)
        self.imgGray:SetActive(dyeItemCount <= 0)
    end
end

function UIHomelandTreeDyeItem:FlushSelect(isSelect)
    self.imgSelect:SetActive(isSelect)
end

function UIHomelandTreeDyeItem:btnOnClick(go)
    if self.callBack then
        self.callBack()
    end
end
