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
	
	local mcount=flr((floor-1)/5)+1
	if mcount>0 and floor != 1 then
		for i=1,min(mcount, mod_count) do
			local fmod=rnd(possible_mods)
			add(floor_mods, fmod)
			del(possible_mods, fmod)
			
			if fmod==1 then
				vortextype=(floor%2)+1	
			end
			
			if fmod==3 then
				firecount=flr(floor*0.3+1)
			end
		end
	end
end