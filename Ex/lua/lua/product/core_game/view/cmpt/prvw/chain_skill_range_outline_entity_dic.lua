--[[------------------------------------------------------------------------------------------
    宝宝的连锁技表现预览数据数据
]] --------------------------------------------------------------------------------------------


_class("ChainSkillRangeOutlineEntityDic", Object)
---@class ChainSkillRangeOutlineEntityDic: Object
ChainSkillRangeOutlineEntityDic=ChainSkillRangeOutlineEntityDic


function ChainSkillRangeOutlineEntityDic:Constructor()
    --key是
    self._petOutlineEntityDic = {}
end

function ChainSkillRangeOutlineEntityDic:ClearChainSkillOutlineEntityDic()
    self._petOutlineEntityDic = {}
end

function ChainSkillRangeOutlineEntityDic:GetChainSkillOutlineEntityDic()
    return self._petOutlineEntityDic
end

function ChainSkillRangeOutlineEntityDic:GetChainSkillOutlineEntityCount()
    return table.count(self._petOutlineEntityDic)
end

---添加一个宝宝的连锁技范围组
---@param petEntityID number 宝宝的entity id
function ChainSkillRangeOutlineEntityDic:AddPetChainSkillOutlineRange(previewIndex)
    --Log.fatal("AddPetChainSkillOutlineRange >>>>>>>",previewIndex)
    self._petOutlineEntityDic[previewIndex] = {}
end

---给宝宝的边界entity列表添加entity id
---@param petEntityID number 
---@param outlineEntityID number
function ChainSkillRangeOutlineEntityDic:AddChainSkillRangeOutlineEntityID(previewIndex, outlineEntityID)
    --Log.fatal("AddChainSkillRangeOutlineEntityID >>>>>>>",previewIndex," ",outlineEntityID)
    local entityIDList = self._petOutlineEntityDic[previewIndex]
    entityIDList[#entityIDList + 1] = outlineEntityID
end

function ChainSkillRangeOutlineEntityDic:HasPreviewIndex(previewIndex)
    if not self._petOutlineEntityDic[previewIndex] then
        return false
    else
        return next(self._petOutlineEntityDic[previewIndex])
    end
end