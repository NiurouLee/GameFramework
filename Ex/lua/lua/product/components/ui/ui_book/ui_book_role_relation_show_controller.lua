---@class UIBookRoleRelationShowController : UIController
_class("UIBookRoleRelationShowController", UIController)
UIBookRoleRelationShowController = UIBookRoleRelationShowController

function UIBookRoleRelationShowController:Constructor()
    self.showBtns = true
end

function UIBookRoleRelationShowController:OnShow(uiParams)
    local data = uiParams[1]
    local shiLiTag = uiParams[2]
    local friendTag = uiParams[3]

    local dataList = {}
    for index, value in ipairs(data) do
        local cfg = Cfg.cfg_pet[value.petTempId]
        local param = {}
        param.pic = cfg.BookStaticBody
        -- param.pos = Vector3(cfg.BookPos[1], cfg.BookPos[2], cfg.BookPos[3])
        -- param.scale = Vector3(cfg.BookScale, cfg.BookScale, cfg.BookScale)
        -- param.layer = cfg.BookLayer
        param.active = value.petPsdId > 0
        table.insert(dataList, param)
    end
    -- table.sort(
    --     dataList,
    --     function(a, b)
    --         return a.layer > b.layer
    --     end
    -- )
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end
    )
    self.topLeftAnchor = self:GetGameObject("TopLeftAnchor")
    self.bottomAnchor = self:GetGameObject("BottomAnchor")
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    local friendCfg = Cfg.cfg_pet_tags[friendTag]
    local shiLiCfg = Cfg.cfg_pet_tags[shiLiTag]

    self.nameTxt:SetText(StringTable.Get(friendCfg.Name))
    self.descTxt:SetText(StringTable.Get(friendCfg.Desc))

    self.pic = {}
    self.picRect = {}
    self.picGO = {}
    local count = table.count(dataList)
    for index = 1, 7 do
        self.picGO[index] = self:GetGameObject("pic" .. index)
        if index > count then
            self.picGO[index]:SetActive(false)
        else
            self.pic[index] = self:GetUIComponent("RawImageLoader", "pic" .. index)
            self.picRect[index] = self:GetUIComponent("RectTransform", "pic" .. index)
            self.picGO[index]:SetActive(true)
        end
    end
    count = count >= 7 and 7 or count
    local scale = ResolutionManager.RealWidth() / 2048
    for index = 1, count do
        if dataList[index].active then
            -- self.pic[index]:Load(dataList[index].pic, "tujian_lihui_frame3")
            self.picGO[index]:SetActive(false)
        else
            -- self.picRect[index].localPosition = dataList[index].pos
            -- self.picRect[index].localScale = dataList[index].scale
            self.pic[index]:LoadImage(dataList[index].pic)
            self.picGO[index]:SetActive(true)
            -- self.picGO[index].transform.localScale = Vector3(scale, scale, 1)
        end
    end
    self.bigImage = self:GetUIComponent("RawImageLoader", "bigimage")
    self.bigImage:LoadImage(friendCfg.GroupPhoto)

    self._cgRt = self:GetUIComponent("RectTransform","bigimage")
    --获取图的比例
    local cgRate = 1.764
    --当前屏幕比
    local screenWidth = ResolutionManager.RealWidth()
    local blackWidth = ResolutionManager.BangWidth()
    local nowWidth = screenWidth - blackWidth * 2
    local screenHeight = ResolutionManager.RealHeight()
    Log.debug("###[UIBookRoleRelationShowController] nowWidth --> ",nowWidth,"| screenHeight --> ",screenHeight)

    local screenRate = nowWidth/screenHeight
    Log.debug("###[UIBookRoleRelationShowController] screenRate --> ",screenRate)

    local setVector2
    if cgRate < screenRate then
        --高上下对齐
        local setWidth = screenHeight * cgRate
        setVector2 = Vector2(setWidth,screenHeight)
    else
        --宽左右对齐
        local setHeight = nowWidth / cgRate
        setVector2 = Vector2(nowWidth,setHeight)
    end
    self._cgRt.sizeDelta = setVector2

    for index = 1, count do
        if self.picRect[index] then
            self.picRect[index] .sizeDelta = setVector2
        end
    end

    --self.bigImage.transform.localScale = Vector3(scale, scale, 1)
end

function UIBookRoleRelationShowController:OnHide()
end

function UIBookRoleRelationShowController:bgbtnOnClick()
    self.showBtns = not self.showBtns
    if self.showBtns then
        self.topLeftAnchor:SetActive(true)
        self.bottomAnchor:SetActive(true)
    else
        self.topLeftAnchor:SetActive(false)
        self.bottomAnchor:SetActive(false)
    end
end
