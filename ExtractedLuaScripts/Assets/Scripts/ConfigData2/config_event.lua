local config_event = {
	[1] = {
		["NPC_dst"] = "Event001_NPC_DstPos",
		["NPC_prefab"] = "Event001_NPC_prefab",
		["NPC_spawn"] = "Event001_NPC_SpawnPos",
		["event_icon"] = "icon_event001",
		["event_interface"] = "Event001_Interface",
		["event_interval"] = {
			[1] = 60,
			[2] = 180,
		}
		,
		["event_limit"] = 80,
		["event_reward"] = {
			[1] = 2,
			[2] = function(n) return n*10 end,
		}
		,
		["event_scene"] = {
			[100] = true,
			[200] = true,
			[300] = true,
			[400] = true,
			[500] = true,
			[600] = true,
		}
		,
		["id"] = 1,
	}
	,
	[2] = {
		["NPC_dst"] = "Event002_NPC_DstPos",
		["NPC_prefab"] = "Event002_NPC_prefab",
		["NPC_spawn"] = "Event002_NPC_SpawnPos",
		["event_icon"] = "icon_event002",
		["event_interface"] = "Event002_Interface",
		["event_interval"] = {
			[1] = 60,
			[2] = 180,
		}
		,
		["event_limit"] = 0,
		["event_reward"] = {
			[1] = 3,
			[2] = 10,
			[3] = 1,
		}
		,
		["event_scene"] = {
			[300] = true,
			[400] = true,
		}
		,
		["id"] = 2,
	}
	,
	[3] = {
		["NPC_dst"] = "Event007_NPC_DstPos",
		["NPC_prefab"] = "Event007_NPC_prefab",
		["NPC_spawn"] = "Event007_NPC_SpawnPos",
		["event_icon"] = "icon_event007",
		["event_interface"] = "Event007_Interface",
		["event_interval"] = {
			[1] = 600,
			[2] = 1800,
		}
		,
		["event_limit"] = 0,
		["event_reward"] = {
			[1] = 3,
			[2] = 50,
			[3] = 1,
		}
		,
		["event_scene"] = {
			[100] = true,
			[200] = true,
			[300] = true,
			[400] = true,
		}
		,
		["id"] = 3,
	}
	,
	[4] = {
		["NPC_dst"] = "Event006_NPC_DstPos",
		["NPC_prefab"] = "Event006_NPC_prefab",
		["NPC_spawn"] = "Event006_NPC_SpawnPos",
		["event_icon"] = "icon_event006",
		["event_interface"] = "Event006_Interface",
		["event_interval"] = {
			[1] = 60,
			[2] = 180,
		}
		,
		["event_limit"] = 5,
		["event_reward"] = {
			[1] = 4,
			[2] = 300,
			[3] = 1,
		}
		,
		["event_scene"] = {
			[300] = true,
			[400] = true,
			[500] = true,
			[600] = true,
		}
		,
		["id"] = 4,
	}
	,
	[5] = {
		["NPC_dst"] = "Event001_NPC_DstPos",
		["NPC_prefab"] = "Event001_NPC_prefab",
		["NPC_spawn"] = "Event001_NPC_SpawnPos",
		["event_icon"] = "icon_event005",
		["event_interface"] = "Event005_Interface",
		["event_interval"] = {
			[1] = 60,
			[2] = 180,
		}
		,
		["event_limit"] = 80,
		["event_reward"] = {
			[1] = 6,
			[2] = function(n) return n*8 end,
		}
		,
		["event_scene"] = {
			[700] = true,
			[800] = true,
			[900] = true,
			[1000] = true,
		}
		,
		["id"] = 5,
	}
	,
}
return config_event