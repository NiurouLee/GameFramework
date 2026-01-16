--
---@class UICampainEnterContainer : UICustomWidget
_class("UICampainEnterContainer", UICustomWidget)
UICampainEnterContainer = UICampainEnterContainer

function UICampainEnterContainer:Constructor()
   
end

--初始化
function UICampainEnterContainer:OnShow(uiParams)
    self:_GetComponents()
end


function UICampainEnterContainer:OnHide(uiParams)
   
end

--获取ui组件
function UICampainEnterContainer:_GetComponents()
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
end

--设置数据
function UICampainEnterContainer:SetData(datas,controller)
    self._datas = datas
    self._controller = controller
    self:_SetItems()
   
end

function UICampainEnterContainer:_SetItems()
    local count = #self._datas
    if count <= 0 then
        return
    end
    self._content:SpawnObjects("UICampainEnterRewardItem", count)
    ---@type table <number, UICampainEnterRewardItem>
    local items = self._content:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetData(self._datas[i],self._controller)
        items[i]:ShowAnim()
    end
    self:StartTask(self.ShowItemCoro,self)
end


function UICampainEnterContainer:Refresh()
    local items = self._content:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetData(self._datas[i],self._controller)
    end
end


function UICampainEnterContainer:ShowItemCoro(TT)
    self:Lock("UICampainEnterContainer:ShowItemCoro")
    local items = self._content:GetAllSpawnList()
    YIELD(TT,500)
    self:UnLock("UICampainEnterContainer:ShowItemCoro")
end


