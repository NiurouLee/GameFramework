---@class UIActivityN33DateHelper : Object
_class("UIActivityN33DateHelper", Object)
UIActivityN33DateHelper = UIActivityN33DateHelper

function UIActivityN33DateHelper:Constructor()
end

--检查剧情是否播放
function UIActivityN33DateHelper.CheckFirstStoryIsPlay()
    local open_id = GameGlobal.GameLogic():GetOpenId()
    local txt = "UIActivityN33DateHelper.CheckFirstStoryPlay" .. open_id
    local num = LocalDB.GetInt(txt)
    if num ~= 1 then
        return false
    end
    return true
end

function UIActivityN33DateHelper.CancelFirstStoryPlay()
    local open_id = GameGlobal.GameLogic():GetOpenId()
    local txt = "UIActivityN33DateHelper.CheckFirstStoryPlay" .. open_id
    LocalDB.SetInt(txt,1)
end

--得到模拟约会小游戏状态
---@return boolean,boolean,number
function UIActivityN33DateHelper.GetDateStatus(campaign)
    if not campaign then
        return false,false,0
    end

    ---@type SimulationOperation
    local comp = campaign:GetComponent(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
    ---@type SimulationOperationComponentInfo
    local compInfo = campaign:GetComponentInfo(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)

    if not compInfo then
        return false,false,0
    end

    --检查小游戏组件是否关闭
    local closeTime = comp.m_component_info.m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime > closeTime then
        return false,false,0
    end

    local isNew = not UIActivityN33DateHelper.CheckFirstStoryIsPlay()
    local canReceive = false
    local allFullLevel = true
    local storyNum = 0

    if table.count(compInfo.arch_infos) == 0 then
        return false,false,0
    end

    for _, v in pairs(compInfo.arch_infos) do
        allFullLevel = allFullLevel and v.level == 4
        local cfg = Cfg.cfg_component_simulation_operation {ArchitectureId = v.arch_id, Level = v.level}[1]
        
        if (v.coin_num + v.default_coin) >= (cfg.LimitNum * 0.5) then
            canReceive =  true
            break
        end
    end
    canReceive = allFullLevel and false or canReceive

    local cfgs = Cfg.cfg_component_simulation_operation_story {}
    for _, storyCfg in pairs(cfgs) do
        if not table.icontains(compInfo.story_list,storyCfg.ID) then
            --检查其条件是否完成
            local buildConditions = storyCfg.PreCondition
            local storyConditions = storyCfg.PreStory
            --判断剧情
            local isStoryOver = true
            if storyConditions then
                for _, v in pairs(storyConditions) do
                    local isInvited = table.icontains(compInfo.story_list,v)
                    if not isInvited then
                        isStoryOver = false
                        break
                    end
                end
            end
            
            --判断建筑
            local isBuildOver = true
            if buildConditions then
                for _, v in pairs(buildConditions) do
                    local id = v[1]
                    local needLevel = v[2]
                    local isGetTargetLevel = compInfo.arch_infos[id].level >= needLevel
                    if not isGetTargetLevel  then
                        isBuildOver = false
                        break
                    end
                end
            end
            
            if isStoryOver and isBuildOver and buildConditions then --没有建筑作为前置条件的约会都是已完成的
                storyNum = storyNum + 1
            end
        end
    end

    return isNew,canReceive,storyNum
end

--传入建筑id得到建筑等级
function UIActivityN33DateHelper.GetDateBuildLvel(campaign,buildID)
    ---@type SimulationOperation
    local comp = campaign:GetComponent(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
    ---@type SimulationOperationComponentInfo
    local compInfo = campaign:GetComponentInfo(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
    if table.count(compInfo.arch_infos) < 1 then
        return 1
    end

    return compInfo.arch_infos[buildID].level
end

--检查小游戏是否开启
function UIActivityN33DateHelper.CheckDateOpen(campaign)
    ---@type SimulationOperationComponentInfo
    local compInfo = campaign:GetComponentInfo(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
    if table.count(compInfo.arch_infos) < 1 then
        return false
    end
    return true
end