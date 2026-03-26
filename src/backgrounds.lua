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
		--76,68
		local bx=cos(i+toff)*(sin(toff)/2+1)*50+76
		local by=sin(i+toff)*(sin(toff)/2+1)*50+68
		local size=22+abs(cos(toff))*10*(1/(sin(toff)+1.3))
		
		--circfill(bx, by, size+6, bgp1)
		--circfill(bx, by, size-6, bgp2)
		
		circ(bx, by, size, bgp1)
		
		local subcircs=8
		for subcir=1,subcircs do
            cycle=subcir/subcircs+toff*2
			local subx=bx+size*cos(cycle)
			local suby=by+size*sin(cycle)
			local subsize=4+2*(sin(cycle+toff*6))
			circfill(subx, suby, subsize, bgp1)
		end
		
	end
end

function draw_bg()
	local bgtable={
        draw_bg_hole,
        draw_bg_polka,
        draw_bg_vort
    }
	bgtable[bg_type]()
end

function reset_bg_list()
	availablebg={}
	for i=1,bg_types do
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