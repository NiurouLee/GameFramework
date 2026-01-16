--[[
    番外奖励界面
]]
---@class UIExtraMissionAwardController:UIController
_class("UIExtraMissionAwardController", UIController)
UIExtraMissionAwardController = UIExtraMissionAwardController

--参数番外ID
--当前星数和领取状态用ID去module获取
--
function UIExtraMissionAwardController:OnShow(uiParams)
    self._getTypes = {}
    self._getTypes[1] = self:GetGameObject("getType_01")
    self._getTypes[2] = self:GetGameObject("getType_02")
    self._getTypes[3] = self:GetGameObject("getType_03")

    self._starAwards = {}
    self._starAwards[1] = self:GetUIComponent("UILocalizationText", "StarAward_01")
    self._starAwards[2] = self:GetUIComponent("UILocalizationText", "StarAward_02")
    self._starAwards[3] = self:GetUIComponent("UILocalizationText", "StarAward_03")

    self._cantGetTexts = {}
    self._cantGetTexts[1] = self:GetUIComponent("UILocalizationText", "cantGetText1")
    self._cantGetTexts[2] = self:GetUIComponent("UILocalizationText", "cantGetText2")
    self._cantGetTexts[3] = self:GetUIComponent("UILocalizationText", "cantGetText3")

    self._awardContents = {}
    self._awardContents[1] = self:GetUIComponent("UISelectObjectPath", "awardContent_01")
    self._awardContents[2] = self:GetUIComponent("UISelectObjectPath", "awardContent_02")
    self._awardContents[3] = self:GetUIComponent("UISelectObjectPath", "awardContent_03")

    self._nStarCounts = {}

    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")

    self:OnValue()
end

function UIExtraMissionAwardController:LoadDataOnEnter(TT, res, uiParams)
    --根据ID去cfg_extra_mission表中取数据
    self._module = GameGlobal.GetModule(ExtMissionModule)
    self._extraMissionID = uiParams[1]

    if self._module then
        self:OnInitData(TT)

        res:SetSucc(true)
    else
        Log.fatal("module is nil!")
        res:SetSucc(false)
    end
end

function UIExtraMissionAwardController:OnValue()
    if self._awardInfo then
        --当前星数
        self.m_nStarCount = self._awardInfo.m_nStarCount

        --设置当前星数--TODO
        self._currentStarNumber = self:GetUIComponent("UILocalizationText", "currentStarNumber")
        self._currentStarNumber:SetText(self.m_nStarCount .. "")

        --奖励列表
        local vecAward = self._awardInfo.m_vecAward

        local idx = 0

        self._awardList = {}
        for key, value in HelperProxy:GetInstance():pairsByKeys(vecAward) do
            idx = idx + 1

            self._nStarCounts[idx] = value.m_nStarCount
            local nAwardRecord = value.m_nAwardStat

            self._awardList[idx] = {}
            self._awardList[idx] = value.m_vecAwardItem

            self:InitListViews(idx, self._awardList[idx])
            self:InitGetType(idx, nAwardRecord)
            self:GetCuurentStar(idx, self._nStarCounts[idx])
        end
    else
        Log.fatal("award info is nil!")
    end
end

function UIExtraMissionAwardController:OnInitData(TT)
    local res = self._module:Request_GetDetail_ExtMission(TT, self._extraMissionID)
    local result = res:GetResult()

    if result == 0 then
        self._awardInfo = self._module:UI_GetExtMissionAward(self._extraMissionID)
    else
        local errmsg = self._module:GetErrorMsg(result)
        ToastManager.ShowToast(errmsg)
    end
end

--初始化三个奖励列表
function UIExtraMissionAwardController:InitListViews(scrollViewIndex, awardList)
    self._awardContents[scrollViewIndex]:SpawnObjects("UIExtraMissionAwardControllerItem", table.count(awardList))
    local spawns = self._awardContents[scrollViewIndex]:GetAllSpawnList()

    for i = 1, table.count(spawns) do
        self:ShowItem(spawns[i], awardList[i], i)
    end
end

--初始化阶段星数
---@param index int 下标
---@param stars int 星数
function UIExtraMissionAwardController:GetCuurentStar(index, stars)
    self._starAwards[index]:SetText(stars .. "")
end

--显示每个奖励Item
---@param item GameObject 每个奖励
---@param awardItem awardInfo 奖励信息
---@param index int 下标
function UIExtraMissionAwardController:ShowItem(item, awardItem, index)
    local ItemTempleate = Cfg.cfg_item[awardItem.assetid]
    if ItemTempleate then
        local itemInfo = {
            item_id = awardItem.assetid,
            item_count = awardItem.count,
            icon = ItemTempleate.Icon,
            item_name = ItemTempleate.Name,
            simple_desc = ItemTempleate.RpIntro,
            color = ItemTempleate.Color
        }
        item:GetGameObject():SetActive(true)

        item:SetData(
            itemInfo,
            index,
            function(id, pos)
                self:ShowSelectInfo(id, pos)
            end,
            Color(1, 1, 1, 1)
        )
    end
end

--显示info
---@param id int itemID
---@param pos Vector2 位置
function UIExtraMissionAwardController:ShowSelectInfo(id, pos)
    self._selectInfo:SetData(id, pos)
end

function UIExtraMissionAwardController:bgOnClick()
    self:CloseDialog()
end

--初始化三个奖励列表的领取状态
---@param index int 下标
---@param state EnumAwardRecord 状态
function UIExtraMissionAwardController:InitGetType(index, state)
    self:InitStageGetType(index, state)
end

--初始化三个奖励列表的领取状态
---@param index int 下标
---@param state enum 状态
---@param getType EnumAwardRecord
function UIExtraMissionAwardController:InitStageGetType(index, getType)
    local stageObjTransform = self._getTypes[index]:GetComponent("Transform")

    local count = stageObjTransform.childCount
    for i = 1, count - 1 do
        local go = stageObjTransform:GetChild(i)
        if go then
            go.gameObject:SetActive(false)
        end
    end

    if getType == EnumAwardRecord.Getting then
        stageObjTransform:GetChild(1).gameObject:SetActive(true)
    elseif getType == EnumAwardRecord.HaveDown then
        stageObjTransform:GetChild(2).gameObject:SetActive(true)
    elseif getType == EnumAwardRecord.Disable then
        stageObjTransform:GetChild(3).gameObject:SetActive(true)
        self._cantGetTexts[index]:SetText("<color=red>" .. self.m_nStarCount .. "</color>/" .. self._nStarCounts[index])
    end
end

--三个阶段领取事件
function UIExtraMissionAwardController:btnStage1OnClick()
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    --请求服务器，等待回调成功了
    GameGlobal.TaskManager():StartTask(self.GetClick, self, self._extraMissionID, 1)
end
function UIExtraMissionAwardController:btnStage2OnClick()
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    --请求服务器，等待回调成功了
    GameGlobal.TaskManager():StartTask(self.GetClick, self, self._extraMissionID, 2)
end
function UIExtraMissionAwardController:btnStage3OnClick()
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    --请求服务器，等待回调成功了
    GameGlobal.TaskManager():StartTask(self.GetClick, self, self._extraMissionID, 3)
end
function UIExtraMissionAwardController:GetClick(TT, extID, idx)
    self:Lock("UIExtraMissionAwardController:GetClick")
    local res = self._module:Request_GetAward(TT, extID, self._nStarCounts[idx])
    self:UnLock("UIExtraMissionAwardController:GetClick")
    local result = res:GetResult()
    if result == 0 then
        --self:ShowDialog("UIGetItemController", self._awardList[idx])
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CancelRedPoint, self._extraMissionID)
        self:InitStageGetType(idx, EnumAwardRecord.HaveDown)
        local tempPets = {}
        local pets = self._awardList[idx]
        if #pets > 0 then
            for i = 1, #pets do
                local ispet = GameGlobal.GetModule(PetModule):IsPetID(pets[i].assetid)
                if ispet then
                    table.insert(tempPets, pets[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                    self:ShowDialog("UIGetItemController", self._awardList[idx])
                end
            )
        else
            self:ShowDialog("UIGetItemController", self._awardList[idx])
        end
    else
        local errmsg = self._module:GetErrorMsg(result)
        ToastManager.ShowToast(errmsg)
    end
end
