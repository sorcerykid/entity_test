-- NB: This mod is intended for use with the Minimal game and expects
-- a singlenode mapgen. See README.txt for licensing information.

local entity_props = {
	paniki = {
		collisionbox = { -0.4, -0.2, -0.4, 0.4, 0.3, 0.4 },
		textures = { "mobs_paniki.png" },
		mesh = "paniki.b3d",
		yaw_origin = -math.pi / 2,
		enable_swimming = false,
		enable_climbing = false,
	},
	reindeer = {
		collisionbox = { -0.3, -0.1, -0.3, 0.3, 1.4, 0.3 },
		textures = { "mobs_reindeer.png" },
		mesh = "reindeer.b3d",
		yaw_origin = 0,
		enable_swimming = true,
		enable_climbing = true,
	},
}

local presets = {
	["(Custom)"] = { },
	["(Reset)"] = {
		"now: set_pos(home)",
		"now: unlock_velocity()",
		"now: set_velocity(none)",
		"now: set_rotation(none)",
		"now: set_acceleration(none)",
	},
	["Big square fly"] = {
		"now: set_pos(vec(8,5,8))",
		"now: set_yaw(rad90)",
		"now: set_acceleration_vert()",
		"now: set_speed(4)",
		"after 4: add_yaw(rad90)",
		"after 4: add_yaw(rad90)",
		"after 4: add_yaw(rad90)",
		"after 4: set_speed(0)",
	},
	["Big circle fly"] = {
		"now: set_pos(vec(0,5,8))",
		"now: set_yaw(rad90)",
		"now: set_acceleration_vert()",
		"now: set_speed(4)",
		"now: turn_by(rad90,3,4)",
		"after 12: set_speed(0)",
	},
	["Big diamond fly"] = {
		"now: set_pos(vec(0,5,-8))",
		"now: set_yaw(-rad45)",
		"now: set_acceleration_vert()",
		"now: set_speed(4)",
		"after 2.8: add_yaw(rad90)",
		"after 2.8: add_yaw(rad90)",
		"after 2.8: add_yaw(rad90)",
		"after 2.8: set_speed(0)",
	},
	["Roundabounce"] = {
		"now: set_pos(vec(0,2,8))",
		"now: set_yaw(rad90)",
		"now: set_acceleration_vert(-9)",
		"now: set_speed(2.5)",
		"now: turn_by(rad45,1,8)",
		"now: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_velocity_vert(4)",
		"after 1: set_speed(0)",
	},
	["Zig zaggy fun"] = {
		"now: set_pos(vec(8,5,5))",
		"now: set_yaw(rad90)",
		"now: set_acceleration_vert()",
		"now: set_speed(4)",
		"after 4: turn_by(rad180,1)",
		"after 4.5: turn_by(-rad180,1)",
		"after 4.5: turn_by(rad180,1)",
		"after 4.5: turn_by(-rad180,1)",
		"after 4.5: set_speed(0)",
	},
	["Lots of collisions"] = {
		"now: set_pos(vec(0,5,0))",
		"now: set_yaw()",
		"now: set_acceleration_vert(-9)",
		"now: unlock_velocity()",
		"after 1: set_velocity_horz(-8,0)",
		"after 1: set_velocity_horz(8,0)",
		"after 1: set_velocity_horz(-8,0)",
		"after 1: set_velocity_horz(0,-8)",
		"after 2: set_velocity_horz(12,0)",
		"after 2: set_velocity_horz(-12,12)",
		"after 2: set_velocity_horz(12,0)",
		"after 2: set_velocity_horz(-12,-12)",
		"after 2: set_velocity_horz(12,0)",
		"after 2: set_velocity_horz(-12,0)",
	},
	["Drown in water"] = {
		"now: set_pos(vec(6,4.5,0))",
		"now: set_yaw()",
		"now: set_acceleration_vert()",
		"now: unlock_velocity()",
		"now: set_velocity(vec(0,-0.2,0))",
		"after 15: set_velocity_vert(0.2)",
		"after 1.5: set_velocity_vert(-0.2)",
		"after 3: set_velocity_vert(0.2)",
		"after 15: set_velocity_vert()",
	},
	["Back and forth"] = {
		"now: set_pos(vec(-8,2,4))",
		"now: set_yaw(rad90)",
		"now: set_acceleration_vert(-9)",
		"now: set_speed_lateral(0,-2.5)",
		"after 2: turn_by(rad90,2)",
		"after 2: set_speed(0)",
		"after 1.5: set_speed(4)",
		"after 3.5: set_speed(0)",
		"after 1.5: set_speed(-2.5)",
		"now: turn_by(-rad90,2)",
		"after 4: set_speed(0)",
	}
}

local preset_list = { "(Custom)", "(Reset)", "Big square fly", "Big circle fly", "Big diamond fly", "Roundabounce", "Zig zaggy fun", "Lots of collisions", "Drown in water", "Back and forth" }

local is_running = false
local is_lagging = false
local player = nil
local avatar = nil
local player_huds = nil
local script = nil
local async_expr = nil

-------------------------------------

local pi = math.pi
local format = string.format
local fs = minetest.formspec_escape

local _ = nil

local function is_match( text, glob )
     -- use underscore variable to preserve captures
     _ = { string.match( text, glob ) }
     return #_ > 0
end

local function printf( ... )
	minetest.chat_send_all( string.format( ... ) )
end

local function pos_to_str( vec, is_int )
	return format( is_int and "(%d,%d,%d)" or "(%0.1f,%0.1f,%0.1f)", vec.x, vec.y, vec.z )
end

local function rot_to_str( vec )
	return format( "(%0.1f,%0.1f,%0.1f)", vec.x / pi * 180, vec.y / pi * 180, vec.z / pi * 180 )
end

local function join( list, sep, func )
	local str = ""
	for i, v in ipairs( list ) do
		local res = func( i, v )
		if res ~= nil then
			str = i > 1 and str .. sep .. res or str .. res
		end
	end
	return str
end

local function sanitize( buf )
	return string.trim( string.gsub( buf, ".", { ["\r"] = "\n", ["\t"] = " ", ["\f"] = " ", ["\b"] = " " } ) ) .. "\n"
end

local function update_hud( idx, ... )
	player:hud_change( player_huds[ idx ], "text", format( ... ) )
end

local function create_hud( )
	player_huds = {
		-- hud background
		player:hud_add( {
			hud_elem_type = "image",
       			text = "default_cloud.png^[colorize:#000066BB",
	       		scale = { x = -15, y = -31 },
			position = { x = 0.05, y = 0.25 },
			alignment = { x = 1, y = 1 },
		} ),
		player:hud_add( {
			hud_elem_type = "image",
			text = "default_cloud.png^[colorize:#006600BB",
	       		scale = { x = -15, y = -38 },
			position = { x = 0.05, y = 0.56 },
			alignment = { x = 1, y = 1 },
		} ),
		player:hud_add( {
			hud_elem_type = "image",
			text = "default_cloud.png^[colorize:#006666BB",
	       		scale = { x = -40, y = -15 },
			position = { x = 0.30, y = 0.70 },
			alignment = { x = 1, y = 1 },
		} ),

		-- hud foreground
		player:hud_add( {
			-- pos, rot, new_vel, old_vel
			hud_elem_type = "text",
			text = "",
			position = { x = 0.05, y = 0.25 },
			scale = { x = -15, y = -31 },
			number = 0xFFFFFF,
			alignment = { x = 1, y = 1 },
			offset = { x = 8, y = 8 }
		} ),
		player:hud_add( {
			-- collides_xz, collides_y, is_standing, is_swimming, is_climbing
			hud_elem_type = "text",
			text = "",
			position = { x = 0.05, y = 0.56 },
			scale = { x = -15, y = -38 },
			number = 0xFFFFFF,
			alignment = { x = 1, y = 1 },
			offset = { x = 8, y = 8 }
		} ),
		player:hud_add( {
			-- touched_objects
			hud_elem_type = "text",
			text = "",
			position = { x = 0.30, y = 0.70 },
			scale = { x = -15, y = -15 },
			number = 0xFFFFFF,
			alignment = { x = 1, y = 1 },
			offset = { x = 8, y = 8 }
		} ),
		player:hud_add( {
			-- collisions
			hud_elem_type = "text",
			text = "",
			position = { x = 0.50, y = 0.70 },
			scale = { x = -15, y = -15 },
			number = 0xFFFFFF,
			alignment = { x = 1, y = 1 },
			offset = { x = 0, y = 8 }
		} ),
	}
end

local function get_formspec( preset_name )
	local script = presets[ preset_name ]
	local formspec = "size[10.0,8.0]" ..
		"real_coordinates[true]" ..
		format( "textarea[0.5,0.8;9.0,5.8;script;Enter a script for this object:;%s]",
			join( script, "\n", function ( i, v ) return fs( v ) end ) ) ..
		"button_exit[7.5,6.9;2.0,0.7;run;Run]" ..
		"label[0.5,7.2;Preset:]" ..
		format( "dropdown[1.8,6.9;5.0,0.7;presets;%s;%d",
			join( preset_list, ",", function ( i, v ) return fs( v ) end ),
			table.indexof( preset_list, preset_name ) )

	return formspec
end

local function execute( expr )
	local func = loadstring( "return obj:" .. expr )
	if func then
      		setfenv( func, {
			obj = avatar,
			pi = math.pi,
			inf = math.huge,
			nan = 0/0,
			vec = vector.new,
			home = { x = 0, y = 5, z = 0 },
			none = { x = 0, y = 0, z = 0 },
			rad360 = 2 * pi,
			rad180 = pi,
			rad90 = pi / 2,
			rad60 = pi / 3,
			rad45 = pi / 4,
			rad30 = pi / 6,
			rad20 = pi / 9,
		} )
		local status, err = pcall( func )
		if not status then
			minetest.chat_send_all( "[Avatar] Execution failed: " .. err )
			return false
		end
		if err then
			minetest.chat_send_all( "[Avatar] Result: " .. tostring( err ) )
		end
		return true
	else
		minetest.chat_send_all( "[Avatar] Syntax error in expression." )
		return false
	end
end

local function execute_script( script )
	presets[ "(Custom)" ] = script   -- save script to presets

	local lines = { }

	for i, v in ipairs( script ) do
		local expr
		if is_match( v, "^now: (.+)" ) then
			table.insert( lines, { expr = _[ 1 ] } )
		elseif is_match( v, "^after (%d+): (.+)" ) or is_match( v, "^after (%d+%.%d): (.+)" ) then
			table.insert( lines, { time = tonumber( _[ 1 ] ), expr = _[ 2 ] } )
		else
			minetest.chat_send_all( format( "[Avatar] Invalid statement on line %d.", i ) )
			return
		end
	end

	local function next_step( idx )
		while lines[ idx ] do
			local cur_line = lines[ idx ]
			if cur_line.time then
				minetest.after( cur_line.time, function ( )
					cur_line.time = nil
					next_step( idx )
				end )
				return
			else
				minetest.chat_send_all( format( "[Avatar] Line %d: %s", idx, cur_line.expr ) )
				if not execute( cur_line.expr ) then
					is_running = false
					return
				end
			end
			idx = idx + 1
		end
		is_running = false
		minetest.chat_send_all( "[Avatar] Script completed." )
	end

	is_running = true
	next_step( 1 )
end

-------------------------------------

minetest.register_entity( "entity_test:avatar",{
	hp_max = 1,
	physical = true,
	static_save = true,
	description = "Avatar",
	collisionbox = { -0.2, -0.2, -0.2, 0.2, 1.2, 0.2 },
	visual = "mesh",
	visual_size = { x = 1, y = 1 },
	collide_with_objects = true,
	collision_checks = { },
	immersion_checks = { "default:water" },

	on_step = function( self, dtime, pos, rot, new_vel, old_vel, res )
		local obj = self.object

		if avatar == obj then
			if async_expr then
				execute( async_expr )
				async_expr = nil
			end

			if is_lagging then
				if math.random( 10 ) == 1 then
					-- Stall process for 0.3 secs
					local t = os.clock( )
					while os.clock( ) - t <= 1.6 do end
				end
			end

			update_hud( 4, "pos:\n%s\n\nrot:\n%s\n\nnew_vel:\n%s\n\nold_vel:\n%s",
				pos_to_str( pos ), rot_to_str( rot ), pos_to_str( new_vel ), pos_to_str( old_vel ) )

			if res then
				update_hud( 5, "is_standing:\n%s\n\nis_swimming:\n%s\n\nis_climbing:\n%s\n\ncollides_xz\n%s\n\ncollides_y\n%s",
					tostring( res.is_standing ), tostring( res.is_swimming ), tostring( res.is_climbing ),
					tostring( res.collides_xz ), tostring( res.collides_y ) )
				update_hud( 6, "touched_objects:\n%s", join( res.touched_objects, "\n", function ( i, v )
						return ( v and "player" or "entity" ) .. " @ " .. pos_to_str( v:get_pos( ) )
					end ) )
				update_hud( 7, "collisions:\n%s", join( res.collisions, "\n", function ( i, v )
						return minetest.get_node( v ).name .. " @ " .. pos_to_str( v, true )
					end ) )
			end
		end

		if res then
			print( string.format( "[%d] pos=%s rot=%s new_vel=%s old_vel=%s, col_xz=%s, col_y=%s",
				self.id, pos_to_str( pos ), rot_to_str( rot ), pos_to_str( new_vel ), pos_to_str( old_vel ),
				tostring( res.collides_xz ), tostring( res.collides_y ) ) )
		else
			print( string.format( "[%d] pos=%s rot=%s new_vel=%s old_vel=%s",
				self.id, pos_to_str( pos ), rot_to_str( rot ), pos_to_str( new_vel ), pos_to_str( old_vel ) ) )
		end
	end,

	on_activate = function ( self, staticdata, dtime, id )
		printf( "[Avatar] on_activate( ): dtime=%0.1f, id=%d", dtime, id )
		self.id = id
	end,

	on_deactivate = function ( self, id )
		printf( "[Avatar] on_deactivate( ): id=%d", id )
		if avatar == self.object then
			for i, v in ipairs( player_huds ) do
				player:hud_remove( v )
				player_huds = nil
			end
			avatar = nil
			printf( "[Avatar] Deselected object id " .. self.id .. "." )
		end
	end,

	on_punch = function ( self )
		avatar = self.object
		printf( "[Avatar] Selected object id " .. self.id .. "." )
	end,

	get_staticdata = function ( self )
		printf( "[Avatar] get_staticdata( )" )
	end,
} )

minetest.register_chatcommand( "add", {
	func = function( name, param )
		player = minetest.get_player_by_name( name )
		avatar = minetest.add_entity( { x = 0, y = 5, z = 0 }, "entity_test:avatar" )

		avatar:set_properties( entity_props[ param ] or entity_props.reindeer )
		if not player_huds then
			create_hud( )
		end

		return true, "[Avatar] Selected object id " .. avatar:get_luaentity( ).id .. "."
	end
} )

minetest.register_chatcommand( "sel", {
	func = function( name, param )
		local id = tonumber( param )
		if minetest.luaentities[ id ] then
			avatar = minetest.luaentities[ id ].object
			if not player_huds then
				create_hud( )
			end

			return true, "[Avatar] Selected object id " .. id .. "."
		end
	end
} )

minetest.register_chatcommand( "cmd", {
	func = function( name, param )
		if avatar then
			if is_running then
				return false, "[Avatar] The script is still running."
			elseif param == "" then
				minetest.show_formspec( name, "entity_test:editor", get_formspec( preset_list[ 1 ] ) )
				return true
			elseif string.find( param, "^@" ) then
				async_expr = string.sub( param, 2 )
				return true, "[Avatar] Performing asynchronous execution."
			else
				return execute( param )
			end
		else
			return false, "[Avatar] No object selected."
		end
	end
} )

minetest.register_chatcommand( "lag", {
	func = function( name, param )
		is_lagging = not is_lagging
		return true, "[Avatar] Randomly induced lag " .. ( is_lagging and "enabled" or "disabled" ) .. "."
	end
} )

minetest.register_on_player_receive_fields( function( player, formname, fields )
        local name = player:get_player_name( )

        if formname ~= "entity_test:editor" then return end

	if fields.run then
		execute_script( string.split( sanitize( fields.script ), "\n" ) )
	elseif fields.presets then
		local idx = table.indexof( preset_list, fields.presets )
		minetest.show_formspec( name, "entity_test:editor", get_formspec( preset_list[ idx ] ) )
	end
end )

local function construct_spawn( )
	for y = 0, 4 do
		for x = -20 - y, 20 + y do
			for z = -20 - y, 20 + y do
				minetest.set_node( { x = x, y = 1 - y, z = z}, { name = "default:cobble" } )
			end
		end
	end

	for y = 2, 5 do
		for x = -10, 10 do
			minetest.set_node( { x = x, y = y, z = -10 }, { name = "default:cobble" } )
			minetest.set_node( { x = x, y = y, z = 10 }, { name = "default:cobble" } )
		end
		for z = -9, 9 do
			minetest.set_node( { x = -10, y = y, z = -z }, {name = "default:cobble" } )
			minetest.set_node( { x = 10, y = y, z = z }, { name = "default:cobble" } )
		end
		minetest.set_node( { x = 0, y = y, z = 9 }, { name = "default:ladder", param2 = 4 } )
	end

	for y = 2, 3 do
		for z = -2, 2 do
			for x = 4, 8 do
				local is_cobble = math.abs( z ) == 2 or x % 4 == 0
				minetest.set_node( { x = x, y = y, z = z }, {
					name = is_cobble and "default:cobble" or "default:water_source"
				} )

				minetest.set_node( { x = -x, y = y, z = z }, {
					name = is_cobble and "default:cobble" or "default:lava_source"
				} )
			end
		end
	end

	for x = -2, 2 do
		minetest.set_node( { x = x, y = 2, z = 0 }, { name = "default:ladder", param2 = 1 } )
	end
end

minetest.register_on_joinplayer( function( )
	minetest.after( 0.5, construct_spawn )
end )

minetest.register_on_leaveplayer( function ( )
	if avatar then
		avatar_obj:remove( )
	end
end )

