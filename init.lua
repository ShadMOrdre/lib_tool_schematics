--This mod is licensed under CC BY-SA

lib_tool_schematics = {}
lib_tool_schematics.name = "lib_tool_schematics"
lib_tool_schematics.ver_max = 1
lib_tool_schematics.ver_min = 0
lib_tool_schematics.ver_rev = 0
lib_tool_schematics.ver_str = lib_tool_schematics.ver_max .. "." .. lib_tool_schematics.ver_min .. "." .. lib_tool_schematics.ver_rev
lib_tool_schematics.authorship = "ShadMOrdre."
lib_tool_schematics.license = "LGLv2.1"
lib_tool_schematics.copyright = "2022"
lib_tool_schematics.path_mod = minetest.get_modpath(minetest.get_current_modname())
lib_tool_schematics.path_world = minetest.get_worldpath()
lib_tool_schematics.path = lib_tool_schematics.path_mod


minetest.log("[MOD] lib_tool_schematics:  Loading...")
minetest.log("[MOD] lib_tool_schematics:  Version:" .. lib_tool_schematics.ver_str)
minetest.log("[MOD] lib_tool_schematics:  Legal Info: Copyright " .. lib_tool_schematics.copyright .. " " .. lib_tool_schematics.authorship .. "")
minetest.log("[MOD] lib_tool_schematics:  License: " .. lib_tool_schematics.license .. "")


lib_tool_schematics.path = minetest.get_modpath("lib_tool_schematics")
lib_tool_schematics.worldpath = minetest.get_worldpath()


local schem_file_list = {}
local schem_file_list_length = 0
local schem_file_list_idx = 1
local current_schematic = {}
--[[local states = {
	"action",
	"select_file",
	"select_rotation",
	"select_offset",
	"select_action",
	"select_config",
	"select_config_type",
}--]]
local states = {
	"select_action",			--  place schematic, convert schematic
	"select_schem_path",
	"select_schem_type",
	"select_schem_file",
	"select_schem_rot",
	"select_schem_offset",
	"select_convert_type",
	"select_placement_type",
	"action",				--  performs the action as defined in the various config settings
}
--[[local schem_actions = {
	"place_schem",
	"mts2lua",
	"lua2mts",
}--]]
local schem_actions = {
	"place_schem",
	"convert_schem",
}
local path_locations = {
	lib_tool_schematics.path_mod .. "/schems/",
	lib_tool_schematics.path_world .. "/schems/",
}
local file_types = {
	"mts",
	"lua",
}
local rotatations = {
	"0",
	"90",
	"180",
	"270",
}
local convert_types = {
	"mts2lua",
	"lua2mts",
}
local placement_types = {
	"offset",
	"center",
}
--[[local config_actions = {
	"select_schem_file",
	"select_schem_rot",
	"select_save_type",
}--]]

local current_state = states[1]
local current_schem_action = schem_actions[1]               --TYPES:		"mts2lua", "lua2mts"
-- local current_config_action = config_actions[1]
local current_path_location = path_locations[1]
local current_file_type = file_types[1]
-- local current_rot = rotatations[1]                --ROTATIONS:	"0", "90", "180", "270"
-- local current_offset = 0
local current_rot = rotatations[1]                --ROTATIONS:	"0", "90", "180", "270"
local current_offset = 0
local current_convert_type = convert_types[1]
local current_placement_type = placement_types[1]



--
-- function to copy tables
--
function lib_tool_schematics.shallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end
--
-- fill chests
--
function lib_tool_schematics.fill_default_chest(pos)

	-- find chests within radius
	local chestpos = minetest.find_node_near(pos, 25, {"default:chest"}, true)
  
	if not chestpos then
		minetest.chat_send_all(" no chest_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("chest_pos ".. tostring(chestpos))
	end
  
	-- initialize chest (mts chests don't have meta)
	local meta = minetest.get_meta(chestpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Chest" then
		minetest.registered_nodes["default:chest"].on_construct(chestpos)
	end

	-- fill chest
	local inv = minetest.get_inventory( {type="node", pos=chestpos} )

	-- always
	inv:add_item("main", "default:apple "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("main", "farming:bread "..math.random(0,3))
		inv:add_item("main", "default:torch "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				inv:add_item("main", "farming:wheat "..math.random(0,3))
				inv:add_item("main", "farming:string "..math.random(0,3))
				inv:add_item("main", "farming:seed_cotton "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("main", "default:pick_wood "..math.random(0,1))
		inv:add_item("main", "default:axe_wood "..math.random(0,1))
		inv:add_item("main", "default:shovel_wood "..math.random(0,1))
		inv:add_item("main", "farming:hoe_wood "..math.random(0,1))
		inv:add_item("main", "default:torch "..math.random(0,1))
	end
end

function lib_tool_schematics.fill_basket(pos)

	-- find chests within radius
	local chestpos = minetest.find_node_near(pos, 25, {"earthbuild:basket"}, true)
  
	if not chestpos then
		minetest.chat_send_all(" no chest_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("chest_pos ".. tostring(chestpos))
	end
  
	-- initialize chest (mts chests don't have meta)
	local meta = minetest.get_meta(chestpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Basket" then
		minetest.registered_nodes["earthbuild:basket"].on_construct(chestpos)
	end

	-- fill chest
	local inv = minetest.get_inventory( {type="node", pos=chestpos} )

	-- always
	inv:add_item("main", "earthbuild:bottlegourd "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("main", "earthbuild:unfired_clay_pot "..math.random(0,3))
		inv:add_item("main", "earthbuild:fire_sticks "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				inv:add_item("main", "earthbuild:seed_bottlegourd "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("main", "earthbuild:flint_knife "..math.random(0,1))
		inv:add_item("main", "earthbuild:flint_axe "..math.random(0,1))
		inv:add_item("main", "earthbuild:dirt_compactor "..math.random(0,1))
		inv:add_item("main", "earthbuild:turf_cutter "..math.random(0,1))
		inv:add_item("main", "earthbuild:woven_mat "..math.random(0,1))
		inv:add_item("main", "earthbuild:bottlegourd_cup "..math.random(0,1))
		inv:add_item("main", "earthbuild:storage_pot_unfired "..math.random(0,1))
	end
end

function lib_tool_schematics.fill_bottlegourd_container(pos)

	-- find chests within radius
	local chestpos = minetest.find_node_near(pos, 25, {"earthbuild:bottlegourd_container"}, true)
  
	if not chestpos then
		minetest.chat_send_all(" no chest_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("chest_pos ".. tostring(chestpos))
	end
  
	-- initialize chest (mts chests don't have meta)
	local meta = minetest.get_meta(chestpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Bottle Gourd" then
		minetest.registered_nodes["earthbuild:bottlegourd_container"].on_construct(chestpos)
	end

	-- fill chest
	local inv = minetest.get_inventory( {type="node", pos=chestpos} )

	-- always
	inv:add_item("main", "earthbuild:bottlegourd "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("main", "earthbuild:unfired_clay_pot "..math.random(0,3))
		inv:add_item("main", "earthbuild:fire_sticks "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				inv:add_item("main", "earthbuild:seed_bottlegourd "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("main", "earthbuild:flint_knife "..math.random(0,1))
		inv:add_item("main", "earthbuild:flint_axe "..math.random(0,1))
		inv:add_item("main", "earthbuild:dirt_compactor "..math.random(0,1))
		inv:add_item("main", "earthbuild:turf_cutter "..math.random(0,1))
		inv:add_item("main", "earthbuild:woven_mat "..math.random(0,1))
		inv:add_item("main", "earthbuild:bottlegourd_cup "..math.random(0,1))
		inv:add_item("main", "earthbuild:storage_pot_unfired "..math.random(0,1))
	end
end

function lib_tool_schematics.fill_storage_pot(pos)

	-- find chests within radius
	local chestpos = minetest.find_node_near(pos, 25, {"earthbuild:storage_pot"}, true)
  
	if not chestpos then
		minetest.chat_send_all(" no chest_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("chest_pos ".. tostring(chestpos))
	end
  
	-- initialize chest (mts chests don't have meta)
	local meta = minetest.get_meta(chestpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Storage Pot" then
		minetest.registered_nodes["earthbuild:storage_pot"].on_construct(chestpos)
	end

	-- fill chest
	local inv = minetest.get_inventory( {type="node", pos=chestpos} )

	-- always
	inv:add_item("main", "earthbuild:bottlegourd "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("main", "earthbuild:unfired_clay_pot "..math.random(0,3))
		inv:add_item("main", "earthbuild:fire_sticks "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				inv:add_item("main", "earthbuild:seed_bottlegourd "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("main", "earthbuild:flint_knife "..math.random(0,1))
		inv:add_item("main", "earthbuild:flint_axe "..math.random(0,1))
		inv:add_item("main", "earthbuild:dirt_compactor "..math.random(0,1))
		inv:add_item("main", "earthbuild:turf_cutter "..math.random(0,1))
		inv:add_item("main", "earthbuild:woven_mat "..math.random(0,1))
		inv:add_item("main", "earthbuild:bottlegourd_cup "..math.random(0,1))
		inv:add_item("main", "earthbuild:storage_pot_unfired "..math.random(0,1))
	end
end

--
-- initialize furnace
--
function lib_tool_schematics.initialize_default_furnace(pos)

	-- find chests within radius
	local furnacepos = minetest.find_node_near(pos, 7, {"default:furnace"})

	-- initialize furnacepos (mts furnacepos don't have meta)
	if furnacepos then
		local meta = minetest.get_meta(furnacepos)
		if meta:get_string("infotext") ~= "furnace" then
			minetest.registered_nodes["default:furnace"].on_construct(furnacepos)
		end
	end
end

function lib_tool_schematics.initialize_earthen_furnace(pos)

	-- find chests within radius
	local furnacepos = minetest.find_node_near(pos, 7, {"earthbuild:earthen_furnace"})

	-- initialize furnacepos (mts furnacepos don't have meta)
	if furnacepos then
		local meta = minetest.get_meta(furnacepos)
		if meta:get_string("infotext") ~= "furnace" then
			minetest.registered_nodes["earthbuild:earthen_furnace"].on_construct(furnacepos)
		end
	end
end

function lib_tool_schematics.initialize_hearth(pos)

	-- find chests within radius
	local furnacepos = minetest.find_node_near(pos, 7, {"earthbuild:hearth"})

	-- initialize furnacepos (mts furnacepos don't have meta)
	if furnacepos then
		local meta = minetest.get_meta(furnacepos)
		if meta:get_string("infotext") ~= "hearth" then
			minetest.registered_nodes["earthbuild:hearth"].on_construct(furnacepos)
		end
	end
end

--
-- Init default signs
--
function lib_tool_schematics.initialize_default_signs(pos)

	-- find sign_wall_wood within radius
	local woodsignpos = minetest.find_node_near(pos, 7, {"default:sign_wall_wood"})
	local text = ""

	-- initialize sign_wall_wood (mts sign_wall_wood don't have meta)
	if woodsignpos then
		local meta = minetest.get_meta(woodsignpos)
		minetest.registered_nodes["default:sign_wall_wood"].on_construct(woodsignpos)
	end

	-- find sign_wall_steel within radius
	local steelsignpos = minetest.find_node_near(pos, 7, {"default:sign_wall_steel"})

	-- initialize sign_wall_steel (mts sign_wall_steel don't have meta)
	if steelsignpos then
		local meta = minetest.get_meta(steelsignpos)
		minetest.registered_nodes["default:sign_wall_steel"].on_construct(steelsignpos)
	end

end

--
-- initialize armor stand
--
function lib_tool_schematics.initialize_default_armor_stand(pos)

	-- find armor_stand within radius
	local armor_standpos = minetest.find_node_near(pos, 7, {"armor_stand:armor_stand"})

	-- initialize armor_stand (mts armor_stand don't have meta)
	if armor_standpos then
		local meta = minetest.get_meta(armor_standpos)
		if meta:get_string("infotext") ~= "Armor Stand" then
			minetest.registered_nodes["armor_stand:armor_stand"].on_construct(armor_standpos)
		end
	end
end

--
-- initialize drawers
--
function lib_tool_schematics.initialize_drawer1(pos)

	-- find drawers within radius
	local drawer1pos = minetest.find_node_near(pos, 7, {"drawers:wood1"})

	-- initialize drawers (mts drawers don't have meta)
	if drawer1pos then
		local meta = minetest.get_meta(drawer1pos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if string.find(meta:get_string("infotext"),"drawers") then
			minetest.registered_nodes["drawers:wood1"].on_construct(drawer1pos)
		end
	end
end

function lib_tool_schematics.initialize_drawer2(pos)

	-- find drawers within radius
	local drawer2pos = minetest.find_node_near(pos, 7, {"drawers:wood2"})

	-- initialize drawers (mts drawers don't have meta)
	if drawer2pos then
		local meta = minetest.get_meta(drawer2pos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if string.find(meta:get_string("infotext"),"drawers") then
			minetest.registered_nodes["drawers:wood2"].on_construct(drawer2pos)
		end
	end
end

function lib_tool_schematics.initialize_drawer4(pos)

	-- find drawers within radius
	local drawer4pos = minetest.find_node_near(pos, 7, {"drawers:wood4"})

	-- initialize drawers (mts drawers don't have meta)
	if drawer4pos then
		local meta = minetest.get_meta(drawer4pos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if string.find(meta:get_string("infotext"),"drawers") then
			minetest.registered_nodes["drawers:wood4"].on_construct(drawer4pos)
		end
	end
end

--
-- initialize fluid tanks
--
function lib_tool_schematics.initialize_fluid_tank(pos)

											-- -- find fluid_tank within radius
											-- local tankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank"})

											-- -- initialize fluid_tank (mts fluid_tank don't have meta)
											-- if tankpos then
												-- local meta = minetest.get_meta(tankpos)
												-- -- if meta:get_string("infotext") ~= "furnace" then
												-- if string.find(meta:get_string("infotext"),"Fluid Tank") then
													-- minetest.registered_nodes["fluid_tanks:tank"].on_construct(tankpos)
												-- end
											-- end



-- fluid_tanks:tank
-- fluid_tanks:tank_liquid_cement
-- fluid_tanks:tank_liquid_grease
-- fluid_tanks:tank_liquid_lava
-- fluid_tanks:tank_liquid_lava_cooling
-- fluid_tanks:tank_liquid_metal_bronze
-- fluid_tanks:tank_liquid_metal_chromium
-- fluid_tanks:tank_liquid_metal_copper
-- fluid_tanks:tank_liquid_metal_corium
-- fluid_tanks:tank_liquid_metal_gold
-- fluid_tanks:tank_liquid_metal_lead
-- fluid_tanks:tank_liquid_metal_mercury
-- fluid_tanks:tank_liquid_metal_mese
-- fluid_tanks:tank_liquid_metal_mithril
-- fluid_tanks:tank_liquid_metal_obsidian
-- fluid_tanks:tank_liquid_metal_silver
-- fluid_tanks:tank_liquid_metal_steel
-- fluid_tanks:tank_liquid_metal_tin
-- fluid_tanks:tank_liquid_metal_zinc
-- fluid_tanks:tank_liquid_mud
-- fluid_tanks:tank_liquid_mud_boiling
-- fluid_tanks:tank_liquid_oil
-- fluid_tanks:tank_liquid_oil_02
-- fluid_tanks:tank_liquid_oil_03
-- fluid_tanks:tank_liquid_quicksand
-- fluid_tanks:tank_liquid_water
-- fluid_tanks:tank_liquid_water_dirty
-- fluid_tanks:tank_liquid_water_murky
-- fluid_tanks:tank_liquid_water_river
-- fluid_tanks:tank_liquid_water_river_muddy
-- fluid_tanks:tank_liquid_water_rushing
-- fluid_tanks:tank_liquid_water_swamp



	-- find fluid_tank within radius
	local emptytankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank"})
	-- local tankpos = pos
	-- local node = minetest.get_node(pos)

	-- initialize fluid_tank (mts fluid_tank don't have meta)
	if emptytankpos then
	-- if (string.find(node.name, "fluid_tanks:") and string.find(node.name, "tank")) then
		local meta = minetest.get_meta(emptytankpos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank"].on_construct(emptytankpos)

--[[			-- local node = minetest.get_node(pos)
			-- local meta = minetest.get_meta(pos)

			local buffer = gal.lib.fluid.get_buffer_data(pos, "buffer")
			local percentile = buffer.amount / buffer.capacity

			local node_name = node.name
			local ndef = minetest.registered_nodes[node_name]
			if buffer.amount == 0 and ndef['_base_node'] then
				node_name = ndef['_base_node']
			end

			-- Select valid tank for current fluid
			if buffer.amount > 0 and not ndef['_base_node'] and buffer.fluid ~= "" then
				local fluid_name = gal.lib.fluid.cleanse_node_name(buffer.fluid)
				local new_node_name = node.name .. "_" .. fluid_name
				local new_def = minetest.registered_nodes[new_node_name]
				if new_def then
					node_name = new_node_name
					ndef = new_def
				end
			end

			if buffer.amount == 0 and ndef['_base_node'] then
				node_name = ndef['_base_node']
				ndef = minetest.registered_nodes[node_name]
				meta:set_string("buffer_fluid", "")
			end

			if node_name:match("^:") ~= nil then
				node_name = node_name:sub(2)
				ndef = minetest.registered_nodes[node_name]
			end

			-- Update infotext
			meta:set_string("infotext", ("%s\nContents: %s"):format(ndef.description,
				gal.lib.fluid.buffer_to_string(buffer)))

			local param2 = math.min(percentile * 63, 63)

			-- Node changed, lets switch it
			if node_name ~= node.name or param2 ~= node.param2 then
				minetest.swap_node(pos, {name = node_name, param2 = param2, param1 = node.param1})
			end--]]
		end
	end

	local cementtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_cement"})
	if cementtankpos then
		local meta = minetest.get_meta(cementtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_cement"].on_construct(cementtankpos)
		end
	end
	local greasetankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_grease"})
	if greasetankpos then
		local meta = minetest.get_meta(greasetankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_grease"].on_construct(greasetankpos)
		end
	end
	local lavatankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_lava"})
	if lavatankpos then
		local meta = minetest.get_meta(lavatankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_lava"].on_construct(lavatankpos)
		end
	end
	local lava_coolingtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_lava_cooling"})
	if lava_coolingtankpos then
		local meta = minetest.get_meta(lava_coolingtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_lava_cooling"].on_construct(lava_coolingtankpos)
		end
	end
	local mudtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_mud"})
	if mudtankpos then
		local meta = minetest.get_meta(mudtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_mud"].on_construct(mudtankpos)
		end
	end
	local mud_boilingtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_mud_boiling"})
	if mud_boilingtankpos then
		local meta = minetest.get_meta(mud_boilingtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_mud_boiling"].on_construct(mud_boilingtankpos)
		end
	end
	local oiltankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_oil"})
	if oiltankpos then
		local meta = minetest.get_meta(oiltankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_oil"].on_construct(oiltankpos)
		end
	end
	local oil_02tankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_oil_02"})
	if oil_02tankpos then
		local meta = minetest.get_meta(oil_02tankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_oil_02"].on_construct(oil_02tankpos)
		end
	end
	local oil_03tankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_oil_03"})
	if oil_03tankpos then
		local meta = minetest.get_meta(oil_03tankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_oil_03"].on_construct(oil_03tankpos)
		end
	end
	local quicksandtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_quicksand"})
	if quicksandtankpos then
		local meta = minetest.get_meta(quicksandtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_quicksand"].on_construct(quicksandtankpos)
		end
	end
	local watertankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water"})
	if watertankpos then
		local wt_node = minetest.get_node_or_nil(watertankpos)
		local wt_p2
		if wt_node ~= nil and wt_node.param2 ~= nil then
			wt_p2 = ((tonumber(wt_node.param2) + 1) / 8) * 1000
			-- local wt_description = wt_node.description
			local meta = minetest.get_meta(watertankpos)
			if string.find(meta:get_string("infotext"),"Contents: Water") then
				-- minetest.registered_nodes["fluid_tanks:tank_liquid_water"].on_construct(watertankpos)
				minetest.registered_nodes["fluid_tanks:tank_liquid_water"].on_timer(watertankpos)
			end
			meta:set_string("buffer_fluid", "gal:liquid_water_source")
			meta:set_int("buffer_fluid_storage", wt_p2)
			minetest.get_node_timer(watertankpos):start(0.2)
		end
		
		
	end
	local water_dirtytankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_dirty"})
	if water_dirtytankpos then
		local meta = minetest.get_meta(water_dirtytankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_dirty"].on_construct(water_dirtytankpos)
		end
	end
	local water_murkytankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_murky"})
	if water_murkytankpos then
		local meta = minetest.get_meta(water_murkytankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_murky"].on_construct(water_murkytankpos)
		end
	end
	local water_rivertankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_river"})
	if water_rivertankpos then
		local meta = minetest.get_meta(water_rivertankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_river"].on_construct(water_rivertankpos)
		end
	end
	local water_river_muddytankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_river_muddy"})
	if water_river_muddytankpos then
		local meta = minetest.get_meta(water_river_muddytankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_river_muddy"].on_construct(water_river_muddytankpos)
		end
	end
	local water_rushingtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_rushing"})
	if water_rushingtankpos then
		local meta = minetest.get_meta(water_rushingtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_rushing"].on_construct(water_rushingtankpos)
		end
	end
	local water_swamptankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_water_swamp"})
	if water_swamptankpos then
		local meta = minetest.get_meta(water_swamptankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_water_swamp"].on_construct(water_swamptankpos)
		end
	end
	local acidtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_acid"})
	if acidtankpos then
		local meta = minetest.get_meta(acidtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_acid"].on_construct(acidtankpos)
		end
	end
	local bronzetankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_bronze"})
	if bronzetankpos then
		local meta = minetest.get_meta(bronzetankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_bronze"].on_construct(bronzetankpos)
		end
	end
	local chromiumtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_chromium"})
	if chromiumtankpos then
		local meta = minetest.get_meta(chromiumtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_chromium"].on_construct(chromiumtankpos)
		end
	end
	local coppertankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_copper"})
	if coppertankpos then
		local meta = minetest.get_meta(coppertankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_copper"].on_construct(coppertankpos)
		end
	end
	local coriumtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_corium"})
	if coriumtankpos then
		local meta = minetest.get_meta(coriumtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_corium"].on_construct(coriumtankpos)
		end
	end
	local goldtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_gold"})
	if goldtankpos then
		local meta = minetest.get_meta(goldtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_gold"].on_construct(goldtankpos)
		end
	end
	local leadtankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_lead"})
	if leadtankpos then
		local meta = minetest.get_meta(leadtankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_lead"].on_construct(leadtankpos)
		end
	end
	local mercurytankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_mercury"})
	if mercurytankpos then
		local meta = minetest.get_meta(mercurytankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_mercury"].on_construct(mercurytankpos)
		end
	end
	local mesetankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_mese"})
	if mesetankpos then
		local meta = minetest.get_meta(mesetankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_mese"].on_construct(mesetankpos)
		end
	end
	local mithriltankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_mithril"})
	if mithriltankpos then
		local meta = minetest.get_meta(mithriltankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_mithril"].on_construct(mithriltankpos)
		end
	end
	local obsidiantankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_obsidian"})
	if obsidiantankpos then
		local meta = minetest.get_meta(obsidiantankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_obsidian"].on_construct(obsidiantankpos)
		end
	end
	local silvertankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_silver"})
	if silvertankpos then
		local meta = minetest.get_meta(silvertankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_silver"].on_construct(silvertankpos)
		end
	end
	local steeltankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_steel"})
	if steeltankpos then
		local meta = minetest.get_meta(steeltankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_steel"].on_construct(steeltankpos)
		end
	end
	local tintankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_tin"})
	if tintankpos then
		local meta = minetest.get_meta(tintankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_tin"].on_construct(tintankpos)
		end
	end
	local zinctankpos = minetest.find_node_near(pos, 7, {"fluid_tanks:tank_liquid_metal_zinc"})
	if zinctankpos then
		local meta = minetest.get_meta(zinctankpos)
		if string.find(meta:get_string("infotext"),"Fluid Tank") then
			minetest.registered_nodes["fluid_tanks:tank_liquid_metal_zinc"].on_construct(zinctankpos)
		end
	end




end

--
-- initialize itemframes
--
function lib_tool_schematics.initialize_itemframe(pos)

	-- find itemframes within radius
	local itemframepos = minetest.find_node_near(pos, 7, {"itemframes:frame"})

	-- initialize itemframes (mts itemframes don't have meta)
	if itemframepos then
		local meta = minetest.get_meta(itemframepos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if meta:get_string("infotext") ~= "Item frame (right-click to add/remove item)" then
			minetest.registered_nodes["itemframes:frame"].after_place_node(itemframepos)
		end
	end
end

--
-- initialize item pedestal
--
function lib_tool_schematics.initialize_itempedestal(pos)

	-- find item pedestals within radius
	local pedestalpos = minetest.find_node_near(pos, 7, {"itemframes:pedestal"})

	-- initialize item pedestals (mts item pedestals don't have meta)
	if pedestalpos then
		local meta = minetest.get_meta(pedestalpos)
		-- if meta:get_string("infotext") ~= "furnace" then
		if meta:get_string("infotext") ~= "Pedestal (right-click to add/remove item)" then
			minetest.registered_nodes["itemframes:pedestal"].after_place_node(pedestalpos)
		end
	end
end

--
-- initialize item shelves
--
function lib_tool_schematics.initialize_itemshelves(pos)

	-- find item pedestals within radius
	local small_shelfpos = minetest.find_node_near(pos, 7, {"itemshelf:small_shelf"})

	if not small_shelfpos then
		minetest.chat_send_all(" no small_shelf_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("small_shelf_pos ".. tostring(small_shelfpos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if small_shelfpos then
		local meta = minetest.get_meta(small_shelfpos)
		if meta:get_string("infotext") ~= "Item Shelf - Shelf (4)" then
			minetest.registered_nodes["itemshelf:small_shelf"].after_place_node(small_shelfpos)
		end

		-- fill chest
		local small_shelfinv = minetest.get_inventory( {type="node", pos=small_shelfpos} )

		-- always
		small_shelfinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			small_shelfinv:add_item("main", "farming:bread "..math.random(0,3))
			small_shelfinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					small_shelfinv:add_item("main", "farming:wheat "..math.random(0,3))
					small_shelfinv:add_item("main", "farming:string "..math.random(0,3))
					small_shelfinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			small_shelfinv:add_item("main", "default:pick_wood "..math.random(0,1))
			small_shelfinv:add_item("main", "default:axe_wood "..math.random(0,1))
			small_shelfinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			small_shelfinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			small_shelfinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

	-- find item pedestals within radius
	local large_shelfpos = minetest.find_node_near(pos, 7, {"itemshelf:large_shelf"})

	if not large_shelfpos then
		minetest.chat_send_all(" no large_shelf found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("large_shelf ".. tostring(large_shelfpos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if large_shelfpos then
		local meta = minetest.get_meta(large_shelfpos)
		if meta:get_string("infotext") ~= "Item Shelf - Shelf (6)" then
			minetest.registered_nodes["itemshelf:large_shelf"].after_place_node(large_shelfpos)
		end
		-- fill chest
		local large_shelfinv = minetest.get_inventory( {type="node", pos=large_shelfpos} )

		-- always
		large_shelfinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			large_shelfinv:add_item("main", "farming:bread "..math.random(0,3))
			large_shelfinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					large_shelfinv:add_item("main", "farming:wheat "..math.random(0,3))
					large_shelfinv:add_item("main", "farming:string "..math.random(0,3))
					large_shelfinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			large_shelfinv:add_item("main", "default:pick_wood "..math.random(0,1))
			large_shelfinv:add_item("main", "default:axe_wood "..math.random(0,1))
			large_shelfinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			large_shelfinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			large_shelfinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

	-- find item pedestals within radius
	local half_depth_shelf_smallpos = minetest.find_node_near(pos, 7, {"itemshelf:half_depth_shelf_small"})

	if not half_depth_shelf_smallpos then
		minetest.chat_send_all(" no half_depth_shelf_small found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("half_depth_shelf_small ".. tostring(half_depth_shelf_smallpos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if half_depth_shelf_smallpos then
		local meta = minetest.get_meta(half_depth_shelf_smallpos)
		if meta:get_string("infotext") ~= "Item Shelf - Half Shelf (4)" then
			minetest.registered_nodes["itemshelf:half_depth_shelf_small"].after_place_node(half_depth_shelf_smallpos)
		end
		-- fill chest
		local half_depth_shelf_smallinv = minetest.get_inventory( {type="node", pos=half_depth_shelf_smallpos} )

		-- always
		half_depth_shelf_smallinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			half_depth_shelf_smallinv:add_item("main", "farming:bread "..math.random(0,3))
			half_depth_shelf_smallinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					half_depth_shelf_smallinv:add_item("main", "farming:wheat "..math.random(0,3))
					half_depth_shelf_smallinv:add_item("main", "farming:string "..math.random(0,3))
					half_depth_shelf_smallinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			half_depth_shelf_smallinv:add_item("main", "default:pick_wood "..math.random(0,1))
			half_depth_shelf_smallinv:add_item("main", "default:axe_wood "..math.random(0,1))
			half_depth_shelf_smallinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			half_depth_shelf_smallinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			half_depth_shelf_smallinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

	-- find item pedestals within radius
	local half_depth_shelf_largepos = minetest.find_node_near(pos, 7, {"itemshelf:half_depth_shelf_large"})

	if not half_depth_shelf_largepos then
		minetest.chat_send_all(" no half_depth_shelf_large found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("half_depth_shelf_large ".. tostring(half_depth_shelf_largepos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if half_depth_shelf_largepos then
		local meta = minetest.get_meta(half_depth_shelf_largepos)
		if meta:get_string("infotext") ~= "Item Shelf - Half Shelf (6)" then
			minetest.registered_nodes["itemshelf:half_depth_shelf_large"].after_place_node(half_depth_shelf_largepos)
		end
		-- fill chest
		local half_depth_shelf_largeinv = minetest.get_inventory( {type="node", pos=half_depth_shelf_largepos} )

		-- always
		half_depth_shelf_largeinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			half_depth_shelf_largeinv:add_item("main", "farming:bread "..math.random(0,3))
			half_depth_shelf_largeinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					half_depth_shelf_largeinv:add_item("main", "farming:wheat "..math.random(0,3))
					half_depth_shelf_largeinv:add_item("main", "farming:string "..math.random(0,3))
					half_depth_shelf_largeinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			half_depth_shelf_largeinv:add_item("main", "default:pick_wood "..math.random(0,1))
			half_depth_shelf_largeinv:add_item("main", "default:axe_wood "..math.random(0,1))
			half_depth_shelf_largeinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			half_depth_shelf_largeinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			half_depth_shelf_largeinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

	-- find item pedestals within radius
	local half_depth_open_shelf_smallpos = minetest.find_node_near(pos, 7, {"itemshelf:half_depth_open_shelf_small"})

	if not half_depth_open_shelf_smallpos then
		minetest.chat_send_all(" no half_depth_open_shelf_small found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("half_depth_open_shelf_small ".. tostring(half_depth_open_shelf_smallpos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if half_depth_open_shelf_smallpos then
		local meta = minetest.get_meta(half_depth_open_shelf_smallpos)
		if meta:get_string("infotext") ~= "Item Shelf - Half Open-Back Shelf (4)" then
			minetest.registered_nodes["itemshelf:half_depth_open_shelf_small"].after_place_node(half_depth_open_shelf_smallpos)
		end
		-- fill chest
		local half_depth_open_shelf_smallinv = minetest.get_inventory( {type="node", pos=half_depth_open_shelf_smallpos} )

		-- always
		half_depth_open_shelf_smallinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			half_depth_open_shelf_smallinv:add_item("main", "farming:bread "..math.random(0,3))
			half_depth_open_shelf_smallinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					half_depth_open_shelf_smallinv:add_item("main", "farming:wheat "..math.random(0,3))
					half_depth_open_shelf_smallinv:add_item("main", "farming:string "..math.random(0,3))
					half_depth_open_shelf_smallinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			half_depth_open_shelf_smallinv:add_item("main", "default:pick_wood "..math.random(0,1))
			half_depth_open_shelf_smallinv:add_item("main", "default:axe_wood "..math.random(0,1))
			half_depth_open_shelf_smallinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			half_depth_open_shelf_smallinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			half_depth_open_shelf_smallinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

	-- find item pedestals within radius
	local half_depth_open_shelf_largepos = minetest.find_node_near(pos, 7, {"itemshelf:half_depth_open_shelf_large"})

	if not half_depth_open_shelf_largepos then
		minetest.chat_send_all(" no half_depth_open_shelf_large found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("half_depth_open_shelf_large ".. tostring(half_depth_open_shelf_largepos))
	end
  
	-- initialize item pedestals (mts item pedestals don't have meta)
	if half_depth_open_shelf_largepos then
		local meta = minetest.get_meta(half_depth_open_shelf_largepos)
		if meta:get_string("infotext") ~= "Item Shelf - Half Open-Back Shelf (6)" then
			minetest.registered_nodes["itemshelf:half_depth_open_shelf_large"].after_place_node(half_depth_open_shelf_largepos)
		end
		-- fill chest
		local half_depth_open_shelf_largeinv = minetest.get_inventory( {type="node", pos=half_depth_open_shelf_largepos} )

		-- always
		half_depth_open_shelf_largeinv:add_item("main", "default:apple "..math.random(1,3))

		-- low value items
		if math.random(0,1) < 1 then

			half_depth_open_shelf_largeinv:add_item("main", "farming:bread "..math.random(0,3))
			half_depth_open_shelf_largeinv:add_item("main", "default:torch "..math.random(0,3))

			---- additional fillings when farmin mod enabled
			--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

				if math.random(0,1) < 1 then

					half_depth_open_shelf_largeinv:add_item("main", "farming:wheat "..math.random(0,3))
					half_depth_open_shelf_largeinv:add_item("main", "farming:string "..math.random(0,3))
					half_depth_open_shelf_largeinv:add_item("main", "farming:seed_cotton "..math.random(0,3))
				end
			--end
		end

		-- medium value items
		if math.random(0,3) < 1 then
			half_depth_open_shelf_largeinv:add_item("main", "default:pick_wood "..math.random(0,1))
			half_depth_open_shelf_largeinv:add_item("main", "default:axe_wood "..math.random(0,1))
			half_depth_open_shelf_largeinv:add_item("main", "default:shovel_wood "..math.random(0,1))
			half_depth_open_shelf_largeinv:add_item("main", "farming:hoe_wood "..math.random(0,1))
			half_depth_open_shelf_largeinv:add_item("main", "default:torch "..math.random(0,1))
		end
	end

end

--
-- fill vessels shelf
--
function lib_tool_schematics.fill_vessels_shelf(pos, town_name)

	-- find vessels shelf within radius
	local vesselshelfpos = minetest.find_node_near(pos, 25, {"vessels:shelf"}, true)
  
	if not vesselshelfpos then
		minetest.chat_send_all(" no vesselshelf_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("vesselshelf_pos ".. tostring(vesselshelfpos))
	end
  
	-- initialize vessels shelf (mts vessels shelf don't have meta)
	local meta = minetest.get_meta(vesselshelfpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Empty Vessels Shelf" then
		minetest.registered_nodes["vessels:shelf"].on_construct(vesselshelfpos)
	end

	-- fill vessels shelf
	local inv = minetest.get_inventory( {type="node", pos=vesselshelfpos} )

	-- always
	inv:add_item("vessels", "vessels:drinking_glass "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("vessels", "vessels:glass_bottle "..math.random(0,3))

		if math.random(0,1) < 1 then

			inv:add_item("vessels", "vessels:glass_fragments "..math.random(0,3))
		end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("vessels", "vessels:steel_bottle "..math.random(0,1))
	end

end

--
-- fill default bookshelf
--
function lib_tool_schematics.fill_default_bookshelf(pos, town_name)

	-- find bookshelf within radius
	local bookshelfpos = minetest.find_node_near(pos, 25, {"default:bookshelf"}, true)
  
	if not bookshelfpos then
		minetest.chat_send_all(" no bookshelf_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("bookshelf_pos ".. tostring(bookshelfpos))
	end
  
	-- initialize bookshelf (mts bookshelf don't have meta)
	local meta = minetest.get_meta(bookshelfpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Empty Bookshelf" then
		minetest.registered_nodes["default:bookshelf"].on_construct(bookshelfpos)
	end

	-- fill bookshelf
	local inv = minetest.get_inventory( {type="node", pos=bookshelfpos} )

	-- always
	inv:add_item("books", "default:book "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		-- inv:add_item("books", "lorebooks:a_brief_history_of_the_universe "..math.random(0,3))
		-- inv:add_item("main", "default:torch "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				-- inv:add_item("books", "lorebooks:the_mese_mystery "..math.random(0,3))
				-- inv:add_item("main", "farming:string "..math.random(0,3))
				-- inv:add_item("main", "farming:seed_cotton "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		-- inv:add_item("books", "lorebooks:geography_101 "..math.random(0,1))
		-- inv:add_item("main", "default:axe_wood "..math.random(0,1))
		-- inv:add_item("main", "default:shovel_wood "..math.random(0,1))
		-- inv:add_item("main", "farming:hoe_wood "..math.random(0,1))
		-- inv:add_item("main", "default:torch "..math.random(0,1))
	end

end

--
-- fill lib_books bookshelf
--
function lib_tool_schematics.fill_lib_books_shelf(pos, town_name)

--[[
	-- TODO: more book types
	local callbacks = {}
	table.insert(callbacks, {func = lib_towns.generate_travel_guide, param1=pos, param2=town_name})

	local inv = minetest.get_inventory( {type="node", pos=pos} )
	for i = 1, math.random(2, 8) do
		local callback = callbacks[math.random(#callbacks)]
		local book = callback.func(callback.param1, callback.param2)
		if book then
			inv:add_item("books", book)
		end
	end
--]]

	-- find bookshelf within radius
	local bookshelfpos = minetest.find_node_near(pos, 25, {"lib_books:bookshelf"}, true)
  
	if not bookshelfpos then
		minetest.chat_send_all(" no bookshelf_pos found near ".. tostring(pos))
		return
	else
		minetest.chat_send_all("bookshelf_pos ".. tostring(bookshelfpos))
	end
  
	-- initialize bookshelf (mts bookshelf don't have meta)
	local meta = minetest.get_meta(bookshelfpos)
	--local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") ~= "Bookshelf" then
		minetest.registered_nodes["lib_books:bookshelf"].on_construct(bookshelfpos)
	end

	-- fill bookshelf
	local inv = minetest.get_inventory( {type="node", pos=bookshelfpos} )

	-- always
	inv:add_item("books", "lib_books:book "..math.random(1,3))

	-- low value items
	if math.random(0,1) < 1 then

		inv:add_item("books", "lorebooks:a_brief_history_of_the_universe "..math.random(0,3))
		-- inv:add_item("main", "default:torch "..math.random(0,3))

		---- additional fillings when farmin mod enabled
		--if minetest.get_modpath("farming") ~= nil and farming.mod == "redo" then

			if math.random(0,1) < 1 then

				inv:add_item("books", "lorebooks:the_mese_mystery "..math.random(0,3))
				-- inv:add_item("main", "farming:string "..math.random(0,3))
				-- inv:add_item("main", "farming:seed_cotton "..math.random(0,3))
			end
		--end
	end

	-- medium value items
	if math.random(0,3) < 1 then
		inv:add_item("books", "lorebooks:geography_101 "..math.random(0,1))
		-- inv:add_item("main", "default:axe_wood "..math.random(0,1))
		-- inv:add_item("main", "default:shovel_wood "..math.random(0,1))
		-- inv:add_item("main", "farming:hoe_wood "..math.random(0,1))
		-- inv:add_item("main", "default:torch "..math.random(0,1))
	end

end

--
-- init cottages
--
function lib_tool_schematics.initialize_cottages(pos)

	-- find Barrel within radius
	local barrelpos = minetest.find_node_near(pos, 7, {"cottages:barrel"})

	-- initialize Barrel (mts Barrel don't have meta)
	if barrelpos then
		local meta = minetest.get_meta(barrelpos)
		if meta:get_string("infotext") ~= "Public barrel" then
			minetest.registered_nodes["cottages:barrel"].on_construct(barrelpos)
		end
	end

	-- find Hand Mill within radius
	local millpos = minetest.find_node_near(pos, 7, {"cottages:handmill"})

	-- initialize Hand Mill (mts Hand Mill don't have meta)
	if millpos then
		local meta = minetest.get_meta(millpos)
		if meta:get_string("infotext") ~= "Public mill, powered by punching" then
			minetest.registered_nodes["cottages:handmill"].on_construct(millpos)
		end
	end

	-- find Shelf within radius
	local shelfpos = minetest.find_node_near(pos, 7, {"cottages:shelf"})

	-- initialize Shelf (mts Shelf don't have meta)
	if shelfpos then
		local meta = minetest.get_meta(shelfpos)
		if meta:get_string("infotext") ~= "open storage shelf" then
			minetest.registered_nodes["cottages:shelf"].on_construct(shelfpos)
		end
	end

	-- find Threshing Floor within radius
	local threshpos = minetest.find_node_near(pos, 7, {"cottages:threshing_floor"})

	-- initialize Threshing Floor (mts Threshing Floor don't have meta)
	if threshpos then
		local meta = minetest.get_meta(threshpos)
		if meta:get_string("infotext") ~= "Public threshing floor" then
			minetest.registered_nodes["cottages:threshing_floor"].on_construct(threshpos)
		end
	end

	-- find Well within radius
	local wellpos = minetest.find_node_near(pos, 7, {"cottages:water_gen"})

	-- initialize Well (mts Well don't have meta)
	if wellpos then
		local meta = minetest.get_meta(wellpos)
		if meta:get_string("infotext") ~= "Public tree trunk well" then
			minetest.registered_nodes["cottages:water_gen"].on_construct(wellpos)
		end
	end

end


--
-- initialize furnace, chests, bookshelves
--
function lib_tool_schematics.initialize_nodes(pos, width, depth, height)

	local p = lib_tool_schematics.shallowCopy(pos)

	for yi = 1,height do
		for xi = 0,width do
			for zi = 0,depth do

				local ptemp = {x=p.x+xi, y=p.y+yi, z=p.z+zi}
				local node = minetest.get_node(ptemp)

				-- if node.name == "default:furnace" or node.name == "default:chest" or node.name == "default:bookshelf" or node.name == "vessels:shelf" or
					-- node.name == "lib_forge:furnace" or node.name == "lib_forge:dual_furnace" or
					-- node.name == "lib_chests:chest" or node.name == "lib_chests:chest_connected_right" or node.name == "lib_books:bookshelf" or
					-- node.name == "drawers:wood1" or node.name == "drawers:wood2" or node.name == "drawers:wood4" or 
					-- node.name == "armor_stand:armor_stand" or 
					-- node.name == "itemshelf:small_shelf" or node.name == "itemshelf:large_shelf" or 
					-- node.name == "itemshelf:half_depth_shelf_small" or node.name == "itemshelf:half_depth_shelf_large" or 
					-- node.name == "itemshelf:half_depth_open_shelf_small" or node.name == "itemshelf:half_depth_open_shelf_large" or 
					-- (string.find(node.name, "fluid_tanks:") and ((string.find(node.name, "tank")) or (string.find(node.name, "tank_")))) or 
					-- -- node.name == "itemframes:frame" or node.name == "itemframes:pedestal" or 
					-- node.name == "earthbuild:earthen_furnace" or node.name == "earthbuild:hearth" or
					-- node.name == "earthbuild:basket" or node.name == "earthbuild:bottlegourd_container" or node.name == "earthbuild:storage_pot" or
					-- node.name == "cottages:barrel" or node.name == "cottages:handmill" or node.name == "cottages:shelf" or 
					-- node.name == "cottages:threshing_floor" or node.name == "cottages:water_gen" then
					-- minetest.registered_nodes[node.name].on_construct(ptemp)
				-- end

				-- when chest is found -> fill with stuff
				if node.name == "default:chest" then
					minetest.after(3,lib_tool_schematics.fill_default_chest,pos)
				end

				if node.name == "default:furnace" then
					lib_tool_schematics.initialize_default_furnace(pos)
				end

				if node.name == "default:bookshelf" then

					minetest.after(3,lib_tool_schematics.fill_default_bookshelf,pos)

				end

				if node.name == "vessels:shelf" then

					minetest.after(3,lib_tool_schematics.fill_vessels_shelf,pos)

				end

				if node.name == "default:sign_wall_wood" or node.name == "default:sign_wall_steel" then
					lib_tool_schematics.initialize_default_signs(pos)
				end

				-- when chest is found -> fill with stuff
				if node.name == "earthbuild:basket" then
					minetest.after(3,lib_tool_schematics.fill_basket,pos)
				end

				if node.name == "earthbuild:bottlegourd_container" then
					minetest.after(3,lib_tool_schematics.fill_bottlegourd_container,pos)
				end

				if node.name == "earthbuild:storage_pot" then
					minetest.after(3,lib_tool_schematics.fill_storage_pot,pos)
				end

				if node.name == "earthbuild:earthen_furnace" then
					lib_tool_schematics.initialize_earthen_furnace(pos)
				end

				if node.name == "earthbuild:hearth" then
					lib_tool_schematics.initialize_hearth(pos)
				end

				if node.name == "armor_stand:armor_stand" then
					lib_towns.initialize_default_armor_stand(pos)
				end

				if node.name == "drawers:wood1" then
					lib_towns.initialize_drawer1(pos)
				end

				if node.name == "drawers:wood2" then
					lib_towns.initialize_drawer2(pos)
				end

				if node.name == "drawers:wood4" then
					lib_towns.initialize_drawer4(pos)
				end

				if string.find(node.name, "fluid_tanks:") and string.find(node.name, "tank") then
					lib_tool_schematics.initialize_fluid_tank(pos)
				end

				-- if node.name == "itemframes:frame" then
					-- lib_towns.initialize_itemframe(pos)
				-- end

				-- if node.name == "itemframes:pedestal" then
					-- lib_towns.initialize_itempedestal(pos)
				-- end

				if node.name == "itemshelf:small_shelf" or node.name == "itemshelf:large_shelf" or 
					node.name == "itemshelf:half_depth_shelf_small" or node.name == "itemshelf:half_depth_shelf_large" or 
					node.name == "itemshelf:half_depth_open_shelf_small" or node.name == "itemshelf:half_depth_open_shelf_large" then
					lib_tool_schematics.initialize_itemshelves(pos)
				end

				-- when chest is found -> fill with stuff
				-- if node.name == "lib_chests:chest" or node.name == "lib_chests:chest_connected_left" then
					-- minetest.after(3,lib_chests.init_chests,pos)
				-- end

				if node.name == "lib_chests:chest" then
					minetest.after(3,lib_chests.fill_chest,pos)
					-- minetest.after(3,lib_chests.init_chest_connected,pos)
				end

				if node.name == "lib_chests:chest_connected_right" then
					minetest.after(3,lib_chests.init_chest_connected,pos)
				end

				if node.name == "lib_forge:furnace" then
					lib_forge.initialize_furnace(pos)
				end

				if node.name == "lib_forge:dual_furnace" then
					lib_forge.initialize_dual_furnace(pos)
				end

				if node.name == "cottages:barrel" or node.name == "cottages:handmill" or node.name == "cottages:shelf" or 
					node.name == "cottages:threshing_floor" or node.name == "cottages:water_gen" then
					lib_tool_schematics.initialize_cottages(pos)
				end

				if node.name == "lib_books:bookshelf" then
					-- if town_name and town_name ~= "" then
						--for t,twn in pairs(lib_towns.towns) do
						--	fill_shelf(pos, t)
						--	fill_shelf(twn.pos, town_name)
						--end
						--fill_shelf(pos, town_name)

						--minetest.after(3,fill_shelf,pos,town_name)
					-- end

					minetest.after(3,lib_tool_schematics.fill_lib_books_shelf,pos)

				end

				if minetest.get_item_group(node.name, "plant") > 0 then
					minetest.get_node_timer(pos):start(1000) -- start crops growing
				end

				if minetest.get_item_group(node.name, "sapling") > 0 then
					minetest.get_node_timer(pos):start(1000) -- start crops growing
				end

				if minetest.get_item_group(node.name, "leaves") > 0 then
					minetest.get_node_timer(pos):start(1000) -- start crops growing
				end

			end
		end
	end
end

function lib_tool_schematics.get_file_list()

	local file_list = minetest.get_dir_list( lib_tool_schematics.worldpath..'/schems', false );
	local idx_file_list = 1
	if file_list then
		for _,filename in ipairs( file_list ) do		


			-- we need the filename without extension (*.mts, *.we, *.wem)
			local schemname = filename;
			local i = string.find(           filename, '.mts',  -4 );
			if( i ) then
				schemname = string.sub( filename, 1, i-1 );
			else
				i = string.find(         filename, '.we',   -3 );
				if( i ) then
					schemname = string.sub( filename, 1, i-1 );
				else
					i = string.find( filename, '.wem',  -4 );
					if( i ) then
						schemname = string.sub( filename, 1, i-1 );
					else
						i = string.find( filename, '.schematic', -10 );
						if( i ) then
							schemname = string.sub( filename, 1, i-1 );
						else
							i = string.find( filename, '.lua', -4 );
							if( i ) then
								schemname = string.sub( filename, 1, i-1 );
							else
								return;
							end
						end
					end
				end
			end

			-- only add known file types
			if( not( schemname )) then
				return;
			end

			schem_file_list[idx_file_list] = filename

			idx_file_list = idx_file_list + 1

		end
    end

	-- schem_file_list_length = idx_file_list - 1
	schem_file_list_length = #schem_file_list

end

lib_tool_schematics.get_file_list()
local current_schem_name = schem_file_list[1]

function lib_tool_schematics.convert_mts_to_lua()
  local building = current_path_location .. current_schem_name
  local str = minetest.serialize_schematic(building, "lua", {lua_use_comments = true, lua_num_indent_spaces = 0}).." return(schematic)"
  local schematic = loadstring(str)()
  local file = io.open(current_path_location .. current_schem_name..".lua", "w")
  file:write(dump(schematic))
  file:close()
--print(dump(schematic))
end

function lib_tool_schematics.mts_save()
    local f = assert(io.open(current_path_location .. current_schem_name, "r"))
    local content = f:read("*all").." return(schematic2)"
    f:close()
	
	-- local T = lib_towns.schems.T

	-- -- local schematic
	-- if string.find(schematic2, "schem") or string.find(schematic2, "tent") then
		-- schematic2 = lib_towns.schematics[schematic2]
	-- elseif string.find(schematic2, "bldg_sch_") then
		-- schematic2 = lib_towns.schems.get2(schematic2, sub)
	-- else
		-- schematic2 = lib_towns.schems.get(schematic2, sub)
	-- end

  local schematic2 = loadstring("schematic2 = "..content)()


  local seb = minetest.serialize_schematic(schematic2, "mts", {})
  -- local seb = minetest.serialize_schematic(schematic, "mts", {})
	local filename = current_path_location .. current_schem_name .. ".mts"
	filename = filename:gsub("\"", "\\\""):gsub("\\", "\\\\")
	local file, err = io.open(filename, "wb")
	if err == nil and seb then
		file:write(seb)
		file:flush()
		file:close()
	end
	print("Wrote: " .. filename)
end

minetest.register_craftitem("lib_tool_schematics:schematics_tool", {
    description = "Schematics Tool",
    inventory_image = "xdecor_hammer.png",
    --
    -- save lua of schem
    --
    on_use = function(itemstack, placer, pointed_thing)
	
		if pointed_thing == nil then
			return
		end
	
		if current_state == states[1] then
			current_state = states[2]
		elseif current_state == states[2] then
			current_state = states[3]
		elseif current_state == states[3] then
			current_state = states[4]
		elseif current_state == states[4] then
			current_state = states[5]
		elseif current_state == states[5] then
			current_state = states[6]
		elseif current_state == states[6] then
			current_state = states[7]
		elseif current_state == states[7] then
			current_state = states[8]
		elseif current_state == states[8] then
			current_state = states[9]
		elseif current_state == states[9] then
			current_state = states[1]
		end
		minetest.chat_send_all( "Current State = " .. current_state)
		return itemstack
		
		
	end,
    
	--
    -- build schematic
    --
	on_secondary_use = function(itemstack, user, pointed_thing)

		if pointed_thing == nil then
		
			minetest.chat_send_all( "Secondary Usage Happening Now at a Lua Function Near You!!!")
		
		end

	end,
	
    on_place = function(itemstack, placer, pointed_thing)

		if current_state == states[1] then
		
			if current_schem_action == schem_actions[1] then
				current_schem_action = schem_actions[2] 
			elseif current_schem_action == schem_actions[2] then
				current_schem_action = schem_actions[1]
			end
			minetest.chat_send_all( "Schematic Action = " .. current_schem_action)
			
		elseif current_state == states[2] then
		
			if current_path_location == path_locations[1] then
				current_path_location = path_locations[2]
			else
				current_path_location = path_locations[1]
			end
			minetest.chat_send_all( "Using " .. current_path_location .. " path location.")		

		elseif current_state == states[3] then
		
			if current_file_type == file_types[1] then
				current_file_type = file_types[2]
			else
				current_file_type = file_types[1]
			end
			minetest.chat_send_all( "Using " .. current_file_type .. " file type.")		

		elseif current_state == states[4] then

			lib_tool_schematics.get_file_list()
			current_schem_name = schem_file_list[1]

			if current_schem_name ~= "" then
			-- if current_schem_name ~= nil then
				current_schem_name = schem_file_list[schem_file_list_idx]
				if current_schem_name ~= nil then
					minetest.chat_send_all( "Using " .. schem_file_list_idx .. " of " .. schem_file_list_length .. "files")		
					minetest.chat_send_all( "Using " .. current_schem_name)
				end
				if schem_file_list_idx == schem_file_list_length then
					schem_file_list_idx = 1
				else
					schem_file_list_idx = schem_file_list_idx + 1
				end
			end

		elseif current_state == states[5] then

			if current_rot == rotatations[1] then
				current_rot = rotatations[2]
			elseif current_rot == rotatations[2] then
				current_rot = rotatations[3]
			elseif current_rot == rotatations[3] then
				current_rot = rotatations[4]
			elseif current_rot == rotatations[4] then
				current_rot = rotatations[1]
			end
			minetest.chat_send_all( "Rotation = " .. current_rot)

		elseif current_state == states[6] then

--[[			current_offset = current_offset +  1
			if current_offset == 10 then
				current_offset = 0
			end
			minetest.chat_send_all( "Offset = " .. current_offset)--]]

			current_offset = current_offset -  1
			if current_offset == -10 then
				current_offset = 10
			end
			minetest.chat_send_all( "Offset = " .. current_offset)

--[[			if current_config_action == config_actions[1] then
			
				if current_schem_name ~= "" then
					if schem_file_list_idx == schem_file_list_length then
						schem_file_list_idx = 1
					else
						schem_file_list_idx = schem_file_list_idx + 1
					end
					current_schem_name = schem_file_list[schem_file_list_idx]
					minetest.chat_send_all( "Using " .. schem_file_list_idx .. " of " .. schem_file_list_length .. "files")		
					minetest.chat_send_all( "Using " .. current_schem_name)
				end
				
			elseif current_config_action == config_actions[2] then
			
				if current_rot == rotatations[1] then
					current_rot = rotatations[2]
				elseif current_rot == rotatations[2] then
					current_rot = rotatations[3]
				elseif current_rot == rotatations[3] then
					current_rot = rotatations[4]
				elseif current_rot == rotatations[4] then
					current_rot = rotatations[1]
				end
				minetest.chat_send_all( "Rotation = " .. current_rot)
				
			elseif current_config_action == config_actions[3] then
			
				if current_schem_action == schem_actions[1] then
					current_schem_action = schem_actions[2] 
				elseif current_schem_action == schem_actions[2] then
					current_schem_action = schem_actions[3]
				elseif current_schem_action == schem_actions[3] then
					current_schem_action = schem_actions[1]
				end
				minetest.chat_send_all( "Save Type = " .. current_schem_action)
				
			end--]]
			
		elseif current_state == states[7] then

			if current_convert_type == convert_types[1] then
				current_convert_type = convert_types[2]
			else
				current_convert_type = convert_types[1]
			end
			minetest.chat_send_all( "Using " .. current_convert_type .. " conversion type.")		

--[[			if current_config_action == config_actions[1] then
				current_config_action = config_actions[2]
			elseif current_config_action == config_actions[2] then
				current_config_action = config_actions[3]
			elseif current_config_action == config_actions[3] then
				current_config_action = config_actions[1]
			end
			minetest.chat_send_all( "Current Config Action = " .. current_config_action)--]]
			
		elseif current_state == states[8] then

			if current_placement_type == placement_types[1] then
				current_placement_type = placement_types[2]
			else
				current_placement_type = placement_types[1]
			end
			minetest.chat_send_all( "Using " .. current_placement_type .. " placement type.")		

		elseif current_state == states[9] then

			if current_schem_action == schem_actions[1] then

				if pointed_thing.above then

					local schematic = {}

					if current_file_type == file_types[1] then

						local schem_lua = minetest.serialize_schematic(current_path_location .. current_schem_name, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}).." return(schematic)"
						
						--schem_lua = schem_lua:gsub("air", "ignore")

						schem_lua = schem_lua:gsub("biomes:fir_needles", "ignore")
						schem_lua = schem_lua:gsub("biomes:fir_tree", "ignore")

						schem_lua = schem_lua:gsub("decor_shield:shield", "lib_ecology:savanna_leaves")

						schem_lua = schem_lua:gsub("doors:door_steel_b_1", "doors:door_steel")
						schem_lua = schem_lua:gsub("doors:door_steel_b_2", "doors:door_steel")
						schem_lua = schem_lua:gsub("doors:door_steel_t_1", "doors:door_steel")
						schem_lua = schem_lua:gsub("doors:door_steel_t_2", "doors:door_steel")
						schem_lua = schem_lua:gsub("doors:door_wood_b_1", "doors:door_wood")
						schem_lua = schem_lua:gsub("doors:door_wood_t_1", "doors:door_wood")

						schem_lua = schem_lua:gsub("kblocks:hedge", "hedges:apple_hedge")

						schem_lua = schem_lua:gsub("hyrule_mapgen:canopy_leaves", "lib_ecology:savanna_leaves")

						schem_lua = schem_lua:gsub("quartz:block", "lib_materials:quartz_block")

						--schem_lua = schem_lua:gsub("xdecor:cobble_wall_c2", "lib_ecology:mushroom_big_brown")
						schem_lua = schem_lua:gsub("xdecor:stone_tile", "lib_materials:stone_tile")

						schem_lua = schem_lua:gsub("xpanes:pane_1", "xpanes:pane")
						schem_lua = schem_lua:gsub("xpanes:pane_2", "xpanes:pane")
						schem_lua = schem_lua:gsub("xpanes:pane_3", "xpanes:pane")
						schem_lua = schem_lua:gsub("xpanes:pane_4", "xpanes:pane")
						schem_lua = schem_lua:gsub("xpanes:pane_5", "xpanes:pane")
						schem_lua = schem_lua:gsub("xpanes:bar_1", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_2", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_3", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_4", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_5", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_6", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_7", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_8", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_9", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_10", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_11", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_12", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_13", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_14", "xpanes:bar")
						schem_lua = schem_lua:gsub("xpanes:bar_15", "xpanes:bar")

						-- -- format schematic string
						schematic = loadstring(schem_lua)()

					elseif current_file_type == file_types[2] then

						schematic = dofile(current_path_location .. current_schem_name)

					else

						return

					end

					local width = schematic["size"]["x"]
					local depth = schematic["size"]["z"]
					local height = schematic["size"]["y"]

					local p = pointed_thing.above
					p.y = p.y - current_offset
					
					if current_placement_type == placement_types[1] then
						p.x = p.x - width/2
						p.z = p.z - depth/2
					end
					
					-- -- local count = worldedit.deserialize(pointed_thing.above, value)
					-- --{["air"] = "ignore", }
					-- lib_tool_schematics.path..'/schems/'..current_schem_name, 
					minetest.place_schematic(p, schematic, current_rot, nil)
					lib_tool_schematics.initialize_nodes(p, width, depth, height)
				end
				minetest.chat_send_all( "Placed " .. current_schem_name .. " at " .. tostring(p))

			elseif current_schem_action == schem_actions[2] then

				if current_convert_type == convert_types[1] then
					lib_tool_schematics.convert_mts_to_lua()
				-- elseif current_schem_action == "lua2mts" then
				elseif current_convert_type == convert_types[2] then
					lib_tool_schematics.mts_save()			
				end
				minetest.chat_send_all( "Saved " .. current_schem_name .. " using " .. current_schem_action)

			else
			
			end

		end

		return itemstack

    end,

})


minetest.log("[MOD] lib_tool_schematics:  Successfully loaded.")

