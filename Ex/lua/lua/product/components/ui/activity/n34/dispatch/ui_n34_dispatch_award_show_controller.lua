--
---@class UIN34DispatchAwardShowControlller : UIController
_class("UIN34DispatchAwardShowControlller", UIController)
UIN34DispatchAwardShowControlller = UIN34DispatchAwardShowControlller

---@param res AsyncRequestRes
function UIN34DispatchAwardShowControlller:LoadDataOnEnter(TT, res)
    
end
--初始化
function UIN34DispatchAwardShowControlller:OnShow(uiParams)
    self:InitWidget()
    self:LoadWard(uiParams)
end
--获取ui组件
function UIN34DispatchAwardShowControlller:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.awardsContent = self:GetUIComponent("UISelectObjectPath", "LoadAwards")
    --generated end--
end

function UIN34DispatchAwardShowControlller:LoadWard(uiParams)
    local awards = uiParams
    self._mainItems = self.awardsContent:SpawnObjects("UIN34DispatchAwardItem",#awards)
    for i, v in ipairs(self._mainItems) do
        v:SetData(awards[i])
    end
end

--按钮点击
function UIN34DispatchAwardShowControlller:BGOnClick(go)
    self:CloseDialog()
end
