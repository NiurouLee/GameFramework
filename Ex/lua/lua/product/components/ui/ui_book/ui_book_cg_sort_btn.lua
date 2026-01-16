---@class UIBookCGSortBtn:UICustomWidget
_class("UIBookCGSortBtn", UICustomWidget)
UIBookCGSortBtn = UIBookCGSortBtn

function UIBookCGSortBtn:Constructor()
    self.names = {
        [BookCGType.Main] = StringTable.Get("str_book_cg_main"), -- 主线
        [BookCGType.Ext] = StringTable.Get("str_book_cg_ext"), -- 番外
        [BookCGType.Season] = StringTable.Get("str_season_system_name"), -- 赛季
        [BookCGType.Pet] = StringTable.Get("str_book_cg_pet_skin") -- 星灵
    }
end
function UIBookCGSortBtn:OnShow(uiParams)
end

function UIBookCGSortBtn:GetComponents()
    self._name = self:GetUIComponent("UILocalizationText", "name")
    self._selectImgGo = self:GetGameObject("selectImg")
end

function UIBookCGSortBtn:SetData(cgType, curCgType, callback)
    self:GetComponents()
    self._cgType = cgType
    self._callback = callback
    self:OnValue(curCgType)
end

function UIBookCGSortBtn:OnValue(curCgType)
    self._name:SetText(self.names[self._cgType])
    self:Flush(curCgType)
end

function UIBookCGSortBtn:bgOnClick()
    if self._callback then
        self._callback(self._cgType)
    end
end

function UIBookCGSortBtn:Flush(cgType)
    if cgType == self._cgType then
        self._selectImgGo:SetActive(true)
        self._name.color = Color(252 / 255, 232 / 255, 2 / 255, 1)
    else
        self._selectImgGo:SetActive(false)
        self._name.color = Color(1, 1, 1, 1)
    end
end
