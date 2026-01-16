---@class UIN29DetectiveCluePopController: UIController
_class("UIN29DetectiveCluePopController", UIController)
UIN29DetectiveCluePopController = UIN29DetectiveCluePopController

function UIN29DetectiveCluePopController:LoadDataOnEnter(TT, res, uiParams)

end

--初始化
function UIN29DetectiveCluePopController:OnShow(uiParams)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20ShowNormalResult)
    self.clueId = uiParams[1]
    self.type = uiParams[2]
    self.callback = uiParams[3]
    self:InitWidget()
    self:InitData()
end
--获取ui组件
function UIN29DetectiveCluePopController:InitWidget()

    ---@type UnityEngine.UI.Image
    self._item = self:GetUIComponent("RawImageLoader", "Item")
    ---@type UILocalizationText
    self._name = self:GetUIComponent("UILocalizationText", "Name")
    ---@type UILocalizationText
    self._Info = self:GetUIComponent("UILocalizedTMP", "Info")
    self._anim = self:GetUIComponent("Animation", "Anim")
end

function UIN29DetectiveCluePopController:InitData()
    self:SetFontMat("ui_n29_detective_clue_pop_text_outline.mat")
    local cfg = Cfg.cfg_component_detective_item[self.clueId]
    local Name = cfg.Name
    local Icon = cfg.Icon
    local info = cfg.Info
    self._anim:Play("uieff_UIN29DetectiveCluePopController_in")
    self._item:LoadImage(Icon)
    self._name:SetText(StringTable.Get(Name))
    self._Info:SetText(StringTable.Get(info))
end

function UIN29DetectiveCluePopController:SetFontMat(resname)
    self._res = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    -- if not self._res  then
    --     return
    -- end 
    -- local obj  = self._res.Obj
    -- local mat = lable.fontMaterial
    -- lable.fontMaterial = obj
    -- lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
    if self._res and self._res.Obj then
        self.mat = self._res.Obj
        local oldMaterial = self._Info.fontMaterial
        self._Info.fontMaterial = self.mat
        self._Info.fontMaterial:SetTexture("_MainTex", oldMaterial:GetTexture("_MainTex"))
    end
end

------------------------------onclick--------------------------------
function UIN29DetectiveCluePopController:CloseOnClick()
    --废弃
    --人物点动效	弹窗关闭后，对话列表、退出、线索库按钮滑入
    --探索点动效    弹窗变为一个光点飞入线索按钮，同时调查进度+1
    -- if self.type == UIN29DetectiveType.Person then
    --     Log.fatal("人物点动效")
    -- else
    --     Log.fatal("探索点动效")
    -- end
    self._anim:Play("uieff_UIN29DetectiveCluePopController_out")
    self:CloseDialog()
    if self.callback then
        self.callback()
    end

end

function UIN29DetectiveCluePopController:OnHide()
    
end