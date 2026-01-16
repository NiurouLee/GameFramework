---@class UIRugueLikeChooseCardController:UIController
_class("UIRugueLikeChooseCardController", UIController)
UIRugueLikeChooseCardController = UIRugueLikeChooseCardController

---@param uiParam table 要选择得圣物,结算传进来
function UIRugueLikeChooseCardController:OnShow(uiParam)
    self._timeOut = false
    ---@type MazeModule
    self._module = GameGlobal.GetModule(MazeModule)
    if self._module == nil then
        Log.fatal("[error] maze --> MazeModule == nil !")
        return
    end

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
    self._refreshMaze = uiParam[2]
    if uiParam[1] then
        self._timeOut = true
        for index, relic in ipairs(uiParam[1]) do
            self._relicTab[index] = relic.id
        end
    else
        --拿到对局结束得mazeresult
        local gameMatchModule = self:GetModule(GameMatchModule)
        local matchResult = UI_MatchResult:New()

        matchResult = gameMatchModule:GetMachResult()

        local tempRelics = matchResult.relics

        for i = 1, table.count(tempRelics) do
            self._relicTab[i] = tempRelics[i].assetid
        end
    end

    self._diced = (table.count(self._relicTab) == 3)

    --奖励信息
    self._count = 3

    self._index = 0
    --点击状态,0，未选择，1已选择
    self._state = 0

    self:GetComponents()

    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)
end
function UIRugueLikeChooseCardController:OnHide()
end
function UIRugueLikeChooseCardController:GetComponents()
    self._down = self:GetGameObject("DownAnchor")

    self._posTab = {}
    local pos1 = self:GetUIComponent("RectTransform", "pos1")
    table.insert(self._posTab, pos1)
    local pos2 = self:GetUIComponent("RectTransform", "pos2")
    table.insert(self._posTab, pos2)
    local pos3 = self:GetUIComponent("RectTransform", "pos3")
    table.insert(self._posTab, pos3)

    self._itemTab = {}

    self._itemPool = self:GetUIComponent("UISelectObjectPath", "itemPool")

    self._itemPool:SpawnObjects("UIRugueLikeChooseCardItem", self._count)

    ---@type UIRugueLikeChooseCardItem[]
    self._itemTab = self._itemPool:GetAllSpawnList()

    for i = 1, self._count do
        self._itemTab[i]:SetData(
            i,
            self._relicTab[i],
            self._posTab[i].position,
            function(index)
                self:CardClick(index)
            end,
            function(index)
                self:ChooseClick(index)
            end
        )
    end

    self._nameTex = self:GetUIComponent("UILocalizationText", "name")
    self._descTex = self:GetUIComponent("UILocalizationText", "desc")
    self._colorBg = self:GetUIComponent("Image", "colorDown")

    self._diceCountTex = self:GetUIComponent("UILocalizationText", "diceCount")

    self._diceCount = self:GetDiceCount()
    self._diceGo = self:GetGameObject("dice")
    self._chooseBtn2 = self:GetGameObject("chooseBtn2")
    self._btns = self:GetGameObject("btns")

    if self._diceCount ~= nil and self._diceCount > 0 then
        self._diceGo:SetActive(true)
        self._chooseBtn2:SetActive(false)
        self._btns:SetActive(true)
    else
        self._diceGo:SetActive(false)
        self._chooseBtn2:SetActive(true)
        self._btns:SetActive(false)
    end

    self._diceCountTex:SetText(self._diceCount)
end

function UIRugueLikeChooseCardController:GetDiceCount()
    local diceCount = self._itemModule:GetItemCount(RoleAssetID.RoleAssetRelicDice)
    return diceCount
end

function UIRugueLikeChooseCardController:CardClick(index)
    if self._index == index then
        return
    end
    self._index = index

    for i = 1, self._count do
        if i == self._index then
            self._itemTab[i]:CancelOrSelect(true)
        else
            self._itemTab[i]:CancelOrSelect(false)
        end
    end

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
end

function UIRugueLikeChooseCardController:chooseBtnOnClick()
    if self._state == 1 then
        self:Lock("UIRugueLikeChooseCardControllerchooseBtnOnClick")
        GameGlobal.TaskManager():StartTask(self.ChooseBtnClick, self)
    end
end
function UIRugueLikeChooseCardController:chooseBtn2OnClick()
    if self._state == 1 then
        self:Lock("UIRugueLikeChooseCardControllerchooseBtnOnClick")
        GameGlobal.TaskManager():StartTask(self.ChooseBtnClick, self)
    end
end

function UIRugueLikeChooseCardController:resetBtnOnClick()
    --已经摇过一次了
    if self._diced then
        ToastManager.ShowToast(StringTable.Get("str_maze_choose_had_reseted"))
        return
    end

    --判断筛子数量
    if self._diceCount <= 0 then
        ToastManager.ShowToast(StringTable.Get("str_maze_choose_dice_count_not_enough"))
        return
    end

    self._diced = true

    self:Lock("DiaoZhaTian")

    self:StartTask(self.OnresetBtnOnClick, self)
end
function UIRugueLikeChooseCardController:OnresetBtnOnClick(TT)
    local res, msg = self._module:RequestUseDice(TT, self._relicTab[self._index])
    self:UnLock("DiaoZhaTian")
    if res:GetSucc() then
        self._relicTab[self._index] = self._relicTab[4]

        table.remove(self._relicTab, 4)

        local item = self._relicTab[self._index]
        if item then
            --吊炸天特效
            self._itemTab[self._index]:Flush(item)
            YIELD(TT, 500)
            local item = self._cfg_item[self._relicTab[self._index]]
            if item then
                self._nameTex:SetText(StringTable.Get(item.Name))
                self._descTex:SetText(StringTable.Get(item.RpIntro))
                self._colorBg.sprite = self._atlas:GetSprite("map_shengwu_xian" .. item.Color)
                local c = Color(1, 1, 1, 1)

                if item.Color == 3 then
                    c = Color(178 / 255, 127 / 255, 250 / 255, 1)
                elseif item.Color == 4 then
                    c = Color(255 / 255, 243 / 255, 55 / 255, 1)
                elseif item.Color == 5 then
                    c = Color(255 / 255, 142 / 255, 0 / 255, 1)
                end

                self._nameTex.color = c
            end
        end

        self._diceCount = self:GetDiceCount()

        self._diceCountTex:SetText(self._diceCount)
    else
        Log.fatal("###maze choose relic -- reset relic error , msg --> ", msg)
    end
end

function UIRugueLikeChooseCardController:ChooseBtnClick(TT)
    local res = self._module:RequestSelectRelic(TT, self._relicTab[self._index])
    self:UnLock("UIRugueLikeChooseCardControllerchooseBtnOnClick")
    if res:GetSucc() then
        if self._timeOut == false then
            self:ShowDialog("UIRugueLikeBattleResultController", true)
        else
            self:CloseDialog()
            if self._refreshMaze then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnChooseCardClose)
            end
        end
    else
        local result = res:GetResult()
        Log.error("###[UIRugueLikeChooseCardController] RequestSelectRelic fail ! result --> ",result)
        self:CloseDialog()
    end
end
