--[[------------------------------------------------------------------------------------------
    LinkageNumComponent : 独立的连线数量组件
]] --------------------------------------------------------------------------------------------

---@class LinkageNumComponent: Object
_class("LinkageNumComponent", Object)
LinkageNumComponent=LinkageNumComponent


function LinkageNumComponent:Constructor(linkageNumOffset)
    self._linkageNumOffset = Vector3(linkageNumOffset[1],linkageNumOffset[2],0)
    self._pathCountText = nil
    self._linkCount = 0
    self._linkChainRate = 0
    self._mpb = nil
    self._entityConfigId = nil
end

function LinkageNumComponent:SetEntityConfigId(id)
    self._entityConfigId = id
end

function LinkageNumComponent:GetEntityConfigId()
    return self._entityConfigId
end

function LinkageNumComponent:GetLinkageIndex()
    return self._linkCount
end

function LinkageNumComponent:SetLinkNum(linkCount)
    self._linkCount = linkCount
end

function LinkageNumComponent:SetLinkChainRate(rate)
    self._linkChainRate = rate
end

function LinkageNumComponent:GetLinkChainRate()
    return self._linkChainRate
end

function LinkageNumComponent:SetLinkCount(viewRoot)
    --[[ 保留textmesh的实现方式 可能会采用这种方式
    local linkCount = self._linkCount
    if self._pathCountText == nil then
        local tempObject = GameObjectHelper.FindChild(viewRoot.transform,"AttackRateText") 
        self._pathCountText = tempObject:GetComponent("TextMesh")
    end

    self._pathCountText.text = linkCount

    local attackRateFormat = ""
    local realLinkCount = linkCount - 1
    local num = math.floor(realLinkCount / 10 + 1) 
    local lastNum = realLinkCount
    local multiCharacter = "*"
    local splitCharacter = "."
    if realLinkCount < 10 then 
        attackRateFormat = '*'..num..'.'..lastNum
        --attackRateFormat = string.format("%s%d%s%d",multiCharacter,num,splitCharacter,lastNum)
    else
        lastNum = realLinkCount % 10
        attackRateFormat = '*'..num..'.'..lastNum
        --attackRateFormat = string.format("%s%d%s%d",multiCharacter,num,splitCharacter,lastNum)
    end
    --Log.fatal("Num",num," lastNum",lastNum," ",attackRateFormat)

    self._pathCountText.text = attackRateFormat

    if realLinkCount >= BattleConst.SuperChainCount then 
        self._pathCountText.text = '*'..'.'..'*'
    end]]
    
    local linkCount = self._linkCount
    local realLinkCount = self._linkChainRate

    local numMax = GameObjectHelper.FindChild(viewRoot.transform,"number_MAX") 
    local numRoot = GameObjectHelper.FindChild(viewRoot.transform,"normal") 

    --max
    if realLinkCount >= BattleConst.SuperChainCount then
        numMax.gameObject:SetActive(true)
        numRoot.gameObject:SetActive(false)
        return
    end

    --使用shader frame的方式
    numMax.gameObject:SetActive(false)
    numRoot.gameObject:SetActive(true)

    local num = math.floor(realLinkCount / 10 + 1) 
    local lastNum = realLinkCount
    if lastNum >= 10 then
        lastNum = lastNum % 10
    end

    local num1 = GameObjectHelper.FindChild(viewRoot.transform,"number_1") 
    local num2 = GameObjectHelper.FindChild(viewRoot.transform,"number_2")

    if not self._mpb then
        self._mpb = UnityEngine.MaterialPropertyBlock:New()
    end
    self._mpb:SetInt("_StartFrame", num + 1)
    ---@type UnityEngine.Renderer
    local num1Renderer = num1.gameObject:GetComponent(typeof(UnityEngine.Renderer))
    --Log.fatal(tostring(num1Renderer:HasPropertyBlock()))
    num1Renderer:SetPropertyBlock(self._mpb)

    self._mpb:SetInt("_StartFrame", lastNum + 1)
    ---@type UnityEngine.Renderer
    local num2Renderer = num2.gameObject:GetComponent(typeof(UnityEngine.Renderer))
    num2Renderer:SetPropertyBlock(self._mpb)
end
----------------------------------------------------------------------
function Entity:LinkageNum()
    return self:GetComponent(self.WEComponentsEnum.LinkageNum)
end

function Entity:HasLinkageNum()
    return self:HasComponent(self.WEComponentsEnum.LinkageNum)
end

function Entity:AddLinkageNum(linkageNumOffset)
    local index = self.WEComponentsEnum.LinkageNum
    local component = LinkageNumComponent:New(linkageNumOffset)
    self:AddComponent(index, component)
end

function Entity:ReplaceLinkageNum(linkageNumOffset)
    local index = self.WEComponentsEnum.LinkageNum
    local component = LinkageNumComponent:New(linkageNumOffset)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveLinkageNum()
    if self:HasLinkageNum() then
        self:RemoveComponent(self.WEComponentsEnum.LinkageNum)
    end
end
