pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- core functions
	
function _init()
 build_map()
end


function _update60()
	get_input()
end


function _draw()
 cls()

 draw_raycast_3d()
	draw_map() 
 draw_player(true)
 --draw_debug()
	--draw_debug2()
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
 
end

function tan(x) return sin(x) / cos(x) end

-- https://github.com/nangidev/pico-8-projects/blob/master/tech/lerp.p8
function lerp(tar,pos,perc)
 return (1-perc)*tar + perc*pos;
end
-->8
-- player stuff

player = {x=64,y=64,z=1,fov=.25,view_dist=20}
move_interval = 1 / 60 * 20
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

function draw_player(cone)
	-- get the xd and yd
	local ray_len = 3
	local xd = ray_len * cos(player.z)
	local yd = ray_len * sin(player.z)

 line(player.x,player.y,player.x + xd,player.y + yd,11)
	circ(player.x,player.y,2,11)

--[[ this shit is broke yo
	if cone then
		local yd = player.view_dist * tan(player.z-(.5*player.fov)) 
		line(player.x,player.y,player.x + player.view_dist,player.y + yd,12)
	end
--]]--
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
	  elseif (x==50 and (y > 20 and y < 100)) then
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
  if ray_dist > 30 then
   col_color = 1
  elseif ray_dist > 15 then
   col_color = 13
  else
   col_color = 14
  end

 	-- draw the column
  line(column,64 - (col_height / 2),column,64 + (col_height / 2),col_color)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000