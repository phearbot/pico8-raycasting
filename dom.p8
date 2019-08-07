pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- core functions
	
function _init()
 build_map()
end


function _update60()
 pull_data_from_gpio()
	get_input()
 push_data_to_gpio()
end


function _draw()
 cls()

 -- draw_raycast_3d()
	-- draw_map() 
 draw_player(player.x,player.y,player.z,11)
 draw_other_players()
 -- draw_hud()
 --draw_debug()
	--draw_debug2()
 draw_debug3()
end

function draw_debug()
	print("x: " .. player.x,3,100,11)
	print("y: " .. player.y,3,108,11)
	print("z: " .. player.z,3,116,11)
	print("diffx: " .. diff_x,3,10,11)	
	print("diffy: " .. diff_y,3,18,11)
	print("ray_x: " .. ray_x,3,26,11)
	print("ray_y: " .. ray_y,3,34,11)
	print("steps: " .. steps,3,42,11)
	print("ray_dist: " .. ray_dist,3,50,11)
end

function draw_debug2()
 print("cpu: " .. stat(0),3,2,11)
 print("cpu: " .. stat(1),3,10,11)
 print("mem: " .. stat(2),3,18,11)
 print("fps: " .. stat(7),3,26,11)

 print("x: " .. player.x,3,70,11)
 print("y: " .. player.y,3,78,11)
 print("z: " .. player.z,3,86,11)

 print("gpiox: " .. peek4(0x5f80),3,100,11)
 print("gpioy: " .. peek4(0x5f84),3,108,11)
 print("gpioz: " .. peek4(0x5f88),3,116,11)
end

debug_add_player = 0
debug_move_enemy = 0
debug_enemy_id = -1
function draw_debug3()
 print("other_players: " .. #other_players,3,2,11)
 print("add player called: " .. debug_add_player,3,10,11)
 print("move enemy called: " .. debug_move_enemy,3,18,11)

 if (#other_players > 0) then
  print("enemy id: " .. other_players[1].id,3,26,11)
  print("enemy x: " .. other_players[1].x,3,34,11) 
  print("enemy y: " .. other_players[1].y,3,42,11) 
  print("enemy z: " .. other_players[1].z,3,50,11) 
  print("other_player_id: " .. debug_enemy_id,3,58,11)
 end
end

function tan(x) return sin(x) / cos(x) end

-- https://github.com/nangidev/pico-8-projects/blob/master/tech/lerp.p8
function lerp(tar,pos,perc)
 return (1-perc)*tar + perc*pos;
end
-->8
-- player stuff

player = {x=64,y=64,z=0,fov=.25,view_dist=20}
move_interval = 1 / 60 * 10
rotate_interval = 1 / 120

function get_input()
	-- left/right turns the z axis
 if (btn(0)) player.z+= rotate_interval
 if (btn(1)) player.z-= rotate_interval

	-- up/down moves forard based on z
 if (btn(2)) then
 	player.x += move_interval * cos(player.z)
 	player.y += move_interval * sin(player.z)
 end
 if (btn(3)) then
 	player.x -= move_interval * cos(player.z)
 	player.y -= move_interval * sin(player.z)
 end
	
 -- this is unnecessary because the functions accept anges > 1
	-- keep z between 0 and 1
	-- https://pico-8.fandom.com/wiki/sin
	if (player.z > 1) player.z -= 1
	if (player.z < 0) player.z += 1
	
end

function draw_player(x,y,z,_color)
	-- get the xd and yd
	local ray_len = 3
	local xd = ray_len * cos(z)
	local yd = ray_len * sin(z)

 line(x,y,x + xd,y + yd,_color)
	circ(x,y,2,_color)
end

function draw_hud()
 
end

-->8
-- 2d map stuff

function build_map()
	map_grid = {}
	for x=0, 127 do
	 map_grid[x] = {}
	 for y=0, 127 do
	  if (x==0 or y == 0 or x==127 or y==127) then
	  	map_grid[x][y] = 1
	  elseif (x==70 and (y > 20 and y < 100)) then
	  	map_grid[x][y] = 1
	  elseif (x==60 and (y > 20 and y < 100)) then
	  	map_grid[x][y] = 1  
	  else
	   map_grid[x][y] = 0
	 	end
	 end
	end
end

function draw_map()
	for x=0, 127 do
		for y=0, 127 do
			if map_grid[x][y] == 1 then
				pset(x,y,9)
			end
		end
	end
end
-->8
-- raycasting stuff


function draw_raycast_3d()
 for col=0,127 do
  cast_single_ray((player.z + (player.fov/2)) - (col * (player.fov / 128)), col)
 end
end

function cast_single_ray(ray_ang, column)
 local ray_len = 30
	--local ray_ang = player.z -- this will change
 diff_x = ray_len * cos(ray_ang)
 diff_y = ray_len * sin(ray_ang)
	
	--diff_x = abs(x2)
	--diff_y = abs(y2)
	
	if abs(diff_x) > abs(diff_y) then
		steps = abs(diff_x)
	else
		steps = abs(diff_y)
	end
	
	-- calculate steps
	step_x = diff_x / steps
	step_y = diff_y / steps
	
	ray_x = player.x
	ray_y = player.y
	-- iterate over one ray
 hit = false
	for i=0,steps do
	 ray_x += step_x
	 ray_y += step_y
	 
	 -- these breaks stop null ref exceptions?
	 -- if (ray_x < 0 or ray_x > 127) break
	 --	if (ray_y < 0 or ray_y > 127) break
	 if map_grid[flr(ray_x)][flr(ray_y)] == 1 then
   hit=true
   break
  end
	end
	
 if hit then 
 	-- calculate distance
 	new_diff_x = player.x - ray_x
 	new_diff_y = player.y - ray_y
 	ray_dist = cos(player.z - ray_ang) * sqrt((new_diff_x*new_diff_x) + (new_diff_y*new_diff_y))
 	
  col_height = (200 / ray_dist)

  -- this will draw the ray being cast
 	--line(player.x,player.y,ray_x,ray_y,12)

 	-- calculate column height
  -- percent = ray_dist / (ray_len * cos(player.z - ray_ang))
  -- col_height = lerp(128, 1, percent) 
 	
  -- color based on distance?
  if ray_dist > 20 then
   col_color = 1
  elseif ray_dist > 10 then
   col_color = 13
  else
   col_color = 14
  end

 	-- draw the column
  line(column,64 - (col_height / 2),column,64 + (col_height / 2),col_color)
	end
end
-->8
-- netcode stuff
push_data_size = 16 --everything after this is data we read from gpio 
pull_data_location = 0x5f80 + push_data_size -- needed here for ref between functions

-- i hope to god i documented this somewhere
function pull_data_from_gpio()
 pull_data_location = 0x5f80 + push_data_size -- reset it here

 while (pull_data_location < 0x5f80 + 128) do
  pull_data_action = peek(pull_data_location)

  -- no check for 0, because 0 means it wasn't set, and that falls under else
  if (pull_data_action == 1) then
   add_player()
  elseif (pull_data_action == 2) then
   move_other_players()
  elseif (pull_data_action == 3) then
   remove_player()
  else
   break
  end

  -- clear data that was just read
  for i=0x5f80 + push_data_size,pull_data_location - 4,4 do
   poke4(i,0)
  end
 end
end


function add_player()
 -- need to test this
 debug_add_player += 1

 local _id=peek(pull_data_location+1) 
 local _x=peek4(pull_data_location+2) 
 local _y=peek4(pull_data_location+6) 
 local _z=peek4(pull_data_location+10) 
 add(other_players,{id=_id,x=_x,y=_y,z=_z})

 pull_data_location += 14 -- 13 bytes + increment from action identifying byte
end

function move_other_players()
 debug_move_enemy += 1
 -- this may be able to be optimized
 local other_player_id = peek(pull_data_location+1)

 debug_enemy_id = other_player_id

 for i=1,#other_players do
  if other_player_id == other_players[i].id then
   other_players[i].x = peek4(pull_data_location+2)
   other_players[i].y = peek4(pull_data_location+6)
   other_players[i].z = peek4(pull_data_location+10)
  end
 end
 pull_data_location += 14 -- 13 bytes + increment from function byte
end

function remove_player()
 local other_player_id = peek(pull_data_location+1)

 for i=1,#other_players do
  if other_player_id == other_players[i].id then
   del(other_players, other_players[i])
   break
  end
 end

 pull_data_location += 2  -- 1 bytes + function byte
end

function push_data_to_gpio()
 poke4(0x5f80,player.x)
 poke4(0x5f84,player.y)
 poke4(0x5f88,player.z)
end


-->8
--enemy stuff

other_players={}

function draw_other_players()
 for i=1,#other_players do
   draw_player(other_players[i].x,other_players[i].y,other_players[i].z,8)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
