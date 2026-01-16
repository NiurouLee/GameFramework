---@class UIDrawCardAwardDetailItemNew:UICustomWidget
_class("UIDrawCardAwardDetailItemNew", UICustomWidget)
UIDrawCardAwardDetailItemNew = UIDrawCardAwardDetailItemNew

function UIDrawCardAwardDetailItemNew:OnShow()
    self.title = self:GetUIComponent("UILocalizationText", "title")
    self.detail = self:GetUIComponent("UILocalizationText", "detail")
    self.content = self:GetGameObject("content")
    self.detailItem = self:GetUIComponent("UISelectObjectPath","DetailItem") 
    self.allPetTitle = self:GetGameObject("AllpetTitle")
    self.upTitle = self:GetGameObject("upTitle")
    self.upSix = self:GetGameObject("UpSix")
    self.upPetSix = self:GetGameObject("UpPetSix")
    self.upFive = self:GetGameObject("UpFive")
    self.upPetFive = self:GetGameObject("UpPetFive")
    self.mustTitle = self:GetGameObject("mustTitle")
    self.must = self:GetGameObject("must")
    self.sixup = self:GetUIComponent("UISelectObjectPath","Sixup")
    self.fiveup = self:GetUIComponent("UISelectObjectPath","Fiveup")
    self.mustPet = self:GetUIComponent("UISelectObjectPath","mustPet")
    self.sixrateText = self:GetUIComponent("UILocalizationText", "sixrate")
    self.fiverateText = self:GetUIComponent("UILocalizationText", "fiverate")
    self.mustText = self:GetUIComponent("UILocalizationText", "mustText")
    self.upTitleText = self:GetUIComponent("UILocalizationText", "upTitleText")
end

function UIDrawCardAwardDetailItemNew:SetData(title, content,id)

    self.poolId=id
    local cfg = Cfg.cfg_drawcard_pool_view[id]

    self.title.text = StringTable.Get(title)
    if content then
        self.detail.text = StringTable.Get(content)
    else
        self.content:SetActive(false)
    end
    --id为卡池id，不传id时不显示光灵概率相关部分内容
    if not id then
        self.allPetTitle:SetActive(false)
        self.upTitle:SetActive(false)
        self.upSix:SetActive(false)
        self.upPetSix:SetActive(false)
        self.upFive:SetActive(false)
        self.upPetFive:SetActive(false)
        self.mustTitle:SetActive(false)
        self.must:SetActive(false)
        self.detailItem:ClearWidgets()
    end

 
    --全部可能出现的光灵部分
    if id then
        self.allPetTitle:SetActive(true)
        self.detailItem:SpawnObjects("UIDrawCardAwardPet", 4)
        local item = self.detailItem:GetAllSpawnList()
        for k, value in ipairs(item) do
            value:SetData(k,id)
        end
        UnityEngine.Canvas.ForceUpdateCanvases()
    end
    --细分光灵up，十连必得和没有up的情况
    if id then
        local fivepet = cfg.fiveup
        local sixpet = cfg.sixup
        local fivetitle = cfg.fivetitle
        local sixtitle = cfg.sixtitle
        --六星光灵up
        if sixpet and sixpet[1] and sixpet[1][2] then
            self.upTitle:SetActive(true)
            self.upSix:SetActive(true)
            self.upPetSix:SetActive(true)
            self.upTitleText:SetText(StringTable.Get(sixtitle[1]))
            self.sixrateText:SetText(StringTable.Get(sixtitle[2]))
            self.sixup:SpawnObjects("UIDrawCardAwardPetItem",#sixpet)
            self.sixitems = self.sixup:GetAllSpawnList()
            for idx, value in ipairs(self.sixitems) do
                value:SetData(6, sixpet[idx][1],sixpet[idx][2]/1000)
            end
        end
        --十连必得光灵
        if sixpet and sixpet[1] and sixpet[1][2] == nil then
            self.mustTitle:SetActive(true)
            self.must:SetActive(true)
            self.mustText:SetText(StringTable.Get(sixtitle[1]))
            self.mustPet:SpawnObjects("UIDrawCardAwardPetItem",#sixpet)
            self.mustPetItems = self.mustPet:GetAllSpawnList()
            for idx, value in ipairs(self.mustPetItems) do
                value:SetData(6, sixpet[idx][1])
            end
        end
        --五星光灵up
        if fivepet and fivepet[1] and fivepet[1][2] then
            self.upTitle:SetActive(true)
            self.upFive:SetActive(true)
            self.upPetFive:SetActive(true)
            self.upTitleText:SetText(StringTable.Get(fivetitle[1]))
            self.fiverateText:SetText(StringTable.Get(fivetitle[2]))
            self.fiveup:SpawnObjects("UIDrawCardAwardPetItem",#fivepet)
            self.fiveitems = self.fiveup:GetAllSpawnList()
            for idx, value in ipairs(self.fiveitems) do
                value:SetData(5, fivepet[idx][1],fivepet[idx][2]/1000)
            end
        end
        -- --五星光灵特殊文本暂无
        -- if fivepet and fivepet[1] and fivepet[1][2] == nil then
        --     self.mustTitle:SetActive(true)
        --     self.mustText:SetText(fivetitle[1])
        --     self.fiveup:SpawnObjects("UIDrawCardAwardPetItem",#fivepet)
        --     self.fiveitems = self.fiveup:GetAllSpawnList()
        --     for idx, value in ipairs(self.fiveitems) do
        --         value:SetData(5, fivepet[idx][1])
        --     end
        -- end
    end

    
 
end

-- function UIDrawCardAwardDetailItemNew:LoadAllPetData()
--     self.allPetTitle:SetActive(true)
--     if self.poolId then
--         self.allPetTitle:SetActive(true)
--         self.detailItem:SpawnObjects("UIDrawCardAwardPet", 4)
--         local item = self.detailItem:GetAllSpawnList()
        
--         for k, value in ipairs(item) do
--             value:SetData(k,self.poolId)
--         end
--     end
-- end

function UIDrawCardAwardDetailItemNew:OnHide()
end
