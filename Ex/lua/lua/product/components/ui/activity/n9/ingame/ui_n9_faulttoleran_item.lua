---@class UIN9FaultTolerantItem : UICustomWidget
_class("UIN9FaultTolerantItem", UICustomWidget)
UIN9FaultTolerantItem = UIN9FaultTolerantItem
function UIN9FaultTolerantItem:OnShow(uiParams)
    self:InitWidget()
end

function UIN9FaultTolerantItem:OnHide() 

end 
function UIN9FaultTolerantItem:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.used = self:GetGameObject("used")
    ---@type UnityEngine.GameObject
    self.nouse = self:GetGameObject("nouse")
    ---@type UnityEngine.Animation
    self.ani = self:GetUIComponent("Animation","go")
    --generated end--
end

function UIN9FaultTolerantItem:Refresh() 
    self.used:SetActive(true)
    self.nouse:SetActive(true)
end 
function UIN9FaultTolerantItem:SetUsed(used) 
    self:StartTask(
        function(TT)
            YIELD(TT, 1000)
            if not (self.nouse and  self.nouse.gameObject) then  return end 
            self.nouse:SetActive(not used)
            self.used:SetActive(used)
        end,
        self
    )
end 
function UIN9FaultTolerantItem:SetData(nIndex)
    self._index = nIndex
end 

function UIN9FaultTolerantItem:PlayeAni()
    self.ani:Play("uieff_FaultToLearnItem_Fade")
end 




