--[[
    活动辅助类
]]
---@class UIN19Helper:Object
_class("UIN19Helper", Object)
UIN19Helper = UIN19Helper

function UIN19Helper:Constructor()
end

function UIN19Helper.GetNewPoint(campaign)
    local sampleNew = campaign:CheckCampaignNew()

    local componentId = ECampaignN19CommonComponentID.PANGOLIN
    local component = campaign:GetComponent(componentId)
    local minigameOp =   campaign:CheckComponentOpen(componentId)

    -- 任务新开启
    local new = component:NewTaskRed("N19TaskComp", "red")
    -- 组件开起
    local comNew = component:GetPrefsComponentNew("N19TaskComp")
    return sampleNew or  (new ~= nil and new > 0 ) or  (minigameOp and comNew < 1)
end
