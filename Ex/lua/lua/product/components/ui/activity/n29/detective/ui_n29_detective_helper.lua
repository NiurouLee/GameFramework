-- 侦探游戏的两个搜索界面
--- @class UIN29DetectiveType
local UIN29DetectiveType = {
    Person = 0, --人物点
    Suspect = 1, --探索点
}
_enum("UIN29DetectiveType", UIN29DetectiveType)

---@class UIN29DetectiveHelper : Object
_class("UIN29DetectiveHelper", Object)
UIN29DetectiveHelper = UIN29DetectiveHelper

function UIN29DetectiveHelper:Constructor()
end

--构建openIDkey值
function UIN29DetectiveHelper.BuildOpenIdKey(psdId,str)
    local roleModule = GameGlobal.GetModule(RoleModule)
    local openID = roleModule:GetPstId()
    local key = psdId .. openID .. str
    return key
end

--检查本地是否有该OpenIdKey值
function UIN29DetectiveHelper.CheckOpenIdKey(psdId,str)
    local key = UIN29DetectiveHelper.BuildOpenIdKey(psdId,str)
    local value = LocalDB.GetInt(key)
    if value == 1 then
        return true
    end
    return false
end

--设置本地OpenIdKey值
function UIN29DetectiveHelper.SetOpenIdKey(psdId,str)
    local key = UIN29DetectiveHelper.BuildOpenIdKey(psdId,str)
    LocalDB.SetInt(key, 1)
end

--tb中是否含有item
function UIN29DetectiveHelper.Contain(tb,item)
    for _, v in pairs(tb) do
        if v == item then
            return true
        end
    end
    return false
end

--判断话题点是否锁定
function UIN29DetectiveHelper.IsLock(value,severlist)
    local severlist = severlist
    local NeedClue = Cfg.cfg_component_detective_talk[value].NeedClue
    local Clue = Cfg.cfg_component_detective_talk[value].ClueId

    if not NeedClue then
        
        return false
    else
        if  UIN29DetectiveHelper.Judge(NeedClue, severlist) and
            UIN29DetectiveHelper.IsInList(Clue,severlist) then
            return false
        else
            return true
        end
    end
end

--判断话题是否可以出示
function UIN29DetectiveHelper.IsShow(id,severlist)
    local severlist = severlist
    local Clue = Cfg.cfg_component_detective_talk[id].ClueId
    local NeedClue = Cfg.cfg_component_detective_talk[id].NeedClue

    if not NeedClue then
        return false
    else
        return UIN29DetectiveHelper.Judge(NeedClue, severlist)

    end

end

--判断id是否存在于list表中
function UIN29DetectiveHelper.IsInList(id,list)
    if not id then
        return false
    end
    
    for _, value in ipairs(list) do
        if id==value then
            return true
        end
    end
    return false
end

---@param needlist 解锁所需要拥有的线索列表
---@param havelist 服务器保存的已经获得的线索列表
--是否拥有需要的所有线索
function UIN29DetectiveHelper.Judge(needlist, havelist)
    local tmp = {}        
    for _, need in ipairs(needlist) do
        for _, have in ipairs(havelist) do
            for i=1,#needlist do
                if  need == have then
                    table.insert(tmp,need)
                    break
                end
            end
        end
    end

    if #needlist == #tmp then
        return true,tmp
    else
        return false,tmp
    end
end
