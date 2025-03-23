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
		{12,13}
	}
end

function match_init(mode)
	menuitem(1, "restart match", restart_match)
	music(6)
	match_persistent_init(mode)
	floor_init(1)
end

function restart_match()
	clear_floor()
	match_init(gamemode)
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
	clky = 131
	clkdir=mode
	if mode==2 then
		clk[1]=0
	end
	
	--gamestate
	floor_level = 20
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
	
	if (bg_type) pastbg=bg_type
	choose_bg_type()
	if pastbg then
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
	if not availablebg or #availablebg==0 then
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
	if p.control then
		trpchannel=3
	else
	 trpchannel=0
	end
	if trpopen and trpdrx == 0 then
		sfx(6, trpchannel)
	elseif not trpopen and trpdrx == 4 then
		sfx(7, trpchannel)
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
		loadincool = 0.25
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
			loadoutcool = 0.25
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
			music(-1)
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
	acts_col = false
	gets_col = false
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
		sfx(2, 3)
		
		--this is only here because
		--of _ENV shenanigans
		add_broken_crate()
		
	end
	if player then
		if t == 14 then 
			if distance(0,0,p.vx,p.vy)>0.5 then
				sfx(11,2)
			end
		else
			sfx(3, 2)
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
	vx -= 0.1 * vx/abs(vx)
	vy -= 0.1 * vy/abs(vy)	
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
		else
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
	if (w.timer==0) sfx(15,2)
	if w.timer<0.25 then
		w.timer+=.01
		w.prog=-1*sin(w.timer)
		w.trem=nil
		if (inmatch)camabs.y-=w.prog
	elseif w.timer<1 then
		w.timer+=.01
		w.prog=1
		w.ptrem=w.trem
		w.trem=7-flr((1-w.timer)*(7/0.75))
		if (w.trem!=w.ptrem) sfx(17,2)
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
			{54,36}
		}
		
			
		if inmatch then
			if gamemode==1 then
				winstr_list[1]="woohoo! you won!"
				winstr_list[2]="your time:"
			else
				winstr_list[1]="phew! time's up!"
				winstr_list[2]=" your score was:"
			end
		else
			winpos_list={
				{46,20},
				{42,28},
				{42,40}
			}
			
			winstr_list={
				"top leaderboard",
				"spots of all time",
				"◀ 20 floor dash ▶",
			}
			
		end
	elseif w.timer<1.01 then
		
		if not inmatch then
			if gamemode==1 then 
				lbdstr="◀ 20 floor dash ▶"
			else
				lbdstr="◀ 3 minute rush ▶"
			end
			winstr_list[3]=lbdstr
		end
		
		if w.letterind==nil then
			w.letterind=0
		end
		
		if w.ask_confirm==nil then
			w.ask_confirm=false
			w.confirmed=false
		end
		
		if placeind!=-1 and inmatch then
			
			if (btnp(1)) then
				
				w.letterind+=1
			end
			if (btnp(0)) w.letterind-=1
			w.letterind%=4
			
			if w.letterind != 3 and not nameselected then
				if btnp(2) then 
					name_arr[w.letterind+1]+=1
					sfx(14,0)
				end
				if btnp(3) then
					name_arr[w.letterind+1]-=1
					sfx(14,0)
				end
			end
			
		end
		if btnp(4) or btnp(5) then
			
			if not inmatch then
				w.timer+=.01
			elseif w.letterind==3 or placeind==-1 then
				if not nameselected then
					nameselected=true
					sfx(13,2)
				end
				
			end
		end
		
		if inmatch and nameselected and stat(22)==12 then
			if placeind != -1 then
				lbd[gamemode][placeind][2]=name_arr
				--stop(lbd[2][placeind][2][1])
				save_lbd()
			end
			w.timer+=.01
		end
	
	elseif w.timer<1.25 then
		w.timer+=.01
		w.prog=1
		w.ptrem=w.trem
		w.trem=flr((1.25-w.timer)*(7/0.25))
		if (w.trem!=w.ptrem) sfx(17,2)
	elseif w.timer<1.5 then
		if (w.timer<1.26) sfx(16,2)
		w.timer+=.01
		w.prog=-1*sin(w.timer)
		
	else
		w.timer=1.5
		w.prog=0
		w.col=0
		if inmatch then
			play_state+=1
		end
		if (not inmatch or play_state==7) del(windows, w)
	end
end

function win_specific(w)
	--stop()
	if w.type == 1 then
		postgame_lb(w)
	end
end

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



function draw_str(str, x, y)
	print(str, x, y+1, 5)
	print(str, x, y, 7)
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


function draw_low_bg()
	map(18, 0, 12-camoff[1], 128-camoff[2], 16, 2)
end

function draw_crates_rem()
	ox = (gamemode-1)*4
	spr(10, 69+ox, 130)
	drawstr = ""
	if (cratetotal >= 10 and cratesbroken < 10) or cratetotal<10 then
		drawstr ..= "0"
	end
	drawstr ..= tostr(cratesbroken)
	drawstr ..= "/"
	if cratetotal < 10 then
		drawstr ..= "0"
	end
	drawstr ..= tostr(cratetotal)
	draw_str(drawstr, 79+ox, 131)
end

function draw_floor_count()
	ox = (gamemode-1)*7
	drawstr = "flr "
	draw_str(drawstr, 101+ox, 131)
	drawstr = ""
	
	if floor_level < 10 then
		drawstr ..= "0"
	end
	drawstr ..= floor_level
	if gamemode == 1 then
		drawstr ..= "/20"
	end
	draw_str(drawstr, 116+ox, 131)
	
end

function draw_level_text()
	if floor_level == 1 then
		draw_wavy_str("use dpad to move!", 44, 23)
		draw_wavy_str("dpad + 🅾️ /❎  to explode!", 30, 33)
		draw_wavy_str("destroy all of the crates", 26, 101)
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
	local outlineblob={}
	for blbind=1,#w.f do
	add(midblob, lerp(w.f[blbind],w.t[blbind],w.prog))
	add(outlineblob, lerp(w.f[blbind],w.t[blbind],w.prog))
	end
	add(midblob,w.col)
	add(outlineblob,7)
	outlineblob[1]-=1
	outlineblob[2]-=1
	outlineblob[3]+=2
	outlineblob[4]+=2
	
	draw_listblob(outlineblob)
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
														
					
					local yoff=0
					if (not inmatch) yoff=4
					
					draw_str(i-3,stroff+42,yoff+8+i*10)
					--score values
					
					--timer
					if gamemode==1 then
						
						for t=1,3 do
							if #lbd[1]>=(i-3) then
								local tscore=lbd[1][i-3][1][t]
								if tscore<10 then
									draw_str(0,stroff+38+t*12,yoff+8+i*10)
									draw_str(tscore,stroff+42+t*12,yoff+8+i*10)
								else
									draw_str(tscore,stroff+38+t*12,yoff+8+i*10)
								end
							else
								draw_str("--",stroff+38+t*12,yoff+8+i*10)
							end
							if (t!=3) draw_str(":",stroff+46+t*12,yoff+8+i*10)
						end
					--score
					else
						if #lbd[2]>=(i-3) then
							draw_str(lbd[2][i-3][1],stroff+50,yoff+8+i*10)
						else
							draw_str("--",stroff+50,yoff+8+i*10)
						end
					end
					
					local lind=windows[1].letterind
					local xoff=0
					if (not placeind or placeind==-1) xoff=9
					for n=1,3 do
						if #lbd[gamemode]>=(i-3) then
							local char = chr((lbd[gamemode][i-3][2][n]%26)+97)
							if (n-1)==lind and i-3==placeind then
								draw_high_str(char,xoff+stroff+85+n*4,yoff+8+i*10)
								sspr(24, 16, 3, 12,xoff+stroff+85+n*4,yoff+5+i*10)
							else
								draw_str(char,xoff+stroff+85+n*4,yoff+8+i*10)
							end
						else
							draw_str("---",xoff+stroff+89,yoff+8+i*10)
						end
					end
					
					if i-3==placeind then
						if lind==3 then
							draw_high_str("ok?",stroff+105,yoff+8+i*10)
						else
							draw_str("ok?",stroff+105,yoff+8+i*10)
						end
					end
					
					
				end
				
				if i==2 and inmatch then
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
	if gamemode==1 then
		timename="time:"
	else
		timename="timer:"
	end
	draw_str(timename, 15, 131)
	draw_clock(15+#timename*4,clky)
	draw_crates_rem(gamemode)
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
	sfx(1,3)	
		
	end
	
end

function fire_player(pl)
	--stop(pl.in_fire)
	if pl.in_fire==false then
		sfx(12,2)
	end
	pl.in_fire=true
	pl.fired=true
	pl.fire_cool = 100
	pl.blast_mode = false
	pl.blast_cool = 0
end

function player_roll_sfx(pl)
	local poke1=0b10001100
	local spd=distance(0,0,pl.vx,pl.vy)
	local norm=(spd/6)-.01
	if (norm<0) then 
		norm=0
		poke1=0
	end
	if (norm>.8) norm=.8
	local adj=flr(norm*32)
	//sets highest bit
	
	
	poke(0x3201+68*9, poke1)
	poke(0x3200+68*9, adj)
	if stat(16) == 22 or stat(16) == 9 then
		sfx(9,0)
	end
	--print(spd, 16, 34, 8)
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
	
	pd=pl.x
	pv=pl.vx
	od1=offx1
	oe=offex
	
	
	for i=1,2 do
	
		if pd < od1 then
	 	pd = od1 pv *= -0.75
	 	if (pv>0.275) sfx(10,2)
	 	if (pv>1.5) camoff[i] -= 1
	 elseif pd > oe then
			pd = oe pv *= -0.75
	 	
	 	if (pv<-0.275) sfx(10,2)
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
	
	do
	local _ENV=pl
	
		blast_cool -= 1
		blast_cool = max(0,blast_cool)
		fire_cool -= 1
		fire_cool = max(0,fire_cool)
		
		local velcomb=abs(vx)+abs(vy)
		
		if blast_mode and blast_cool<100 and velcomb < 2 then
			blast_mode = false
		end
		
		if (blast_cool <= 0) then
			blast_mode = false
		end	
		
		if fire_cool <= 0 then
			fired = false
			fire_cool = 0
		end
	end
	
end

function did_player_enter_trap()
	local temptrap = {}
	temptrap.colspx = 73
	temptrap.colepx = 73+6
	temptrap.colspy = 65
	temptrap.colepy = 65+6
	
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
		xprog=flr(x+(fire_cool/100)*11)-2		
	end
	rect(flr(x-2), y-5, xprog, y-4, col)

end

function draw_player()
	local _ENV=p
	do
	 // player draw
	 if fired and fire_cool%2==0 then
	 	spr(3,x,y)
	 elseif blast_mode and (blast_cool % 2 == 1) then
			spr(2,x,y)
	 else
	 	spr(1,x,y)
	 end
	 
	 if fired then
	 	draw_cooldown(_ENV, true)
	 elseif blast_cool > 0 then
	 	draw_cooldown(_ENV, false)
	 end
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
	//if #windows==0 then
		for i=0,4 do
			for f=0,9 do
				dset(i*10 + f, 0)
			end
		end
		get_lbd()
		sfx(2,2)
	//end
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
					if clk[3] < fclk[3] then
						return i
					end
				end
			end
		end
		
	else
		for i=1,tbcount do
			if endscore>slbd[i][1] then
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
	menuitem(1,"reset save data", clear_lbd)
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
		
		if #windows==0 then
			menu_changed=false
			if (btnp(2)) button_high_ind-=1;menu_changed=true
			if (btnp(3)) button_high_ind+=1;menu_changed=true
			if (menu_changed) sfx(14,2) 
			button_high_ind%=3
		end
		
		if btnp(4) or btnp(5) and #windows==0 then
			if button_high_ind!=2 then
				trstn_phase+=1
				sfx(13,2)
			else
				if #windows<1 then
				gamemode=1
					add_win(
						{64,64,0,0,0},
						{20,12,88,99,8},
						0,0,1)
				end
			end
		end
		
		if #windows!=0 then
		local t = windows[#windows].timer
			if t<1.01 and t>1 then
				if (btnp(0) or btnp(1)) gamemode%=2;gamemode+=1
			end
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
	cls(13)
	for i=0,200,20 do
		for f=0,200,20 do
			local loopt=frameoff%20
			
			local xoff=(f+1+loopt*4)-80
			local yoff=(i+1+loopt*4)-80
			--local dist=1+distance(xoff,yoff,64,64)
			local wobble=3*sin(loopt+(xoff+yoff)/64)+6
			
			draw_blob(xoff+wobble/5,yoff+wobble/3,16,16,flr(wobble),1)
			spr(1,xoff+8+wobble/5,yoff+2+wobble/3)
		end
	end
end

function draw_buttons()
	menu_strs={
		"20 floor dash",
		"3 minute rush",
		" leaderboard "
	}
	for i=0,2	do
		local yset=53+i*18
		local col=13
		onbtn=i==button_high_ind
		
		if (onbtn) col=8
		draw_blob(31,yset-1,62, 10, 3, 0)
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

function draw_epilepsy()
	draw_blob(1,107,125,19,3,0)
	draw_str("! this cart utilizes dizzying !", 3, 110)
	draw_str("!     and flashing images     !", 3, 118)
end

function menu_draw()
	draw_menubg()
	rectfill(6,7,121,40,0)
	map(66,0,0,8)
	draw_buttons()
	draw_epilepsy()
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
888888884f444f44f9fff9ff55555555666666660000000000000000000000000000000000000000000000000000000000000000000000000333333000000000
888888884f444f44f9fff9ff55d55555a006600a00000000000000000000000000000000000000000000800000000000000800000008000033b77b3300000000
888888884f444f44f9fff9ff55555d5500a660aa0000000000000000000000000000000000000000000880000008800000088000000880003bb77bb300000000
88888888ffffffff99999999555555550aa66aa00000000000000000000000000000000000000000000988000009880000888800008890003777777300000000
88888888444f444ffff9fff955555555aa066a000000000000000000000000000000000000000000008998000889980008899800008998803777777300000000
88888888444f444ffff9fff955555555a006600a00000000000000000000000000000000000000000899a980089a99800899a980089a99883bb77bb300000000
88888888444f444ffff9fff95d55555500a660aa0000000000000000000000000000000000000000089aa800088aa980008aa980089aa98033b77b3300000000
88888888ffffffff999999995555555d666666660000000000000000000000000000000000000000008998000008980000898000008988000333333000000000
11111111111111111111111107000000000000000000000000000000000000000000000000000000666666666666666666666666011111100d1111d00dddddd0
11dddddddddddddddddddd117070000000000000000000000000000000000000000000000000000062288226633333366cccccc61dddddd1d1dddd1ddd1111dd
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006228822663bbbb366cddddc61d1111d11dd11dd1d1dddd1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006882288663bbbb366cdccdc61d1dd1d11d1dd1d1d1d11d1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006882288663bbbb366cdccdc61d1dd1d11d1dd1d1d1d11d1d
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000006228822663bbbb366cddddc61d1111d11dd11dd1d1dddd1d
1dddddddddddddddddddddd10000000000000000000000000000000000000000000000000000000062288226633333366cccccc61dddddd1d1dddd1ddd1111dd
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000666666666666666666666666011111100d1111d00dddddd0
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000000aaaaaa00aaaaaa00aaaaaa00b3333b0033333300bbbbbb0
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000aa8888aaaabbbbaaaaccccaab33bb33b33bbbb33bb3333bb
11dddddddddddddddddddd1170700000000000000000000000000000000000000000000000000000a888778aabbb77baaccc77ca33bbbb333bb33bb3b33bb33b
11111111111111111111111107000000000000000000000000000000000000000000000000000000a888878aabbbb7baacccc7ca3bb33bb33b3bb3b3b3b33b3b
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
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
888888888888888888888888888888888888888888888888888888888888888888888888888888888882282288882288228882228228888888ff888888228888
888882888888888ff8ff8ff88888888888888888888888888888888888888888888888888888888888228882288822222288822282288888ff8f888888222888
88888288828888888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888ff888f888888288888
888882888282888ff8ff8ff888888888888888888888888888888888888888888888888888888888882288822888222222888888222888ff888f888822288888
8888828282828888888888888888888888888888888888888888888888888888888888888888888888228882288882222888822822288888ff8f888222288888
888882828282888ff8ff8ff8888888888888888888888888888888888888888888888888888888888882282288888288288882282228888888ff888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555550000000000005555555555555555555555555555550000000000005500000000000055555555555
555555e555566656665555e555555555555566566656655550660066600005555555555556555566556656665550666066600005506660666000055555555555
55555ee555555656565555ee55555555555655565656565550060000600005555555555556555656565656565550606060600005500060006000055555555555
5555eee555556656565555eee5555555555666566656565550060066600005555555555556555656565656665550606060600005500660666000055555555555
55555ee555555656565555ee55555555555556565556565550060060000005555555555556555656565656555550606060600005500060600000055555555555
555555e555566656665555e555555555555665565556665550666066600005555555555556665665566556555550666066600005506660666000055555555555
55555555555555555555555555555555555555555555555550000000000005555555555555555555555555555550000000000005500000000000055555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555577777566666566666566666555556666666659999999956666666656666666656666666656666666656666666656666666655555555555
55555665566566655575577565556565556565656555556667766659999979956666667756677777656666777656676666656676667656667766655555dd5555
5555656565555655557757756665656665656565655555667667665999779795666677675667666765666676765676766665767676765667777665555d55d555
5555656565555655557757756555656655656555655555676666765977999795667766675667666765666676765766676765777777775677667765555d55d555
55556565655556555577577565666566656566656555557666666757999999757766666757776667757777767757666776756767676757766667755555dd5555
55556655566556555575557565556565556566656555556666666659999999956666666656666666656666666656666666656766666756666666655555555555
55555555555555555577777566666566666566666555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555555555555005dd500500500500500566555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555565655665655555005dd50050050050056656655555dddddddd5dddddddd5777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd55555555555
555565656565655555005dd50050050056656656655555dddddddd5d55ddddd5775775775ddd55ddd5ddddd5dd5dd5ddddd5dddddddd5dddddddd55555555555
555565656565655555005dd50050056656656656655555dddddddd5d555dddd5755755775dddddddd5dddd55dd5dd55dddd55d5d5d5d5d55dd55d55555555555
555566656565655555005dd50056656656656656655555ddd55ddd5dddd555d5775575575d5d55d5d5ddd555dd5dd555ddd55d5d5d5d5d55dd55d55555555555
555556556655666555005dd56656656656656656655555dddddddd5ddddd55d5775775775d5d55d5d5dd5555dd5dd5555dd5dddddddd5dddddddd55555555555
5555555555555555550057756656656656656656655555dddddddd5dddddddd5777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd55555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda0555
55507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada0555
55507a1a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda0555
55507171777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa0555
555071771a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550a17771aaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500177771000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550a17711aaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55507711717a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda0555
55507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada0555
55507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda0555
55507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda0555
55507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada0555
55507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda0555
55507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda0555
55507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada0555
55507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda0555
55507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda0555
55507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada0555
55507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda0555
55507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda055077aa7a7a666aaeeaaaccaaaddda0555
55507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada05507a7a777a6a6aaaeaaaacaaaaada0555
55507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda05507a7a7a7a6a6aaaeaaaacaaaddda0555
55507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa05507a7a777a6a6aaaeaaaacaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda0555
55507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada0555
55507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda0555
55507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
555077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda055077aa7a7a666aaeeaaacccaaddda0555
55507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada05507a7a777a6a6aaaeaaaaacaaaada0555
55507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda05507a7a7a7a6a6aaaeaaacccaaddda0555
55507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa05507a7a777a6a6aaaeaaacaaaadaaa0555
5550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0550777a7a7a666aaeeeaacccaaddda0555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550aaaaaaaaaaaaaaaaaaaaaaaaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555dd555dd5ddd5ddd555555ddd5d5d5ddd5ddd555555dd55ddd5ddd5d5d5dd55ddd5555ddd5ddd5d5d5ddd5ddd5ddd5555dd55ddd5ddd5ddd5ddd5dd555555
5555d5d5d5d55d5555d555555d5d5d5d555d555d555555d5d5d5555d55d5d5d5d5d555555d5d5d555d5d5d555d5d5d5d5555d5d5d5d5ddd5d5d5d555d5d55555
5555d5d5d5d55d555d5555555dd55d5d55d555d5555555d5d5dd555d55d5d5d5d5dd55555dd55dd55d5d5dd55dd55dd55555d5d5ddd5d5d5ddd5dd55d5d55555
5555d5d5d5d55d55d55555555d5d5d5d5d555d55555555d5d5d5555d55d5d5d5d5d555555d5d5d555ddd5d555d5d5d5d5555d5d5d5d5d5d5d555d555d5d55555
5555d5d5dd55ddd5ddd555555ddd55dd5ddd5ddd555555ddd5ddd55d555dd5d5d5ddd5555d5d5ddd55d55ddd5d5d5ddd5555ddd5d5d5d5d5d555ddd5d5d55555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55551111111111111115555551111111111111115555551111111111111111111111155551111111111111111111111155551111111111111111111111155555
555511111111eeeeee15555551dddddd11111111555555111111111111111fffffff15555111111111111111fffffff155551dddddd111111111111111155555
555511111111eeeeee15555551dddddd11111111555555111111111111111fffffff15555111111111111111fffffff155551dddddd111111111111111155555
555511111111eeeeee15555551dddddd11111111555555111111111111111fffffff15555111111111111111fffffff155551dddddd111111111111111155555
55551111111111111115555551111111111111115555551111111111111111111111155551111111111111111111111155551111111111111111111111155555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
101112130000000000000000000000000000202121212121212121212121212121220000000000000000000000000000000000000000000000000000000000000000c0c1c2c3c4c5c6c7c8c9cacbcccdcecf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000303131313131313131313131313131320000000000000000000000000000000000000000000000000000000000000000d0d1d2d3d4d5d6d7d8d9dadbdcdddedf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0e1e2e3e4e5e6e7e8e9eaebecedeeef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0f1f2f3f4f5f6f7f8f9fafbfcfdfeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010180003eb272cb2620b6518b3514b1512b0510b0512b2516b5522b5632b5700040100411e01224042280422804228032260121e051160110c0400487734b762ab4628b562ab562cb07343400a0600c05008020
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
b80400002835000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000005410063310733108331093310a3310b3310c3310d3310e3310f331103311a3001c301000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
0004000011410103310f3310e3310d3310c3310b3310a331093310833107331063310000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
80020000326750c475000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00080c0451104516045180451f0451b0451804513045130050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000c00080f04513045180451b045220451d0451b04516045130050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001800100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
280c00200011100111001110011100111001110011100111001420012100121001210012100121001210012100152001310013100131001310013100131001310016200131001310013100131001310013100131
280c00200311103111031110311103111031110311103111031420311103111031110311103111031110311103142031110311103111031210312103121031210314203121031210312103131031310313103141
010600200000000000000000000009645096050964509605096450964509605076050564505605056050000509645096450960509605096450960509605000050964509645096050000509645096050960509605
000600200965509605096250960509625096050962509605096550960509635096050963509605096350960509655096050964509605096450964509645096050966509605096650960509665096650966509605
0106002009625096250962500005096250e6050e625096050963509635096350000509635000050e6350960509635096050964500005096450e6450c645096050964509655096550000509655006550e6550e605
410c00200014500145001450014500175001450014500145001750014500145001550017500175001550015500175001550015500155001750017500155001550017500155001550015500175001750015500155
cd0600200f3150f3150f315273050f1150f3050f315044050f3250f3250f3250f3050f1250f3050f3250f3050f1350f3050f3350f3050f135003050f335003050f3450f3450f345003050f3450f3450f34500305
430c00200f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f1220f1120f1120f1220f122
cd0600200c3250c3250c325273050c1250f3050c325044050c3350c3350c3350f3050c1350f3050c3350f3050c1450f3050c3450f3050c145003050c345003050c3550c3550c355003050c3550c3550c35500305
430c00200c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c1220c1120c1120c1220c122
8906002008640086451b3051b305016551c30501655003051764017645003050030501655003050165500305003050030500305003050864008645003050030517640176450000508605086451b0050864500005
cd0600200f3400f3400f340043000f340000000f3200f3000f3200f3400f3200f3000f3300f3000f3300f3000f330003000f330003000f3400f3400f340003000f3400f3400f340003000f340000000f34000000
d40600200c3310c3310c3310c3010c3310c3010c3310c3010c3310c3310c3310c3010c3310c3010c3310c3010c3310c3010c3310c3010c3310c3310c3310c3010c3310c3310c3310c3010c3310c3010c3310c301
d50600200f3310f3310f3310f3010f3310f3010f3310f3010f3310f3310f3310f3010f3310f3010f3310f3010f3310f3010f3310f3010f3310f3310f3310f3010f3310f3310f3310f3010f3310f3010f3310f301
410c00200314503145031450314503175031450314503145031750314503145031550317503175031550315503175031550315503155031750317503155031550317503155031550315503175031750315503155
190600200963509635096350000009635000000e635096050964509645096450000509645000050e6450960509645096350963500000096550e6550c655096050965509665096650000509665006650e6650e605
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
__music__
00 16144344
00 16155544
00 16141744
00 16151859
00 16141719
00 1615181a
00 16141c1b
00 16152526
01 16231721
02 16241821
00 41424344
00 161d1e21
00 161f2021

