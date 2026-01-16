---@class UIDrawCardAwardPoolDetailController:UIController
_class("UIDrawCardAwardPoolDetailController", UIController)
UIDrawCardAwardPoolDetailController = UIDrawCardAwardPoolDetailController

function UIDrawCardAwardPoolDetailController:OnShow(uiParam)
    ---@type table<boolean>
    self._btnStateTb = {false,false,false}  --index=1为按钮1的状态，true为激活，false为未激活 index最大为3

    ---@type PrizePoolInfo
    self._poolData = uiParam[1]
    self.cfg = Cfg.cfg_drawcard_pool_view[self._poolData.performance_id]
    self._count = #self.cfg.PoolDetailSubTitle

    self.title = self:GetUIComponent("UILocalizationText", "title")
    self.title.text = StringTable.Get(self.cfg.PoolDetailTitle)
    self._intruduce = self:GetGameObject( "intruduce")
    self._rate = self:GetGameObject( "rate")
    self._conversion = self:GetGameObject( "Conversion")

    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    self.RateContent = self:GetUIComponent("UISelectObjectPath", "RateContent")
    self.converseContent = self:GetUIComponent("UISelectObjectPath", "ConverseContent")    
    
    self._ruletag = self:GetUIComponent("Image", "ruletag")
    self._ratetag = self:GetUIComponent("Image","ratetag")
    self._conversiontag = self:GetUIComponent("Image","conversiontag")

    self._rateTip = self:GetGameObject( "ratetip")
    self._conversTip = self:GetGameObject( "conversTip")

    self._ruleText = self:GetUIComponent("UILocalizationText", "RuleText")
    self._rateText = self:GetUIComponent("UILocalizationText","RateText")
    self._conText = self:GetUIComponent("UILocalizationText","ConText")
    self._atlas = self:GetAsset("UIDrawCard.spriteatlas", LoadType.SpriteAtlas)

    --提前加载数据
    self:SetData()

    self._btnImgTb = {}
    table.insert(self._btnImgTb,self._ruletag)
    table.insert(self._btnImgTb,self._ratetag)
    table.insert(self._btnImgTb,self._conversiontag)
    self._textTb = {}
    table.insert(self._textTb,self._ruleText)
    table.insert(self._textTb,self._rateText)
    table.insert(self._textTb,self._conText)
    

    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    local tipspool = self:GetUIComponent("UISelectObjectPath", "tipspool")
    self._tipsPoolObj = self:GetGameObject("tipspool")
    self._tips = tipspool:SpawnObject("UISelectInfo")

    self.tipspool = self:GetGameObject( "tipspool")

    self:RuletagOnClick()


end

function UIDrawCardAwardPoolDetailController:SetData()
    self:StartTask(self.CreateItems, self)
end

function UIDrawCardAwardPoolDetailController:CreateItems(TT)
    
    self:Lock("UIDrawCardAwardPoolDetailController")
    YIELD(TT)
    self._rate:SetActive(true)
    local item = self.RateContent:SpawnObject("UIDrawCardAwardDetailItemNew")
    item:SetData(self.cfg.PoolDetailSubTitle[2], self.cfg.PoolDetail[2],self._poolData.performance_id)  
     
    self:UnLock("UIDrawCardAwardPoolDetailController")
    self._rate:SetActive(false)
end

function UIDrawCardAwardPoolDetailController:ShowTips(itemId, pos)
    self._tipsPoolObj:SetActive(true)
    self._tips:SetData(itemId, pos)
end

function UIDrawCardAwardPoolDetailController:OnHide()
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
end

function UIDrawCardAwardPoolDetailController:ChangeState(index)
    
    for i, v in pairs(self._btnStateTb) do
        if v then
            --将按钮的图片置灰
            local img = self._btnImgTb[i]
            img.sprite = self._atlas:GetSprite("card_pool_sm_btn02")
            local text=self._textTb[i]
            text.color=Color(242/255 , 242/255 , 242/255)
        end
        v = false
    end
    self._btnStateTb[index] = true
    --将目标按钮的图片变亮
    local whiteImg = self._btnImgTb[index]
    whiteImg.sprite =self._atlas:GetSprite("card_pool_sm_btn01")
    local text=self._textTb[index]
    text.color=Color(50/255 , 50/255 , 50/255)
 
end

function UIDrawCardAwardPoolDetailController:CloseOnClick()
    self:CloseDialog()
end

function UIDrawCardAwardPoolDetailController:RuletagOnClick()
    self._rateTip:SetActive(false)
    self._conversTip:SetActive(false)
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self.tipspool:SetActive(false)
    self._conversion:SetActive(false)
    self._intruduce:SetActive(true)
    self._rate:SetActive(false)
    local item = self.content:SpawnObject("UIDrawCardAwardDetailItemNew")
    item:SetData(self.cfg.PoolDetailSubTitle[1], self.cfg.PoolDetail[1])
    -- for idx, value in ipairs(items) do
    --     value:SetData(self.cfg.PoolDetailSubTitle[1], self.cfg.PoolDetail[1])
    -- end
    self:ChangeState(1)

end

function UIDrawCardAwardPoolDetailController:RatetagOnClick()

    self._rateTip:SetActive(true)
    self._conversTip:SetActive(false)
    self.tipspool:SetActive(false)
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self._intruduce:SetActive(false)
    self._conversion:SetActive(false)
    self._rate:SetActive(true)
   
    -- self.RateContent:SpawnObjects("UIDrawCardAwardDetailItemNew", 1)
    -- local items = self.RateContent:GetAllSpawnList()
    -- items[1]:SetData(self.cfg.PoolDetailSubTitle[2], self.cfg.PoolDetail[2],self._poolData.performance_id)

    self:ChangeState(2)
end

function UIDrawCardAwardPoolDetailController:ConversiontagOnClick()
    self._rateTip:SetActive(false)
    self._conversTip:SetActive(true)
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self.tipspool:SetActive(true)
    self._conversion:SetActive(true)
    self._intruduce:SetActive(false)
    self._rate:SetActive(false)
    self._tipsPoolObj:SetActive(false)
    self.converseContent:SpawnObjects("UIDrawCardAwardConversionItem", 4)
    local items = self.converseContent:GetAllSpawnList()

    for idx, value in ipairs(items) do
        value:SetData(idx)
    end
    self:ChangeState(3)

end
