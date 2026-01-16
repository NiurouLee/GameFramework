--
---@class UIActivityN33ArchUpgradeReward : UIController
_class("UIActivityN33ArchUpgradeReward", UIController)
UIActivityN33ArchUpgradeReward = UIActivityN33ArchUpgradeReward
local ARCH_LEVEL_MAX_CONST = 4
---@param res AsyncRequestRes
function UIActivityN33ArchUpgradeReward:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end
--初始化
function UIActivityN33ArchUpgradeReward:OnShow(...)
    self:InitWidget()
    local data = table.unpack({...})
    local archID = data[1]
    local currArchLv = data[2]
    local rewards = data[3]
    self.activityConst = data[4]
    self.rewards = rewards
    self:RefreshUI(archID, currArchLv, rewards)
    self:PlayAnim(true)
end
--获取ui组件
function UIActivityN33ArchUpgradeReward:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.rootNode = self:GetGameObject("RootNode")
    ---@type UnityEngine.GameObject
    self.titleNode = self:GetGameObject("TitleNode")
    ---@type UnityEngine.GameObject
    self.rewardNode = self:GetGameObject("RewardNode")
    ---@type UnityEngine.UI.Image
    self.closeBtn = self:GetUIComponent("Image", "CloseBtn")
    ---@type UILocalizationText
    self.titleText = self:GetUIComponent("UILocalizationText", "TitleText")
    ---@type UILocalizationText
    self.currDesText = self:GetUIComponent("UILocalizationText", "currDesText")
    ---@type UILocalizationText
    self.rewardUnlockText = self:GetUIComponent("UILocalizationText", "RewardUnlockText")
    ---@type UILocalizationText
    self.rewardItemText = self:GetUIComponent("UILocalizationText", "RewardItemText")
    ---@type UICustomWidgetPool
    self.rewardHeadList = self:GetUIComponent("UISelectObjectPath", "RewardHeadList")
    ---@type UnityEngine.GameObject
    self.rewardItemList = self:GetGameObject("RewardItemList")
    ---@type UnityEngine.GameObject
    self.rewardItemParent = self:GetGameObject("RewardItemParent")
    ---@type UnityEngine.GameObject
    self.rewardItemGo = self:GetGameObject("RewardItem")
    ---@type UnityEngine.GameObject
    self.rewardPetGo = self:GetGameObject("PetReward")
    ---@type UICustomWidgetPool
    self.rewardItem = self:GetUIComponent("UISelectObjectPath", "RewardItem")
    ---@type UICustomWidgetPool
    self.petReward = self:GetUIComponent("UISelectObjectPath", "PetReward")
    ---@type UnityEngine.GameObject
    self.petRewardParent = self:GetGameObject("PetRewardParent")
    ---@type UnityEngine.UI.Image
    self.currStarNode_1 = self:GetUIComponent("Image", "currStarNode_1")
    ---@type UnityEngine.UI.Image
    self.currStarNode_2 = self:GetUIComponent("Image", "currStarNode_2")
    ---@type UnityEngine.UI.Image
    self.currStarNode_3 = self:GetUIComponent("Image", "currStarNode_3")
    ---@type UnityEngine.UI.Image
    self.currStarNode_4 = self:GetUIComponent("Image", "currStarNode_4")
    ---@type UILocalizationText
    self.nextDesText = self:GetUIComponent("UILocalizationText", "nextDesText")
    ---@type UnityEngine.UI.Image
    self.nextStarNode_1 = self:GetUIComponent("Image", "nextStarNode_1")
    ---@type UnityEngine.UI.Image
    self.nextStarNode_2 = self:GetUIComponent("Image", "nextStarNode_2")
    ---@type UnityEngine.UI.Image
    self.nextStarNode_3 = self:GetUIComponent("Image", "nextStarNode_3")
    ---@type UnityEngine.UI.Image
    self.nextStarNode_4 = self:GetUIComponent("Image", "nextStarNode_4")
    self._anim = self:GetGameObject():GetComponent("Animation")
    --generated end--
end

function UIActivityN33ArchUpgradeReward:RefreshUI(archID, currArchLv, rewards)
    if currArchLv >= ARCH_LEVEL_MAX_CONST then
        self.titleText:SetText(StringTable.Get("str_n33_date_upgrade_reward_key1"))
    else
        self.titleText:SetText(StringTable.Get("str_n33_date_upgrade_reward_key2"))
    end
    self.rewardUnlockText:SetText(StringTable.Get("str_n33_date_arch_info_key5"))
    self.rewardItemText:SetText(StringTable.Get("str_n33_date_arch_info_key6"))
    for i = 1, ARCH_LEVEL_MAX_CONST do
        self["currStarNode_"..i].gameObject:SetActive(i == (currArchLv - 1))
        self["nextStarNode_"..i].gameObject:SetActive(i == currArchLv)
    end
    local currCfg = Cfg.cfg_component_simulation_operation {ArchitectureId = archID, Level = currArchLv}[1]
    local preCfg = Cfg.cfg_component_simulation_operation {ArchitectureId = archID, Level = currArchLv - 1}[1]
    self.currDesText:SetText(StringTable.Get(preCfg.Name))
    self.nextDesText:SetText(StringTable.Get(currCfg.Name))
    self:RefreshUI_RewardList(rewards)
    self:RefreshUI_RewardPetList(currCfg.StoryList)
    self.closeBtn.gameObject:SetActive(true)
end
function UIActivityN33ArchUpgradeReward:RefreshUI_RewardList(rewards)
    local rewardCount = table.count(rewards)

    for i = 1, rewardCount do
        local item = UnityEngine.GameObject.Instantiate(self.rewardItemGo, self.rewardItemParent.transform)
        item:SetActive(true)
        local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        ---@type UIActivityN33RewardItem
        local itemWidget = rowPool:SpawnObject("UIActivityN33RewardItem")
        itemWidget:SetRewardData_Item(rewards[i], false, self.activityConst)
    end
end

function UIActivityN33ArchUpgradeReward:RefreshUI_RewardPetList(storyList)
    if not storyList then
        return
    end
    local rewardCount = table.count(storyList)
    for i = 1, rewardCount do
        local item = UnityEngine.GameObject.Instantiate(self.rewardPetGo, self.petRewardParent.transform)
        item:SetActive(true)
        local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        ---@type UIActivityN33RewardItem
        local itemWidget = rowPool:SpawnObject("UIActivityN33RewardItem")
        itemWidget:SetRewardData_PetStory(storyList[i], false, self.activityConst)
    end
end
--按钮点击
function UIActivityN33ArchUpgradeReward:CloseBtnOnClick(go)
    if self.activityConst:CheckSimulationOperationIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        self:SwitchState(UIStateType.UIActivityN33MainController)
        return
    end
    self:ShowDialog("UIGetItemController", self.rewards,function()
        self:PlayAnim(false, function ()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN33UpgradeRewardOver)
            self:CloseDialog()
        end)
    end, true)
end


function UIActivityN33ArchUpgradeReward:PlayAnim(isIn, callback)
    -- local key = "uieffanim_UIActivityN33ArchUpgradeReward_in"
    if isIn then
        self:StartTask(
            function(TT)
                self:Lock("uieffanim_UIActivityN33ArchUpgradeReward_in")
                self._anim:Play("uieffanim_UIActivityN33ArchUpgradeReward_in")
                YIELD(TT, 2000)
                self:UnLock("uieffanim_UIActivityN33ArchUpgradeReward_in")
                self:_CheckGuide()
                if callback then
                    callback()
                end
            end,
            self
        )
    else 
        self:StartTask(
            function(TT)
                self:Lock("uieffanim_UIActivityN33ArchUpgradeReward_out")
                self._anim:Play("uieffanim_UIActivityN33ArchUpgradeReward_out")
                YIELD(TT, 250)
                self:UnLock("uieffanim_UIActivityN33ArchUpgradeReward_out")
                self:_CheckGuide()
                if callback then
                    callback()
                end
            end,
            self
        )
    end 
end

function UIActivityN33ArchUpgradeReward:_CheckGuide()
    local guideModule = GameGlobal.GetModule(GuideModule)
    if not guideModule:IsGuideDone(123004) then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIActivityN33ArchUpgradeReward)
    end
end