pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--prime

function _init()
	count = 1
	
	--cool flags here!
	constant_init()
	
	match_init()
end

function constant_init()
	
	debug = true
	
	--number tile gfx position
	--position of 0
	nx = 0
	ny = 32
end

function match_init()
	match_persistent_init()
	floor_init(1)
end

function match_persistent_init()
	-- particles
	prt = {}
	prtcol = {10, 9, 4, 0}
	
	--camera
	camabs = {}
	camabs.x = 12
	camabs.y = 12
	camoff = {0, 0}
	
	--clock
	--[minutes, seconds, millis]
	clk = {0, 0, 0}
	clkx = 39
	clky = 131
	
	--gamestate
	floor_level = 1
	
end

function floor_init()
	--trapdoor
	trpdrx = 0
	trpdrvx = 0
	trpdrax = 0.04
	trpcooldown = 60
	trpopen = true
	
	--gamestate
	play_state = 0
	cratesbroken = 0
	cratestotal = 10
	leave_state = 1
	floor_won = false
	
	loadincool = 0
	loadoutcool = 0
	
	--layout loading
	player_init()
	level_map_load()
	init_actors()
end

function draw_base_map()
	// map draw
 for i=0,17 do
		for f=0,15 do
			if (i<=1 or i>=17) then
				mset(i, f, 17)
			else
				if (f<=1 or f>=15) then
					mset(i, f, 17)
				else
					mset(i, f, 19)
				end
			end
		end
	end
	mset(9, 8, 0)
end

function level_map_load()
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
	
function clear_floor()
	o = {}
end

function next_level_init()
	clear_floor()
	
	floor_level += 1
	floor_init(floor_level)
end
	
function trpupdate()
	
	if trpopen then
		trpdrx += 0.25
	else
		trpdrx -= 0.25
	end
	
	if trpopen and trpdrx >= 4 then 
		trpdrx = 4
		
		if play_state == 1 then
			play_state = 2
			p[1].control = true
		end
		if play_state == 2 and cratesbroken < cratestotal then
			trpopen = false
		elseif play_state == 2 and cratesbroken >= cratestotal then
			play_state = 3
		end
	elseif not trpopen and trpdrx <= 0 then
		trpdrx = 0
	end
	
end

function loadin_floor_tick()
	loadincool += 0.0055
	if loadincool >= 0.25 then
		loacincool = 0.25
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
		if p[1].x != 72 and p[1].y != 64 then
			trpupdate()
		end
	end
	
	--levelend init
	if cratesbroken >= cratestotal then
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
		p[1].control = false
	end
end

function end_floor_tick()
	player_leave_tick()
		
	--[[
	
	hasn't started leaving, 
	first frame
	
	]]
	if leave_state == 1 then
	
	
	--[[
		
	moving towards trapdoor center
		
	]]
	elseif leave_state == 2 then
	
	
	--[[
		
	player inside, door shutting
		
	]]
	elseif leave_state == 3 then
	
	
	--[[
		
	door shut, transitioning
			
	]]
	elseif leave_state == 4 then
		loadoutcool += 0.0055
		if loadoutcool >= 0.25 then
			loacoutcool = 0.25
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
		next_level_init()
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
 
 for loop=1,#p do
 	player_tick(loop)
 end
 
 particle_physics()
 tick_actors()
 tick_clock(true)
end

function _update60()
 match_loop()
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

function draw_transition_elements()
 poke(0x5f34,0x2)
 if play_state == 0 then
	 circfill(75.5, 67.5, 89-cos(loadincool)*89, 0|0x1800)
	elseif play_state >= 4 then
		circfill(75.5, 67.5, 88+sin(loadoutcool)*89, 0|0x1800)
	end
end

function _draw()
 cls(0)
 
 camera(camabs.x + camoff[1], camabs.y + camoff[2])

	camoff[1] = 0
	camoff[2] = 0
 
 map(0, 0, 0, 0, 18, 18)
	
	p_under = play_state <= 1 and trpdrx<4
	 
 if p_under or leave_state >= 3 then
 	draw_players()
 	draw_trapdoor()
	end
	
	draw_particles()
 
 if not p_under and leave_state < 3 then
 	draw_trapdoor()
 	draw_players()
 end
	draw_actors()
	
	draw_transition_elements()
	
 draw_hud()
 end

-->8
--actors

o={}

function load_actor(t, x, y)
	a = {}
	
	a.t = t
	a.x = x
	a.y = y
	a.px = a.x
	a.py = a.y
	a.vx = 0
	a.vy = 0
	a.pvx = a.vx
	a.pvy = a.vy
	a.ax = 0
	a.ay = 0
	a.colx = 0.5
	a.coly = 0.5
	a.colw = 7
	a.colh = 7
	--actor's collision start points
	a.colspx = a.x + a.colx
	a.colspy = a.x + a.coly
	--actor's collision end points
	a.colepx = a.colspx + a.colw
	a.colepy = a.colspy + a.colh
 a.fric = 0.1
	a.weight = 1
	a.phys_obj = false
	a.snapped = false
	a.frames = 0
	a.despawn = -1
	a.control = false
	
	add(o, a)
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
	
	for crate=1,cratestotal do
		repeat
		rx = 8*flr(rnd(15))+16
		ry = 8*flr(rnd(13))+16
		until not is_actor_there(rx, ry)
		load_actor(10, rx, ry)
		
		o[#o].phys_obj = true
		o[#o].damage = 0
		
	end
	
	for fire=1,2 do
		repeat
		rx = 8*flr(rnd(14))+16
		ry = 8*flr(rnd(13))+16
		until not is_actor_there(rx, ry)
		load_actor(26, rx, ry)
		
		o[#o].frametimer = 0
		o[#o].coly = 3.5
		o[#o].colh = 4
		o[#o].colx = 1.5
		o[#o].colw = 5
		o[#o].phys_obj = false
		dirx = sgn(rnd(1)-1)
		diry = sgn(rnd(1)-1)
		o[#o].vx = 0.5*dirx
		o[#o].vy = 0.3*diry
		o[#o].fric = 0
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

--[[ returns a list
	    
]]
--[[
function is_in_actor(a1, a2, ...)
	arg = {...}
	if arg[1] != nil then
		res = arg[1]
	else
		res = hit_physactor_check(a1, a2)
	end
		
	return (res[1] or res[2]) and (res[3] or res[4])
end

]]

function will_a_touch(a1, a2, future)
	spx = a1.colspx
	epx = a1.colepx
	spy = a1.colspy
	epy = a1.colepy
	
	if future then
		spx += a1.vx
		epx += a1.vx
		spy += a1.vy
		epy += a1.vy
	end
	xcomp1 = max(spx, a2.colspx)
	ycomp1 = max(spy, a2.colspy)
	xcomp2 = min(epx, a2.colepx)
	ycomp2 = min(epy, a2.colepy)
	
	if xcomp1<xcomp2 
	and ycomp1<ycomp2 then
	 return true
	end
	
	return false
end

function is_crate(a1)
	if (a1.t >= 10 and a1.t <= 13) return true
	return false
end

function actor_collide(a1, a2)
	if (is_crate(a1) and is_crate(a2)) return
	if will_a_touch(a1, a2, true) then
	 gener_hit(a1, a2)
	 hit_action(a1, a2)
		hit_action(a2, a1)
	end
	
end

function hit_action(a1, a2)
	
	for player in all(p) do
		if a1 == player then
			hit_res1 = will_physa_hit(a1, a2, false)
			hit_res2 = will_physa_hit(a1, a2, true)
			
			if a2.phys_obj == true then
				for bit=1,4 do
					if not hit_res1[bit] and hit_res2[bit] then
						if not a1.blast_mode then
							if bit == 1 then
								if sgn(a1.vx) == -1 then
									a1.x = a2.colepx-a2.colx
									a1.vx *= -0.8
								--else
								--	a1.x = a2.x-a1.colw
								--	a1.vx *= -0.8
								end
							elseif bit == 2 then
								if sgn(a1.vx) == 1 then
									a1.x = a2.x-a1.colw
									a1.vx *= -0.8
								--else
								--	a1.x = a2.colepx-a2.colx
								--	a1.vx *= -0.8
								end
							elseif bit == 3 then
								if sgn(a1.vy) == -1 then
									a1.y = a2.colepy
									a1.vy *= -0.8
								--else
								--	a1.y = a2.y-a1.colh
								--	a1.vy *= -0.8
								end
							else
								if sgn(a1.vy) == 1 then
									a1.y = a2.y-a1.colh
									a1.vy *= -0.8
								--else
								--	a1.y = a2.colepy
								--	a1.vy *= -0.8
								end
							end
						end
						--crate
						if a2.t >= 10 and a2.t <= 13 then
							crate_damage(a2, a1.blast_mode, true)
						end	
					end
				end
			end
		--actors
		else
			--crate
			if a1.t >= 10 and a1.t <= 13 then
				
			end
			
			--fire
			if a1.t >= 26 and a1.t <= 29 then
				--crate interaction
				if a2.t >= 10 and a2.t <= 13 then
					local res1 = will_a_touch(a1, a2, false)
					local res2 = will_a_touch(a1, a2, true)
					if not res1 and res2 then
						crate_damage(a2, false, false)
					end
				end			
			end
			
		end
		break
	end
end

function crate_damage(ac, instant, player)
	
	if (ac.t == 13) return
	
	if instant then
		ac.t = 13
		damage = 100
	else
		ac.damage += 1
		ac.t += 1
	end
	
	if ac.t == 13 then
		ac.phys_obj = false
		ac.despawn = 300
		sfx(2, 2)
		cratesbroken += 1
	end
	if (player) sfx(3, 3)
end

function actor_col()
 for a1 in all(o) do 
 	for a2 in all(o) do
 		if a1 != a2 then
 			actor_collide(a1, a2)
 		end
 	end
 end
end

function will_hit_wall(ac, future)
	if ac.blast_mode == nil then
 
 cx = ac.x
 cy = ac.y
 
 if future then
 	cx += ac.vx
 	cy += ac.vy
 end
 
 if cx <= 16 then
 ac.x = 16
 ac.vx *= -1
 end
 if cy <= 16 then
 ac.y = 16
 ac.vy *= -1
 end
 if cx >= 128 then
 ac.x = 128
 ac.vx *= -1
 end
 if cy >= 112 then
 ac.y = 112
 ac.vy *= -1
 end
 
 return false
 end
end

function gener_hit(a1, a2)
 
end

function actor_hit_actions()

end

function actor_phys_apply()
	for act in all(o) do
		isplayer = false
		for player in all(p) do
			if (act == player) isplayer = true
		end
		if not isplayer then
			actvarapply(act)
		end
			actor_col_upd(act)
	end
end

function actor_col_upd(a1)
	local a = a1
	--actor's collision start points
	a.colspx = a.x + a.colx
	a.colspy = a.y + a.coly
	--actor's collision end points
	a.colepx = a.colspx + a.colw
	a.colepy = a.colspy + a.colh
end

function actvarapply(act)
	act.pvx = act.vx
	act.pvy = act.vy
	act.px = act.x
	act.py = act.y
	act.vx -= a.fric * act.vx/abs(act.vx)
	act.vy -= a.fric * act.vy/abs(act.vy)	
	if sgn(act.vx) != sgn(act.pvx) then
		act.vx = 0
	end
	if sgn(act.vy) != sgn(act.pvy) then
		act.vy = 0
	end
	act.vx += act.ax
	act.vy += act.ay
	act.x += act.vx
	act.y += act.vy
	act.snapped = false
end

function actor_specific()
	for ac in all(o) do 
		--fire
		if ac.t <= 29 and ac.t >= 26 then
			ac.frametimer += rnd(10)/20
			ac.frametimer %= 4
			ac.t = 26 + flr(ac.frametimer)
			will_hit_wall(ac, false)
		end
		
		--stagehole
		if ac.t == 3 then
			 
		end
		
	end
end

function actor_decay()
	for i=1,#o do
	if (i > #o) break
		if o[i].despawn == 0 then
			del(o, o[i])
			i -= 1
		elseif o[i].despawn > 0 then
			o[i].despawn -= 1
		end
	end
end

function tick_actors()
	actor_col()
	actor_phys_apply()
	actor_specific()
	actor_decay()
end

function draw_actors()
	for act in all(o) do
		for player in all(p) do
			if act != player then
				print(act.t)
				
				if act.despawn > 0 then
					if act.despawn % 2 == 0
					   or act.despawn > 60 then
						spr(act.t, act.x, act.y)
					end
				else
					spr(act.t, act.x, act.y)
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

function ilerp(v1, v2, inter)
	return (inter-v1)/(v2-v1)
end

function distance(x1,y1,x2,y2)
	return sqrt(((x2-x1)^2 + (y2-y1)^2))
end

-->8
--hud

chrs = {
	[":"] = 40,
	["?"] = 44,
	["!"] = 48,
	["."] = 52,
	["/"] = 56,
	["["] = 60,
	["]"] = 64,
	[" "] = 68,
	["_"] = 72
}

--[[

assumes all numbers in tile gfx
are consecutive

]]

function tick_clock(dir)
	if (not p[1].control) return
	frame = 1/.6
	if (dir == true) then
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
end

function draw_char(inp, x, y)
	orded = ord(tostr(inp))
	if orded >=48 and orded <= 57 then
		char_ind = inp*4
		sspr(nx+char_ind, ny, 4, 6, x, y)
	else
		char = chrs[inp]
		sspr(nx+char, ny, 4, 6, x, y)
	end
end

function draw_letter(letter, x, y)
	if (ord(letter) < 97) draw_char(letter, x, y)
	sspr((ord(letter)-97)*4, 40, 4, 6, x, y)
end

function draw_str(str, x, y)
	strver = tostr(str)
	for ind=1,#strver do
		draw_letter(strver[ind], x, y)
		x += 4
	end
end

function draw_clock()
	
	draw_str("timer:", 14, 131)
	
	per_num_offx = 0
	for val in all(clk) do
		val = flr(val)
		local offx = clkx+per_num_offx
		num = val%10
		
		dispstr = ""
		
		dispstr ..= tostr((val-num)/10)
		dispstr ..= tostr(num)
		if per_num_offx != 24 then
			dispstr ..= ":"
		end
		draw_str(dispstr, offx, clky)
		
		per_num_offx += 12
		
	end
end

function draw_mem()
	local mem = stat(0)
	print(mem, 16, 16, 8)
end

function draw_cpu()
	local cpu = stat(1)
	print(cpu, 16, 22, 8)
end

function draw_player_stats()
	print(p[1].x, 16, 28, 8)
	print(p[1].y, 16, 34, 8)
end

function draw_low_bg()
	map(18, 0, 12-camoff[1], 128-camoff[2], 16, 2)
end

function draw_crates_rem()
	spr(10, 72, 130)
	drawstr = ""
	if cratestotal >= 10 and cratesbroken < 10 then
		drawstr ..= "0"
	end
	drawstr ..= tostr(cratesbroken)
	drawstr ..= "/"
	drawstr ..= tostr(cratestotal)
	draw_str(drawstr, 82, 131)
end

function draw_floor_count()
	drawstr = ""
	drawstr ..= "floor "
	drawstr ..= floor_level
	draw_str(drawstr, 106, 131)
end

function draw_debug()
	draw_mem()
	draw_cpu()
	draw_player_stats()
end

function draw_hud()
	draw_low_bg()
	draw_clock()
	draw_crates_rem()
	draw_floor_count()
	if (debug) draw_debug()
end
-->8
--player

function player_init()
	--init the player variables
	p = {}
	for pcount=0,0 do
		--[[
		c stands for...
		copy?
		i think it makes sense.
		]]
		local c = {}
		c.t = 1
		c.x = 72
		c.y = 64
		c.px = c.x
		c.py = c.y
		c.vx = 0
		c.vy = 0
		c.pvx = c.vx
		c.pvy = c.vy
		c.colx = 0.5
		c.coly = 0.5
		c.colw = 7
		c.colh = 7
		--actor's collision start points
		c.colspx = c.x + c.colx
		c.colspy = c.x + c.coly
		--actor's collision end points
		c.colepx = c.colspx + c.colw
		c.colepy = c.colspy + c.colh
		c.ax = 0
		c.ay = 0
		c.weight = 1.5
		c.frames = 0
		c.snapped = false
		c.blast_cool = 0
		c.blast_mode = false
		c.despawn = -1
		c.control = false
		
		add(p, c)
		add(o, c)
		
	end
end

function add_boom_part(player)
	add(prt, {})
	boom = prt[#prt]
	boom.life = rnd(10)+5
	boom.type = 0
	boom.x = p[player].x
	boom.y = p[player].y
	boom.vx = rnd(4)-2
	boom.vy = rnd(4)-2
	prt[#prt] = boom
end

function player_blast(player)
	l = btn(0, player-1)
	r = btn(1, player-1)
	u = btn(2, player-1)
	d = btn(3, player-1)
	
	if l or r or u or d then
	boost = 6
		if l then
			p[player].vx -= boost
		end
		if r then
			p[player].vx += boost
		end
		if u then
			p[player].vy -= boost
		end
		if d then
			p[player].vy += boost
		end
		
	for particles=1,30 do
		add_boom_part(player)
	end
		
	p[player].blast_cool = 120
	p[player].blast_mode = true
	sfx(1,2)	
		
	end
	
end

function player_tick(player)
	if p[player].control then
		player_control(player)
	end
end

function player_control(player)
	
	if btn(5, player-1) and p[player].blast_cool <= 0 then
		player_blast(player)
	end
	
	// set first calc vars for x
	pos = p[player].x
	vel = p[player].vx
	acc = p[player].ax
	
	// loop for both x and y calcs
	for loop=0,2,2 do
		
		l = btn(0+loop, player-1)
		r = btn(1+loop, player-1)
		
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
		
		// apply acceleration
		vel += acc
		
		// friction
		vel -= 0.03 * vel
		if abs(vel) < 0.01 then
			vel = 0
		end
	 
	 // apply velocity
	 pos += vel
	 
	 // border check
	 if pos <= 16 then
	 	pos = 16 vel *= -0.75
	 	if (vel>0.275) sfx(0, -1)
	 	if (vel>1.5) camoff[1+(loop/2)] -= 1
	 elseif pos >= 128 or (loop==2 and pos >= 112) then
	 	if loop == 2 then pos = 112 else pos = 128 end
	 	
	 	vel *= -0.75
	 	
	 	if (vel<-0.275) sfx(0, -1)
	 	if (vel<-1.5) camoff[1+(loop/2)] += 1
	 end
	 
	 // switch calc vars to y
	 if loop == 0 then
	 	p[player].x = pos
	 	pos = p[player].y
	 	p[player].vx = vel
	 	vel = p[player].vy
	 	p[player].ax = acc
	 	acc = p[player].ay
	 else
	 	p[player].y = pos
	 	p[player].vy = vel
	 	p[player].ay = acc
		end	 
	end
	
	p[player].blast_cool -= 1
	
	if (p[player].blast_cool <= 0) or not (abs(p[player].vx) + abs(p[player].vy) > 5) then
		p[player].blast_mode = false
	end	
end

function did_player_enter_trap()
	local temptrap = {}
	temptrap.colspx = 72+2
	temptrap.colepx = 72+2+4
	temptrap.colspy = 64+2
	temptrap.colepy = 64+2+4
	for player in all(p) do
		if will_a_touch(temptrap, player ,false) then
			return true
		end
	end
	return false
end

function player_leave_tick()
	
	--[[
	
	hasn't started leaving, 
	first frame
	
	]]
	if leave_state == 1 then
	
	p[1].blast_mode = false
	p[1].blast_cool = 0
	leave_state = 2
	
	--[[
		
	moving towards trapdoor center
		
	]]
	elseif leave_state == 2 then
	
	p[1].x = lerp(72, p[1].x, 0.5)
	p[1].y = lerp(64, p[1].y, 0.5)
	if distance(p[1].x, p[1].y, 72, 64) < 1 then
		p[1].x = 72
		p[1].y = 64
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

function draw_players()
	for pnum=1,#p do
	 // ball explode anim
	 count = count + .01
	 // player draw
	 if p[pnum].blast_mode and (p[pnum].blast_cool % 2 == 1) then
			spr(2, p[pnum].x, p[pnum].y)
	 else
	 	spr(1, p[pnum].x, p[pnum].y)
	 end
 end
end


__gfx__
00000000001111000099990000000000000000000000000000000000000000000000000000000000499999940999490409949904000000000000000000000000
00000000011127100999a79000000000000000000000000000000000000000000000000000000000944444494444444944444449000000000000000000000000
00000000111177719999777900000000000000000000000000000000000000000000000000000000944949499449494494444940000000000000000000000000
00000000111127219999a7a900000000000000000000000000000000000000000000000000000000949494494494944404949440040004400000000000000000
00000000111111119999999900000000000000000000000000000000000000000000000000000000944949499449494994494949004000400000000000000000
00000000111111119999999900000000000000000000000000000000000000000000000000000000949494494494944904949449000099000000000000000000
00000000011111100999999000000000000000000000000000000000000000000000000000000000944444499444444494444444490400040000000000000000
00000000001111000099990000000000000000000000000000000000000000000000000000000000499999944944494409400900004000400000000000000000
8888888894999499f9fff9ff55555555666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888894999499f9fff9ff55d55555a006600a0000000000000000000000000000000000000000000080000000000000080000000800000000000000000000
8888888894999499f9fff9ff55555d5500a660aa0000000000000000000000000000000000000000000880000008800000088000000880000000000000000000
888888884444444499999999555555550aa66aa00000000000000000000000000000000000000000000988000009880000888800008890000000000000000000
8888888899949994fff9fff955555555aa066a000000000000000000000000000000000000000000008998000889980008899800008998800000000000000000
8888888899949994fff9fff955555555a006600a00000000000000000000000000000000000000000899a980089a99800899a980089a99880000000000000000
8888888899949994fff9fff95d55555500a660aa0000000000000000000000000000000000000000089aa800088aa980008aa980089aa9800000000000000000
8888888844444444999999995555555d666666660000000000000000000000000000000000000000008998000008980000898000008988000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11dddddddddddddddddddd1100000000000000000000000000000000000000000000000000000000011111111111111111111110000000000000000000000000
1dddddddddddddddddddddd10000000000000000000000000000000000000000000000000000000011dddddddddddddddddddd11000000000000000000000000
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000001d11111111111111111111d1000000000000000000000000
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000001d10000000000000000001d1000000000000000000000000
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000001d10000000000000000001d1000000000000000000000000
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000001d10000000000000000001d1000000000000000000000000
1dddddddddddddddddddddd1000000000000000000000000000000000000000000000000000000001d10000000000000000001d1000000000000000000000000
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000000000000000
1dddddddddddddddddddddd100000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000000000000000
11dddddddddddddddddddd1100000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000000000000000
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000011000000000000000000110000000000000000000000000
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000001111111111111111111100000000000000000000000000
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1eeeeeeeeeeeeeeeeeeeeee100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700700777077707070777077707770777077700000777070000000007077000770000000000000000000000000000000000000000000000000000000000000
75707700557055707070755075505570757075700700557070000000075075000570000000000000000000000000000000000000000000000000000000000000
70705700777077707770777077700070777077700500077070000000070070000070000000000000000000000000000000000000000000000000000000000000
70700700755055705570557075700070757055700700055050000000070070000070000000000000000000000000000000000000000000000000000000000000
77707770777077700070777077700070777000700500070070007000750077000770000077700000000000000000000000000000000000000000000000000000
55505550555055500050555055500050555000500000050050005000500055000550000055500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007700077077007770777007707070777077707070700077707700077077707770777077707770707070707070707070707770000000000000000000000000
75707570755075707550755075507070575057507070700077707570707070707070707075505750707070707070707070705570000000000000000000000000
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
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1011121300000000000000000000000000002021212121212121212121212121212200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000003031313131313131313131313131313200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002b6501c6500c6500365000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500003865031640276401a6300d620056100161000600096000360000600166001460011600106000e6000c600096000660005600036000260000600006000060000600006000060000600006000060000600
000300003565028300306500c3002a6301d300226300d3001a63011300116300930006630043000b6000030001600003000060000600000000000000000000000000000000000000000000000000000000000000
000200002a6502a6501c3101b3001b310000001860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
