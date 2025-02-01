pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--unbreakaball
--by shk

--prime

function _init()
	cartdata("shk-unbreakaball")
	--clear_lbd()
	get_lbd()
	
	--cool flags here!
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
		{5,6},
		{12,13}
	}
end

function match_init(mode)
	match_persistent_init(mode)
	floor_init(1)
end

function match_persistent_init(mode)
	-- particles
	prt = {}
	prtcol = {10, 9, 4, 0}
	
	--camera
	camabs = {}
	camabs.x = 12
	camabs.y = 0
	camoff = {0, 0}
	
	--clock
	--[minutes, seconds, millis]
	clk = {0, 0, 0}
	clkx = 39
	clky = 131
	clkdir=mode
	if mode==2 then
		clk[1]=3
	end
	
	--gamestate
	floor_level = 15
	gamemode=mode
	
	init_floor_dimens()
	
end

function gen_floor_type(floor)
	--[[
	1=tutorial
	2=smallbox
	3=bigbox
	4=smallswitch
	5=moreswitch
	--]]
	local ftype = 1
	
	if floor <= 5 then
		ftype=floor
		vortextype=0
	else
		local fmod = floor%5
		if fmod > 0 then
			ftype=fmod+1
		else
			ftype=flr(rnd(4))+2
		end
	end	
	
	return ftype
end

function has_mod(mod_id)
	for mod in all(floor_mods) do
		if (mod==mod_id) return true
	end
	return false
end

function gen_floor_mods(floor)
	--[[
	1=vortex
	2=steelcrate
	3=fires
	4=heal
	--]]
	possible_mods={1,2,3,4}
	mod_count=#possible_mods
	floor_mods={}
	
	local mcount=flr((floor-1)/5)
	if mcount>0 then
		for i=1,min(mcount, mod_count) do
			local fmod=rnd(possible_mods)
			add(floor_mods, fmod)
			del(possible_mods, fmod)
			
			if fmod==1 then
				vortextype=(floor%2)+1	
			end
			
			if fmod==3 then
				firecount=flr((floor*1.5+1)/5)
			end
			
		end
	end
	
end

function floor_init(floor)
	--trapdoor
	trpdrx = 0
	trpcooldown = 60
	trpopen = true
	
	--gamestate
	play_state = 0
	cratesbroken = 0
	cratetotal = 10
	switchtotal = 3
	switchclear = false
	firecount=0
	
	if (switchtotal == 0) switchclear = true
	leave_state = 1
	floor_won = false
	floor_type = gen_floor_type(floor)
	gen_floor_mods(floor)
	
	loadincool = 0
	loadoutcool = 0
	
	--loading
	player_init()
	level_map_load(floor)
	init_actors(floor)
	
	--background
	bg_types=3
	
	if (bg_type != nil) pastbg=bg_type
	choose_bg_type()
	if pastbg != nil then
		//hAS TO END UP BEING A NEW
		//TYPE, SINCE THE OLD TYPE
		//WILL BE REMOVED FROM THE
		//POOL
		if pastbg==bg_type then
			choose_bg_type()
		end
	end
	
	
	bgpal = rnd(bg_pals)
	bgpalpick=1+flr(rnd(2))
	bgp1=bgpal[bgpalpick]
	bgp2=bgpal[2-bgpalpick+1]
end

function reset_bg_list()
	availablebg={}
	for i=0,bg_types-1 do
		add(availablebg, i)
	end
end

function choose_bg_type()
	if availablebg==nil or #availablebg==0 then
		reset_bg_list()
	end
	local typeind=flr(rnd(#availablebg))+1
	bg_type=availablebg[typeind]
	deli(availablebg, typeind)
end

function draw_base_map()
	clear_map()
	--local offx = (15-lev_w)/2
	--local offy = (13-lev_h)/2	
	mset(i, f, 17)
	mset(i, f, 19)
	
	
	// map draw
 for i=offx2+1,offx2+lev_w+2 do
		for f=offy2+1,offy2+lev_h+2 do
			if i==offx2+1 or i==offx2+lev_w+2 then
				mset(i, f, 17)
			end
			if f==offy2+1 or f==offy2+lev_h+2 then
				mset(i, f, 17)
			end
			
			if i>offx2+1 and i<offx2+lev_w+2 then
				mset(i, f, 19)
			end
			--??
			if f==offy2+1 or f==offy2+lev_h+2 then
				mset(i, f, 17)
			end
		end
	end
	mset(9, 8, 0)
end

function init_floor_dimens(floor)
	
	if floor == 1 then
		lev_w = 13
		lev_h = 3
	else
		//max w=13
		lev_w = (flr(rnd(5))+2)*2+1
		//max h=11
		lev_h = (flr(rnd(4))+2)*2+1
	end
	
	def_map_offs()
	
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
	
function clear_map()
	for i=0,17 do
		for f=0,17 do
			mset(i, f, 0)
		end
	end
end
	
function clear_floor()
	o={}
	crates={}
	switches={}
	fires={}
	items={}
	clear_map()
end

function next_level_init()
	clear_floor()
	
	floor_level += 1
	floor_init(floor_level)
end
	
function trpupdate()
	
	if trpopen and trpdrx == 0 then
		sfx(6, 3)
	elseif not trpopen and trpdrx == 4 then
		sfx(7, 3)
	end
	
	if trpopen then
		trpdrx += 0.25
	else
		trpdrx -= 0.25
	end
	
	if trpopen and trpdrx >= 4 then 
		trpdrx = 4
		
		if play_state == 1 then
			play_state = 2
			p.control = true
		end
		if play_state == 2 and cratesbroken < cratetotal then
			trpopen = false
		elseif play_state == 2 and cratesbroken >= cratetotal then
			play_state = 3
		end
	elseif not trpopen and trpdrx <= 0 then
		trpdrx = 0
	end
	
end

function loadin_floor_tick()
	if (camabs.y!=12)  return
	loadincool += 0.0055
	if loadincool >= 0.25 then
		play_state = 1
	end
end
	
function start_floor_tick()
	trpcooldown -= 1
	if trpcooldown <= 0 then
		trpopen = true
		trpcooldown = 0
		trpupdate()
	end
end

function playing_floor_tick()
	--closing after trapdoor initially opens
	if trpopen == false and not floor_won then
		if p.x != 72 or p.y != 64 then
			trpupdate()
		end
	end
	
	check_switches()
	
	--levelend init
	if cratesbroken >= cratetotal and switchclear then
		if not trpopen then
			trpopen = true
		end
		trpupdate()
	end
	
end

function postwin_floor_tick()
	trpupdate()
	if did_player_enter_trap() then
		play_state = 4
		p.control = false
	end
end

function end_floor_tick()
	player_leave_tick()
		
	--[[
	
	hasn't started leaving, 
	first frame
	
	]]
	--if leave_state == 1 then
	
	
	--[[
		
	moving towards trapdoor center
		
	]]
	--elseif leave_state == 2 then
	
	
	--[[
		
	player inside, door shutting
		
	]]
	--elseif leave_state == 3 then
	
	
	--[[
		
	door shut, transitioning
			
	]]
	--else
	if leave_state == 4 then
		loadoutcool += 0.0055
		if loadoutcool >= 0.25 then
			play_state = 5
		end
	end
end
	
function level_state_process()
	if play_state == 0 then
		loadin_floor_tick()
	elseif play_state == 1 then
		start_floor_tick()
	elseif play_state == 2 then
		playing_floor_tick()
	elseif play_state == 3 then
		postwin_floor_tick()
	elseif play_state == 4 then
		end_floor_tick()
	elseif play_state == 5 then 
		--[[
		
		should only be run once
		before next play_state
		change is performed
		
		]]
		if (floor_level==20 and gamemode==1) or (clk[1]==0and clk[2]==0 and clk[3]==0) then
			
			if not floor_won then
				floor_won=true
				endscore=floor_level
				name_arr={0,0,0}
				if #windows==0 then
					add_win(
						{76,68,0,0,0},
						{12+20,8,88,99,8},
						1,0,1)
						
					upd_lbd(gamemode)
					
				end
			end
		else
			next_level_init()
		end
	elseif play_state==7 then run()
	end
end
	
function draw_trapdoor()
	move = trpdrx
	palt(0, false)
	--left hatch
	sspr(32+flr(trpdrx), 8, 4-flr(trpdrx), 8, 72, 64)
	--right hatch
	sspr(36, 8, 4-flr(trpdrx), 8, 76+move, 64)
	palt(0, true)
end

function match_loop()
	level_state_process()
 
 if camabs.y<12 and play_state==0 then
 	camabs.y+=1
 elseif camabs.y>12 then
 	camabs.y=12
 end
 
 
 player_tick(p)
 
 
 particle_physics()
 tick_actors()
 tick_clock(2-clkdir)
end
	
function draw_prt_ind(p)
	// boost explosion
	if p.type == 0 then
			circfill(p.x, p.y, p.life%5,prtcol[5-min(flr(p.life), 4)])
	end
end
	
function draw_particles()
	foreach(prt, draw_prt_ind)
end

--function draw_playbox()
--	if (trpcooldown == 60) boxy = -20
--	
--	cosy = cos((62-trpcooldown)/120)
--	cosy = cosy*cosy*cosy
--	
--	boxy += cosy*4
--	
--	rectfill(56, boxy, 56+9+6*5, boxy+20, 0)
--end

function draw_bg_hole()
	if (bgcircs == nil) then
		bgcircs = {
			{75, 0},
			{50, 1},
			{25, 0},
			{0, 1}
		}
	end
	
	for bgc=1,#bgcircs do
		bgcircs[bgc][1] += 0.75
		currad = bgcircs[bgc][1]
		
		if currad > 100 then
			add(bgcircs, bgcircs[bgc])
			bgcircs[#bgcircs][1] %= 100
			del(bgcircs, bgcircs[bgc])
			currad = bgcircs[bgc][1]
		end
		local colind = bgcircs[bgc][2]
		local col = 1
		if colind==0 then
			col=bgp1
		elseif colind==1 then
			col=bgp2
		end
		
		circfill(75, 68, currad*1.14, col)
	end
end

function draw_bg_polka()
	cls(bgp1)
	for row=1,6 do
		for crc=1,5 do
			local cx=64-(row*32)+crc*32
			local cy=-32+(row*8)+crc*32
			cy+=frameoff*10*sgn(3-row)
			cy%=180
			cx+=frameoff*10*sgn(3-crc)
			cx%=180
			local size=6+sin((frameoff/4)*sqrt(row*crc))*3
			circfill(cx, cy, size, bgp2)
		end
	end
end

function draw_bg_vort()
	cls(bgp2)
	local toff=frameoff/8
	toff-=(sin(toff/8)/2)
	for i=0.25,1,0.25 do
		//76,68
		local bx=cos(i+toff)*(sin(toff)/2+1)*50+76
		local by=sin(i+toff)*(sin(toff)/2+1)*50+68
		local size=22+abs(cos(toff))*10*(1/(sin(toff)+1.3))
		
		--circfill(bx, by, size+6, bgp1)
		--circfill(bx, by, size-6, bgp2)
		
		circ(bx, by, size, bgp1)
		
		local subcircs=8
		for subcir=1,subcircs do
			local subx=bx+size*cos(subcir/subcircs+toff*1.5)
			local suby=by+size*sin(subcir/subcircs+toff*1.5)
			local subsize=4+2*(sin(toff*8+(subcir/subcircs)))
			circfill(subx, suby, subsize, bgp1)
		end
		
	end
end

function draw_bg()
	
	if bg_type == 0 then
		draw_bg_hole()
	elseif bg_type == 1 then
		draw_bg_polka()
	elseif bg_type == 2 then
		draw_bg_vort()
	end
	
end

function draw_transition_elements()
 poke(0x5f34,0x2)
 if play_state == 0 then
	 circfill(75.5, 67.5, 89-cos(loadincool)*89, 0|0x1800)
	 if (loadincool==0) cls()
	elseif play_state >= 4 then
		circfill(75.5, 67.5, 88+sin(loadoutcool)*88, 0|0x1800)
		if (loadoutcool>=0.25) cls()
	end
end

function draw_map_border()
	--local offx = (15-lev_w)/2
	--local offy = (13-lev_h)/2
	
	pal(15,0)
	
	local x1=8*(offx2+1)-1
	local x2=8*(offx2+lev_w+3)
	local y1=8*(offy2+1)-1
	local y2=8*(offy2+lev_h+3)
	
	rectfill(x1,y1,x2,y2,15)
	pal(15,15)
end

function match_draw()
	cls(0)
 
 camera(camabs.x + camoff[1], camabs.y + camoff[2])

	camoff[1] = 0
	camoff[2] = 0
 
 draw_bg()
 
 draw_map_border()
 
 map(0, 0, 0, 0, 18, 18)
	
	draw_actors()
	
	p_under = play_state <= 1 and trpdrx<4
	 
 if p_under or leave_state >= 3 then
 	draw_player()
 	draw_trapdoor()
	end
	
 if not p_under and leave_state < 3 then
 	draw_trapdoor()
 	draw_player()
 end
	
	draw_particles()
	
	draw_level_text()

	draw_transition_elements()
	--draw_playbox()
	
 draw_hud()
 
 --draw_blob(30,30,0,0,4,0)
end

-->8
--actors

o={}
crates={}
switches={}
fires={}
items={}

function load_actor(t, x, y)
	local a = {}
	setmetatable(a,{__index=_ENV})
	a.t = t
	a.x = x
	a.y = y
	
	do
	local _ENV=a
	px = x
	py = y
	vx = 0
	vy = 0
	pvx = vx
	pvy = vy
	ax = 0
	ay = 0
	colx = 0.5
	coly = 0.5
	colw = 7
	colh = 7
	--actor's collision start points
	colspx = x + colx
	colspy = y + coly
	--actor's collision end points
	colepx = colspx + colw
	colepy = colspy + colh
 fric = 0.1
	weight = 1
	acts_col = false
	gets_col = false
	snapped = false
	frames = 0
	despawn = -1
	control = false
	z = 0
	end
	
	add(o, a)
end

function init_actor_counts()
	local actorcnt=max(flr(sqrt(lev_w*lev_h)), 1)
	if floor_type == 1 then
		cratetotal = 15
		switchtotal = 0
	elseif floor_type == 2 then
		cratetotal = round(actorcnt*1.5)
		switchtotal = 0
	elseif floor_type == 3 then
		lev_w=min(lev_w+2, 13)
		lev_h=min(lev_h+2, 11)
		def_map_offs()
		draw_base_map()
		
		cratetotal = round(actorcnt*2.5)
		switchtotal = 0
	elseif floor_type == 4 then
		cratetotal=round(actorcnt*2)
		switchtotal=round(actorcnt*0.25)
		switchtotal=max(switchtotal, 2)
	elseif floor_type == 5 then
		lev_w=min(lev_w+2, 13)
		lev_h=min(lev_h+2, 11)
		def_map_offs()
		draw_base_map()
		
		cratetotal=round(actorcnt*1.75)
		switchtotal=round(actorcnt*0.75)
		switchtotal=max(switchtotal, 2)
	end
end

function is_actor_there(x, y)
	for ac in all(o) do
		if ac.x == x and ac.y == y then
			return true
		end
	end
	return false
end

function init_actors()
	
	init_actor_counts()
	
	//same as map offsets, but in pixels and added by one tile
	--local offx = (19-lev_w)*4
	--local offy = (17-lev_h)*4
	
	makesteel=has_mod(2)
	if makesteel then
		makesteel=true
		steelmax=flr(cratetotal*0.375)
		steelsmade=0
	end
	
	for crate=1,cratetotal do
		
		--generates at random
		--locations
		make_crate(nil,nil)
		
	end
	
	for switch=1,switchtotal do
		a_pick_random_spot()
		load_actor(58, rx, ry)
		
		local sw = o[#o]
		
		sw.acts_col = false
		--sw.damage = 0
		sw.z = 2
		sw.blink = 0
		add(switches, sw)
	end
	
	if has_mod(3) then
		for fire=1,firecount do
			a_pick_random_spot()
			load_actor(26, rx, ry)
			
			local fr = o[#o]
			
			fr.acts_col = false
			--fr.damage = 0
			fr.z = 2
			fr.frametimer = 0
			add(fires, fr)
		end
	end
	
	if has_mod(1) then
		--vortecies
		if voertextype != 0 then
			local vxt = 0
			if vortextype == 1 then
				vxt = 45
			elseif vortextype == 2 then
				vxt = 61
			end
			
			a_pick_random_spot()
			
			load_actor(vxt, rx, ry)
			
			local vx = o[#o]
			
			vx.frametimer = 0
			vx.z = 2	
		end
	end
	
	if has_mod(4) and lev_w>3 and lev_h>3 then
		--this is stupid.
		--don't do this in your game.
		tries=0
		repeat
		rx = 8*flr(rnd(lev_w-4))+offx1+16
		ry = 8*flr(rnd(lev_h-4))+offy1+16
		tries+=1
		until not is_actor_there(rx, ry) or tries==50
		
		if tries != 50 then
			load_actor(30, rx, ry)
			
			local it=o[#o]
			do
			local _ENV = it
			
			frametimer = 0
			coly = 1
			colh = 6
			colx = 1
			colw = 6
			acts_col = false
			vx = 0
			vy = 0
			fric = 0
			z = 7
			exploding=false
			timer=0
			despawn=-1
			end
			
			add(items, it)
			
			add_item_surr_crates(rx,ry)
			
		end
	end
	
end

function a_pick_random_spot()
	repeat
	rx = 8*flr(rnd(lev_w))+offx1
	ry = 8*flr(rnd(lev_h))+offy1
	until not is_actor_there(rx, ry)
end

function make_crate(x,y)
	local crx=nil
	local cry=nil
	if x!=nil and y!= nil then
		--stop("▒")
		crx=x
		cry=y
	end
	
	--local offx = (19-lev_w)*4
	--local offy = (17-lev_h)*4

	local crt=10
	if makesteel then
		crt=14
		steelsmade+=1
		if (steelsmade==steelmax) makesteel=false
	end
	
	if crx==nil or cry==nil then
		a_pick_random_spot()	
		crx=rx
		cry=ry
	end
	load_actor(crt, crx, cry)
	
	local cr = o[#o]
	
	cr.acts_col = true
	--cr.damage = 0
	cr.z = 2
	
	add(crates,cr)
end

function add_item_surr_crates(x,y)
	
	for fy=-2,2 do
		
		for fx=-2+(abs(fy)),2-(abs(fy)) do
			local ax=x+fx*8
			local ay=y+fy*8
			
			if not is_actor_there(ax,ay) then
				--stop("!")
				make_crate(ax, ay)
				cratetotal+=1
			end
		end
	end
	
end

function will_physa_hit(a1, a2, future)
	local res = {false, false, false, false}
	
	local spx = a1.colspx
	local epx = a1.colepx
	local spy = a1.colspy
	local epy = a1.colepy
	
	if future then
		spx += a1.vx
		epx += a1.vx
		spy += a1.vy
		epy += a1.vy
	end
	
	-- check if each side of a1 intersects with a2
	local l_int = a2.colspx < spx and spx < a2.colepx
	local r_int = a2.colspx < epx and epx < a2.colepx
	local t_int = a2.colspy < spy and spy < a2.colepy
	local b_int = a2.colspy < epy and epy < a2.colepy
		
	res[1] = l_int
	res[2] = r_int
	res[3] = t_int
	res[4] = b_int
	
	return res
end

function will_a_touch(a1, a2, future)
	local _ENV=a1
	local spx = colspx
	local epx = colepx
	local spy = colspy
	local epy = colepy
	
	if future then
		spx += vx
		epx += vx
		spy += vy
		epy += vy
	end
	
	if max(spx, a2.colspx)<min(epx, a2.colepx) 
	and max(spy, a2.colspy)<min(epy, a2.colepy) then
	 return true
	end
	
	return false
end

function is_crate(a1)
	return (a1.t >= 10 and a1.t <= 15)
end

function is_player(a1)
	return a1.t==1 or a1.t==2 or a1.t==3
end

function actor_collide(a1, a2)
	if is_crate(a1) then
		if	(not is_player(a2)) return
	end
	
	if (distance(a1.x, a1.y, a2.x, a2.y) >= 16) return
	if will_a_touch(a1, a2, true) then
	 hit_action(a1, a2)
		hit_action(a2, a1)
	end
	
end

function hit_action(a1, a2)
	--player
	hit_crate = false
	if a1 == p then
		player_hit_actor(a1, a2)
	end
	
	
	--fire
	if a1.t >= 26 and a1.t <= 29 then
		--player interaction
		if is_player(a2) and a2.control then
			fire_touched=true
			fire_player(a2)
		end			
	end
	
	--item
	if a1.t == 30 and is_player(a2) and a2.control then
		heal_explode(a1, a2)
	end
	
end

function crate_damage(ac, instant, player)
	local _ENV=ac
	if (t == 13 or t==15) return
	
	if instant then
		if t==14 then
			t = 15
		else
			t = 13
		end
		--damage = 100
	else
		if t!=14 then
			--ac.damage += 1
			t += 1
		end
	end
	
	if t == 13 or t == 15 then
		acts_col = false
		despawn = 300
		sfx(2, 2)
		
		--this is only here because
		--of _ENV shenanigans
		add_broken_crate()
		
	end
	if player then
		if t == 14 then 
			if distance(0,0,p.vx,p.vy)>0.5 then
				sfx(11,3)
			end
		else
			sfx(3, 3)
		end
	end
end

function add_broken_crate()
	cratesbroken += 1
end

function switch_toggle(a1)
	local _ENV=a1
	if t == 58 then
		t = 59
		sfx(4, 2)
	elseif t == 59 then
		t = 58
		blink = 0
		sfx(5, 2)
	end
end

function confirm_switches()
	for sw in all(switches) do
		if sw.t == 59 then
			sw.t = 60
		end
	end
	sfx(8, 1)
end

function check_switches()
	if switchtotal == 0 then 
		switchclear = true
		return
	end
	oncount = 0
	for sw in all(switches) do
		if sw.t == 59 then
			oncount += 1
		end
	end
	
	if oncount == switchtotal then
		switchclear = true
		confirm_switches()
	end
end

function heal_explode(it)
	if not it.exploding then
		it.exploding = true
		it.timer=100
	end
end

function actor_col()
 
 for cr in all(crates) do
 	actor_collide(p,cr)
 end
 
 for sw in all(switches) do
 	actor_collide(p,sw)
 end

 	fire_touched=false
 	for fr in all(fires) do
 		actor_collide(p,fr)
 	end
 	if (fire_touched==false) p.in_fire=false
 
 for it in all(items) do
 		actor_collide(p,it)
 end
 
end

function actor_phys_apply()
	for act in all(o) do
		isplayer = false
		if (act == p) isplayer = true
		if not isplayer then
			actvarapply(act)
		end
			actor_col_upd(act)
	end
end

function actor_col_upd(a1)
	local _ENV = a1
	--actor's collision start points
	colspx = x + colx
	colspy = y + coly
	--actor's collision end points
	colepx = colspx + colw
	colepy = colspy + colh
end

function actvarapply(act)
	local _ENV=act
	pvx = vx
	pvy = vy
	px = x
	py = y
	vx -= fric * vx/abs(vx)
	vy -= fric * vy/abs(vy)	
	if sgn(vx) != sgn(pvx) then
		act.vx = 0
	end
	if sgn(vy) != sgn(pvy) then
		vy = 0
	end
	vx += ax
	vy += ay
	x += vx
	y += vy
	snapped = false
end

function actor_specific()
	for ac in all(o) do
		local _ENV=ac 
		--fire
		if t <= 29 and t >= 26 then
			frametimer += rnd(10)/20
			frametimer %= 4
			t = 26 + flr(frametimer)
		end
		if t >= 45 and t <= 47 then
			frametimer += 0.1
			local frame = frametimer % 3
			t = 45 + flr(frame)
			
			
			if p.control then
				local xdist= x-p.x
				local ydist= y-p.y
				local dist=distance(x,y,p.x,p.y)
				p.vx+=(xdist/(0.1+dist))/10
				p.vy+=(ydist/(0.1+dist))/10
			end
			
		end
		if (t >= 61 and t <= 63) then
			frametimer += 0.1
			local frame = frametimer % 3
			t = 61 + flr(frame)
			
			
			if p.control then
				local xdist= ac.x-p.x
				local ydist= ac.y-p.y
				local dist=distance(x,y,p.x,p.y)
				p.vx-=(xdist/(0.1+dist))/10
				p.vy-=(ydist/(0.1+dist))/10
			end
			
			
		end
		
		--item
		if t==30 then
			if exploding == true then
				heal_item_tick(ac)
			end
		end
	end
end

function heal_item_tick(it)
	
	if it.timer > 0 then
		it.timer-=1
		it.despawn=it.timer
		
		local rad=sin((100-it.timer)/-200)*16.2
		for cr in all(crates) do
			local dist = distance(it.x, it.y, cr.x, cr.y)
			--stop(dist)
			if dist<=rad and cr.t != 10 and cr.t != 14 then
				if cr.t == 13 or cr.t == 15 then
					cr.acts_col = true
					cr.despawn = -1
					if cratesbroken!=cratestotal then
						cratesbroken-=1
					end
				end
				cr.t-=1
				--cr.damage=0
			end
			
		end
		
		
	elseif it.timer == 0 then
		del(items, it)
		del(o, it)
	end
	
end

function actor_decay()
	for i=1,#o do
	if (i > #o) break
	ob=o[i]
		if ob.despawn == 0 then
			del(crates, ob)
			del(o, ob)
			i -= 1
		elseif ob.despawn > 0 then
			ob.despawn -= 1
		end
	end
end

function get_ordered_actors()
	if (#o == 0) return {}
	assemble = {}
	clone = {}
	
	for ac in all(o) do
		add(clone, ac)
	end
	
	repeat
		lowestind = 1
		for i=2,#clone do
			if clone[lowestind].z > clone[i].z then
				lowestind = i
			end
		end
		add(assemble, clone[lowestind])
		deli(clone, lowestind)
	until #clone == 0
	
	return assemble
	
end

function tick_actors()
	actor_col()
	actor_phys_apply()
	actor_specific()
	actor_decay()
end

function draw_switch(a1)
	local _ENV=a1
	blink += 1
	blink %= 2
	if blink == 1 then
		pal({[t-48]=0})
	end
	
	spr(t, x, y)
	pal()
	
end

function draw_actors()
	
	--ordered objects
	local oo = get_ordered_actors()
	
	for act in all(oo) do
		if act != p then
			local _ENV=act
			
			if despawn > 0 then
				if despawn % 2 == 0
				   or despawn > 60 then
					spr(t, x, y)
				end
				
				if t==30 then
					local fill_list={
						0b0101111101011111.1,
						0b1010111110101111.1,
						0b1111101011111010.1,
						0b1111010111110101.1,
					}
					
					local rad=sin((100-timer)/-200)*16
					--fillp(fill_list[(frameoff)%4+1])
					local ind=flr((frameoff*8)%4+1)
					fillp(fill_list[ind])
					for col=11,3,-8do
						circfill(x+4, y+4, rad, col)
						ind=flr(((frameoff*8)+2)%4+1)
						fillp(fill_list[ind])
					end
					fillp()						
				end
				
			else
				if t == 59 or t == 60 then
					draw_switch(act)
				else
					spr(t, x, y)
				end
				
				if t>=45 and t<=47 then
					local csize=sin(((2.5-(frametimer%2.5))/20)+.5)*181
					
					circ(x+4, y+4, csize, 1)
					
				end
						
				
				if t>=61 and t<=63 then
					local csize=sin(((frametimer%2.5)/20)+.5)*181
					
					circ(x+4, y+4, csize, 11)
					
				end
				
				
				
			end
		end
	end
end
-->8
--helper
function lerp(v1, v2, percent)
	return (v1 + (v2-v1)*percent)
end

--function ilerp(v1, v2, inter)
--	return (inter-v1)/(v2-v1)
--end

function distance(x1,y1,x2,y2)
	return sqrt(((x2-x1)^2 + (y2-y1)^2))
end

function round(num)
	return flr(num+0.5)
end
-->8
--hud

--chrs = {
--	[":"] = 40,
--	["?"] = 44,
--	["!"] = 48,
--	["."] = 52,
--	["/"] = 56,
--	["["] = 60,
--	["]"] = 64,
--	[" "] = 68,
--	["_"] = 72
--}

--[[
from/to:
x,y,w,h,r

col
prog
type
--]]

windows={}

function add_win(f,t,col,prog,typ)
	local w={}
	w.f=f
	w.t=t
	w.col=col
	w.prog=prog
	w.type=typ
	
	if typ == 1 then
		w.timer=0
	end
	
	add(windows,w)
end

function win_tick()
	for w in all(windows) do
		win_specific(w)
	end
end

function postgame_lb(w)
	if w.timer<0.25 then
		w.timer+=.01
		w.prog=-1*sin(w.timer)
		w.trem=nil
		if (inmatch)camabs.y-=w.prog
	elseif w.timer<1 then
		w.timer+=.01
		w.prog=1
		w.trem=7-flr((1-w.timer)*(7/0.75))
		pal(1)
		--stop(w.trem)
		winstr_list={
			"",
			"",
			"leaderboard:",
		}
		winpos_list={
			{46,16},
			{38,24},
			{60,32}
		}
		
		if gamemode==1 then
			winstr_list[1]="woohoo! you won!"
			winstr_list[2]="your time:"
		else
			winstr_list[1]="phew! time's up!"
			winstr_list[2]="your score was:"
		end
	elseif w.timer<1.01 then
		
		if w.letterind==nil then
			w.letterind=0
		end
		
		if w.ask_confirm==nil then
			w.ask_confirm=false
			w.confirmed=false
		end
		
		if placeind!=-1 then
			
			if (btnp(1)) then
				
				w.letterind+=1
			end
			if (btnp(0)) w.letterind-=1
			w.letterind%=4
			
			if w.letterind != 3 then
				if (btnp(2)) name_arr[w.letterind+1]+=1
				if (btnp(3)) name_arr[w.letterind+1]-=1
			end
			
		end
		
		if (w.letterind==3 or placeind==-1) and (btnp(4) or btnp(5)) then
			if w.letterind==3 then
				lbd[gamemode][placeind][2]=name_arr
				--stop(lbd[2][placeind][2][1])
				save_lbd()
			end
			w.timer+=.01
		end
	
	elseif w.timer<1.25 then
		w.timer+=.01
		w.prog=1
		w.trem=flr((1.25-w.timer)*(7/0.25))
	elseif w.timer<1.5 then
		w.timer+=.01
		w.prog=-1*sin(w.timer)
		
	else
		w.timer=1.5
		w.prog=0
		w.col=0
		play_state+=1
	end
end

function win_specific(w)
	--stop()
	if w.type == 1 then
		postgame_lb(w)
	end
end

--[[

assumes all numbers in tile gfx
are consecutive

]]

function tick_clock(dir)
	if (not p.control) return
	frame = 1/.6
	if (dir == 1) then
		clk[3] += frame
		if clk[3] > 99 then
			clk[3] = clk[3]-100
			clk[2] += 1
			if clk[2] > 59 then
				clk[2] = clk[2]-60
				clk[1] += 1
				if clk[1] > 99 then
					clk[1] = 99
					clk[2] = 59
					clk[3] = 99
				end
			end
		end
	else
		clk[3] -= frame
		if clk[3] < 0 then
			clk[3] = 100+clk[3]
			clk[2] -= 1
			if clk[2] < 0 then
				clk[2] = 60+clk[2]
				clk[1] -= 1
				if clk[1] < 0 then
					clk[1] = 0 
					clk[2] = 0
					clk[3] = 0
				end
			end
		end
	end
	//makes sure they don't
	//become negative for some
	//reason
	clk[1]=abs(clk[1])
	clk[2]=abs(clk[2])
	clk[3]=abs(clk[3])
end

--function draw_char(inp, x, y)
--	orded = ord(tostr(inp))
--	if orded >=48 and orded <= 57 then
--		char_ind = inp*4
--		sspr(nx+char_ind, ny, 4, 6, x, y)
--	else
--		char = chrs[inp]
--		if char==nil then
--			stop(inp)
--	end
--		
--		sspr(nx+char, ny, 4, 6, x, y)
--	end
--end

--function draw_letter(letter, x, y)
--	if (ord(letter) < 97) draw_char(letter, x, y)
--	sspr((ord(letter)-97)*4, 40, 4, 6, x, y)
--end

function draw_str(str, x, y)
	print(str, x, y+1, 5)
	print(str, x, y, 7)
	
	--strver = tostr(str)
	--for ind=1,#strver do
	--	draw_letter(strver[ind], x, y)
	--	x += 4
	--end
end

function draw_high_str(str, x, y)
	print(str, x, y+1, 5)
	print(str, x, y, 9+flr(frameoff*5%2))
end

function draw_wavy_str(str, x, y)
	strver = tostr(str)
	for ind=1,#strver do
		local yh = y+sin(frameoff+ind/#strver)*0.75
		print(strver[ind], x, yh+1,5)
		print(strver[ind], x, yh,7)
		x += 4
	end
end


function draw_clock(x,y)
	
	per_num_offx = 0
	for t in all(clk) do
		vl = flr(t)
		
		local offx = x+per_num_offx
		num = vl%10
		
		dispstr = ""
		
		dispstr ..= tostr(flr((vl-num)/10))
		dispstr ..= tostr(num)
		if per_num_offx != 24 then
			dispstr ..= ":"
		end
		draw_str(dispstr, offx, y)
		
		per_num_offx += 12
		
	end
end

--function draw_mem()
--	local mem = stat(0)
--	print(mem, 16, 16, 8)
--end

--function draw_cpu()
--	local cpu = stat(1)
--	print(cpu, 16, 22, 8)
--end

--function draw_player_stats()
--	print(p[1].x, 16, 28, 8)
--	print(p[1].y, 16, 34, 8)
--end

function draw_low_bg()
	map(18, 0, 12-camoff[1], 128-camoff[2], 16, 2)
end

function draw_crates_rem()
	spr(10, 73, 130)
	drawstr = ""
	if cratetotal >= 10 and cratesbroken < 10 then
		drawstr ..= "0"
	end
	drawstr ..= tostr(cratesbroken)
	drawstr ..= "/"
	drawstr ..= tostr(cratetotal)
	draw_str(drawstr, 83, 131)
end

function draw_floor_count()
	drawstr = ""
	drawstr ..= "floor "
	drawstr ..= floor_level
	draw_str(drawstr, 106, 131)
end

function draw_level_text()
	if floor_level == 1 then
		draw_wavy_str("use dpad to move!", 42, 24)
		draw_wavy_str("press o/x to explode!", 34, 34)
		draw_wavy_str("destroy all of the crates", 26, 100)
		draw_wavy_str("to reach the next floor!", 29, 110)
	end
end

function draw_blob(x,y,w,h,rad,col)
	w=max(w,rad*2)
	h=max(h,rad*2)
	
	xrad=x+rad
	yrad=y+rad
	xw=x+w
	yh=y+h
	xwrad=xw-rad
	yhrad=yh-rad
	
	circfill(xrad,yrad,rad,col)
	circfill(xwrad,yrad,rad,col)
	circfill(xrad,yhrad,rad,col)
	circfill(xwrad,yhrad,rad,col)
	rectfill(xrad,y,xwrad,yh,col)
	rectfill(x,yrad,xw,yhrad,col)

end

function draw_listblob(l)
	draw_blob(l[1],l[2],l[3],l[4],l[5],l[6])
end

function gen_win_draw(w)
	local midblob={}
	for blbind=1,#w.f do
	add(midblob, lerp(w.f[blbind],w.t[blbind],w.prog))
	end
	add(midblob,w.col)
	draw_listblob(midblob)
end

function draw_wins()
	for w in all(windows) do
		stroff=0
		if (not inmatch) stroff=-12
		gen_win_draw(w)
		if w.trem!=nil then
			for i=1,w.trem do
				
				if i<=3 then
					
				
					local poss=winpos_list[i]
					draw_str(winstr_list[i],stroff+poss[1],poss[2])
				else
				
					--score values
					
					--timer
					if gamemode==1 then
						
						for t=1,3 do
							if #lbd[1]>=(i-3) then
								local tscore=lbd[1][i-3][1][t]
								if tscore<10 then
									draw_str(0,stroff+30+t*12,8+i*10)
									draw_str(tscore,stroff+34+t*12,8+i*10)
								else
									draw_str(tscore,stroff+30+t*12,8+i*10)
								end
							else
								draw_str("--",stroff+30+t*12,8+i*10)
							end
							if (t!=3) draw_str(":",stroff+38+t*12,8+i*10)
						end
					--score
					else
						if #lbd[2]>=(i-3) then
							draw_str(lbd[2][i-3][1],stroff+42,8+i*10)
						else
							draw_str("--",stroff+42,8+i*10)
						end
					end
					
					local lind=windows[1].letterind
					for n=1,3 do
						if #lbd[gamemode]>=(i-3) then
							local char = chr((lbd[gamemode][i-3][2][n]%26)+97)
							if (n-1)==lind and i-3==placeind then
								draw_high_str(char,stroff+82+n*4,8+i*10)
							else
								draw_str(char,stroff+82+n*4,8+i*10)
							end
						else
							draw_str("---",stroff+86,8+i*10)
						end
					end
					
					if i-3==placeind then
						if lind==3 then
							draw_high_str("ok?",stroff+102,8+i*10)
						else
							draw_str("ok?",stroff+102,8+i*10)
						end
					end
					
					
				end
				
				if i==2 then
					if gamemode==1 then
						draw_clock(stroff+84,24)
					else
						draw_str(endscore,stroff+104,24)
					end
				end
			end
		end
	end
end

--function draw_debug()
--	draw_mem()
--	draw_cpu()
--	draw_player_stats()
--end

function draw_hud()
	draw_low_bg()
	draw_str("timer:", 14, 131)
	draw_clock(clkx,clky)
	draw_crates_rem()
	draw_floor_count()
	draw_wins()
	//if (debug) draw_debug()
end
-->8
--player

function player_init()
	--init the player variables
	p = {}
	setmetatable(p,{__index=_ENV})
	do
	local _ENV=p
	t = 1
	x = 72
	y = 64
	px = x
	py = y
	vx = 0
	vy = 0
	pvx = vx
	pvy = vy
	colx = 0.5
	coly = 0.5
	colw = 7
	colh = 7
	--actor's collision start points
	colspx = x + colx
	colspy = y + coly
	--actor's collision end points
	colepx = colspx + colw
	colepy = colspy + colh
	ax = 0
	ay = 0
	weight = 1.5
	frames = 0
	snapped = false
	blast_cool = 0
	blast_mode = false
	fired = false
	in_fire = false
	fire_cool = 0
	despawn = -1
	control = false
	gets_col = true
	z = 5
	end
	add(o,p)
end

function add_boom_part(pl)
	add(prt, {})
	boom = prt[#prt]
	boom.life = rnd(10)+5
	boom.type = 0
	boom.x = pl.x
	boom.y = pl.y
	boom.vx = rnd(4)-2
	boom.vy = rnd(4)-2
	prt[#prt] = boom
end

function destroy_surr(pl)
	
	dist = 2*8
	
	for ac in all(o) do
		if ac != pl then
			if ac.t >= 10 and ac.t <=12 or ac.t == 14 then
				if distance(ac.x, ac.y, pl.x, pl.y) <= dist then
					crate_damage(ac, true, false)
				end	
			end
		end
	end
	
	
end

function player_blast(pl)
	
	l = btn(0)
	r = btn(1)
	u = btn(2)
	d = btn(3)
	
	--pvx = pl.vx
	--pvy = pl.vy
	
	if l or r or u or d then
	boost = 6
		if(l)pl.vx=boost*-1
		if(r)pl.vx=boost
		if(u)pl.vy=boost*-1
		if(d)pl.vy=boost
		
	for particles=1,30 do
		add_boom_part(pl)
	end
	
	destroy_surr(pl)
	
	pl.blast_cool = 120
	pl.blast_mode = true
	sfx(1,2)	
		
	end
	
end

function fire_player(pl)
	--stop(pl.in_fire)
	if pl.in_fire==false then
		sfx(12,-1)
	end
	pl.in_fire=true
	pl.fired=true
	pl.fire_cool = 200
	pl.blast_mode = false
	pl.blast_cool = 0
end

function player_roll_sfx(pl)
	local poke1=0b10001100
	local spd=distance(0,0,pl.vx,pl.vy)
	local norm=(spd/6)-.05
	if (norm<0) then 
		norm=0
		poke1=0
	end
	if (norm>.8) norm=.8
	local adj=flr(norm*32)
	//sets highest bit
	
	
	poke(0x3201+68*9, poke1)
	poke(0x3200+68*9, adj)
	sfx(9,0)
	
	print(spd, 16, 34, 8)
end

function player_tick(pl)
	if pl.control then
		player_control(pl)
		player_roll_sfx(pl)
	end
end

function player_bounce_actor(a1, a2)
	local hit_res1 = will_physa_hit(a1, a2, false)
	local hit_res2 = will_physa_hit(a1, a2, true)
	
	for bit=1,4 do
		if not hit_res1[bit] and hit_res2[bit] then
			if not a1.blast_mode then
				sgnx = sgn(a1.vx)
				sgny = sgn(a1.vy)
				if bit == 1 and sgnx == -1 then
					a1.x = a2.colepx-a2.colx
					a1.vx *= -0.8
				elseif bit == 2 and sgnx == 1 then
					a1.x = a2.x-a1.colw
					a1.vx *= -0.8
				elseif bit == 3 and sgny == -1 then
					a1.y = a2.colepy
					a1.vy *= -0.8
				elseif bit == 4 and sgny == 1 then
					a1.y = a2.y-a1.colh
					a1.vy *= -0.8
				end
			end
			--crate
			if is_crate(a2) then
				if not hit_crate then
					crate_damage(a2, a1.blast_mode, true)
					hit_crate = true
				end
			end	
		end
	end
	
end

function player_hit_actor(a1, a2)
	
	if a2.acts_col then
		if a1.gets_col then
			player_bounce_actor(a1, a2)
		else
		
		end
	else
		if a1.gets_col then
			--switch
			if a2.t == 58 or a2.t == 59 then
				--if not already touching
				if will_a_touch(a1, a2, false) == false then
					switch_toggle(a2)
				end
			end
		else
		
		end
	end
end

function player_border_check(pl)
	
	//same as map offsets, but in pixels and added by one tile
	--local offx = (19-lev_w)*4
	--local offy = (17-lev_h)*4
	local offex = offx1+(lev_w-1)*8
	local offey = offy1+(lev_h-1)*8
	
	// border check
-- if pl.x < offx1 then
-- 	pl.x = offx1 pl.vx *= -0.75
-- 	if (pl.vx>0.275) sfx(10,-1)
-- 	if (pl.vx>1.5) camoff[1] -= 1
-- elseif pl.x > offex then
--		pl.x = offex pl.vx *= -0.75
-- 	
-- 	if (pl.vx<-0.275) sfx(10,-1)
-- 	if (pl.vx<-1.5) camoff[1] += 1
-- end
--
-- if pl.y < offy1 then
-- 	pl.y = offy1 pl.vy *= -0.75
-- 	if (pl.vy>0.275) sfx(10,-1)
-- 	if (pl.vy>1.5) camoff[2] -= 1
-- elseif pl.y > offey then
--		pl.y = offey pl.vy *= -0.75 	
-- 	if (pl.vy<-0.275) sfx(10,-1)
-- 	if (pl.vy<-1.5) camoff[2] += 1
-- end
	
	pd=pl.x
	pv=pl.vx
	od1=offx1
	oe=offex
	
	
	for i=1,2 do
	
		if pd < od1 then
	 	pd = od1 pv *= -0.75
	 	if (pv>0.275) sfx(10,-1)
	 	if (pv>1.5) camoff[i] -= 1
	 elseif pd > oe then
			pd = oe pv *= -0.75
	 	
	 	if (pv<-0.275) sfx(10,-1)
	 	if (pv<-1.5) camoff[i] += 1
	 end
	 
	 if i==1 then
		 pl.x=pd
			pl.vx=pv
			
			pd=pl.y
			pv=pl.vy
			od1=offy1
			oe=offey
 	else
 		pl.y=pd
			pl.vy=pv
 	end
 	
 end
	
end

function player_control(pl)
	
	if pl.blast_cool<=0 and pl.fired != true then
		if btn(5) or btn(4) then
			player_blast(pl)
		end
	end
	
	// set first calc vars for x
	pos = pl.x
	vel = pl.vx
	acc = pl.ax
	
	// loop for both x and y calcs
	for loop=0,2,2 do
		
		l = btn(0+loop)
		r = btn(1+loop)
		
		// both directions pressed
	 if (l and r) then
	 	acc = 0
	 else
	 // 1 direction pressed
	 	if l then 
	 		acc = -0.15
	 	elseif r then
	  	acc = 0.15
	 	else	
	 		acc = 0
	 	end
	 end
		
		player_border_check(pl)
		
		// apply acceleration
		vel += acc
		
		// friction
		vel -= 0.03 * vel
		if abs(vel) < 0.01 then
			vel = 0
		end
	 
	 // apply velocity
	 pos += vel
	 
	 player_border_check(pl)
	 
	 // switch calc vars to y
	 if loop == 0 then
	 	pl.x = pos
	 	pos = pl.y
	 	pl.vx = vel
	 	vel = pl.vy
	 	pl.ax = acc
	 	acc = pl.ay
	 else
	 	pl.y = pos
	 	pl.vy = vel
	 	pl.ay = acc
		end	 
	end
	
	pl.blast_cool -= 1
	pl.fire_cool -= 1
	
	local velcomb=abs(pl.vx)+abs(pl.vy)
	
	if pl.blast_mode and pl.blast_cool<100 and velcomb < 2 then
		pl.blast_mode = false
	end
	
	if (pl.blast_cool <= 0) then
		pl.blast_mode = false
	end	
	
	if pl.fire_cool <= 0 then
		pl.fired = false
		pl.fire_cool = 0
	end
	
end

function did_player_enter_trap()
	local temptrap = {}
	temptrap.colspx = 72+2
	temptrap.colepx = 72+2+4
	temptrap.colspy = 64+2
	temptrap.colepy = 64+2+4
	
	if will_a_touch(temptrap, p,false) then
		return true
	end
	
	return false
end

function player_leave_tick()
	--[[
	
	hasn't started leaving, 
	first frame
	
	]]
	if leave_state == 1 then
	
	p.blast_mode = false
	p.blast_cool = 0
	leave_state = 2
	
	--[[
		
	moving towards trapdoor center
		
	]]
	elseif leave_state == 2 then
	
	p.x = lerp(72, p.x, 0.8)
	p.y = lerp(64, p.y, 0.8)
	if distance(p.x, p.y, 72, 64) < 1 then
		p.x = 72
		p.y = 64
		leave_state = 3
	end
	
	--[[
		
	player inside, door shutting
		
	]]
	elseif leave_state == 3 then
	trpopen = false
	trpupdate()
	if trpdrx == 0 then
		leave_state = 4
	end
	
	--[[
		
	door shut, transitioning
			
	]]
	elseif leave_state == 4 then
	
	end
end

function draw_cooldown(pl, fire)
	if (play_state>3) return
	local _ENV=pl
	
	--container edges
	local x2=x-2
	local x9=x+9
	local y5=y-5
	local y4=y-4
	
	color(7)
	line(x2, y-6, x9, y-6)
	line(x2, y-3, x9, y-3)
	line(x-3, y5, x-3, y4)
	line(x+10, y5, x+10, y4)
	--bg
	rect(x2, y5, x9, y4, 0)
	
	local xprog=0
	local col=0
	
	if fired == false then
		--progress
		xprog=flr(x+9-(blast_cool/120)*12)
		col=11
	else
		col=8+(flr(frameoff%2))
		xprog=flr(x+(fire_cool/200)*11)-2		
	end
	rect(flr(x-2), y-5, xprog, y-4, col)

end

function draw_player()
 // player draw
 if p.fired and p.fire_cool%2==0 then
 	spr(3,p.x,p.y)
 elseif p.blast_mode and (p.blast_cool % 2 == 1) then
		spr(2,p.x,p.y)
 else
 	spr(1,p.x,p.y)
 end
 
 if p.fired then
 	draw_cooldown(p, true)
 elseif p.blast_cool > 0 then
 	draw_cooldown(p, false)
 end
end


-->8
--leaderboard

lbd={}

function get_lbd()
	tlbd={}
	slbd={}
	for i=0,4 do
		assembletime={}
		is_valid_time=false
		for f=0,2 do
			num=dget(i*10 + f)
			is_valid_time=is_valid_time or num!=0
			add(assembletime,num)
		end
		
		if is_valid_time then
			lbdstr={}
			for f=3,5 do
				local char=dget(i*10+f)
				add(lbdstr,char)
			end
			add(tlbd, {assembletime, lbdstr})			
		end
	end

	
	for i=0,4 do
		
		num=dget(i*10 + 6)
		
		if num != 0 then
			lbdstr={}
			for f=7,9 do
				local char=dget(i*10+f)
				add(lbdstr,char)
			end
			add(slbd, {num, lbdstr})			
		end
	end
	
	lbd={tlbd,slbd}
	
end

function upd_lbd(mode)
	placeind=which_place(mode)	
	if placeind!=-1 then
		if mode==1 then
			data={clk[1],clk[2],flr(clk[3])}
		else
			data=endscore
		end
		if #lbd[mode]==0 then
			placeind=1
		end
		add(lbd[mode], {data,name_arr},placeind)
		if #lbd[mode]>5 then
			deli(lbd[mode],6)
		end
	end
end

function save_lbd()
	tlbd=lbd[1]
	slbd=lbd[2]
	for i=0,#tlbd-1 do
		--stop(tlbd[i+1])
		for f=0,2 do
			
			local d=tlbd[i+1][1][f+1]
			
			dset(i*10 + f, d or 0)
		end
		for f=3,5 do
			local d=tlbd[i+1][2][f-2]
			dset(i*10 + f, d or 0)
		end
	end
	for i=0,#slbd-1 do
		dset(i*10 + 6, slbd[i+1][1] or 0)
		for f=7,9 do
			local d=slbd[i+1][2][f-6]
			dset(i*10 + f, d or 0)
		end
	end
end

function clear_lbd()
	
	for i=0,4 do
		for f=0,9 do
			dset(i*10 + f, 0)
		end
	end
end

function which_place(mode)
	tlbd=lbd[1]
	slbd=lbd[2]
	
	flbd=lbd[mode]
	tbcount=#flbd
	
	if mode==1 then
		for i=1,tbcount do
			--stop("tb")
			fclk=tlbd[i][1]
			--stop(fclk[1])
			if clk[1] < fclk[1] then
				return i
			elseif clk[1]==fclk[1] then
				--stop("==")
				if clk[2] < fclk[2] then
					return i
				elseif clk[2]==fclk[2] then
					if clk[3] <= fclk[3] then
						return i
					end
				end
			end
		end
		
	else
		for i=1,tbcount do
			if endscore>=slbd[i][1] then
				return i
			end
		end
	end
	
	if tbcount==5 then
			return -1
	else
		return tbcount+1
	end
	
end
-->8
--menu

function menu_init()
	m_trstn=-0.25
	trstn_phase=0
	gamemode=1
	button_high_ind=-1
	
end

function menu_tick()
	if trstn_phase==0 then
		m_trstn+=0.01
		--stop(m_trstn)
		if m_trstn>0.75 then
			trstn_phase+= 1
			m_trstn=0.75
		end
		
	elseif trstn_phase==1 then
		win_tick()
		button_high_ind=button_high_ind==-1 and 0 or button_high_ind
		
		if (btnp(2)) button_high_ind-=1
		if (btnp(3)) button_high_ind+=1
		button_high_ind%=3
	
		if btnp(4) or btnp(5) then
			if button_high_ind!=2 then
				trstn_phase+=1
				sfx(13,-1)
			else
				if #windows<1 then
					add_win(
						{64,64,0,0,0},
						{20,8,88,99,8},
						0,0,1)
				end
			end
		end
		
		if #windows!=0 then
			if (btnp(0) or btnp(1)) gamemode%=2;gamemode+=1
		end
	
	elseif trstn_phase==2 then
		m_trstn-=0.01
		if m_trstn<0 then
			trstn_phase+= 1
			m_trstn=0
		end
	elseif trstn_phase==3 then
		inmatch=true
		match_init(button_high_ind+1)
	end
	
	
	
end

function draw_menubg()
	cls(1)
end

function draw_buttons()
menu_strs={
"20 floor dash",
"3 minute rush",
" leaderboard "
}
	for i=0,2	do
		local yset=60+i*18
		local col=13
		onbtn=i==button_high_ind
		
		if (onbtn) col=8
		draw_blob(32,yset,60, 8, 3, col)
		if trstn_phase >= 2 and onbtn then
			draw_high_str(menu_strs[i+1], 37, yset+2)
		else
			draw_str(menu_strs[i+1], 37, yset+2)
		end
	end
end

function draw_transition()
	if (m_trstn<0) cls(0)
	for i=0,3 do
		own_trstn=m_trstn-i/8
		if own_trstn < 0.25 then
			if i%2==0 then
				draw_blob(-33,i*32,188-(-188*sin(own_trstn)),0,16,0)
			else
				draw_blob(-16+-188*sin(max(own_trstn,0)),i*32, 188,0, 16,0)
			end
		end
	end
end

function menu_draw()
	draw_menubg()
	map(66,0,0,8)
	draw_buttons()
	draw_transition()
	draw_wins()
end
__gfx__
00000000001111000099990000888800000000000000000000000000000000000000000000000000499999940999490409949904000000006666667700000070
00000000011127100999a79008889780000000000000000000000000000000000000000000000000944444494444444944444449000000006d5555d760700606
00000000111177719999777988887778000000000000000000000000000000000000000000000000944949499449494494444940000000006565655600060000
00000000111127219999a7a988889798000000000000000000000000000000000000000000000000949494494494944404949440040004406556565606000660
00000000111111119999999988888888000000000000000000000000000000000000000000000000944949499449494994494949004000406565655600700070
00000000111111119999999988888888000000000000000000000000000000000000000000000000949494494494944904949449000099006556565600006600
00000000011111100999999008888880000000000000000000000000000000000000000000000000944444499444444494444444490400046d5555d667070007
00000000001111000099990000888800000000000000000000000000000000000000000000000000499999944944494409400900004000406666666600600060
8888888894999499f9fff9ff55555555666666660000000000000000000000000000000000000000000000000000000000000000000000000333333000000000
8888888894999499f9fff9ff55d55555a006600a00000000000000000000000000000000000000000000800000000000000800000008000033b77b3300000000
8888888894999499f9fff9ff55555d5500a660aa0000000000000000000000000000000000000000000880000008800000088000000880003bb77bb300000000
888888884444444499999999555555550aa66aa00000000000000000000000000000000000000000000988000009880000888800008890003777777300000000
8888888899949994fff9fff955555555aa066a000000000000000000000000000000000000000000008998000889980008899800008998803777777300000000
8888888899949994fff9fff955555555a006600a00000000000000000000000000000000000000000899a980089a99800899a980089a99883bb77bb300000000
8888888899949994fff9fff95d55555500a660aa0000000000000000000000000000000000000000089aa800088aa980008aa980089aa98033b77b3300000000
8888888844444444999999995555555d666666660000000000000000000000000000000000000000008998000008980000898000008988000333333000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000666666666666666666666666011111100d1111d00dddddd0
11dddddddddddddddddddd110000000000000000000000000000000000000000000000000000000062288226633333366cccccc61dddddd1d1dddd1ddd1111dd
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006228822663bbbb366cddddc61d1111d11dd11dd1d1dddd1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006882288663bbbb366cdccdc61d1dd1d11d1dd1d1d1d11d1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006882288663bbbb366cdccdc61d1dd1d11d1dd1d1d1d11d1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006228822663bbbb366cddddc61d1111d11dd11dd1d1dddd1d
1dddddddddddddddddddddd10000000000000000000000000000000000000000000000000000000062288226633333366cccccc61dddddd1d1dddd1ddd1111dd
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000666666666666666666666666011111100d1111d00dddddd0
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000000aaaaaa00aaaaaa00aaaaaa00b3333b0033333300bbbbbb0
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000aa8888aaaabbbbaaaaccccaab33bb33b33bbbb33bb3333bb
11dddddddddddddddddddd1100000000000000000000000000000000000000000000000000000000a888778aabbb77baaccc77ca33bbbb333bb33bb3b33bb33b
11111111111111111111111100000000000000000000000000000000000000000000000000000000a888878aabbbb7baacccc7ca3bb33bb33b3bb3b3b3b33b3b
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000a888888aabbbbbbaacccccca3bb33bb33b3bb3b3b3b33b3b
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000a888888aabbbbbbaacccccca33bbbb333bb33bb3b33bb33b
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000aa8888aaaabbbbaaaaccccaab33bb33b33bbbb33bb3333bb
1eeeeeeeeeeeeeeeeeeeeee1000000000000000000000000000000000000000000000000000000000aaaaaa00aaaaaa00aaaaaa00b3333b0033333300bbbbbb0
77700700777077707070777077707770777077700000777070000000007077000770000000000000000000000000000000000000000000000000000000000000
75707700557055707070755075505570757075700700557070000000075075000570000000000000000000000000000000000000000000000000000000000000
70705700777077707770777077700070777077700500077070000000070070000070000000000000000000000000000000000000000000000000000000000000
70700700755055705570557075700070757055700700055050000000070070000070000000000000000000000000000000000000000000000000000000000000
77707770777077700070777077700070777000700500070070007000750077000770000077700000000000000000000000000000000000000000000000000000
55505550555055500050555055500050555000500000050050005000500055000550000055500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007700077077007770777007707070777077707070700077707700077077707770777077707770707070707070707070707770000000000000000000000000
75707570755075707550755075507070575057507070700077707570757075707570757075505750707070707070707070705570000000000000000000000000
77707750700070707700770070707770070007007750700075707070707077707070775077700700707070707070575077700750000000000000000000000000
75707570700070707500750070707570070007007570700070707070707075507750757055700700707077707770757057507500000000000000000000000000
70707750577077507770700077507070777077007070777070707070775070005570707077700700777057507770707007007770000000000000000000000000
50505500055055005550500055005050555055005050555050505050550050000050505055500500555005005550505005005550000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000
00000006556667755556667755666677555566775544444444444455554444444444445555444444444444445555444444444455554444555555544450000000
000000065065d5755556d5d75065d567555065d75049999999999945504999999999994550499999999999945554999999999945504994555554499450000000
00000006506d5d6555565d56506d5d5665506d565049944444449994504994444444999450499999999999945549994444449994504994555449999450000000
000000065065d5655556d5d65065d5d5655065d65049940000004994504994000000499450499444444444445049994000049994504994544999994450000000
00000006506d5d6555565d56506d566d66506d565049945555504994504994555550499450499400000000055049994555049994504994499999440550000000
000000065065d5655556d5d65065d666d65065d65049944444449994504994444444999450499444444444445049994444449994504999999944055550000000
00000006506d5d6555565d56506d560656606d565049999999999945504999999999994550499999999999945049999999999994504999994405555550000000
000000065065d5655556d5d65065d606656065d65049999999999945504999999444445550499999999999945049999999999994504999994455555550000000
00000006506d5d6555565d56506d56006d666d565049944444449994504994499940055550499444444444445049994444449994504999999944555550000000
000000065065d5775566d5d65065d65066d665d65049940000004994504994049994555550499400000000055049994000049994504994499999445550000000
00000006506d5d57666d5d57506d5650065d5d565049945555504994504994004999455550499444444444445049994555049994504994044999994450000000
000000065066d5d5d5d5d5775065d6550665d5d65049944444449994504994500499945550499999999999945049994555049994504994000449999450000000
0000000650077d5d5d5d5665507d565500665d575049999999999945504994550049994550499999999999945049994555049994504994550004499450000000
00000006550076666666665550776655507666775044444444444455504444555004444450444444444444445044444555044444504444555500044450000000
00000006555000000000055550000555500000055000000000000555500005555500000550000000000000055000005555000005500005555555000550000000
00000006555588888888885555551111111112755555111111111275555275555555555555527555555555555555555555555555555555555555555550000000
00000006555888888888888555d1111111111777555111111111177755d777555555555555d77755555555555555555555555555555555555555555550000000
00000006558888800008888850d111dddddd127255d1111ddddd127250d272555555555550d27255555555555555777577757755777555577557575550000000
00000006508888555550888850d111000000d11150d111d55555d11150d111555555555550d11155555555555555777575757575755555575757575550000000
00000006509888555550889850d111555550111150d111555555d11150d111555555555550d11155555555555555757577757575775555577555755550000000
00000006508988888888898950d111111111111550d111111111111150d111555555555550d11155555555555555757575757575755555575755755550000000
00000006508889889898888850d111111111115550d111111111111150d111555555555550d11155555555555555757575757755777555577555755550000000
00000006509898898888989850d111dddddd111550d111111111111150d111555555555550d11155555555555555555555555555555555555555555550000000
00000006508989000000898950d111000000d11150d111000000d11150d111555555555550d11155555555555555555555555555555555555555555550000000
00000006509898555550989850d111555550d11150d111555550d11150d111555555555550d11155555555555555555555555775757575755555555550000000
00000006509999555550999950d111555550111150d111555550d11150d111111111111550d11111111111155555555555557555757575755555555550000000
00000006509999555550999950d111111111111150d111555550d11150d111111111111150d11111111111115555555555555755777577555555555550000000
00000006509999555550999950d111111111111550d111555550d11150dd11111111111150dd1111111111115555555555555575757575755555555550000000
000000065099995555509999500ddddddddddd55500ddd5555500ddd500dddddddddddd5500dddddddddddd55555555555557755757575755555555550000000
00000006500005555550000555000000000005555500055555550005550000000000005555000000000000555555555555555555555555555555555550000000
00000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600000000
__label__
333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333
3333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333
333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333
3333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333
333388338383838333338883888b888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333
33333833838383833333338b8b8bbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333
333338338883888333333b8b8b8bbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333
33333833338333833333bb8b8b8bbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333
3333888333833383383bbb8b888bbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333
333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333
33338883333388838b8b8bbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333
33338383333383838b8b8bbbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333
333383833333888b888b888bb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333
333383833333338bbb8b8b8bb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333
3333888338333b8bbb8b888b888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
3333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
333388838383bbbb8bbb88bb88bb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333
33338383838bbbbb8bbbb8bbb8bbbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333
33338883888bbbbb888bb8bbb8bbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
33338383338bbbbb8b8bb8bbb8bbbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
333388833b8bb8bb888b888b888b888bbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
333388838bbbbbbb8bbb888b888b888bbbbbbbbbbbbbbbbbbb333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
3333338b8bbbbbbb8bbb8bbb8b8b8b8bbbbbbbbbbbbbbbbb3333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333
3333338b888bbbbb888b888b888b888bbbbbbbbbbbbbbb33333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
3333338b8b8bbbbb8b8bbb8b8b8b8b8bbbbbbbbbbbbb333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
33333b8b888bb8bb888b888b888b888bbbbbbbbbbbb33333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
3bbb949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499bb33
3bbb949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499bb33
3bbb949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499bb33
bbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbb3
bbbb999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bbb3
bbbb999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bbb3
bbbb999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bbb3
bbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbb
bbbb949994994999999459994954599949545555555559949954555555555555555555555555599949545555555549999994555555554999999494999499bbbb
bbbb9499949994444449444444494444444955d555554444444955d5555555d5555555d555554444444955d555559444444955d555559444444994999499bbbb
bbbb9499949994494949944949449449494455555d559444494555555daaa5555d5555555d559449494455555d559449494955555d559449494994999499bbbb
bbbb44444444949494494494944444949444555555555494944554555aaaaaaaa55554555445449494445555555594949449555555559494944944444444bbbb
bbbb999499949449494994494949944949495555555594494949554aaaaaaaaaaaa555455545944949495555555594494949555555559449494999949994bbbb
bbbb99949994949494494494944944949449555555555494944955aaaaaaaaaaaaaa55559955449494495555555594949449555555559494944999949994bbbb
bbbb999499949444444994444444944444445d5555559444444449aaaaaaaaaaaaaa49545554944444445d555555944444495d5555559444444999949994bbbb
bbbb444444444999999449444944494449445555555d5945595d55aaaaaaaaaaaaaaa545554d494449445555555d499999945555555d4999999444444444bbbb
bbbb94999499555555555aaaaaa55aaaaaa5499999945aaaaaa555aaaaaa666aa666a5555555555555555999495449999994499999945555555594999499bbbb
bbbb9499949955d55555aa8888aaaa8888aa94444449aa8888aa55aaaaaa006aa600a5d5555555d5555544444449944444499444444955d5555594999499bbbb
bbbb9499949955555d55a888778aa888778a94494949a888778a55aaaaaa0a6aa60aa5555d5555555d5594494944944949499449494955555d5594999499bbbb
bbbb4444444455555555a888878aa888878a94949449a888878a54aaaaaaaa6aa6aaa4555445555555554494944494949449949494495555555544444444bbbb
bbbb9994999455555555a888888aa888888a94494949a888888a55aaaaaaa06aa6a0a5455545555555559449494994494949944949495555555599949994bbbb
bbbb9994999455555555a888888aa888888a94949449a888888a55aaaaaa006aa60055559955555555554494944994949449949494495555555599949994bbbb
bbbb999499945d555555aa8888aaaa8888aa94444449aa8888aa495aaaaa0a6aa60a495455545d5555559444444494444449944444495d55555599949994bbbb
bbbb444444445555555d5aaaaaad5aaaaaad499999945aaaaaad554aaaaa666aa6665545554d5555555d4944494449999994499999945555555d44444444bbbb
bbbb94999499599499545555555549999994599949545999495455555aaa5555555555555555555555555999495455555555499999944999999494999499bbbb
bbbb949994994444444955d5555594444449444444494444444955d5555555d5555555d5555555d555554444444955d55555944444499444444994999499bbbb
bbbb949994999444494555555d5594494949944949449449494455555d5555555d5555555d5555555d559449494455555d55944949499449494994999499bbbb
bbbb444444445494944555555555949494494494944444949444545554455455544554555445555555554494944455555555949494499494944944444444bbbb
bbbb999499949449494955555555944949499449494994494949554555455545554555455511115555559449494955555555944949499449494999949994bbbb
bbbb999499945494944955555555949494494494944944949449555599555555995555559111271555554494944955555555949494499494944999949994bbbb
bbbb99949994944444445d55855594444449944444449444444449545554495455544954111177715555944444445d555555944444499444444999949994bbbb
bbbb444444445945595d5558855d4999999449444944494449445545554d5545554d554511112721555d494449445555555d499999944999999444444444bbbb
bbbb949994999499949994998899949994999499949994999499949994999499949994991111111194999499949994999499949994999499949994999499bbbb
bbbb949994999499949994899899949994999499949994999499949994999499949994991111111194999499949994999499949994999499949994999499bbbb
bbbb94999499949994999899a989949994999499949994999499949994999499949994999111111994999499949994999499949994999499949994999499bbb3
bbbb4444444444444444489aa844444444444444444444444444444444444444444444444411114444444444444444444444444444444444444444444444bbb3
bbbb999499949994999499899894999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bbb3
bbbb999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bbb3
3bbb999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994999499949994bb33
3bbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb33
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333338333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333883333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333339883333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333899833333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb899a983333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb89aa8b33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333
3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8998bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333
333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333
3333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
3333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
33333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333
333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333
3333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333
33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333
333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333
3333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333
33333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333
333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333
33333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333
333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333
3333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333
333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333
3333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333
333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333
3333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333
333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333
33333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11
1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd49999994ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1
1d777d777d777d777d777dddddd777d777ddddd777d777ddddd777d777dd94444449dd777d777ddd7d777d777ddddd777d7dddd77dd77d777dddddd7ddddddd1
1d575d575d777d755d7d7dd7ddd757d757dd7dd757d557dd7dd757d755dd94494949dd757d557dd75d557d755ddddd755d7ddd7d7d7d7d7d7ddddd77ddddddd1
1dd7ddd7dd757d77dd775dd5ddd7d7d7d7dd5dd7d7ddd7dd5dd7d7d777dd94949449dd7d7ddd7dd7dd777d777ddddd77dd7ddd7d7d7d7d775ddddd57ddddddd1
1dd7ddd7dd7d7d75dd757dd7ddd7d7d7d7dd7dd7d7ddd7dd7dd7d7d557dd94494949dd7d7ddd7dd7dd755d557ddddd75dd7ddd7d7d7d7d757dddddd7ddddddd1
1dd7dd777d7d7d777d7d7dd5ddd777d777dd5dd777ddd7dd5dd777d777dd94949449dd777ddd7d75dd777d777ddddd7ddd777d775d775d7d7ddddd777dddddd1
1dd5dd555d5d5d555d5d5dddddd555d555ddddd555ddd5ddddd555d555dd94444449dd555ddd5d5ddd555d555ddddd5ddd555d55dd55dd5d5ddddd555dddddd1
1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd49999994ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1
11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
101112130000000000000000000000000000202121212121212121212121212121220000000000000000000000000000000000000000000000000000000000000000c0c1c2c3c4c5c6c7c8c9cacbcccdcecf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000303131313131313131313131313131320000000000000000000000000000000000000000000000000000000000000000d0d1d2d3d4d5d6d7d8d9dadbdcdddedf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0e1e2e3e4e5e6e7e8e9eaebecedeeef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0f1f2f3f4f5f6f7f8f9fafbfcfdfeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000180003eb272cb2620b6518b3514b1512b0510b0512b2516b5522b5632b5700040100411e01224042280422804228032260121e051160110c0400487734b762ab4628b562ab562cb07343400a0600c05008020
000500003865031640276401a6300d620056100161000600096000360000600166001460011600106000e6000c600096000660005600036000260000600006000060000600006000060000600006000060000600
000300003565028300306500c3002a6301d300226300d3001a63011300116300930006630043000b6000030001600003000060000600000000000000000000000000000000000000000000000000000000000000
000200002a6502a6501c3101b3001b310000001860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000184501f450234402432024410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000018450133300f4200c32009410083100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
420300000324003240032400324004240072400924018200182001820018200182000060007600076000660006600056000560005600000000000000000000000000000000000000000000000000000000000000
420300000924007240052400324003240032400324018200182001820018200182000060007600076000660006600056000560005600000000000000000000000000000000000000000000000000000000000000
7404000024372243721f3721f37224372243721f3721f37224372243721f3721f3721f3721f3721f3021f30200002000020000200002000020000200002000020000200002000020000200002000020000200002
001000000085000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b6501c6500c6500365000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44020000344502b400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
760400001962330623396333a64339643356432e65327653206531a64314643106430c6430a643096330763306633066330563305633056230562305623046230462303623036230362302613026130161304613
8c0700002d110251202d110251302d110211302d1102a1402d110201001e1001b10018100151000e1000810002100000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
