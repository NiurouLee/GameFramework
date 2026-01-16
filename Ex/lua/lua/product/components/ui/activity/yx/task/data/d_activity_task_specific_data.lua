--[[
    活动 任务界面 共用一套代码 不同活动类型配置差异部分
]]
---@class DActivityTaskSpecificData
_class("DActivityTaskSpecificData", Object)
---@class DActivityTaskSpecificData:Object
function DActivityTaskSpecificData:Constructor()
    self.shopBtnScriptName = ""
    self.campaignType = 0
    self.progressCmptId = 0
    self.questCmptId = 0
    self.progressNumSpecialColor = 0
    self.progressGotStr = ""
    self.progressCanGetStr = ""
    self.questBgNotFinish = ""
    self.questBgFinish = ""
    self.spriteAtlasName = ""
    self.isProgressImgNeedChange = false
    self.topProgressImg = ""
    self.topProgressBgImg = ""
    self.bottomProgressImg = ""
    self.bottomProgressBgImg = ""
    self.normalProgressImg = ""
    self.normalProgressBgImg = ""
    self.progressFirstCellImgHeight = 0
    self.progressNormalCellImgHeight = 0
    self.isCloseWithAnim = false
    self.closeAnimTb = {}
end
---@public
---商店按钮脚本名
function DActivityTaskSpecificData:GetShopBtnScriptName()
    return self.shopBtnScriptName
end
---@public
---活动类型
function DActivityTaskSpecificData:GetCampaignType()
    return self.campaignType
end
---@public
---个人进度组件id
function DActivityTaskSpecificData:GetProgressCmptId()
    return self.progressCmptId
end
---@public
---任务组件id
function DActivityTaskSpecificData:GetQuestCmptId()
    return self.questCmptId
end
---@public
---任务 进度数字 特殊颜色
function DActivityTaskSpecificData:GetQuestNumSpecialColor()
    return self.progressNumSpecialColor
end
---@public
---任务 文本 已获得
function DActivityTaskSpecificData:GetQuestGotStr()
    return self.progressGotStr
end
---@public
---任务 文本 可领取
function DActivityTaskSpecificData:GetQuestCanGetStr()
    return self.progressCanGetStr
end
---@public
---任务 未完成底板
function DActivityTaskSpecificData:GetQuestBgNotFinish()
    return self.questBgNotFinish
end
---@public
---任务 完成底板
function DActivityTaskSpecificData:GetQuestBgFinish()
    return self.questBgFinish
end
---@public
---任务 atlas名
function DActivityTaskSpecificData:GetSpriteAtlasName()
    return self.spriteAtlasName
end
---@public
---任务 个人进度条 是否需要换图片 （圆角）
function DActivityTaskSpecificData:IsProgressImgNeedChange()
    return self.isProgressImgNeedChange
end
---@public
---任务 个人进度条 顶部格子 图片 （圆角）
function DActivityTaskSpecificData:GetTopProgressImg()
    return self.topProgressImg
end
---@public
---任务 个人进度条 顶部格子 图片 （圆角）
function DActivityTaskSpecificData:GetTopProgressBgImg()
    return self.topProgressBgImg
end
---@public
---任务 个人进度条 底部格子 （圆角）
function DActivityTaskSpecificData:GetBottomProgressImg()
    return self.bottomProgressImg
end
---@public
---任务 个人进度条 底部格子 （圆角）
function DActivityTaskSpecificData:GetBottomProgressBgImg()
    return self.bottomProgressBgImg
end
---@public
---任务 个人进度条 中部格子 （圆角）
function DActivityTaskSpecificData:GetNormalProgressImg()
    return self.normalProgressImg
end
---@public
---任务 个人进度条 中部格子 （圆角）
function DActivityTaskSpecificData:GetNormalProgressBgImg()
    return self.normalProgressBgImg
end
---@public
---任务 个人进度条 顶部格子进度条长度（樱龙使 顶部格子进度条缩短）
function DActivityTaskSpecificData:GetProgressFirstCellImgHeight()
    return self.progressFirstCellImgHeight
end
---@public
---任务 个人进度条 普通格子进度条长度（樱龙使 顶部格子进度条缩短）
function DActivityTaskSpecificData:GetProgressNormalCellImgHeight()
    return self.progressNormalCellImgHeight
end
---@public
---任务 界面退出 是否有动画
function DActivityTaskSpecificData:IsCloseWithAnim()
    return self.isCloseWithAnim
end
---@public
---任务 界面退出 动画
function DActivityTaskSpecificData:GetCloseAnimTb()
    return self.closeAnimTb
end

----------------------------------------------------
--[[
    伊芙醒山
]]
---@class DActivityTaskSpecificData_EveSinsa
_class("DActivityTaskSpecificData_EveSinsa", DActivityTaskSpecificData)
---@class DActivityTaskSpecificData_EveSinsa:DActivityTaskSpecificData
function DActivityTaskSpecificData_EveSinsa:Constructor()
    self.shopBtnScriptName = "UIActivityEveSinsaShopBtn"
    self.campaignType = ECampaignType.CAMPAIGN_TYPE_EVERESCUEPLAN
    self.progressCmptId = ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_PERSON_PROGRESS
    self.questCmptId = ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_QUEST
    self.progressNumSpecialColor = "FFED00"
    self.progressGotStr = "str_activity_evesinsa_task_received"
    self.progressCanGetStr = "str_activity_evesinsa_task_can_get"
    self.questBgNotFinish = "event_eve_di71"
    self.questBgFinish = "event_eve_di19"
    self.spriteAtlasName = "UIActivityEveSinsa.spriteatlas"
    self.isProgressImgNeedChange = false
    self.topProgressImg = ""
    self.topProgressBgImg = ""
    self.bottomProgressImg = ""
    self.bottomProgressBgImg = ""
    self.normalProgressImg = ""
    self.normalProgressBgImg = ""
    self.progressFirstCellImgHeight = 0
    self.progressNormalCellImgHeight = 0
    self.isCloseWithAnim = true
    self.closeAnimTb = {}
    self.closeAnimTb.uiCloseAnim = "uieff_Activity_Eve_Task_Out"
end
----------------------------------------------------
--[[
    樱龙使
]]
---@class DActivityTaskSpecificData_Sakura
_class("DActivityTaskSpecificData_Sakura", DActivityTaskSpecificData)
---@class DActivityTaskSpecificData_Sakura:DActivityTaskSpecificData
function DActivityTaskSpecificData_Sakura:Constructor()
    self.shopBtnScriptName = "UISakuraDrawShopBtn"
    self.campaignType = ECampaignType.CAMPAIGN_TYPE_HIIRO
    self.progressCmptId = ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_PERSON_PROGRESS
    self.questCmptId = ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_QUEST
    self.progressNumSpecialColor = "FF7F00"
    self.progressGotStr = "str_sakura_task_award_got"
    self.progressCanGetStr = "str_sakura_task_award_can_get"
    self.questBgNotFinish = "legend_renwu_di21"
    self.questBgFinish = "legend_renwu_di8"
    self.spriteAtlasName = "UISakura.spriteatlas"
    self.isProgressImgNeedChange = true
    self.topProgressImg = "legend_renwu_di14"
    self.topProgressBgImg = "legend_renwu_di13"
    self.bottomProgressImg = "legend_renwu_di19"
    self.bottomProgressBgImg = "legend_renwu_di20"
    self.normalProgressImg = "legend_renwu_di17"
    self.normalProgressBgImg = "legend_renwu_di18"
    self.progressFirstCellImgHeight = 166.6
    self.progressNormalCellImgHeight = 220
    self.isCloseWithAnim = true
    self.closeAnimTb = {}
    self.closeAnimTb.bgCloseAnim = "uieff_UISakuraTaskController_b_out"
    self.closeAnimTb.uiCloseAnim = "uieff_UISakuraTaskController_u_out"
end
