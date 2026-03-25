--menu

function menu_init()
	music(24)
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
			if (menu_changed) sfx(14,0) 
			button_high_ind%=3
		end
		
		if btnp(4) or btnp(5) and #windows==0 then
			if button_high_ind!=2 then
				trstn_phase+=1
				sfx(13,0)
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
			
			rrectfill(xoff+wobble/5,yoff+wobble/3,16,16,flr(wobble),1)
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
		rrectfill(31,yset-1,62, 10, 3, 0)
		rrectfill(32,yset,60, 8, 3, col)
		
		
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
				rrectfill(-33, i*32, 188-(-188*sin(own_trstn)), 32, 16, 0)
			else
				rrectfill(-16+-188*sin(max(own_trstn,0)), i*32, 188, 32, 16, 0)
			end
		end
	end
end

function draw_epilepsy()
	rrectfill(1,107,125,19,3,0)
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