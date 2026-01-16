AutoTest_211216_115526={
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
				id = 5100111,
				name = "e1",
				pos = 508,
				},
			},
		[4] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[5] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[6] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e1",
				trigger = 88,
				},
			},
		[7] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "skillIncreaseParam",
				attr_select_index = 9,
				defname = "e1",
				key = "CalcDamage_5",
				key_select_index = 8,
				skillid = 320116,
				trigger = 102,
				varname = "v1",
				},
			},
		[8] = {
			action = "CheckLocalValue",
			args = {
				target = 1.3500000238419,
				trigger = 88,
				varname = "v1",
				},
			},
		[9] = {
			action = "FakeCastSkill",
			args = {
				name = "p1",
				pickUpPos = {
					[1] = 508.0,
					},
				},
			},
		[10] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		name = "主动技强化：若上回合主动技已就绪但未使用，则最终伤害提高35%",
		},
	},
name = "费劳尔觉醒2",
petList = {
	[1] = {
		awakening = 0,
		equiplv = 1,
		grade = 2,
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