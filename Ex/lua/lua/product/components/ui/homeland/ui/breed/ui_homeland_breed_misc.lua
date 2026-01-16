---@class HomelandBreedUIType
local HomelandBreedUIType = {
    Mutation = 1, --突变
    Clone = 2, --克隆
    StateChg = 3, --态变
    Manual = 4 --手册
}
_enum("HomelandBreedUIType", HomelandBreedUIType)

---@class HomelandBreedUIWidget
local HomelandBreedUIWidget = {
    [HomelandBreedUIType.Mutation] = "UIHomelandBreedMutation", --突变
    [HomelandBreedUIType.Clone] = "UIHomelandBreedClone", --克隆
    [HomelandBreedUIType.StateChg] = "UIHomelandBreedStateChg", --态变
    [HomelandBreedUIType.Manual] = "UIHomelandBreedManual" --手册
}
_enum("HomelandBreedUIWidget", HomelandBreedUIWidget)

---@class HomelandBreedState
local HomelandBreedState = {
    None = 0, --未知
    Mutationing = 1, --突变中
    Cloning = 2, --复制中
    MutationReap = 4, --突变完成待收获
    CloneReap = 5, --复制完成待收获
    StateChgReap = 6 --态变完成等待收获
}
_enum("HomelandBreedState", HomelandBreedState)

---@class HomelandBreedTypeStr
local HomelandBreedTypeStr = {
    [HomelandBreedState.Mutationing] = "str_homeland_breed_mutation", --突变中
    [HomelandBreedState.Cloning] = "str_homeland_breed_clone", --Cloning
    [HomelandBreedState.MutationReap] = "str_homeland_breed_mutation", --突变完成待收获
    [HomelandBreedState.CloneReap] = "str_homeland_breed_clone", --克隆完成待收获
    [HomelandBreedState.StateChgReap] = "str_homeland_breed_statechg" --态变完成等待收获
}
_enum("HomelandBreedTypeStr", HomelandBreedTypeStr)

--物种
---@class HomelandBreedSpeciesType
local HomelandBreedSpeciesType = {
    Tree = 1 --树
}
_enum("HomelandBreedSpeciesType", HomelandBreedSpeciesType)

--物种字符串
---@class HomelandBreedSpeciesStr
local HomelandBreedSpeciesStr = {
    [HomelandBreedSpeciesType.Tree] = "str_homeland_breed_tree"
}
_enum("HomelandBreedSpeciesStr", HomelandBreedSpeciesStr)

--谱系
---@class HomelandBreedPedigree
local HomelandBreedPedigree = {
    Jia = 1, --甲
    Yi = 2 --乙
}
_enum("HomelandBreedPedigree", HomelandBreedPedigree)

--谱系字符串
---@class HomelandBreedPedigreeStr
local HomelandBreedPedigreeStr = {
    [HomelandBreedPedigree.Jia] = "str_homeland_breed_pedigree_j",
    [HomelandBreedPedigree.Yi] = "str_homeland_breed_pedigree_y"
}
_enum("HomelandBreedPedigreeStr", HomelandBreedPedigreeStr)

--稀有度字符串
---@class HomelandBreedRarityStr
local HomelandBreedRarityStr = {
    [RarityType.C] = "C",
    [RarityType.B] = "B",
    [RarityType.A] = "A",
    [RarityType.S] = "S"
}
_enum("HomelandBreedRarityStr", HomelandBreedRarityStr)

---@class HomelandBreedTool
local HomelandBreedTool = {
    GetTimeStr = function(time)
        if time <= 0 then
            return "00:00:00"
        end
        local h = math.floor(time / 3600)
        time = time - h * 3600
        local m = math.floor(time / 60)
        local s = math.floor(time - m * 60)
        if h < 10 then
            h = "0" .. h
        end
        if m < 10 then
            m = "0" .. m
        end
        if s < 10 then
            s = "0" .. s
        end
        return h .. ":" .. m .. ":" .. s
    end,
    --获取剩余时间
    GetRemainTime = function(time)
        local day, hour, minute
        day = math.floor(time / 86400)
        hour = math.floor(time / 3600) % 24
        minute = math.floor(time / 60) % 60
        local timestring = ""
        if day > 0 then
            timestring = day .. StringTable.Get("str_activity_common_day")
            if hour > 0 then
                timestring = timestring .. hour .. StringTable.Get("str_activity_common_hour")
            end
        elseif hour > 0 then
            timestring = hour .. StringTable.Get("str_activity_common_hour")
            if minute > 0 then
                timestring = timestring .. minute .. StringTable.Get("str_activity_common_minute")
            end
        elseif minute > 0 then
            timestring = minute .. StringTable.Get("str_activity_common_minute")
        else
            timestring = StringTable.Get("str_activity_common_less_minute")
        end
        return timestring
    end
}
_enum("HomelandBreedTool", HomelandBreedTool)
