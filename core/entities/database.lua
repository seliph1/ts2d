--[[-----------------------------------------------------------------------------
	-- CS2D Entity Database
	-- Defines schemas, labels, colors, and parameter mappings for CS2D entities.
	-- CS2D documentation uses 0-based indexing (ints[0]..ints[9], strs[0]..strs[9]).
	-- In Lua, these map to 1-based indices (number_settings[1..10], string_settings[1..10]).
-------------------------------------------------------------------------------]]

local Database = {}

Database.ENTITIES = {
	[0] = {
		name = "Info_T",
		label = "T",
		color = { 1, 0, 0 },
		category = "info",
		description = "Terrorist Spawn Point",
	},
	[1] = {
		name = "Info_CT",
		label = "CT",
		color = { 0, 0.4, 1 },
		category = "info",
		description = "Counter-Terrorist Spawn Point",
	},
	[2] = {
		name = "Info_VIP",
		label = "VIP",
		color = { 1, 0.8, 0 },
		category = "info",
		description = "VIP Spawn Point",
	},
	[3] = {
		name = "Info_Hostage",
		label = "Hostage",
		color = { 0.8, 0.8, 0.8 },
		category = "info",
		description = "Hostage Spawn Point",
	},
	[4] = {
		name = "Info_RescuePoint",
		label = "Rescue",
		color = { 0.2, 0.8, 0.2 },
		category = "info",
		description = "Hostage Rescue Zone",
	},
	[5] = {
		name = "Info_BombSpot",
		label = "Bomb",
		color = { 1, 0, 0.5 },
		category = "info",
		description = "Bomb Planting Spot",
		int_schema = { [1] = "spot_letter" },
	},
	[6] = {
		name = "Info_EscapePoint",
		label = "Escape",
		color = { 1, 0.5, 0 },
		category = "info",
		description = "Terrorist Escape Zone",
	},
	[7] = {
		name = "Info_Target",
		label = "Target",
		color = { 0.8, 0, 0.8 },
		category = "info",
		description = "Target Spot",
	},
	[8] = {
		name = "Info_Animation",
		label = "Anim",
		color = { 0.5, 0.5, 0.5 },
		category = "info",
		description = "Animation Anchor",
	},
	[9] = {
		name = "Info_Storm",
		label = "Storm",
		color = { 0.3, 0.3, 0.6 },
		category = "info",
		description = "Storm Weather Zone",
	},
	[10] = {
		name = "Info_TileFX",
		label = "TileFX",
		color = { 0.4, 0.6, 0.4 },
		category = "info",
		description = "Tile Effect Modifier",
	},
	[11] = {
		name = "Info_NoBuying",
		label = "NoBuy",
		color = { 0.7, 0.2, 0.2 },
		category = "info",
		description = "No Buying Zone",
	},
	[12] = {
		name = "Info_NoWeapons",
		label = "NoWpn",
		color = { 0.7, 0.4, 0.2 },
		category = "info",
		description = "No Weapons Zone",
	},
	[13] = {
		name = "Info_NoFOW",
		label = "NoFOW",
		color = { 0.2, 0.7, 0.7 },
		category = "info",
		description = "No Fog of War Zone",
	},
	[14] = {
		name = "Info_Quake",
		label = "Quake",
		color = { 0.6, 0.4, 0.2 },
		category = "info",
		description = "Earthquake Trigger Zone",
	},
	[15] = {
		name = "Info_CTF_Flag",
		label = "Flag",
		color = { 1, 1, 0 },
		category = "info",
		description = "CTF Flag Base",
		int_schema = { [1] = "team" },
	},
	[16] = {
		name = "Info_OldRender",
		label = "OldRender",
		color = { 0.5, 0.5, 0.5 },
		category = "info",
		description = "Legacy Render Flag",
	},
	[17] = {
		name = "Info_Dom_Point",
		label = "DomPoint",
		color = { 0.8, 0.4, 0.8 },
		category = "info",
		description = "Domination Control Point",
	},
	[18] = {
		name = "Info_NoBuildings",
		label = "NoBuild",
		color = { 0.5, 0.2, 0.2 },
		category = "info",
		description = "No Construction Zone",
	},
	[19] = {
		name = "Info_BotNode",
		label = "BotNode",
		color = { 0.3, 0.8, 0.8 },
		category = "info",
		description = "Bot Navigation Node",
	},
	[20] = {
		name = "Info_TeamGate",
		label = "TeamGate",
		color = { 0.4, 0.4, 0.8 },
		category = "info",
		description = "Team Barrier Gate",
	},
	[21] = {
		name = "Env_Item",
		label = "Item",
		color = { 0, 1, 0 },
		category = "env",
		description = "Weapon / Item Generator",
		int_schema = {
			[1] = "item_type",
			[2] = "amount",
			[3] = "delay",
		},
	},
	[22] = {
		name = "Env_Sprite",
		label = "Spr",
		color = { 0, 1, 0 },
		category = "env",
		description = "Map Sprite Visual",
		int_schema = {
			[1] = "size_x",
			[2] = "size_y",
			[3] = "shift_x",
			[4] = "shift_y",
			[5] = "rotation",
			[6] = "red",
			[7] = "green",
			[8] = "blue",
			[9] = "fx",
			[10] = "blend",
		},
		str_schema = {
			[1] = "filepath",
			[2] = "alpha",
			[3] = "mask",
			[4] = "rotationspeed",
		},
	},
	[23] = {
		name = "Env_Sound",
		label = "Sound",
		color = { 0, 1, 0 },
		category = "env",
		description = "Sound Emitter",
		int_schema = {
			[1] = "volume",
			[2] = "mode",
		},
		str_schema = {
			[1] = "soundfile",
		},
	},
	[24] = {
		name = "Env_Decal",
		label = "Decal",
		color = { 0, 1, 0 },
		category = "env",
		description = "Decal Visual",
		str_schema = {
			[1] = "filepath",
		},
	},
	[25] = {
		name = "Env_Breakable",
		label = "Breakable",
		color = { 0, 1, 0 },
		category = "env",
		description = "Destructible Entity",
		int_schema = {
			[1] = "health",
			[2] = "particle_type",
		},
	},
	[26] = {
		name = "Env_Explode",
		label = "Explode",
		color = { 0, 1, 0 },
		category = "env",
		description = "Explosion Generator",
		int_schema = {
			[1] = "damage",
			[2] = "radius",
		},
	},
	[27] = {
		name = "Env_Hurt",
		label = "Hurt",
		color = { 0, 1, 0 },
		category = "env",
		description = "Damage Zone",
		int_schema = {
			[1] = "damage",
			[2] = "delay",
		},
	},
	[28] = {
		name = "Env_Image",
		label = "Image",
		color = { 0, 1, 0 },
		category = "env",
		description = "Overlay Image",
	},
	[29] = {
		name = "Env_Object",
		label = "Object",
		color = { 0, 1, 0 },
		category = "env",
		description = "Interactive Map Object",
	},
	[30] = {
		name = "Env_Building",
		label = "Build",
		color = { 0, 1, 0 },
		category = "env",
		description = "Pre-placed Building",
	},
	[31] = {
		name = "Env_NPC",
		label = "NPC",
		color = { 0, 1, 0 },
		category = "env",
		description = "Non-Player Character",
	},
	[32] = {
		name = "Env_Room",
		label = "Room",
		color = { 0, 1, 0 },
		category = "env",
		description = "Room Ambient Sound Zone",
	},
	[33] = {
		name = "Env_Light",
		label = "Light",
		color = { 0, 1, 0 },
		category = "env",
		description = "Dynamic Light Source",
		int_schema = {
			[1] = "red",
			[2] = "green",
			[3] = "blue",
			[4] = "radius",
		},
	},
	[34] = {
		name = "Env_LightStripe",
		label = "LStripe",
		color = { 0, 1, 0 },
		category = "env",
		description = "Linear Light Stripe",
	},
	[35] = {
		name = "Env_Cube3D",
		label = "C3D",
		color = { 0, 1, 0 },
		category = "env",
		description = "3D Geometry Cube",
	},
	[50] = {
		name = "Gen_Particles",
		label = "Particles",
		color = { 1, 0.5, 0 },
		category = "gen",
		description = "Particle Generator",
	},
	[51] = {
		name = "Gen_Sprites",
		label = "GenSpr",
		color = { 1, 0.5, 0 },
		category = "gen",
		description = "Sprite Generator",
	},
	[52] = {
		name = "Gen_Weather",
		label = "Weather",
		color = { 1, 0.5, 0 },
		category = "gen",
		description = "Weather Generator",
	},
	[53] = {
		name = "Gen_FX",
		label = "GenFX",
		color = { 1, 0.5, 0 },
		category = "gen",
		description = "Special Effects Generator",
	},
	[70] = {
		name = "Func_Teleport",
		label = "Teleport",
		color = { 0.8, 0.2, 0.8 },
		category = "func",
		description = "Teleporter Gate",
		int_schema = {
			[1] = "target_x",
			[2] = "target_y",
		},
		str_schema = {
			[1] = "target_name",
		},
	},
	[71] = {
		name = "Func_DynWall",
		label = "DynWall",
		color = { 0.8, 0.2, 0.8 },
		category = "func",
		description = "Dynamic Wall / Door",
		int_schema = {
			[1] = "tile_index",
			[2] = "mode",
			[3] = "speed",
			[4] = "width",
			[5] = "height",
		},
		str_schema = {
			[1] = "alpha",
		},
	},
	[72] = {
		name = "Func_Message",
		label = "Message",
		color = { 0.8, 0.2, 0.8 },
		category = "func",
		description = "Text Message Trigger",
		int_schema = {
			[1] = "target_mode",
		},
		str_schema = {
			[1] = "text",
		},
	},
	[73] = {
		name = "Func_GameAction",
		label = "GameAction",
		color = { 0.8, 0.2, 0.8 },
		category = "func",
		description = "Console Command Action",
		str_schema = {
			[1] = "command",
		},
	},
	[80] = {
		name = "Info_NoWeather",
		label = "NoWeather",
		color = { 0.5, 0.5, 0.5 },
		category = "info",
		description = "Disable Weather Area",
	},
	[81] = {
		name = "Info_RadarIcon",
		label = "RadarIcon",
		color = { 0.2, 0.8, 0.4 },
		category = "info",
		description = "Custom Radar Marker",
	},
	[90] = {
		name = "Trigger_Start",
		label = "TrigStart",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Round Start Trigger",
	},
	[91] = {
		name = "Trigger_Move",
		label = "TrigMove",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Movement Area Trigger",
		int_schema = {
			[1] = "width",
			[2] = "height",
		},
	},
	[92] = {
		name = "Trigger_Hit",
		label = "TrigHit",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Projectile / Hit Trigger",
	},
	[93] = {
		name = "Trigger_Use",
		label = "TrigUse",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Key Use (E) Activation Trigger",
		int_schema = {
			[1] = "width",
			[2] = "height",
		},
	},
	[94] = {
		name = "Trigger_Delay",
		label = "TrigDelay",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Delayed Trigger Relay",
		int_schema = {
			[1] = "delay_ms",
		},
	},
	[95] = {
		name = "Trigger_Once",
		label = "TrigOnce",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "One-Time Trigger",
	},
	[96] = {
		name = "Trigger_If",
		label = "TrigIf",
		color = { 1, 1, 0.2 },
		category = "trigger",
		description = "Conditional Logic Trigger",
	},
}

-- Fallback for unknown entity type IDs
Database.UNKNOWN_ENTITY = {
	name = "Unknown",
	label = "???",
	color = { 0.5, 0.5, 0.5 },
	category = "unknown",
	description = "Unknown Entity Type",
}

function Database.get(type_id)
	return Database.ENTITIES[type_id] or Database.UNKNOWN_ENTITY
end

function Database.dump()
	return Database.ENTITIES
end

return Database
