function _init()
	cartdata("shk-unbreakaball")
	--clear_lbd()
	get_lbd()
	
	constant_init()
	
	--match_init(2)
	menu_init()
	frameoff=0
end

function _update60()
	frameoff += .03333
 if not inmatch then
 	menu_tick()
 else
 	match_tick()
 end
end

function _draw()
	cls()
	if not inmatch then
 	menu_draw()
 else
 	match_draw()
 end
end

function match_tick()
	match_loop()
    win_tick()
end

function constant_init()
	
	--debug = true
	
	--number tile gfx position
	--position of 0
	--nx = 0
	--ny = 32
	
	bg_pals = {
		{3,11},
		{8,9},
		{1,13},
		{14,2},
		{4,9},
		{12,13}
	}
end

function draw_base_map()
	clear_map()
	--local offx = (15-lev_w)/2
	--local offy = (13-lev_h)/2	
--	mset(i, f, 17)
--	mset(i, f, 19)
	
	local x1=offx2+1
	local x2=x1+lev_w+1
	local y1=offy2+1
	local y2=y1+lev_h+1
	
	// map draw
 for i=x1,x2 do
		for f=y1,y2 do
			if i>x1 and i<x2 then
				mset(i, f, 19)
			end
			if i==x1 or i==x2 or f==y1 or f==y2 then
				mset(i, f, 17)
			end
		end
	end
	mset(9, 8, 0)
end

function def_map_offs()
	offx1 = (19-lev_w)*4
	offy1 = (17-lev_h)*4
	
	offx2 = (15-lev_w)/2
	offy2 = (13-lev_h)/2
end

function level_map_load(floor)
	
	init_floor_dimens(floor)
	
	draw_base_map()
end

function ind_part_phys(p)
	p.life -= 1
	p.x += p.vx
	p.y += p.vy
	if p.life <= 0 then
		del(prt, p)
	end
end

function particle_physics()
	foreach(prt, ind_part_phys)
end
	
