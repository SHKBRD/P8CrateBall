function draw_trapdoor()
	move = trpdrx
	palt(0, false)
	--left hatch
	sspr(32+flr(trpdrx), 8, 4-flr(trpdrx), 8, 72, 64)
	--right hatch
	sspr(36, 8, 4-flr(trpdrx), 8, 76+move, 64)
	palt(0, true)
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
    
    --rrect(30,30,0,0,4,0)
end