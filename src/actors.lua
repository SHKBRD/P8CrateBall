--actors

-- o={}
-- crates={}
-- switches={}
-- fires={}
-- items={}

function load_actor(t, x, y)
	local a = {}
	setmetatable(a,{__index=_𝘦𝘯𝘷})
	a.t = t
	a.x = x
	a.y = y
	
	do
	local _𝘦𝘯𝘷=a
	
	vx,vy,ax,ay,colx,coly,colw,colh,despawn,z=upsp"0,0,0,0,0.5,0.5,7,7,-1,0"
    pvx,pvy,px,py,acts_col,gets_col,control=vx,vy,x,y,false,false,false
    --actor's collision start points
	colspx,colspy=x+colx,y+coly
	--actor's collision end points
	colepx,colepy=colspx+colw,colspy+colh
	
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
	
	makeallsteel=has_mod(2)
	makesteel=true
	steelsmade=0
	steelmax=flr(cratetotal*0.125*(floor_level%5+1))
	if makeallsteel then
		steelmax=cratetotal
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
		if vortextype != 0 then
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
			local _𝘦𝘯𝘷 = it
			
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
	if makeallsteel or makesteel then
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
	local _𝘦𝘯𝘷=a1
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
	local _𝘦𝘯𝘷=ac
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
		--of _𝘦𝘯𝘷 shenanigans
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
	glob_dest_crate = true
end

function switch_toggle(a1)
	local _𝘦𝘯𝘷=a1
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
        if (fire_touched) break
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
	local _𝘦𝘯𝘷 = a1
	--actor's collision start points
	colspx = x + colx
	colspy = y + coly
	--actor's collision end points
	colepx = colspx + colw
	colepy = colspy + colh
end

function actvarapply(act)
	local _𝘦𝘯𝘷=act
	pvx,pvy,px,py=vx,vy,x,y
	vx -= 0.1 * sgn(vx)
	vy -= 0.1 * sgn(vy)	
	if sgn(vx) != sgn(pvx) then
		vx = 0
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
		local _𝘦𝘯𝘷=ac 
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
					if cratesbroken!=cratetotal then
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
	local _𝘦𝘯𝘷=a1
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
			local _𝘦𝘯𝘷=act
			
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