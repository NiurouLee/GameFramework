--[[------------------------------------------------------------------------------------------
    L2R_LoadingResult : 进度条加载结果的播放
]] --------------------------------------------------------------------------------------------

---@class L2R_LoadingResult: Object
_class("L2R_LoadingResult", Object)
L2R_LoadingResult = L2R_LoadingResult

function L2R_LoadingResult:Constructor()
    ---@type DataTeamCreationResult[]
    self._teamCreationResult = {}

    ---@type DataMonsterCreationResult[]
    self._monsterResultList = {}

    ---@type DataChessPetCreationResult[]
    self._chessPetCreationResult = {}
end

---光灵队伍创建结果
function L2R_LoadingResult:GetTeamCreationResult()
    return self._teamCreationResult
end

function L2R_LoadingResult:SetTeamCreationResult(teamRes)
    self._teamCreationResult = teamRes
end

---怪物创建结果
function L2R_LoadingResult:SetLoadMonsterResultList(resList)
    self._monsterResultList = resList
end

function L2R_LoadingResult:GetLoadMonsterResultList()
    return self._monsterResultList
end

----棋子光灵创建结果
function L2R_LoadingResult:GetChessPetCreationResult()
    return self._chessPetCreationResult
end

function L2R_LoadingResult:SetChessPetCreationResult(res)
    self._chessPetCreationResult = res
end