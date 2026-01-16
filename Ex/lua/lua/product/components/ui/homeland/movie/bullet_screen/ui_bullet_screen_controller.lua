---@class UIHomelandBulletScreenController:UICustomWidget
_class("UIHomelandBulletScreenController", UICustomWidget)
UIHomelandBulletScreenController = UIHomelandBulletScreenController

function UIHomelandBulletScreenController:OnShow(uiParams)

end

function UIHomelandBulletScreenController:OnHide()

end

function UIHomelandBulletScreenController:SetData(timeScale, speedScale, actorScore, itemScore, optionScore, totalScore)
    self:_GetComponents()
    self:InitBulletScreenData()
    --弹幕间隔时间
    self._intervalTime = self._intervalTime * timeScale
    --弹幕速度
    self._flowSpeed = self._flowSpeed * speedScale
    --评分条件
    self._actorScoreCondition = MovieDataManager:GetInstance():GetBulletScreenCondition(actorScore)
    self._propScoreCondition = MovieDataManager:GetInstance():GetBulletScreenCondition(itemScore)
    self._optionScoreCondition = MovieDataManager:GetInstance():GetBulletScreenCondition(optionScore)
    self._totalScoreCondition = MovieDataManager:GetInstance():GetBulletScreenCondition(totalScore)
    --评分类型
    self._actorScoreType = 1
    self._propScoreType = 2
    self._optionScoreType = 3
    self._totalScoreType = 4
    --弹幕库
    self.bulletScreenList = {}
    --对象池
    self._objPoolDic = {}

    self:_OnValue()
end

function UIHomelandBulletScreenController:_GetComponents()
    self._BulletScreenRect = self:GetUIComponent("RectTransform", "BulletScreenRect")

    self._BSType1Prefab = self:GetGameObject("BSType1")
    self._BSType2Prefab = self:GetGameObject("BSType2")
    self._BSType3Prefab = self:GetGameObject("BSType3")

    self._bsPoolDic = {
        [1] = 
        {
            prefab = self._BSType1Prefab,
            type = 1,
        }, 
        [2] = 
        {
            prefab = self._BSType2Prefab,
            type = 2,
        }, 
        [3] = 
        {
            prefab = self._BSType3Prefab,
            type = 3,
        }
    }
end

function UIHomelandBulletScreenController:_OnValue()
    local actorBS = Cfg.cfg_homeland_bullet_screen{ScoreType = self._actorScoreType, ScoreCondition = self._actorScoreCondition}
    local propBS = Cfg.cfg_homeland_bullet_screen{ScoreType = self._propScoreType, ScoreCondition = self._propScoreCondition}
    local optionBS = Cfg.cfg_homeland_bullet_screen{ScoreType = self._optionScoreType, ScoreCondition = self._optionScoreCondition}
    local totalBS = Cfg.cfg_homeland_bullet_screen{ScoreType = self._totalScoreType, ScoreCondition = self._totalScoreCondition}

    self:InsertBulletScreenList(actorBS)
    self:InsertBulletScreenList(propBS)
    self:InsertBulletScreenList(optionBS)
    self:InsertBulletScreenList(totalBS)

    self:RefreshConfigPool()
end

function UIHomelandBulletScreenController:InsertBulletScreenList(cfgs)
    for _, v in pairs(cfgs) do
        table.insert(self.bulletScreenList, v)
    end
end

function UIHomelandBulletScreenController:InitBulletScreenData()
    -- 弹幕滚动速度(像素/每秒)
    self._flowSpeed = 300
    -- 弹幕生成间隔时间
    self._intervalTime = 0.1
    --弹幕上下最小间隔
    self._spaceSize = 20
    --弹幕检查队列
    self._bsCheckQueue = {}
    --屏幕宽度
    self._screenWidth = ResolutionManager.RealWidth()
    --弹幕板子高度
    self._bsPanelHeight = self._BulletScreenRect.sizeDelta.y
    --弹幕板下底值
    self._blPanelLowerPosY = -self._bsPanelHeight / 2
    --定义10像素为一个区域
    self._blockHeight = 10
    --最大间隙格数量（伪随机使用）
    self._randomMaxGap = 5

    --切片区域（200像素即-100，100）
    self._blockList = {}
    local bsPanelUpperPosY = self._bsPanelHeight / 2
    local idx = 1
    for b = self._blPanelLowerPosY, bsPanelUpperPosY, self._blockHeight do
        self._blockList[idx] = {}
        self._blockList[idx].bound = b
        self._blockList[idx].use = false
        idx = idx + 1
    end

end

function UIHomelandBulletScreenController:RefreshConfigPool()
    --弹幕库洗牌
    self.bulletScreenList = table.shuffle(self.bulletScreenList)
    --初始化索引
    self.curBulletIndex = 1
end

function UIHomelandBulletScreenController:BeginShowBulletScreen()
    local deltaTime = self._intervalTime * 1000
    self._BSTimer = GameGlobal.Timer():AddEventTimes(deltaTime, TimerTriggerCount.Infinite, function()
        self:_UpdateBulletScreenStatus()
    end)
end

function UIHomelandBulletScreenController:StopShowBulletScreen()
    if self._BSTimer then
        GameGlobal.Timer():CancelEvent(self._BSTimer)
    end
end

function UIHomelandBulletScreenController:_UpdateBulletScreenStatus()
    --抽取弹幕
    if self.curBulletIndex > #self.bulletScreenList then
        self:RefreshConfigPool()
    end
    local bsCfg = self.bulletScreenList[self.curBulletIndex]
    self.curBulletIndex = self.curBulletIndex + 1
    --生成弹幕
    local obj = self:CreateOneBulletScreen(bsCfg.Type, bsCfg.Content, bsCfg.BodyName)
    obj.transform:SetParent(self._BulletScreenRect.transform)
    obj.transform.localScale = Vector3.one

    local rect = obj:GetComponent("RectTransform")
    local width = rect.sizeDelta.x
    local height = rect.sizeDelta.y + math.random(0, self._randomMaxGap) * 10
    --计算弹幕占几个区域
    local count = height / self._blockHeight
    local bound = self:TryGetBlockSlot(count)
    if bound ~= -1 then
        --设置初始位置
        local posY = self._blPanelLowerPosY + bound*self._blockHeight
        rect.anchoredPosition = Vector2(self._screenWidth, posY)
        local triggerPosX = self._screenWidth - width
        local time1 = (rect.anchoredPosition.x - triggerPosX) / self._flowSpeed
        local targetPosX = -width
        local time2 = (triggerPosX - targetPosX) / self._flowSpeed
        rect:DOAnchorPos(Vector2(triggerPosX, posY), time1):SetEase(DG.Tweening.Ease.Linear):OnComplete(function()
            --清理block列表
            self:SetBlockStatus(bound, count, false)
            rect:DOAnchorPos(Vector2(targetPosX, posY), time2):SetEase(DG.Tweening.Ease.Linear):OnComplete(function()
                self:RecycleBullectScreenToPool(bsCfg.Type, obj)
            end)
        end)
        --更新block列表
        self:SetBlockStatus(bound, count, true)
    else
        self:RecycleBullectScreenToPool(bsCfg.Type, obj)
    end

    -- for _, v in pairs(self._bsCheckQueue) do
    --     local obj = v.obj
    --     local cfg = v.cfg
    --     local rect = v:GetComponent("RectTransform")
    --     local endPosX = rect.anchoredPosition.x + cfg.width
    --     --区域被占
    --     if endPosX > self._screenWidth then
    --         local h = rect.sizeDelta.y
    --         --下边界
    --         local lowerPosY = rect.anchoredPosition.y - cfg.height / 2
    --         --计算弹幕占几个区域
    --         local count = cfg.height / self._blockHeight
    --         self:SetBlockList(lowerPosY, count)
    --     end
    -- end
end

--尝试找到插入弹幕的位置，如果没有返回-1，有则返回下边界
function UIHomelandBulletScreenController:TryGetBlockSlot(count)
    local n = 0
    for id, v in pairs(self._blockList) do
        if v.use then
            n = 0
        else
            n = n + 1
            if n == count then
                return id - count
            end 
        end
    end
    return -1
end


function UIHomelandBulletScreenController:SetBlockStatus(bound, count, use)
    for i = 1, count do
        self._blockList[bound + i].use = use
    end
end

function UIHomelandBulletScreenController:CreateOneBulletScreen(type, content, icon)
    local obj = self:GetBulletScreenFromPool(type)
    obj:SetActive(true)
    local tex = obj.transform:Find("LocalizationText").gameObject:GetComponent("UILocalizationText")
    tex:SetText(StringTable.Get(content))
    if type == 3 then
        local RawImageLoader = obj.transform:Find("Head/BodyImage").gameObject:GetComponent("RawImageLoader")
        RawImageLoader:LoadImage(icon)
        local rect = obj:GetComponent("RectTransform")
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rect)
    end
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(obj:GetComponent("RectTransform"))
    return obj
end

function UIHomelandBulletScreenController:GetBulletScreenFromPool(type)
    self._objPoolDic[type] = self._objPoolDic[type] or {}
    if #self._objPoolDic[type] == 0 then
        return UnityEngine.GameObject.Instantiate(self._bsPoolDic[type].prefab)
    else
        local obj = self._objPoolDic[type][1]
        table.remove(self._objPoolDic[type],1)
        return obj
    end
end

function UIHomelandBulletScreenController:RecycleBullectScreenToPool(type, obj)
    self._objPoolDic[type] = self._objPoolDic[type] or {}
    obj:SetActive(false)
    table.insert(self._objPoolDic[type], obj)
end