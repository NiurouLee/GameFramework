--结算View
---@class UIBounceResult : UICustomWidget
_class("UIBounceResult", UICustomWidget)
UIBounceResult = UIBounceResult
--初始化
function UIBounceResult:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIBounceResult:InitWidget()
    --generated--
    self._atlas = self:GetAsset("UIN28MinigameIn.spriteatlas", LoadType.SpriteAtlas) 
    self.new = self:GetGameObject("new")
    self.chall = self:GetGameObject("chall")
    self.historyScorePar = self:GetGameObject("historyScorePar")
    self.historyScore = self:GetGameObject("historyScore")
    self.curScore = self:GetGameObject("curScore")
    self.historyScoreItems = {}
    self.curScoreItems = {}
    for i = 1, 4, 1 do
        self.historyScoreItems[i] = self.historyScore.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
    end
    for i = 1, 4, 1 do
        self.curScoreItems[i] = self.curScore.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
    end
    self.new:SetActive(false)
    --generated end--
end

--设置数据
---@param exitCall function 退出回调
---@param fightCall function 继续挑战回调 
function UIBounceResult:Init(exitCall,fightCall)
    self._exitCall = exitCall
    self._fightCall = fightCall
end

-- 
function UIBounceResult:FlushUI(gameData)
    if not gameData then 
       return 
    end 

    local res = UIN28GronruGameConst.GetScoreFont(gameData.historyBestScore)
    for i = 1, 4, 1 do
        self.historyScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..res[i])
    end
    res = UIN28GronruGameConst.GetScoreFont(gameData.score)
    for i = 1, 4, 1 do
        self.curScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..res[i])
    end
    -- 无尽关卡 特殊显示
    self.new:SetActive(gameData.levelId == 7 and gameData.score > gameData.historyBestScore)
    self.historyScorePar:SetActive(gameData.levelId == 7)
end

--按钮点击
function UIBounceResult:ExitBtnOnClick(go)
    if self._exitCall then
        self._exitCall()
    end  
end

--按钮点击
function UIBounceResult:FightBtnOnClick(go)
    if self._fightCall then
        self._fightCall()
    end  
end
