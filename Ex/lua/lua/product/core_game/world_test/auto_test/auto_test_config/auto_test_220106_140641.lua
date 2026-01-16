AutoTest_220106_140641 = {
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
			action = "SetEntityHP",
			args = {
				hp = 999999,
				name = "team",
				},
			},
		[4] = {
			action = "AddTrap",
			args = {
				dir = 3,
				disableai = true,
				id = 3400,
				name = "j1",
				pos = 5,
				},
			},
		[5] = {
			action = "AddTrap",
			args = {
				dir = 5,
				disableai = true,
				id = 3401,
				name = "j2",
				pos = 905,
				},
			},
		[6] = {
			action = "AddTrap",
			args = {
				dir = 5,
				disableai = true,
				id = 3408,
				name = "j3",
				pos = 309,
				},
			},
		[7] = {
			action = "AddTrap",
			args = {
				dir = 5,
				disableai = true,
				id = 3409,
				name = "j4",
				pos = 302,
				},
			},
		[8] = {
			action = "AddTrap",
			args = {
				dir = 5,
				disableai = true,
				id = 3408,
				name = "j5",
				pos = 709,
				},
			},
		[9] = {
			action = "AddTrap",
			args = {
				dir = 5,
				disableai = true,
				id = 3409,
				name = "j6",
				pos = 702,
				},
			},
		[10] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = false,
				id = 4010611,
				name = "e1",
				pos = 506,
				},
			},
		[11] = {
			action = "CheckEntityPos",
			args = {
				name = "e1",
				pos = 504,
				trigger = 88,
				},
			},
		[12] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[13] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[14] = {
			action = "CheckSkillRange",
			args = {
				range = {
					[1] = 103.0,
					[2] = 104.0,
					[3] = 105.0,
					[4] = 106.0,
					[5] = 107.0,
					[6] = 202.0,
					[7] = 203.0,
					[8] = 204.0,
					[9] = 205.0,
					[10] = 206.0,
					[11] = 207.0,
					[12] = 208.0,
					[13] = 304.0,
					[14] = 305.0,
					[15] = 404.0,
					[16] = 405.0,
					[17] = 504.0,
					[18] = 505.0,
					[19] = 604.0,
					[20] = 605.0,
					[21] = 704.0,
					[22] = 705.0,
					[23] = 804.0,
					[24] = 805.0,
					[25] = 904.0,
					[26] = 905.0,
					},
				skillid = 500172,
				trigger = 102,
				},
			},
		[15] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[16] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[17] = {
			action = "CheckSkillRange",
			args = {
				range = {
					[1] = 106.0,
					[2] = 107.0,
					[3] = 206.0,
					[4] = 207.0,
					},
				skillid = 500194,
				trigger = 102,
				},
			},
		[18] = {
			action = "CheckMonsterCount",
			args = {
				count = 1,
				monsterid = 4010613,
				trigger = 88,
				},
			},
		[19] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[20] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[21] = {
			action = "CheckSkillRange",
			args = {
				range = {
					[1] = 403.0,
					[2] = 404.0,
					[3] = 502.0,
					[4] = 503.0,
					[5] = 504.0,
					[6] = 505.0,
					[7] = 602.0,
					[8] = 603.0,
					[9] = 604.0,
					[10] = 605.0,
					[11] = 703.0,
					[12] = 704.0,
					},
				skillid = 500170,
				trigger = 102,
				},
			},
		[22] = {
			action = "FakeInputDoubleClick",
			args = {},
			},
		[23] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		name = "新测试用例",
		},
	},
name = "番外1-6幽灵",
petList = {
	[1] = {
		awakening = 0,
		equiplv = 1,
		grade = 0,
		id = 1600191,
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