---@class UIMissionItem : UICustomWidget
_class("UIMissionItem", UICustomWidget)
UIMissionItem = UIMissionItem
function UIMissionItem:OnShow(uiParams)
    self.talePetModule = GameGlobal.GetModule(TalePetModule)
    self.describle = ""
    self.num = 0
    self:InitWidget()
    self:_AttachEvents()
end

function UIMissionItem:OnHide()
    self.active = false
    self:_DetachEvents()
    if self.showInTask then
        GameGlobal.TaskManager():KillTask(self.showInTask)
        self.showInTask = nil
    end
end

function UIMissionItem:_AttachEvents()
    self:AttachEvent(GameEventType.TalePetInfoDataChange,self.InfoDataChange)
end

function UIMissionItem:_DetachEvents()
    self:DetachEvent(GameEventType.TalePetInfoDataChange,self.InfoDataChange)
end

function UIMissionItem:InfoDataChange()
    self:OnRefreshUI()
end

function UIMissionItem:InitWidget()
    self.Bg = self:GetUIComponent("Image","Bg")
    self.progress = self:GetUIComponent("Slider","progress")
    self.curNum = self:GetUIComponent("UILocalizationText","curNum")
    self.totalNum = self:GetUIComponent("UILocalizationText","totalNum")
    self.txtDescrible = self:GetUIComponent("UILocalizationText","txtDescrible")
    self.complete = self:GetGameObject("complete")
    self.running = self:GetGameObject("running")
    self.btnSubmit = self:GetGameObject("btnSubmit")
    self.txtObj = self:GetGameObject("txtObj")
    self.btnDrag = self:GetUIComponent("UIDrag","btnSubmit")

    self.item = self:GetGameObject("item")

    self.BgSpriteN = "legend_sixiang_di16"
    self.BgSpriteY = "legend_sixiang_di17"

    self.atlas = self:GetAsset("UITalePet.spriteatlas", LoadType.SpriteAtlas)
end

function UIMissionItem:ShowInAnim()
    self.showInTask = self:StartTask(self.ShowInAnimT,self)
end

function UIMissionItem:ShowInAnimT(TT)
    self.itemRect = self:GetUIComponent("RectTransform","item")
    self.itemCanvas = self:GetUIComponent("CanvasGroup","item")

    self.itemCanvas.alpha = 0
    self.itemRect.anchoredPosition = Vector2(900,self.itemRect.anchoredPosition.y)

    local durA = (9/30)
    self.itemCanvas:DOFade(1,durA)
    local durR = 20/30
    self.itemRect:DOAnchorPosX(315.5,durR)
    
    ---self.itemRect.anchoredPosition = Vector2(700,self.itemRect.anchoredPosition.y)
end

--- 任务索引
--- 光灵ID
--- 阶段id
function UIMissionItem:SetData(index,petId,stage,active)
    self.index = index
    self.petId = petId
    self.stage = stage
    self.active = active

    if self.active then
        self:OnRefreshUI()
    else
        self:OnHide()
    end
    
    --计数任务
        --任务描述
        --任务进度
        --数量统计
        --任务状态
    --提交道具任务
        --任务描述
        --任务进度
        --数量统计
        --任务状态
        --提交按钮
end

function UIMissionItem:OnRefreshUI()
    
    local cfg_stage = Cfg.cfg_tale_task{PetID = self.petId,Phase = self.stage}
    local cfg = cfg_stage[self.index]
    
    if not cfg then
        return
    end

    if self.talePetModule:IsOpenActity() then
        self.txtDescrible:SetText(StringTable.Get(cfg.ActiveDesc))
        self.describle = StringTable.Get(cfg.ActiveDesc)
    else
        self.txtDescrible:SetText(StringTable.Get(cfg.TaskDesc))
        self.describle = StringTable.Get(cfg.TaskDesc)
    end
    
    local info = self.talePetModule:GetPetInfo(self.petId)
    if info == nil then
        return
    end
    if info.pet_status == TalePetCallType.TPCT_Can_Do or info.pet_status == TalePetCallType.TPCT_Done then
        self:MissionComRefresh()
        return
    end
    local curInfo
    for key, value in pairs(info.datas) do
        if key == cfg.ID then
            curInfo = value
        end
    end
    if curInfo == nil then
        self:MissionComRefresh()
        return
    end
    self.btnSubmit:SetActive(false)
    self.running:SetActive(false)
    self.complete:SetActive(false)
    if curInfo.status then
        --任务已完成
        self:MissionComRefresh()
    else
        self.progress.value = curInfo.cur / curInfo.total
        self.num = curInfo.total
        --self.txtObj:SetActive(true)
        -- self.curNum:SetText(curInfo.cur)
        -- self.totalNum:SetText(curInfo.total)
        self.curNum:SetText("<color=#fd9e00>" .. curInfo.cur .. "</color><color=#ffffff>/</color><color=#ffffff>" .. curInfo.total .. "</color>")
        self.Bg.sprite = self.atlas:GetSprite(self.BgSpriteN)
        if curInfo.item_cfg_id > 0 then
            -- 提交道具任务
            self.btnSubmit:SetActive(true)
            self.running:SetActive(false)
        else
            -- 计数任务
            self.running:SetActive(true)
            self.btnSubmit:SetActive(false)
        end
    end
    self.curInfo = curInfo
end

function UIMissionItem:MissionComRefresh()
    self.progress.value = 1
    --self.txtObj:SetActive(false)
    self.curNum:SetText(StringTable.Get("str_tale_pet_task_comp"))
    self.btnSubmit:SetActive(false)
    self.running:SetActive(false)
    self.complete:SetActive(true)
    self.Bg.sprite = self.atlas:GetSprite(self.BgSpriteY)
end

--提交任务
function UIMissionItem:btnSubmitOnClick()
    --任务类型为提交道具任务时点击提交
    local itemId = self.curInfo.item_cfg_id
    self:ShowDialog("UIMissionSubmitItem",itemId,self.describle,self.num)
end


