--This mod is licensed under CC BY-SA

lib_tool_schematics = {}
lib_tool_schematics.path = minetest.get_modpath("lib_tool_schematics")


local schem_file_list = {}
local schem_file_list_length = 0
local schem_file_list_idx = 0
local current_schematic = {}
local states = {
	"action",
	"select_file",
	"select_rotation",
	"select_offset",
	"select_action",
	"select_config",
	"select_config_type",
}
local rotatations = {
	"0",
	"90",
	"180",
	"270",
}
local schem_actions = {
	"place_schem",
	"mts2lua",
	"lua2mts",
}
local config_actions = {
	"select_schem_file",
	"select_schem_rot",
	"select_save_type",
}
local current_state = states[1]
local current_rot = rotatations[1]                --ROTATIONS:	"0", "90", "180", "270"
local current_schem_action = schem_actions[1]               --TYPES:		"mts2lua", "lua2mts"
local current_offset = 0
local current_config_action = config_actions[1]

--
function lib_tool_schematics.convert_mts_to_lua()
  local building = lib_tool_schematics.path..'/schems/'..current_schem_name
  local str = minetest.serialize_schematic(building, "lua", {lua_use_comments = true, lua_num_indent_spaces = 0}).." return(schematic)"
  local schematic = loadstring(str)()
  local file = io.open(lib_tool_schematics.path..'/schems/'..current_schem_name..".lua", "w")
  file:write(dump(schematic))
  file:close()
--print(dump(schematic))
end

function lib_tool_schematics.mts_save()
    local f = assert(io.open(towns_gambit_schem_path.."hut.lua", "r"))
    local content = f:read("*all").." return(schematic2)"
    f:close()

  local schematic2 = loadstring("schematic2 = "..content)()
  local seb = minetest.serialize_schematic(schematic2, "mts", {})
	local filename = towns_gambit_schem_path .. "hut2" .. ".mts"
	filename = filename:gsub("\"", "\\\""):gsub("\\", "\\\\")
	local file, err = io.open(filename, "wb")
	if err == nil and seb then
		file:write(seb)
		file:flush()
		file:close()
	end
	print("Wrote: " .. filename)
end

function lib_tool_schematics.get_file_list()

	local file_list = minetest.get_dir_list( lib_tool_schematics.path..'/schems', false );
	local idx_file_list = 0
	if file_list then
		for _,filename in ipairs( file_list ) do		
			idx_file_list = idx_file_list + 1


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
							i = string.find( filename, '.lua', -10 );
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
		end
    end
	schem_file_list_length = idx_file_list
end

lib_tool_schematics.get_file_list()
current_schem_name = schem_file_list[1]



minetest.register_craftitem("lib_tool_schematics:schematics_tool", {
    description = "Schematics Tool",
    inventory_image = "worktable_saw.png",
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
		
			if current_schem_action == "place_schem"  then
				if pointed_thing.above then
					
					local schem_lua = minetest.serialize_schematic(lib_tool_schematics.path .. "/schems/"..current_schem_name, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}).." return(schematic)"
					
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
					local schematic = loadstring(schem_lua)()
					--current_schematic = loadstring(schem_lua)()

					local width = schematic["size"]["x"]
					local depth = schematic["size"]["z"]
					local height = schematic["size"]["y"]

					local p = pointed_thing.above
					p.x = p.x - width/2
					p.y = p.y - current_offset
					p.z = p.z - depth/2
					
					-- -- local count = worldedit.deserialize(pointed_thing.above, value)
					-- --{["air"] = "ignore", }
					-- lib_tool_schematics.path..'/schems/'..current_schem_name, 
					minetest.place_schematic(p, schematic, current_rot, nil)
				end
				minetest.chat_send_all( "Placed " .. current_schem_name .. " at " .. tostring(p))
			elseif current_schem_action == "mts2lua" then
				lib_tool_schematics.convert_mts_to_lua()
				minetest.chat_send_all( "Saved " .. current_schem_name .. " using " .. current_schem_action)
			elseif current_schem_action == "lua2mts" then
				lib_tool_schematics.mts_save()			
				minetest.chat_send_all( "Saved " .. current_schem_name .. " using " .. current_schem_action)
			else
			
			end
			
		elseif current_state == states[2] then
		
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
				
		elseif current_state == states[3] then
		
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

		elseif current_state == states[4] then
		
			current_offset = current_offset +  1
			if current_offset == 10 then
				current_offset = 0
			end
			minetest.chat_send_all( "Offset = " .. current_offset)
		
		elseif current_state == states[5] then
		
			if current_schem_action == schem_actions[1] then
				current_schem_action = schem_actions[2] 
			elseif current_schem_action == schem_actions[2] then
				current_schem_action = schem_actions[3]
			elseif current_schem_action == schem_actions[3] then
				current_schem_action = schem_actions[1]
			end
			minetest.chat_send_all( "Save Type = " .. current_schem_action)
			
		elseif current_state == states[6] then
		
			if current_config_action == config_actions[1] then
			
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
				
			end
			
		elseif current_state == states[7] then
		
			if current_config_action == config_actions[1] then
				current_config_action = config_actions[2]
			elseif current_config_action == config_actions[2] then
				current_config_action = config_actions[3]
			elseif current_config_action == config_actions[3] then
				current_config_action = config_actions[1]
			end
			
			minetest.chat_send_all( "Current Config Action = " .. current_config_action)
			
		end
		
		return itemstack
		
    end,
  })







