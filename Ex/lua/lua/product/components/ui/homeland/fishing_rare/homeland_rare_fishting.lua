---@class HomelandRareFishing:Object
_class("HomelandRareFishing", Object)
HomelandRareFishing = HomelandRareFishing

HomelandRareFishing.Fishing_Chat = 1
HomelandRareFishing.Fishing_Submit = 2
HomelandRareFishing.Fishing_Fishing = 3
HomelandRareFishing.Fishing_Limit = 4
--HomelandRareFishing.PetFishing_Fishing = 5

---@class FishType
local FishType = {
    RAREFISH = 1,
    FATFISH = 2
}
_enum("FishType", FishType)

function HomelandRareFishing:Constructor(rareId, homelandFishing)
    self._rareId = rareId
    self._homelandFishing = homelandFishing

    local rareCfgs = Cfg.cfg_homeland_rare_clue{}
    self._rareCfg = rareCfgs[rareId]

    self._curState = self.Fishing_Chat
    --self._curStatePet = self.Fishing_Chat
    self._fishingPosition = 0
    self._submitTimes = 0   -- 已经刷新鱼点的次数

    self:RefreshCurrentState()
end

function HomelandRareFishing:RefreshCurrentState()
    ---@type HomelandModule
    local homeModule = GameGlobal.GetModule(HomelandModule)
    local allFishingClue = homeModule:GetAllRareFishingClue()
    local fishingClue = nil
    local type= self._rareCfg.type
    local rareCfgs = Cfg.cfg_homeland_rare_clue{}
    local fatFishCluePosition={}
    local clintPetId=rareCfgs[self._rareId].PetID

    if allFishingClue ~= nil then
        fishingClue = allFishingClue[self._rareId]
        if type == FishType.FATFISH then
            self._fishingPosition=0
            for k, v in pairs(allFishingClue) do
                local severPetId=rareCfgs[k].PetID
                if severPetId == clintPetId then
                    table.insert(fatFishCluePosition,v)
                end
            end
            for _, v in ipairs(fatFishCluePosition) do

                if v.rare_fishing_position ~= 0 then
                    self._fishingPosition = v.rare_fishing_position
                    break
                end
            end
        end
    end

    if allFishingClue == nil then
        self._fishingPosition=0
    end

    if  type ==  FishType.FATFISH then
        if self._fishingPosition == 0  then
            if self._curState == HomelandRareFishing.Fishing_Fishing then
                self._curState = self.Fishing_Chat
            end
            return
        end
    end

    if type== FishType.RAREFISH then
        if fishingClue==nil then
            if self._curState == HomelandRareFishing.Fishing_Fishing then
                self._curState = self.Fishing_Chat
            end
            return
        end
        self._fishingPosition = fishingClue.rare_fishing_position
        self._submitTimes = fishingClue.today_submit_times
    end


    if self._fishingPosition ~= 0 then
        self._curState = self.Fishing_Fishing
    elseif self._curState == self.Fishing_Submit then
        self._curState = self.Fishing_Submit
    elseif self._curState == self.Fishing_Limit then
        self._curState = self.Fishing_Limit
    elseif self._rareCfg.SubmitTimesEvetyDay == nil then
        self._curState = self.Fishing_Chat
    elseif self._rareCfg.SubmitTimesEvetyDay == 0 then
        self._curState = self.Fishing_Chat
    elseif self._submitTimes >= self._rareCfg.SubmitTimesEvetyDay then
        self._curState = self.Fishing_Limit
    else
        self._curState = self.Fishing_Chat
    end
end

function HomelandRareFishing:GetRareID()
    return self._rareId
end

function HomelandRareFishing:GetRareCfg()
    return self._rareCfg
end

function HomelandRareFishing:GetCurrentState()
    return self._curState
end


function HomelandRareFishing:GetInteractTitle()
    local chatId = self._rareCfg.ChatID
    if chatId == nil then
        return "请配置对话id"
    end

    if self._curState == self.Fishing_Submit then
        return self:GetSubmitTitle()
    else
        return StringTable.Get(self:GetChatCfg(chatId).Title)
    end
end

function HomelandRareFishing:GetInteractIcon()
    local chatId = self._rareCfg.ChatID
    if chatId == nil then
        return nil
    end

    local cfg = self:GetChatCfg(chatId)
    return cfg.Icon
end

function HomelandRareFishing:GetSubmitTitle()
    local title = StringTable.Get("str_homeland_pet_interact_submit")

    local submitId = self:SubmitAssetId()
    local submitCount = self:SubmitAssetCount()
    local itemName = StringTable.Get(Cfg.cfg_item[submitId].Name)
    local haveCount = GameGlobal.GetModule(ItemModule):GetItemCount(submitId)
    haveCount = math.min(haveCount, submitCount)

    local submitTitle = string.format(title, itemName, haveCount, submitCount)

    return submitTitle
end

function HomelandRareFishing:GetFishIdTitle(talkid,txt,_chatword)
    local rareCfgs = Cfg.cfg_homeland_rare_clue
    local data =rareCfgs{TalkId=talkid}

    if data == nil then
        return txt,2,1,nil
    else
        for k,v in pairs(data)do
            local petFishClue=v["ID"]
            if v["SubmitAssetForPosition"]==nil then
                self.submitId=0
                self.submitCount=0
            else
                self.submitId=v["SubmitAssetForPosition"][1]
                self.submitCount=v["SubmitAssetForPosition"][2]
            end
            local petFishTask=v["Task"]
            if petFishTask ~=nil then
                --实际提交选项
                if self.submitId==0 then
                    local haveCount = 2
                    self.submitCount=1
                    local submitTitle = StringTable.Get(_chatword,haveCount)
                    return submitTitle,haveCount,self.submitCount,petFishClue
                else
                    --local haveCount = GameGlobal.GetModule(ItemModule):GetItemCount(self.submitId)
                    local haveCount = UIHomelandShopHelper.GetItemCount_ForSale(self.submitId)
                    if haveCount < 0 then
                        haveCount = 0
                    end
                    local submitTitle = StringTable.Get(_chatword,haveCount)
                    
                    return submitTitle,haveCount,self.submitCount,petFishClue
                end
            else
                local itemName = StringTable.Get(Cfg.cfg_item[self.submitId].Name)--提交材料物品名 之间为参数，现弃用
                local haveCount = 2
                local submitTitle = StringTable.Get(_chatword,haveCount)
            
                local HaveCount=haveCount
            
                return submitTitle,HaveCount,self.submitCount,nil
            end
        end
    end
end

function HomelandRareFishing:GetChatCfg(chatid)
    local cfg_chat = Cfg.cfg_home_pet_chat[chatid]
    if not cfg_chat then
        Log.error("###[UIHomePetInteract] cfg_chat is nil ! id --> ", chatid)
    end
    return cfg_chat
end

function HomelandRareFishing:SubmitAssetId()
    return self._rareCfg.SubmitAssetForPosition[1]
end

function HomelandRareFishing:SubmitAssetCount()
    return self._rareCfg.SubmitAssetForPosition[2]
end

function HomelandRareFishing:FinishClueChat()
    self._curState = self.Fishing_Submit
    --self._curStatePet = self.Fishing_Fishing
end

function HomelandRareFishing:FinishSubmitAsset()
    self._curState = self.Fishing_Fishing
    --self._curStatePet = self.Fishing_Fishing
end

function HomelandRareFishing:OnSubmitAssetClick()
    GameGlobal.TaskManager():StartTask(self.FishingSubmitAssetTask, self)
end

function HomelandRareFishing:FishingSubmitAssetTask(TT)
    ---@type HomelandModule
    local homeModule = GameGlobal.GetModule(HomelandModule)

    local result = homeModule:ApplyHomelandRefreshRarePosition(TT, self._rareId)
    if result:GetSucc() then
        -- 在家园水域出现了稀有鱼点！
        local param = {StringTable.Get("str_homeland_appear_rare_fishing_tips")}
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.Tex, param)

        self:RefreshCurrentState()
        self._homelandFishing:RefreshFishingPosition()
    end
end

--对话刷胖胖鱼点
function HomelandRareFishing:PetFishingSubmitAsset(petFishClue)
    GameGlobal.TaskManager():StartTask(self.PetFishingSubmitAssetTask, self,petFishClue)
    
end

function HomelandRareFishing:PetFishingSubmitAssetTask(TT,petFishClue)
    ---@type HomelandModule  刷鱼点
    local homeModule = GameGlobal.GetModule(HomelandModule)
    local result,asset = homeModule:ApplyHomelandRefreshRarePosition(TT, petFishClue)
    Log.fatal(result)
    if result:GetSucc() then
        -- 在家园水域出现了稀有鱼点！
        local param = {StringTable.Get("str_homeland_appear_rare_fishing_tips")}
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.Tex, param)

        self:RefreshCurrentState()
        self._homelandFishing:RefreshFishingPosition()
        --奖励弹窗
        if #asset > 0 then
            GameGlobal.UIStateManager():ShowDialog("UIHomeShowAwards", asset, nil,
            false,
            nil
        )
        end
    end
end

