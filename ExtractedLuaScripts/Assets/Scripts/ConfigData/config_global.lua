local config_global = {
	["Batman_walkspeed"] = 5.5,
	["activity_duration"] = 32400,
	["activity_freshtime"] = 1800,
	["activity_poolsize"] = 50,
	["affairs_charge"] = 10,
	["affairs_property"] = {
		["buyMaxLimit"] = 10,
		["diamond"] = 30,
	}
	,
	["auto_cloudstorage"] = 900,
	["base_moon_down_rate"] = -0.5,
	["base_moon_up_rate"] = 20,
	["bonus_company"] = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
		[5] = 0,
		[6] = 0,
		[7] = 0,
	}
	,
	["boss_skin"] = {
		[1] = "Boss_001",
		[2] = "Boss_002",
	}
	,
	["building_scale"] = "1,0.7,0.7",
	["bus_interval_time"] = 0.1,
	["bus_wait_time"] = 4,
	["cancel_diamond"] = 50,
	["car_sell_price"] = 0.1,
	["ceochest_free_limit"] = 3,
	["character_run_v"] = 15,
	["character_walk_v"] = 5.5,
	["company_holdtime"] = 12,
	["company_qualities"] = {
		[1] = {
			[1] = 1,
			[2] = 2,
		}
		,
		[2] = {
			[1] = 1,
			[2] = 4,
		}
		,
		[3] = {
			[1] = 1,
			[2] = 5,
		}
		,
		[4] = {
			[1] = 3,
			[2] = 7,
		}
		,
	}
	,
	["cycle_instance_cash"] = {
		[1] = 2000,
		[2] = 600,
		[3] = 20,
	}
	,
	["cycle_instance_duration"] = 12,
	["cycle_instance_freeCoinFre"] = 5,
	["cycle_instance_freeCoinIcon"] = "icon_instance_point",
	["cycle_instance_freeCoinNum"] = 10,
	["cycle_instance_freeCoinTime"] = 10,
	["cycle_instance_initial_time"] = 8,
	["cycle_instance_pack"] = {
		[1] = 1342,
		[2] = 1343,
	}
	,
	["cycle_instance_ship_cooltime"] = 10,
	["cycle_instance_ship_loadtime"] = 2,
	["cycle_instance_time_arrange"] = "1:0,6;3:6,12;2:12,15;3:15,21;2:21,24",
	["cycle_instance_timenode"] = {
		[1] = "8",
		[2] = "20",
	}
	,
	["daily_reset"] = 8,
	["diamond_cooltime"] = 24,
	["diamond_key_ratio"] = {
		[1] = 100,
		[2] = 1,
	}
	,
	["diamond_layout"] = {
		[1] = {
			[1] = 1,
		}
		,
		[2] = {
			[1] = 3,
			[2] = 20,
		}
		,
		[3] = {
			[1] = 2,
		}
		,
		[4] = {
			[1] = 3,
			[2] = 80,
		}
		,
		[5] = {
			[1] = 2,
		}
		,
		[6] = {
			[1] = 2,
		}
		,
		[7] = {
			[1] = 4,
			[2] = 150,
		}
		,
	}
	,
	["diamond_layout_reward"] = {
		[1] = {
			[1] = {
				[1] = 4,
				[2] = 1,
			}
			,
			[2] = {
				[1] = 10,
				[2] = 5,
			}
			,
			[3] = {
				[1] = 20,
				[2] = 15,
			}
			,
		}
		,
		[2] = {
			[1] = {
				[1] = 4,
				[2] = 2,
			}
			,
			[2] = {
				[1] = 10,
				[2] = 10,
			}
			,
			[3] = {
				[1] = 20,
				[2] = 30,
			}
			,
		}
		,
		[3] = {
			[1] = {
				[1] = 4,
				[2] = 3,
			}
			,
			[2] = {
				[1] = 10,
				[2] = 50,
			}
			,
			[3] = {
				[1] = 20,
				[2] = 150,
			}
			,
		}
		,
	}
	,
	["diamond_layout_star"] = {
		[1] = 5,
		[2] = 20,
		[3] = 50,
		[4] = 100,
		[5] = 9999,
	}
	,
	["employee_base_exp"] = 10,
	["employee_improve_exp"] = {
		[1] = {
			[1] = 40,
			[2] = 70,
			[3] = 95,
			[4] = 999,
		}
		,
		[2] = {
			[1] = 0.5,
			[2] = 0.7,
			[3] = 1,
			[4] = 1.2,
		}
		,
	}
	,
	["enable_iap"] = 1,
	["energy_campaign"] = 15,
	["energy_relationship"] = 15,
	["energy_restore"] = 3,
	["energy_tank_effect"] = 60,
	["energy_tank_price"] = 40,
	["energy_uplimit"] = 120,
	["event001_money"] = 2000,
	["factory_camera"] = "60,80",
	["factory_guide"] = "1,300,500,Factory_Guide,0",
	["fbclub_guide"] = "2,700,20001,FBCub_Guide,0",
	["fc_rename_cost"] = 100,
	["fly_icon_setting"] = {
		[2] = {
			[1] = 2,
			[2] = 100,
			[3] = 20,
		}
		,
		[3] = {
			[1] = 3,
			[2] = 2,
			[3] = 10,
		}
		,
	}
	,
	["formula_energy"] = function(rest_time) return rest_time*14 end,
	["formula_rest"] = function(tired) return tired-50 end,
	["formula_toilet"] = function(toilet) return toilet-70 end,
	["fragment_task_refresh"] = 1,
	["fragment_task_refresh_cd"] = 24,
	["fragment_value"] = 10,
	["free_diamond"] = 10,
	["free_petsnack"] = {
		[1] = 1001,
		[2] = 1,
		[3] = 14400,
	}
	,
	["game_clock"] = {
		[1] = 7,
		[2] = 20,
		[3] = 7,
		[4] = 20,
		[5] = 60,
		[6] = 180,
	}
	,
	["game_version"] = "en",
	["guide_company"] = {
		[1] = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
		}
		,
		[2] = {
			[1] = 6,
			[2] = 7,
			[3] = 8,
			[4] = 9,
			[5] = 10,
		}
		,
	}
	,
	["highmood_bonus"] = 2,
	["highmood_cooltime"] = 120,
	["highmood_duration"] = 20,
	["highmood_probility"] = function(n) return n-79 end,
	["highmood_threshold"] = 80,
	["hungry_speed"] = 1,
	["initial_diamond"] = 0,
	["initial_money"] = 12200,
	["initial_mood"] = 70,
	["instance_bgm"] = "bgm_instance",
	["instance_cash"] = 1600,
	["instance_duration"] = 12,
	["instance_employee_upperlimit"] = 100,
	["instance_iaa_cd"] = {
		[1] = 60,
		[2] = 300,
	}
	,
	["instance_iaa_limit"] = 12,
	["instance_iaa_resource"] = 40,
	["instance_initial_time"] = 8,
	["instance_landmark_buff"] = "20,2",
	["instance_offvalue"] = 0.2,
	["instance_ship_cooltime"] = 50,
	["instance_ship_loadtime"] = 2,
	["instance_ship_traveltime"] = 7,
	["instance_state_debuff"] = 0.2,
	["instance_state_threshold"] = 20,
	["instance_state_weaken"] = 5,
	["instance_time_arrange"] = {
		[1] = {
			["range"] = {
				[1] = 0,
				[2] = 6,
			}
			,
			["timeType"] = 1,
		}
		,
		[2] = {
			["range"] = {
				[1] = 6,
				[2] = 12,
			}
			,
			["timeType"] = 3,
		}
		,
		[3] = {
			["range"] = {
				[1] = 12,
				[2] = 15,
			}
			,
			["timeType"] = 2,
		}
		,
		[4] = {
			["range"] = {
				[1] = 15,
				[2] = 21,
			}
			,
			["timeType"] = 3,
		}
		,
		[5] = {
			["range"] = {
				[1] = 21,
				[2] = 24,
			}
			,
			["timeType"] = 2,
		}
		,
	}
	,
	["instance_timenode"] = {
		[1] = "8",
		[2] = "20",
	}
	,
	["leakage_probility"] = function(n) return n-10 end,
	["leakage_threshold"] = 20,
	["login_wait_time"] = 15,
	["match_speed"] = {
		["duration"] = 30,
		["interval"] = 1,
	}
	,
	["meeting_length"] = {
		[1] = 3,
		[2] = 6,
	}
	,
	["meeting_time"] = 9,
	["mood_section"] = {
		[1] = 40,
		[2] = 70,
		[3] = 95,
		[4] = 999,
	}
	,
	["notify_reward"] = 5,
	["office_building_namePool_index"] = "TXT_BUILDINGNAME",
	["office_building_namePool_range"] = "1,10",
	["offline_condition"] = 1,
	["offline_manager_recommend"] = {
		[1] = "1015",
		[2] = "1014",
		[3] = "1013",
		[4] = "1012",
	}
	,
	["offline_reward_limit"] = {
		[1] = 120000,
		[2] = 2400000,
		[3] = 10000000,
		[4] = 20000000,
	}
	,
	["offline_timelimit"] = 2,
	["order_interval"] = 7200,
	["order_reward"] = {
		[1] = {
			[1] = {
				[1] = 1,
				[2] = 1,
			}
			,
		}
		,
	}
	,
	["order_time"] = {
		[1] = 14400,
		[2] = 43200,
	}
	,
	["pass_cnYear_advancedPass"] = 1611,
	["pass_cnYear_ticketPack"] = 1615,
	["pass_cnYear_ultimatePass"] = 1612,
	["pass_game_doubleWeight"] = {
		[1] = 5,
		[2] = 10,
		[3] = 20,
		[4] = 30,
		[5] = 35,
	}
	,
	["pass_game_firstPrizeMultiple"] = 2,
	["pass_game_pointsPerTicket"] = 1,
	["pass_game_pushWeight"] = {
		[1] = 8,
		[2] = 13,
		[3] = 4,
		[4] = 1,
		[5] = 0,
	}
	,
	["pass_game_resetPrize"] = 4,
	["pass_game_ticket"] = {
		[1] = 1,
		[2] = 1,
		[3] = 1,
		[4] = 2,
		[5] = 2,
		[6] = 3,
		[7] = 3,
		[8] = 4,
		[9] = 4,
		[10] = 5,
		[11] = 5,
		[12] = 5,
		[13] = 5,
		[14] = 5,
		[15] = 5,
		[16] = 5,
		[17] = 5,
		[18] = 5,
		[19] = 5,
		[20] = 5,
		[21] = 5,
		[22] = 5,
		[23] = 5,
		[24] = 5,
		[25] = 5,
	}
	,
	["pass_game_ticket_fruitji"] = 1,
	["pass_openScene"] = 200,
	["pass_rewards_exChest"] = "1599,1",
	["pass_rewards_exChestLimit"] = 20,
	["pass_rewards_exChestNeeds"] = 100,
	["pass_rewards_levelUpBuy"] = 150,
	["pet_exp_basespeed"] = 1,
	["player_character_namePool_index"] = "TXT_PLAYERNAME",
	["player_character_namePool_range"] = "1,100",
	["player_rename_cost"] = 100,
	["player_suppertorcount"] = 100,
	["poweroff_probility"] = function(n) return n-80 end,
	["poweroff_room_category"] = 778,
	["poweroff_threshold"] = 90,
	["quest_each_progress"] = 5,
	["rate_appear"] = {
		[1] = 100,
		[2] = 101,
	}
	,
	["rate_reward"] = {
		[1] = 2,
		[2] = 30000,
	}
	,
	["rename_cost"] = 100,
	["rent_debuff"] = 0.8,
	["reroll_cooltime"] = 6000,
	["reset_cycle"] = 24,
	["reset_time"] = 5,
	["rest_length"] = {
		[1] = 5,
		[2] = 10,
	}
	,
	["restore_shop_type"] = "23,26,27,30,36,37,40,41",
	["skipNightEvent"] = {
		["begin"] = 84600,
		["end"] = 19800,
	}
	,
	["skip_diamond"] = 1,
	["special_reward"] = 3000,
	["star_company"] = {
		[1] = 2,
		[2] = 3,
		[3] = 4,
		[4] = 5,
		[5] = 6,
		[6] = 7,
	}
	,
	["survey_scene"] = 2,
	["survey_switch"] = 0,
	["tempConf_duration"] = {
		[1] = 9,
		[2] = 20,
	}
	,
	["tempConf_interval"] = {
		[1] = 1,
		[2] = 2,
	}
	,
	["tempConf_limit"] = 20,
	["ten_fold_discount"] = 20,
	["ticket_limit"] = "50,50",
	["ticket_number"] = 3,
	["ticket_price"] = 100,
	["tired"] = {
		[1] = 0,
		[2] = 60,
	}
	,
	["tired_threshold"] = 90,
	["toilet"] = {
		[1] = 0,
		[2] = 70,
	}
	,
	["toilet_length"] = {
		[1] = 3,
		[2] = 5,
	}
	,
	["toilet_threshold"] = 100,
	["transfer_condition"] = 900,
	["upload_interval"] = 3600,
	["video_diamond"] = 5,
	["weekly_reset"] = {
		[1] = 1,
		[2] = 8,
	}
	,
	["wheel_burst"] = 30,
	["wheel_condition"] = 8,
	["wheel_diamond"] = 160,
	["wheel_free"] = 8,
	["wheel_switch"] = 1,
	["workday_duration"] = {
		[1] = 8,
		[2] = 23,
	}
	,
}
return config_global