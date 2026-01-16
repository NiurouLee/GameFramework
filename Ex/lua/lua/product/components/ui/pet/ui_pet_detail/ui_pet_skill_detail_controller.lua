---@class UIPetSkillDetailController : UIController
_class("UIPetSkillDetailController", UIController)
UIPetSkillDetailController = UIPetSkillDetailController

function UIPetSkillDetailController:Constructor()
end

function UIPetSkillDetailController:OnShow(uiParams)
    ---@type Pet
    self._petData = uiParams[1]

    self._petModule = GameGlobal.GameLogic():GetModule(PetModule)

    self._skillRowPool = self:GetUIComponent("UISelectObjectPath", "fightSkillUISelectObjectPath")

    ---@type UnityEngine.RectTransform
    self._skillPanelTr = self:GetUIComponent("RectTransform", "MovePanel")
    self._skillPanelRightPos = self:GetUIComponent("RectTransform", "RightAnchorPos")

    -----------------------------------------------------------------------------------
    self._leftPos = self:GetUIComponent("RectTransform", "LeftAnchorPos")

    self._leftPos.anchoredPosition = Vector2(uiParams[2], 0)

    self._closeCallback = uiParams[3]

    self._tweener = nil

    self._skillPanelTr.position = self._leftPos.position
    -- self._skillPanelTr.position = self._skillPanelRightPos.position

    --点击关闭时候移动中不在触发关闭事件
    self._isMoving = false
    
    self:RefreshPetSKill()
    --self:MoveSkillPanel(true)
end
function UIPetSkillDetailController:MoveSkillPanel(isOpen)
    if self._tweener then
        self._tweener:Kill()
    end

    if isOpen then
        --移动左边
        self._tweener = self._skillPanelTr:DOMove(self._leftPos.position, 0.5)

        self._isMoving = true
        self._tweener:OnComplete(
            function()
                self._isMoving = false
            end
        )
    else
        --移动右边
        ---@type DG.Tweening.Tweener
        self._tweener = self._skillPanelTr:DOMove(self._skillPanelRightPos.position, 0.4)

        self._isMoving = true
        self._tweener:OnComplete(
            function()
                self._isMoving = false
                self:CloseDialog()
            end
        )
    end
end

function UIPetSkillDetailController:OnHide()
    if self._closeCallback then
        self._closeCallback()
    end
end

function UIPetSkillDetailController:bgOnClick(go)
    self:CloseDialog()
    --[[

        if self._isMoving == false then
            --self:MoveSkillPanel(false)
        end
        ]]
end

---@private
---@param scrollView UIDynamicScrollView
---@param index number
---return UIDynamicScrollViewItem
function UIPetSkillDetailController:RefreshPetSKill()
    local _creatCount = 0
    ---@type UIPetModule
    local uiModule = self._petModule.uiModule
    self._skillDetailInfos = uiModule:GetSkillDetailInfoBySkillTypeHideExtra(self._petData)
    --self._skillDetailInfos = uiModule:GetSkillDetailInfoBySkillType(self._petData)

    
    _creatCount = table.count(self._skillDetailInfos)

    self._skillRowPool:SpawnObjects("UIFightSkillItem", _creatCount)
    ---@type UIFightSkillItem[]
    local rowList = self._skillRowPool:GetAllSpawnList()
    for index = 1, _creatCount do
        local skillItem = rowList[index]
        skillItem:GetGameObject():SetActive(true)
        skillItem:SetData(self._skillDetailInfos[index], self._petData,index)
    end
end
