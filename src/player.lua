--player

function player_init()
	--init the player variables
	p = {}
	setmetatable(p,{__index=_𝘦𝘯𝘷})
	do
	local _𝘦𝘯𝘷=p

    
    vx,vy,ax,ay,blast_cool,fire_cool,t,x,y,colx,coly,colw,colh,despawn,z
	=upsp"0,0,0,0,0,0,1,72,64,0.5,0.5,7,7,-1,5"
    blast_mode,fired,in_fire,control,gets_col=false,false,false,false,true

    px = x
	py = y
    pvx = vx
	pvy = vy
    --actor's collision start points
	colspx = x + colx
	colspy = y + coly
    --actor's collision end points
	colepx = colspx + colw
	colepy = colspy + colh

	end
	add(o,p)
end

function add_boom_part()
	add(prt, {})
	boom = prt[#prt]
	boom.life = rnd(10)+5
	boom.type = 0
	boom.x = p.x
	boom.y = p.y
	boom.vx = rnd(4)-2
	boom.vy = rnd(4)-2
	prt[#prt] = boom
end

function destroy_surr()
	
	dist = 2*8
	
	for ac in all(o) do
		if ac != p then
			if ac.t >= 10 and ac.t <=12 or ac.t == 14 then
				if distance(ac.x, ac.y, p.x, p.y) <= dist then
					crate_damage(ac, true, false)
				end	
			end
		end
	end
	
	
end

function player_blast()
	
	l,r,u,d=btn(0),btn(1),btn(2),btn(3)
	
	--pvx = pl.vx
	--pvy = pl.vy
	
	if l or r or u or d then
	
		if(l)p.vx=-6
		if(r)p.vx=6
		if(u)p.vy=-6
		if(d)p.vy=6
		
	for particles=1,60 do
		add_boom_part()
	end
	
	destroy_surr()
	
	p.blast_cool = 120
	p.blast_mode = true
	sfx(1,3)	
		
	end
	
end

function fire_player()
	--stop(pl.in_fire)
	if p.in_fire==false then
		sfx(12,2)
	end
	p.in_fire=true
	p.fired=true
	p.fire_cool = 100
	p.blast_mode = false
	p.blast_cool = 0
end

function player_roll_sfx()
	local poke1=0b10001100
	local spd=distance(0,0,p.vx,p.vy)
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

function player_tick()
	if p.control then
		player_control()
		player_roll_sfx()
	end
end

function player_bounce_actor(a1, a2)
	local hit_res1 = will_physa_hit(a1, a2, false)
	local hit_res2 = will_physa_hit(a1, a2, true)
	
	for bit=1,4 do
        -- run rest of code if this frame doesn't have collision and next frame does
		if not ((not hit_res1[bit]) and hit_res2[bit]) then goto p_col_cont end

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

		::p_col_cont::
        
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

function player_border_check()
	
	--same as map offsets, but in pixels and added by one tile
	--local offx = (19-lev_w)*4
	--local offy = (17-lev_h)*4
	local offex = offx1+(lev_w-1)*8
	local offey = offy1+(lev_h-1)*8
	
	pd=p.x
	pv=p.vx
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
		 p.x=pd
			p.vx=pv
			
			pd=p.y
			pv=p.vy
			od1=offy1
			oe=offey
 	else
 		p.y=pd
			p.vy=pv
 	end
 	
 end
	
end

function player_control()
	
	if p.blast_cool<=0 and p.fired != true then
		if btn(5) or btn(4) then
			player_blast(p)
		end
	end
	
	// set first calc vars for x
	pos = p.x
	vel = p.vx
	acc = p.ax
	
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
		
		player_border_check()
		
		// apply acceleration
		vel += acc
		
		// friction
		vel -= 0.03 * vel
		if abs(vel) < 0.01 then
			vel = 0
		end
	 
	 // apply velocity
	 pos += vel
	 
	 player_border_check()
	 
	 // switch calc vars to y
	 if loop == 0 then
	 	p.x = pos
	 	pos = p.y
	 	p.vx = vel
	 	vel = p.vy
	 	p.ax = acc
	 	acc = p.ay
	 else
	 	p.y = pos
	 	p.vy = vel
	 	p.ay = acc
		end	 
	end
	
	do
	local _𝘦𝘯𝘷=p
	
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
	temptrap.colepx = 79
	temptrap.colspy = 65
	temptrap.colepy = 71
	
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

function draw_cooldown(fire)
	if (play_state>3) return
	local _𝘦𝘯𝘷=p
	
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
	local _𝘦𝘯𝘷=p
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
	 	draw_cooldown(_𝘦𝘯𝘷, true)
	 elseif blast_cool > 0 then
	 	draw_cooldown(_𝘦𝘯𝘷, false)
	 end
 end
end

