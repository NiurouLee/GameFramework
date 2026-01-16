AutoTest_211216_115929 = {
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
				id = 2071413,
				name = "e1",
				pos = 402,
				},
			},
		[4] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e1",
				percent = 0.5,
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
				attr_select_index = 10,
				defname = "e1",
				key = "CalcDamage_1",
				key_select_index = 5,
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
				id = 2101322,
				name = "e2",
				pos = 107,
				},
			},
		[11] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e2",
				percent = 0.30000001192093,
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
				attr_select_index = 10,
				defname = "e2",
				key = "CalcDamage_5",
				key_select_index = 9,
				skillid = 320116,
				trigger = 102,
				varname = "v2",
				},
			},
		[14] = {
			action = "CheckLocalValue",
			args = {
				target = 1.4099999666214,
				trigger = 88,
				varname = "v2",
				},
			},
		[15] = {
			action = "FakeCastSkill",
			args = {
				name = "p1",
				pickUpPos = {
					[1] = 107.0,
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
				id = 2101322,
				name = "e3",
				pos = 705,
				},
			},
		[18] = {
			action = "SetEntityHPPercent",
			args = {
				name = "e3",
				percent = 0.30000001192093,
				},
			},
		[19] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "skillIncreaseParam",
				attr_select_index = 10,
				defname = "e3",
				key = "CalcDamage_4",
				key_select_index = 8,
				skillid = 2001161,
				trigger = 102,
				varname = "v3",
				},
			},
		[20] = {
			action = "CheckLocalValue",
			args = {
				target = 1.0599999427795,
				trigger = 88,
				varname = "v3",
				},
			},
		[21] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e3",
				trigger = 88,
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
		name = "被动强化：触发的血线条件变为50%,若低于30%则效果翻倍（觉2主动技强化：若上回合主动技已就绪但未使用，则最终伤害提高35%）",
		},
	},
name = "费劳尔觉醒3",
petList = {
	[1] = {
		awakening = 0,
		equiplv = 1,
		grade = 3,
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