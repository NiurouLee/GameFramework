---@class UIEnemyMsg : UICustomWidget
_class("UIEnemyMsg", UICustomWidget)
UIEnemyMsg = UIEnemyMsg
function UIEnemyMsg:OnShow(uiParams)
    self:InitWidget()
end
function UIEnemyMsg:InitWidget()
    --generate--
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    self.contentRect = self:GetUIComponent("RectTransform", "Content")
    self._restrainBtn_obj = self:GetGameObject("restrainBtn")
    self._bgImg = self:GetUIComponent("Image","UIEnemyMsg")
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._blurImg = self:GetGameObject("Image")
    --generate end--
end
function UIEnemyMsg:SetData(levelId, monsterIDs, isChess,noLv)
    if isChess then
        self._restrainBtn_obj:SetActive(false)
    else
        self._restrainBtn_obj:SetActive(true)
    end
    if monsterIDs == nil then
        monsterIDs = UICommonHelper:GetInstance():GetOptimalEnemys(levelId)
    end
    if monsterIDs == nil or #monsterIDs == 0 then
        --qa敌方情报，如果空了，取cfg_mission里的策划配的表
        local _cfg_level = Cfg.cfg_level[levelId]
        if _cfg_level then
            monsterIDs = _cfg_level.MonsterList
        end

        if monsterIDs == nil or #monsterIDs == 0 then
            Log.fatal("[Enemy] 怪物id列表为空")
            return
        end
    end

    --MSG25642	【必现】（测试_王琦）秘境探索敌方情报6个怪以上时，滑动查看自动弹回第一页，无法查看后面的怪物，附视频	4	新缺陷	李学森, 1958	06/25/2021
    --这里改为限制五个，之前秘境没有限制数量 @lixuesen
    self._ids = {}
    local count = table.count(monsterIDs)
    if count > 5 then
        count = 5
    end
    for i = 1, count do
        table.insert(self._ids, monsterIDs[i])
    end

    self.contentRect.anchoredPosition = Vector2(0, self.contentRect.anchoredPosition.y)
    self.content:SpawnObjects("UIEnemyItem", #self._ids)
    ---@type table<number,UIEnemyItem>
    local items = self.content:GetAllSpawnList()

    for idx, value in ipairs(self._ids) do
        local item = items[idx]
        item:SetData(
            self._ids[idx],
            idx,
            function(idx)
                GameGlobal.UAReportForceGuideEvent("UIStageClick", {"EnemyInfo_" .. idx}, true)
                self:ShowDialog("UIEnemyTip", self._ids, idx)
            end
        )
    end

    local sprite
    local activeBlurImg
    if noLv then
        activeBlurImg = false
        sprite = self._atlas:GetSprite("map_black_di09")
    else
        activeBlurImg = true
        sprite = self._atlas:GetSprite("map_guanqia_di3")
    end
    self._blurImg:SetActive(activeBlurImg)
    self._bgImg.sprite = sprite
end

function UIEnemyMsg:restrainBtnOnClick()
    GameGlobal.UAReportForceGuideEvent("UIStageClick", {"restrainBtnOnClick"}, true)
    self:ShowDialog("UIRestrainTips")
end
