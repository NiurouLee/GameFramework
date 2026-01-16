--[[
    活动 任务界面 共用一套代码 不同活动类型配置差异部分
]]
---@class DActivityProgressSpecificData
_class("DActivityProgressSpecificData", Object)
---@class DActivityProgressSpecificData:Object
function DActivityProgressSpecificData:Constructor()
    self.campaignType = 0
    self.progressCmptId = 0
    self.progressNumSpecialColor = 0
    self.progressGotStr = ""
    self.progressCanGetStr = ""
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
---活动类型
function DActivityProgressSpecificData:GetCampaignType()
    return self.campaignType
end
---@public
---个人进度组件id
function DActivityProgressSpecificData:GetProgressCmptId()
    return self.progressCmptId
end
---@public
---任务 进度数字 特殊颜色
function DActivityProgressSpecificData:GetQuestNumSpecialColor()
    return self.progressNumSpecialColor
end
---@public
---任务 文本 已获得
function DActivityProgressSpecificData:GetQuestGotStr()
    return self.progressGotStr
end
---@public
---任务 文本 可领取
function DActivityProgressSpecificData:GetQuestCanGetStr()
    return self.progressCanGetStr
end

---@public
---任务 atlas名
function DActivityProgressSpecificData:GetSpriteAtlasName()
    return self.spriteAtlasName
end
---@public
---任务 个人进度条 是否需要换图片 （圆角）
function DActivityProgressSpecificData:IsProgressImgNeedChange()
    return self.isProgressImgNeedChange
end
---@public
---任务 个人进度条 顶部格子 图片 （圆角）
function DActivityProgressSpecificData:GetTopProgressImg()
    return self.topProgressImg
end
---@public
---任务 个人进度条 顶部格子 图片 （圆角）
function DActivityProgressSpecificData:GetTopProgressBgImg()
    return self.topProgressBgImg
end
---@public
---任务 个人进度条 底部格子 （圆角）
function DActivityProgressSpecificData:GetBottomProgressImg()
    return self.bottomProgressImg
end
---@public
---任务 个人进度条 底部格子 （圆角）
function DActivityProgressSpecificData:GetBottomProgressBgImg()
    return self.bottomProgressBgImg
end
---@public
---任务 个人进度条 中部格子 （圆角）
function DActivityProgressSpecificData:GetNormalProgressImg()
    return self.normalProgressImg
end
---@public
---任务 个人进度条 中部格子 （圆角）
function DActivityProgressSpecificData:GetNormalProgressBgImg()
    return self.normalProgressBgImg
end
---@public
---任务 个人进度条 顶部格子进度条长度
function DActivityProgressSpecificData:GetProgressFirstCellImgHeight()
    return self.progressFirstCellImgHeight
end
---@public
---任务 个人进度条 普通格子进度条长度
function DActivityProgressSpecificData:GetProgressNormalCellImgHeight()
    return self.progressNormalCellImgHeight
end
---@public
---任务 界面退出 是否有动画
function DActivityProgressSpecificData:IsCloseWithAnim()
    return self.isCloseWithAnim
end
---@public
---任务 界面退出 动画
function DActivityProgressSpecificData:GetCloseAnimTb()
    return self.closeAnimTb
end

----------------------------------------------------
--[[
    N5
]]
---@class DActivityTaskSpecificData_N5
_class("DActivityTaskSpecificData_N5", DActivityProgressSpecificData)
---@class DActivityTaskSpecificData_N5:DActivityProgressSpecificData
function DActivityTaskSpecificData_N5:Constructor()
    self.campaignType = ECampaignType.CAMPAIGN_TYPE_N5
    self.progressCmptId = ECampaignN5ComponentID.ECAMPAIGN_N5_PERSON_PROGRESS
    self.progressNumSpecialColor = "FFED00"
    self.progressGotStr = "str_quest_base_got"
    self.progressCanGetStr = "str_quest_base_can_get"
    self.spriteAtlasName = "UIN5.spriteatlas"
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
    self.closeAnimTb.uiCloseAnim = ""
end

