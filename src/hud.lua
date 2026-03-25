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
			
			if (btnp(1) or btnp(4) or btnp(5)) then
				
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

    -- makes sure they dont
	-- become negative for some
	-- reason
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
	if glob_dest_crate then
		draw_high_str(drawstr, 79+ox, 130)
	else
		draw_str(drawstr, 79+ox, clky)
	end
end

function draw_floor_count()
	ox = (gamemode-1)*7
	drawstr = "flr "
	draw_str(drawstr, 102+ox, clky)
	drawstr = ""
	
	if floor_level < 10 then
		drawstr ..= "0"
	end
	drawstr ..= floor_level
	if gamemode == 1 then
		drawstr ..= "/20"
	end
	draw_str(drawstr, 116+ox, clky)
	
end

function draw_level_text()
	if floor_level == 1 then
		rrectfill(25, 19, 101, 23, 4, 0)
		draw_wavy_str("use dpad to move!", 43, 23)
		draw_wavy_str("dpad + 🅾️ /❎  to explode!", 29, 33)
		rrectfill(22, 96, 107, 23, 4, 0)
		draw_wavy_str("destroy all of the crates", 26, 101)
		draw_wavy_str("to reach the next floor!", 29, 110)
	end
end

function draw_listblob(l)
	rrectfill(l[1],l[2],l[3],l[4],l[5],l[6])
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
	draw_str(timename, 15, clky)
	draw_clock(15+#timename*4,clky)
	draw_crates_rem(gamemode)
	draw_floor_count()
	draw_wins()
	//if (debug) draw_debug()
end