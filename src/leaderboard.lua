--leaderboard

lbd={}

function get_lbd()
	tlbd,slbd={},{}
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