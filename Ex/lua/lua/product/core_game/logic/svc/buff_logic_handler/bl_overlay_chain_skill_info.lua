--buff 修改连锁技释放条件为n，但始终只释放1阶连锁
--通过配置新的步数和现有技能的阶段数，来构建新的连锁信息映射
_class("BuffLogicOverlayChainSkillInfo", BuffLogicBase)
---@class BuffLogicOverlayChainSkillInfo: BuffLogicBase
BuffLogicOverlayChainSkillInfo = BuffLogicOverlayChainSkillInfo

function BuffLogicOverlayChainSkillInfo:Constructor(buffInstance, logicParam)
    self._overlayInfo = logicParam.overlayInfo--{{Chain=1,OriChainSkillIndex=1},...} 新步数和现有技能的阶段数
end

function BuffLogicOverlayChainSkillInfo:DoLogic()
    local e = self:GetEntity()
    if not e:HasSkillInfo() then
        return
    end

    local cSkillInfo = e:SkillInfo()
    cSkillInfo:BuffOverlayChainSkillByStepAndOriIndexSkill(self._overlayInfo)

    return {}
end

_class("BuffLogicClearOverlayChainSkillInfo", BuffLogicBase)
---@class BuffLogicClearOverlayChainSkillInfo: BuffLogicBase
BuffLogicClearOverlayChainSkillInfo = BuffLogicClearOverlayChainSkillInfo

function BuffLogicClearOverlayChainSkillInfo:Constructor(buffInstance, logicParam)
end

function BuffLogicClearOverlayChainSkillInfo:DoLogic()
    local e = self:GetEntity()
    if not e:HasSkillInfo() then
        return
    end

    local cSkillInfo = e:SkillInfo()
    cSkillInfo:ClearBuffOverlayChainSkillInfo()

    return {}
end
