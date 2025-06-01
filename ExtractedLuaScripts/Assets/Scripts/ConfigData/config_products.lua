local config_products = {
	[1] = {
		["base_time"] = 6,
		["comment"] = "电池单元",
		["desc"] = "TXT_PRODUCT_1_DESC",
		["icon"] = "icon_product_1",
		["id"] = 1,
		["level"] = 1,
		["name"] = "TXT_PRODUCT_1_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 0,
				["type"] = 0,
			}
			,
		}
		,
		["value"] = 220,
		["workshop_require"] = {
			[1] = 101,
			[2] = 1,
		}
		,
	}
	,
	[2] = {
		["base_time"] = 6,
		["comment"] = "屏幕单元",
		["desc"] = "TXT_PRODUCT_2_DESC",
		["icon"] = "icon_product_2",
		["id"] = 2,
		["level"] = 1,
		["name"] = "TXT_PRODUCT_2_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 0,
				["type"] = 0,
			}
			,
		}
		,
		["value"] = 360,
		["workshop_require"] = {
			[1] = 101,
			[2] = 3,
		}
		,
	}
	,
	[3] = {
		["base_time"] = 30,
		["comment"] = "锂电池",
		["desc"] = "TXT_PRODUCT_3_DESC",
		["icon"] = "icon_product_3",
		["id"] = 3,
		["level"] = 2,
		["name"] = "TXT_PRODUCT_3_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 2,
				["type"] = 1,
			}
			,
		}
		,
		["value"] = 3650,
		["workshop_require"] = {
			[1] = 102,
			[2] = 1,
		}
		,
	}
	,
	[4] = {
		["base_time"] = 50,
		["comment"] = "手机屏幕",
		["desc"] = "TXT_PRODUCT_4_DESC",
		["icon"] = "icon_product_4",
		["id"] = 4,
		["level"] = 2,
		["name"] = "TXT_PRODUCT_4_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 3,
				["type"] = 2,
			}
			,
		}
		,
		["value"] = 6660,
		["workshop_require"] = {
			[1] = 102,
			[2] = 3,
		}
		,
	}
	,
	[5] = {
		["base_time"] = 120,
		["comment"] = "手机",
		["desc"] = "TXT_PRODUCT_5_DESC",
		["icon"] = "icon_product_5",
		["id"] = 5,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_5_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 1,
				["type"] = 3,
			}
			,
			[2] = {
				["num"] = 1,
				["type"] = 4,
			}
			,
		}
		,
		["value"] = 40800,
		["workshop_require"] = {
			[1] = 102,
			[2] = 6,
		}
		,
	}
	,
	[6] = {
		["base_time"] = 5,
		["comment"] = "电路单元1",
		["desc"] = "TXT_PRODUCT_6_DESC",
		["icon"] = "icon_product_6",
		["id"] = 6,
		["level"] = 1,
		["name"] = "TXT_PRODUCT_6_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 0,
				["type"] = 0,
			}
			,
		}
		,
		["value"] = 780,
		["workshop_require"] = {
			[1] = 101,
			[2] = 5,
		}
		,
	}
	,
	[7] = {
		["base_time"] = 10,
		["comment"] = "处理单元1",
		["desc"] = "TXT_PRODUCT_7_DESC",
		["icon"] = "icon_product_7",
		["id"] = 7,
		["level"] = 1,
		["name"] = "TXT_PRODUCT_7_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 0,
				["type"] = 0,
			}
			,
		}
		,
		["value"] = 1800,
		["workshop_require"] = {
			[1] = 101,
			[2] = 5,
		}
		,
	}
	,
	[8] = {
		["base_time"] = 60,
		["comment"] = "显示器2",
		["desc"] = "TXT_PRODUCT_8_DESC",
		["icon"] = "icon_product_8",
		["id"] = 8,
		["level"] = 2,
		["name"] = "TXT_PRODUCT_8_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 4,
				["type"] = 2,
			}
			,
		}
		,
		["value"] = 14000,
		["workshop_require"] = {
			[1] = 102,
			[2] = 5,
		}
		,
	}
	,
	[9] = {
		["base_time"] = 70,
		["comment"] = "大型电源2",
		["desc"] = "TXT_PRODUCT_9_DESC",
		["icon"] = "icon_product_9",
		["id"] = 9,
		["level"] = 2,
		["name"] = "TXT_PRODUCT_9_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 4,
				["type"] = 1,
			}
			,
		}
		,
		["value"] = 12000,
		["workshop_require"] = {
			[1] = 102,
			[2] = 4,
		}
		,
	}
	,
	[10] = {
		["base_time"] = 100,
		["comment"] = "pc主板3",
		["desc"] = "TXT_PRODUCT_10_DESC",
		["icon"] = "icon_product_10",
		["id"] = 10,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_10_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 9,
				["type"] = 6,
			}
			,
			[2] = {
				["num"] = 4,
				["type"] = 7,
			}
			,
		}
		,
		["value"] = 56000,
		["workshop_require"] = {
			[1] = 103,
			[2] = 1,
		}
		,
	}
	,
	[11] = {
		["base_time"] = 220,
		["comment"] = "主机3",
		["desc"] = "TXT_PRODUCT_11_DESC",
		["icon"] = "icon_product_11",
		["id"] = 11,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_11_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 1,
				["type"] = 10,
			}
			,
			[2] = {
				["num"] = 1,
				["type"] = 9,
			}
			,
		}
		,
		["value"] = 160000,
		["workshop_require"] = {
			[1] = 103,
			[2] = 2,
		}
		,
	}
	,
	[12] = {
		["base_time"] = 240,
		["comment"] = "个人电脑3",
		["desc"] = "TXT_PRODUCT_12_DESC",
		["icon"] = "icon_product_12",
		["id"] = 12,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_12_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 1,
				["type"] = 8,
			}
			,
			[2] = {
				["num"] = 1,
				["type"] = 10,
			}
			,
		}
		,
		["value"] = 180000,
		["workshop_require"] = {
			[1] = 103,
			[2] = 3,
		}
		,
	}
	,
	[13] = {
		["base_time"] = 140,
		["comment"] = "掌机屏幕2",
		["desc"] = "TXT_PRODUCT_13_DESC",
		["icon"] = "icon_product_13",
		["id"] = 13,
		["level"] = 2,
		["name"] = "TXT_PRODUCT_13_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 10,
				["type"] = 2,
			}
			,
		}
		,
		["value"] = 37000,
		["workshop_require"] = {
			[1] = 102,
			[2] = 5,
		}
		,
	}
	,
	[14] = {
		["base_time"] = 100,
		["comment"] = "掌机主板3",
		["desc"] = "TXT_PRODUCT_14_DESC",
		["icon"] = "icon_product_14",
		["id"] = 14,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_14_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 9,
				["type"] = 6,
			}
			,
			[2] = {
				["num"] = 4,
				["type"] = 7,
			}
			,
		}
		,
		["value"] = 76440,
		["workshop_require"] = {
			[1] = 103,
			[2] = 4,
		}
		,
	}
	,
	[15] = {
		["base_time"] = 220,
		["comment"] = "游戏掌机3",
		["desc"] = "TXT_PRODUCT_15_DESC",
		["icon"] = "icon_product_15",
		["id"] = 15,
		["level"] = 3,
		["name"] = "TXT_PRODUCT_15_NAME",
		["need_product"] = {
			[1] = {
				["num"] = 1,
				["type"] = 13,
			}
			,
			[2] = {
				["num"] = 1,
				["type"] = 14,
			}
			,
		}
		,
		["value"] = 210000,
		["workshop_require"] = {
			[1] = 103,
			[2] = 5,
		}
		,
	}
	,
}
return config_products