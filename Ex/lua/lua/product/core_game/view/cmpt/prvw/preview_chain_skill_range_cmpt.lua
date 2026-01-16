--[[------------------------------------------------------------------------------------------
    PreviewChainSkillRangeComponent : 连锁技范围预览组件
]] --------------------------------------------------------------------------------------------


_class("PreviewChainSkillRangeComponent", Object)
---@class PreviewChainSkillRangeComponent: Object
PreviewChainSkillRangeComponent = PreviewChainSkillRangeComponent

function PreviewChainSkillRangeComponent:Constructor()
    self._enablePreviewChainSkillRange = false --是否要开启连锁技预览
    self._flashChainSkill = true --是否需要闪烁，临时配成一直闪
    self._curPreviewTypeIndex = 0 --颜色类型索引
    self._previewMaxTime = 1000 --显示时间
    self._curTypeViewStartTime = 0 --当前显示的起始时间
    ---@type ChainSkillRangeOutlineEntityDic
    self._chainSkillRangeOutlineEntityDic = ChainSkillRangeOutlineEntityDic:New()
    ---@type table<number,number>
	self._petSingleEntityDic = {}   --存放单体
    ---@type table<number,Entity>
    self._snipeEffectEntityDic = {}  --已经挂了狙击特效的实体列表防止一个实体多次挂载特效
    ---@type table<number,number>
	self._addHPPetDic = {}    ---存放治疗性连锁技
    ---@type table<number,number>
    self._previewAttackElementType = {} ---攻击属性 key是previewIndex
    ---@type number[]
    self._previewPetID = {} --按预览顺序存放的宝宝ID
    ---@type table<number,number> key是Index
    self._previewTypeList={}
end

---@public
---@param enable boolean
function PreviewChainSkillRangeComponent:EnablePreviewChainSkillRange(enable)
    self._enablePreviewChainSkillRange = enable
end

---@public
function PreviewChainSkillRangeComponent:GetPreviewChainSkillRangeEnable()
    return self._enablePreviewChainSkillRange
end

function PreviewChainSkillRangeComponent:ResetPreviewChainSkillData()
    self._flashChainSkill = true
    self._curPreviewTypeIndex = 0
    self._curTypeViewStartTime = 0
end

function PreviewChainSkillRangeComponent:GetChainSkillRangeOutlineDic()
    return self._chainSkillRangeOutlineEntityDic
end

---@public
---@return boolean 是否需要闪烁
function PreviewChainSkillRangeComponent:IsFlashChainSkillRange()
    return self._flashChainSkill
end

---@public
---@param isFlashRange boolean
function PreviewChainSkillRangeComponent:SetChainSkillRangeFlash(isFlashRange)
    self._flashChainSkill = isFlashRange
end

---@public
---@return number 获取预览的索引
function PreviewChainSkillRangeComponent:GetPreviewTypeIndex()
    return self._curPreviewTypeIndex
end

---@public
---@param previewTypeIndex number
function PreviewChainSkillRangeComponent:SetPreviewTypeIndex(previewTypeIndex)
    self._curPreviewTypeIndex = previewTypeIndex
end

---@public
function PreviewChainSkillRangeComponent:GetPreviewShowTime()
    return self._previewMaxTime
end

---@public
function PreviewChainSkillRangeComponent:GetPreviewStartTime()
    return self._curTypeViewStartTime
end

---@public
---@param previewStartTime number
function PreviewChainSkillRangeComponent:SetPreviewStartTime(previewStartTime)
    self._curTypeViewStartTime = previewStartTime
end

function PreviewChainSkillRangeComponent:GetChainSkillRangeCount()
    return self._chainSkillRangeOutlineEntityDic:GetChainSkillOutlineEntityCount()
end
function PreviewChainSkillRangeComponent:GetChainSkillSingleEntityDic()
    return self._petSingleEntityDic
end

function PreviewChainSkillRangeComponent:AddChainSkillSingleEntityDic(previewIndex,entityID)
    if not self._petSingleEntityDic[previewIndex] then
        self._petSingleEntityDic[previewIndex] ={}
    end
    --Log.fatal("AddChainSkillSingleEntityDic Index：",previewIndex)
    table.insert(self._petSingleEntityDic[previewIndex],entityID)
end

function PreviewChainSkillRangeComponent:GetChainSkillAddHPPetDic()
    return self._addHPPetDic
end

function PreviewChainSkillRangeComponent:AddChainSkillAddHPPetDic(previewIndex,entityID)
    --Log.fatal("AddChainSkillAddHPPetDic Index：",previewIndex)
    self._addHPPetDic[previewIndex]= entityID
end

function PreviewChainSkillRangeComponent:CheckPreviewIndexData(previewIndex,previewType)
    if not  previewType then
        return false
    end
    if previewType == PreviewChainSkillType.Range then
        if not self._chainSkillRangeOutlineEntityDic:HasPreviewIndex(previewIndex) then
            return false
        end
    elseif previewType == PreviewChainSkillType.SingleEntity then
        if not self._petSingleEntityDic[previewIndex] then
            return false
        end
    elseif previewType == PreviewChainSkillType.AddHP then
        if not self._addHPPetDic[previewIndex] then
            return false
        end
    elseif previewType == PreviewChainSkillType.RangeAndSingleEntity then
        if not self._chainSkillRangeOutlineEntityDic:HasPreviewIndex(previewIndex) then
            return false
        end
        if not self._petSingleEntityDic[previewIndex] then
            return false
        end
    end
    return true
end

function PreviewChainSkillRangeComponent:GetPreviewChainSkillTypeByPreviewIndex(previewIndex)
    if self:CheckPreviewIndexData(previewIndex,self._previewTypeList[previewIndex]) then
	    --Log.fatal("GetPreviewIndex Index:",previewIndex," Type:",self._previewTypeList[previewIndex])--,"Trance:",Log.traceback())
        return self._previewTypeList[previewIndex]
    end
    --if self._previewTypeList[previewIndex] then
    --    --Log.fatal("GetPreviewIndex Index:",previewIndex," Type:",self._previewTypeList[previewIndex])--,"Trance:",Log.traceback())
    --    return self._previewTypeList[previewIndex]
    --end
    --Log.fatal("GetPreviewIndex Index:",previewIndex," Type:None Trance:")--,Log.traceback())
    return PreviewChainSkillType.None
end

function PreviewChainSkillRangeComponent:SetPreviewTypeByPreviewIndex(previewIndex,previewType)
    --Log.fatal("SetPreviewIndex Index:",previewIndex," Type:",previewType)--," Trance:",Log.traceback())
    self._previewTypeList[previewIndex] = previewType
end

function PreviewChainSkillRangeComponent:HasSnipeEffect(entityID)
    if self._snipeEffectEntityDic[entityID] then
        return true
    else
        return false
    end
end

function PreviewChainSkillRangeComponent:AddSnipeEffect(masterEntityID,effectEntity)
    self._snipeEffectEntityDic[masterEntityID] = effectEntity
end
---@return table<number,Entity>
function PreviewChainSkillRangeComponent:GetSnipeEffectList()
    return self._snipeEffectEntityDic
end

function PreviewChainSkillRangeComponent:GetPreviewChainSkillSingleEffectList(previewIndex)
    local targetEntityList = self._petSingleEntityDic[previewIndex]
    local effectEntityList = {}
    for i, id in ipairs(targetEntityList) do
        local effectEntity = self._snipeEffectEntityDic[id]
        table.insert(effectEntityList,effectEntity)
    end
    return effectEntityList
end

function PreviewChainSkillRangeComponent:GetChainSkillAddHPPetEntityID(previewIndex)
    return self._addHPPetDic[previewIndex]
end

function PreviewChainSkillRangeComponent:AddChainSkillAttackElementType(previewIndex,elementType)
    self._previewAttackElementType[previewIndex] = elementType
end
---@return PieceType
function PreviewChainSkillRangeComponent:GetChainSkillAttackElementType(previewIndex)
    return self._previewAttackElementType[previewIndex]
end

function PreviewChainSkillRangeComponent:ClearPreviewChainSkill()
    self._addHPPetDic = {}
    self._petSingleEntityDic = {}
    self._snipeEffectEntityDic = {}
    self._previewAttackElementType = {}
    self._previewPetID = {}
    self._previewTypeList = {}
end

function PreviewChainSkillRangeComponent:HasPreviewChainSkillData()
    if self._chainSkillRangeOutlineEntityDic:GetChainSkillOutlineEntityCount() ~=0  or
            next(self._petSingleEntityDic) or
            next(self._addHPPetDic)
    then
        return true
    else
        return false
    end
end

function PreviewChainSkillRangeComponent:AddPreviewPetID(previewIndex, petEntityID)
    self._previewPetID[previewIndex] = petEntityID
end

function PreviewChainSkillRangeComponent:GetPreviewPetID(previewIndex)
    return self._previewPetID[previewIndex]
end

--------------------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return PreviewChainSkillRangeComponent
function Entity:PreviewChainSkillRange()
    return self:GetComponent(self.WEComponentsEnum.PreviewChainSkillRange)
end

function Entity:HasPreviewChainSkillRange()
    return self:HasComponent(self.WEComponentsEnum.PreviewChainSkillRange)
end

function Entity:AddPreviewChainSkillRange()
    local index = self.WEComponentsEnum.PreviewChainSkillRange
    local component = PreviewChainSkillRangeComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePreviewChainSkillRange()
    local index = self.WEComponentsEnum.PreviewChainSkillRange
    local component = PreviewChainSkillRangeComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemovePreviewChainSkillRange()
    if self:HasPreviewChainSkillRange() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewChainSkillRange)
    end
end
---@class PreviewChainSkillType
---@field None number
---@field Range number
---@field SingleEntity number
---@field AddHP number
local PreviewChainSkillType ={
    None = 0,
    Range = 1 , ---显示预警范围范围内怪物波点
    SingleEntity =2, ---范围内怪身上播狙击特效 不显示范围
    AddHP =3, --施法者身上显示加血材质动画,不显示范围
    RangeAndSingleEntity =4,
}
_enum("PreviewChainSkillType",PreviewChainSkillType)