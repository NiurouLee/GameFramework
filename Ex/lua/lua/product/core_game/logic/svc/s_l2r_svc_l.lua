--[[
    服务器不需要逻辑表现同步，所以接口都是空的
]]

_class("L2RService_Server", BaseService)
---@class L2RService_Server:BaseService
L2RService_Server = L2RService_Server


function L2RService_Server:L2RBoardLogicData()
end

function L2RService_Server:L2RSyncPieceType()
end

function L2RService_Server:L2RLoadingData()
end

function L2RService_Server:L2RNormalAttackData(normalSkillCalcor,teamEntity)
end

function L2RService_Server:L2RChainAttackData(teamEntity)
end

function L2RService_Server:L2RActiveAttackData(casterEntity,skillID)
end

function L2RService_Server:L2RFeatureAttackData(casterEntity)
end


function L2RService_Server:L2RAILogicData()
end

function L2RService_Server:L2ROneSkillData(casterEntity, key)
end

function L2RService_Server:L2RChainPathData(teamEntity)
end

---棋子连线数据
function L2RService_Server:L2RChessPathData()
end

---棋子攻击数据
function L2RService_Server:L2RChessAttackData(casterEntity)
end
---San值 每回合降低
function L2RService_Server:L2RSanRoundDecrease(curVal,oldVal,delVal)
end
---昼夜 回合数变化
function L2RService_Server:L2RDayNightRoundChange(curState,oldState,restRound)
end
---通知 同步移动数据
function L2RService_Server:L2RSyncMoveData(entityID,syncMovePath)
end
---同步 小秘境创建伙伴
function L2RService_Server:L2RAddPartnerData(partnerID,petInfo,matchPet,petRes,hp,maxHP)
end
function L2RService_Server:L2RAddRelicData(relicID, buffSeqs)
end
function L2RService_Server:L2RNTSelectRoundTeamNormalBefore()
end

function L2RService_Server:L2RMirageWalkData(mirageWalkRes)    
end

function L2RService_Server:L2RMirageWarningData(warningPosList)
end
function L2RService_Server:L2RPickUpComponentData(entityID,pickUpGridList,directionPickupData,reflectDir,pickUpExtraParam)
end