--[[
    @图鉴总览界面
]]
---@class UIBookRoleEntryController:UIController
_class("UIBookRoleEntryController", UIController)
UIBookRoleEntryController = UIBookRoleEntryController

function UIBookRoleEntryController:OnShow(uiParams)
    local openMainType = uiParams[1]
    local openSubType = uiParams[2]
    -- local bookModule = self:GetModule(BookModule)
    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            -- if not GameGlobal.UIStateManager():IsShow("UIMain") then
            --     self:SwitchState(UIStateType.UIMain)
            -- else
            self:CloseDialog()
            -- end
        end
    )
    self.g1 = self:GetUIComponent("UIView", "g_1")
    self.g2 = self:GetUIComponent("UIView", "g_2")
    self.g3 = self:GetUIComponent("UIView", "g_3")
    self.g4 = self:GetUIComponent("UIView", "g_4")
    self.g5 = self:GetUIComponent("UIView", "g_5")
    self.g6 = self:GetUIComponent("UIView", "g_6")
    self.g7 = self:GetUIComponent("UIView", "g_7")
    self.g8 = self:GetUIComponent("UIView", "g_8")
    -- BaiYeCheng = 1001, --白夜城
    -- BaiYeXiaCheng = 1002, --白夜下城
    -- QiGuang = 1003, --启光
    -- BeiJing = 1004, --北境
    -- HongYouBanShou = 1005, --红油扳手
    -- TaiYangJiaoTuan = 1006, --太阳教团
    -- YouMin = 1007, --游民
    -- Rishi = 1008, --日蚀
    -- PetFilterType
    local atlas = self:GetAsset("UIBook.spriteatlas", LoadType.SpriteAtlas)
    self.cell1 = UIBookRoleEntryCell:New()
    self.cell1:Refresh(self.g1, atlas, PetFilterType.BaiYeCheng)
    self.cell2 = UIBookRoleEntryCell:New()
    self.cell2:Refresh(self.g2, atlas, PetFilterType.BaiYeXiaCheng)
    self.cell3 = UIBookRoleEntryCell:New()
    self.cell3:Refresh(self.g3, atlas, PetFilterType.QiGuang)
    self.cell4 = UIBookRoleEntryCell:New()
    self.cell4:Refresh(self.g4, atlas, PetFilterType.BeiJing)
    self.cell5 = UIBookRoleEntryCell:New()
    self.cell5:Refresh(self.g5, atlas, PetFilterType.HongYouBanShou)
    self.cell6 = UIBookRoleEntryCell:New()
    self.cell6:Refresh(self.g6, atlas, PetFilterType.TaiYangJiaoTuan)
    self.cell7 = UIBookRoleEntryCell:New()
    self.cell7:Refresh(self.g7, atlas, PetFilterType.YouMin)
    self.cell8 = UIBookRoleEntryCell:New()
    self.cell8:Refresh(self.g8, atlas, PetFilterType.RiShi)

    -- self:Refresh()
    -- if openMainType then
    --     self.entrys[openMainType]:picOnClick(nil, openSubType)
    -- end
end
function UIBookRoleEntryController:LoadDataOnEnter(TT, res, uiParams)
    -- local bookModule = self:GetModule(BookModule)
    -- local result = bookModule:GetOpenStatus(TT)
    -- if result and table.count(result) > 0 then
    res:SetSucc(true)
    -- else
    --     res:SetSucc(false)
    -- end
end

-- function UIBookRoleEntryController:Refresh(dontShowAni)
--     local entryDatas = self.clientResInstance:GetEntryDatas()
--     for index, entry in ipairs(self.entrys) do
--         ---@type UIResEntryCell
--         entry:Refresh(entryDatas[index], dontShowAni)
--     end
-- end
function UIBookRoleEntryController:OnUpdate(deltaTimeMS)
end

function UIBookRoleEntryController:OnHide()
    self.cell1:OnHide()
    self.cell2:OnHide()
    self.cell3:OnHide()
    self.cell4:OnHide()
    self.cell5:OnHide()
    self.cell6:OnHide()
    self.cell7:OnHide()
    self.cell8:OnHide()
end

-- function UIBookRoleEntryController:GetEntryCell(mainType)
--     for index, entry in ipairs(self.entrys) do
--         if entry:GetMainType() == mainType then
--             return entry:GetGameObject("pic")
--         end
--     end
-- end
