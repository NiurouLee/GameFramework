AutoTest_211216_113833={
cases = {
	[1] = {
		[1] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[2] = {
			action = "SetTeamPosition",
			args = {
				name = "team",
				pos = 502,
				},
			},
		[3] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2101512,
				name = "e1",
				pos = 402,
				},
			},
		[4] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e1",
				percent = 0.40000000596046,
				},
			},
		[5] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e1",
				trigger = 88,
				},
			},
		[6] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "skillIncreaseParam",
				attr_select_index = 9,
				defname = "e1",
				key = "CalcDamage_1",
				key_select_index = 4,
				skillid = 100116,
				trigger = 102,
				varname = "v1",
				},
			},
		[7] = {
			action = "CheckLocalValue",
			args = {
				target = 1.0299999713898,
				trigger = 88,
				varname = "v1",
				},
			},
		[8] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[9] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[10] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2101512,
				name = "e2",
				pos = 108,
				},
			},
		[11] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e2",
				percent = 0.40000000596046,
				},
			},
		[12] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e2",
				trigger = 88,
				},
			},
		[13] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "skillIncreaseParam",
				attr_select_index = 9,
				defname = "e2",
				key = "CalcDamage_5",
				key_select_index = 8,
				skillid = 300116,
				trigger = 102,
				varname = "v2",
				},
			},
		[14] = {
			action = "CheckLocalValue",
			args = {
				target = 1.0299999713898,
				trigger = 88,
				varname = "v2",
				},
			},
		[15] = {
			action = "FakeCastSkill",
			args = {
				name = "p1",
				pickUpPos = {
					[1] = 108.0,
					},
				},
			},
		[16] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[17] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2101512,
				name = "e3",
				pos = 705,
				},
			},
		[18] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e3",
				percent = 0.40000000596046,
				},
			},
		[19] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "skillIncreaseParam",
				attr_select_index = 9,
				defname = "e3",
				key = "CalcDamage_4",
				key_select_index = 7,
				skillid = 2001161,
				trigger = 102,
				varname = "v3",
				},
			},
		[20] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e3",
				trigger = 88,
				},
			},
		[21] = {
			action = "CheckLocalValue",
			args = {
				target = 1.0299999713898,
				trigger = 88,
				varname = "v3",
				},
			},
		[22] = {
			action = "FakeInputChain",
			args = {
				chainPath = {
					[1] = 502.0,
					[2] = 602.0,
					[3] = 702.0,
					[4] = 703.0,
					[5] = 704.0,
					},
				pieceType = 1,
				},
			},
		[23] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		name = "弗劳尔对血线低于40%的敌人造成的所有伤害（主动、连锁跟普攻），均提高XXX",
		},
	},
name = "费劳尔觉醒1",
petList = {
	[1] = {
		awakening = 0,
		equiplv = 1,
		grade = 1,
		id = 1601161,
		level = 1,
		name = "p1",
		},
	},
remotePet = {},
setup = {
	[1] = {
		args = {
			levelID = 1,
			matchType = 1,
			},
		setup = "LevelBasic",
		},
	},
}