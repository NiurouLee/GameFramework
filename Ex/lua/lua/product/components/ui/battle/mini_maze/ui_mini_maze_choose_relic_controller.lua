---@class UIMiniMazeChooseRelicController:UIController
_class("UIMiniMazeChooseRelicController", UIController)
UIMiniMazeChooseRelicController = UIMiniMazeChooseRelicController

---@param uiParam table 要选择得圣物,结算传进来
function UIMiniMazeChooseRelicController:OnShow(uiParam)
    if BattleStatHelper.GetAutoFightStat() then --自动战斗 n秒后自动选择 中途可手动选
        self._inAutoFight = true
        self._needAutoSelect = true
    else
        self._inAutoFight = false
        self._needAutoSelect = false
    end
    self._autoFightCountDownMsCfg = 5000 --sjs_todo 配置
    self._autoFightCountDownMs = self._autoFightCountDownMsCfg
    self._autoFightCountDownUiNum = 0

    self.ItemColorToTextColor = {
        [ItemColor.ItemColor_White] = Color(207 / 255, 207 / 255, 207 / 255, 1),
        [ItemColor.ItemColor_Green] = Color(32 / 255, 216 / 255, 165 / 255, 1),
        [ItemColor.ItemColor_Blue] = Color(55 / 255, 168 / 255, 255 / 255, 1),
        [ItemColor.ItemColor_Purple] = Color(178 / 255, 137 / 255, 250 / 255, 1),
        [ItemColor.ItemColor_Yellow] = Color(255 / 255, 243 / 255, 55 / 255, 1),
        [ItemColor.ItemColor_Golden] = Color(255 / 255, 142 / 255, 0 / 255, 1)
    }

    self._atlas = self:GetAsset("UIMazeChoose.spriteatlas", LoadType.SpriteAtlas)

    self._itemModule = self:GetModule(ItemModule)
    self._cfg_item = Cfg.cfg_item {}
    self._relicTab = {}
    if uiParam[1] then
        for index, relic in ipairs(uiParam[1]) do
            self._relicTab[index] = relic
        end
    end

    self._closeCallBack = nil
    if uiParam[2] then
        self._closeCallBack = uiParam[2]
    end

    self._openingChoose = false
    if uiParam[3] then
        self._openingChoose = uiParam[3]
    end

    --奖励信息
    self._count = #self._relicTab

    self._index = 0

    --点击状态,0，未选择，1已选择
    self._state = 0

    self:GetComponents()

    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)

    self:_CheckGuide()
end

function UIMiniMazeChooseRelicController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIMiniMazeChooseRelicController)
end

function UIMiniMazeChooseRelicController:OnUpdate(deltaTimeMS)
    if self._state == 0 and self._inAutoFight and self._needAutoSelect then --自动战斗中且玩家未操作
        --更新倒计时
        if self._autoFightCountDownMs > 0 then
            local deltaTime = GameGlobal:GetInstance():GetUnscaledDeltaTime()
            self._autoFightCountDownMs = self._autoFightCountDownMs - deltaTime
            self:RefreshCountDownNum()
            if self._autoFightCountDownMs <= 0 then
                --执行选择
                self:AutoSelect()
            end
        end
    end
end

function UIMiniMazeChooseRelicController:StopAutoSelect()
    self._needAutoSelect = false
    self:RefreshCountDownNum()
end

function UIMiniMazeChooseRelicController:RefreshCountDownNum()
    if self._inAutoFight and self._needAutoSelect then
        local refreshNumSec = 0
        if self._autoFightCountDownMs < 0 then
            refreshNumSec = 0
        else
            refreshNumSec = math.ceil(self._autoFightCountDownMs / 1000)
        end
        if self._autoFightCountDownUiNum ~= refreshNumSec then
            self._autoFightCountDownUiNum = refreshNumSec
            self._countDownAreaGo:SetActive(true)
            local timeNumStr = tostring(self._autoFightCountDownUiNum)
            self._countDownNum:SetText(StringTable.Get("str_n25_wait_auto_select",timeNumStr))
        end
    else
        self._countDownAreaGo:SetActive(false)
    end
end

function UIMiniMazeChooseRelicController:AutoSelect()
    -- self._state = 1
    -- self._index = math.random(1, self._count)
    -- self:ChooseBtnOnClick()
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            --self._state = 1
            self:Lock("UIMiniMazeChooseRelicControllerAutoSelect")
            local tarIndex = math.random(1, self._count)
            self:CardClick(tarIndex)
            YIELD(TT, 1000)
            self:UnLock("UIMiniMazeChooseRelicControllerAutoSelect")
            self:ChooseBtnOnClick()
        end
    )
end

function UIMiniMazeChooseRelicController:OnHide()
end

function UIMiniMazeChooseRelicController:GetComponents()
    self._down = self:GetGameObject("DownAnchor")

    self._posTab = {}
    if self._count == 2 then
        local pos1 = self:GetUIComponent("RectTransform", "pos21")
        table.insert(self._posTab, pos1)
        local pos2 = self:GetUIComponent("RectTransform", "pos22")
        table.insert(self._posTab, pos2)
    else
        local pos1 = self:GetUIComponent("RectTransform", "pos1")
        table.insert(self._posTab, pos1)
        local pos2 = self:GetUIComponent("RectTransform", "pos2")
        table.insert(self._posTab, pos2)
        local pos3 = self:GetUIComponent("RectTransform", "pos3")
        table.insert(self._posTab, pos3)
    end

    self._itemTab = {}

    self._itemPool = self:GetUIComponent("UISelectObjectPath", "itemPool")

    self._itemPool:SpawnObjects("UIMiniMazeChooseRelicItem", self._count)

    ---@type UIMiniMazeChooseRelicItem[]
    self._itemTab = self._itemPool:GetAllSpawnList()

    for i = 1, self._count do
        self._itemTab[i]:SetData(
            i,
            self._relicTab[i],
            self._posTab[i].position,
            function(index)
                self:CardClick(index)
            end
        )
    end

    self._nameTex = self:GetUIComponent("UILocalizationText", "name")
    self._descTex = self:GetUIComponent("UILocalizationText", "desc")
    self._colorBg = self:GetUIComponent("Image", "colorDown")
    self._chooseBtn = self:GetGameObject("chooseBtn")
    self._chooseBtn:SetActive(true)

    self._countDownAreaGo = self:GetGameObject("CountDownArea")
    self._countDownNum = self:GetUIComponent("UILocalizationText", "CountDownNum")
    self._countDownAreaGo:SetActive(self._inAutoFight)
    self:RefreshCountDownNum()
end

function UIMiniMazeChooseRelicController:CardClick(index)
    if self._index == index then
        return
    end

    if self._index ~= 0 then
        self._itemTab[self._index]:CancelOrSelect(false)
    end
    self._itemTab[index]:CancelOrSelect(true)

    self._index = index

    if self._state ~= 1 then
        self._state = 1
    end

    local item = self._cfg_item[self._relicTab[self._index]]
    if item then
        self._nameTex:SetText(StringTable.Get(item.Name))
        self._descTex:SetText(StringTable.Get(item.RpIntro))
        self._colorBg.sprite = self._atlas:GetSprite("map_shengwu_xian" .. item.Color)
        local c = Color(1, 1, 1, 1)

        c = self.ItemColorToTextColor[item.Color]
        self._nameTex.color = c
    end

    self._down.gameObject:SetActive(true)

    self:StopAutoSelect()
end

function UIMiniMazeChooseRelicController:ChooseBtnOnClick()
    self:StopAutoSelect()
    if self._state == 1 then
        local relicID = self._relicTab[self._index]
        -- if self._openingChoose then
        --     BattleStatHelper.SetChooseRelic(relicID)
        -- else
        --     BattleStatHelper.SetWaveChooseRelic(relicID)
        -- end
        self:CloseDialog()
        if self._closeCallBack then
            self._closeCallBack(relicID)
        else
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UIMiniMazeChooseWaveAward, relicID, 0,
                self._openingChoose)
        end
    end
end
