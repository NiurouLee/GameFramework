AutoTest_230118_112240 = {
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
			action = "SetPieceType",
			args = {
				pieceType = 2,
				},
			},
		[4] = {
			action = "SetEntityAttack",
			args = {
				attack = 999999,
				name = "p1",
				},
			},
		[5] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 5100111,
				name = "e1",
				pos = 505,
				},
			},
		[6] = {
			action = "AddBuffToEntity",
			args = {
				buffID = 5250070,
				name = "team",
				},
			},
		[7] = {
			action = "FakeInputChain",
			args = {
				chainPath = {
					[1] = 502.0,
					[2] = 503.0,
					},
				pieceType = 2,
				},
			},
		[8] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[9] = {
			action = "WaitGameOver",
			args = {},
			},
		name = "新测试用例",
		},
	},
name = "拉斐尔",
petList = {
	[1] = {
		awakening = 0,
		equipRefineLv = 0,
		equiplv = 1,
		grade = 0,
		id = 1600281,
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