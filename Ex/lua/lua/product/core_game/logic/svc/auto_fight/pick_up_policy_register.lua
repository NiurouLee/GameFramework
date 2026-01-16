_class("PickUpPolicy_CalcParam", Object)
---@class PickUpPolicy_CalcParam : Object
PickUpPolicy_CalcParam = PickUpPolicy_CalcParam

function PickUpPolicy_CalcParam:Constructor(TT,petEntity,activeSkillID,policyParam)
    self.TT = TT
    ---@type Entity
    self.petEntity = petEntity
    self.activeSkillID = activeSkillID
    self.policyParam = policyParam
end


--[[------------------
    自动战斗点选策略计算器注册和使用
--]] ------------------
---@return pickPosList 点选格子
---@return attackPosList 攻击范围
---@return targetIdList 攻击目标列表
function AutoFightService:CalcPickUpByPolicy(TT,petEntity,activeSkillID,policy,policyParam)
    local classType = self._pickUpPolicyCalculatorDic[policy]

    if (classType == nil) then
        ---选默认的计算器
        classType = PickUpPolicy_Default
    end

    ---创建计算器对象
    local pickUpPolicyObject = classType:New(self._world)
    if pickUpPolicyObject then
        local calcParam = PickUpPolicy_CalcParam:New(TT,petEntity,activeSkillID,policyParam)
        return pickUpPolicyObject:CalcAutoFightPickUpPolicy(calcParam)
    end
end

function AutoFightService:RegistPickUpPolicyCalculator()
    ---注册
    self._pickUpPolicyCalculatorDic = {}
    self._pickUpPolicyCalculatorDic[PickPosPolicy.MovePathEndPos] = PickUpPolicy_MovePathEndPos
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetFei] = PickUpPolicy_PetFei
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetJiaBaiLie] = PickUpPolicy_PetJiaBaiLie
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSaiKa] = PickUpPolicy_PetSaiKa
    self._pickUpPolicyCalculatorDic[PickPosPolicy.NearestPos] = PickUpPolicy_NearestPos
    self._pickUpPolicyCalculatorDic[PickPosPolicy.HeroPos] = PickUpPolicy_HeroPos
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetXiNuoPu] = PickUpPolicy_PetXiNuoPu
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetYuSen] = PickUpPolicy_PetYuSen
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSaiKaReverse] = PickUpPolicy_PetSaiKaReverse
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetLuoYi] = PickUpPolicy_PetLuoYi
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetQingTong] = PickUpPolicy_PetQingTong
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetLen] = PickUpPolicy_PetLen
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetGiles] = PickUpPolicy_PetGiles
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetVice] = PickUpPolicy_PetVice
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetReinhardt] = PickUpPolicy_PetReinhardt
    self._pickUpPolicyCalculatorDic[PickPosPolicy.FeatureMasterSkill] = PickUpPolicy_FeatureMasterSkill
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSPKaLian] = PickUpPolicy_PetSPKaLian
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSPKaLianWithDamage] = PickUpPolicy_PetSPKaLianWithDamage
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetFeiYa] = PickUpPolicy_PetFeiYa
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetJudge] = PickUpPolicy_PetJudge
    self._pickUpPolicyCalculatorDic[PickPosPolicy.Pet1601701] = PickUpPolicy_Pet1601701
    self._pickUpPolicyCalculatorDic[PickPosPolicy.Pet1601751] = PickUpPolicy_Pet1601751
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetZhongxuMain] = PickUpPolicy_PetZhongxuMain
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetZhongxuExtra] = PickUpPolicy_PetZhongxuExtra
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetYeliyaMain] = PickUpPolicy_PetYeliyaMain
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetYeliyaExtra] = PickUpPolicy_PetYeliyaExtra
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetLingEn] = PickUpPolicy_PetLingEn
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetDiNa] = PickUpPolicy_PetDiNa
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetNaNuSaiEr] = PickUpPolicy_PetNaNuSaiEr
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetANaTuoLi] = PickUpPolicy_PetANaTuoLi
    self._pickUpPolicyCalculatorDic[PickPosPolicy.FeatureMasterSkillExtra] = PickUpPolicy_FeatureMasterSkillExtra
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSorkBekk] = PickUpPolicy_PetSorkBekk
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetDanTang] = PickUpPolicy_PetDanTang
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PickupConvertWithWeight] = PickUpPolicy_PickUpConvertWithWeight
    self._pickUpPolicyCalculatorDic[PickPosPolicy.Pet1502051SPBaiLan] = PickUpPolicy_Pet1502051SPBaiLan
    self._pickUpPolicyCalculatorDic[PickPosPolicy.LocalTeamSelectGrid1x4Or2x2Convert] = PickUpPolicy_LocalTeamSelectGrid1x4Or2x2Convert
    self._pickUpPolicyCalculatorDic[PickPosPolicy.LocalTeamSelectCenterGridFor3x3Convert] = PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert
    self._pickUpPolicyCalculatorDic[PickPosPolicy.LocalTeamSelectCornerGridsFor3x3Convert] = PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert
    self._pickUpPolicyCalculatorDic[PickPosPolicy.LocalTeamSelectCenterGridFor1xCrossConvert] = PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert
    self._pickUpPolicyCalculatorDic[PickPosPolicy.LocalTeamPickupConvertWithWeight] = PickUpPolicy_LocalTeamPickUpConvertWithWeight
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetLarrey] = PickUpPolicy_PetLarrey
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetSinan] = PickUpPolicy_PetSinan
    self._pickUpPolicyCalculatorDic[PickPosPolicy.PetJocelyn] = PickUpPolicy_PetJocelyn
end