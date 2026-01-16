require "play_skill_phase_base_r"
--------------------------------
---@class PlaySkillPhase_GridDark: PlaySkillPhaseBase
_class("PlaySkillPhase_GridDark", PlaySkillPhaseBase)
PlaySkillPhase_GridDark = PlaySkillPhase_GridDark

--------------------------------
function PlaySkillPhase_GridDark:Constructor()
    ---加血表现执行函数
end
function PlaySkillPhase_GridDark:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParam_GridDark
    local paramWork = phaseParam
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type SkillPhaseParam_GridDark_Type
    local nDarkType = paramWork:GetDarkType() or SkillPhaseParam_GridDark_Type.Dark
    if SkillPhaseParam_GridDark_Type.Dark == nDarkType then
        pieceService:SetAllPieceDark()
    elseif SkillPhaseParam_GridDark_Type.Resume == nDarkType then   ---暂不支持
    end
end
--------------------------------
