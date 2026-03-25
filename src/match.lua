function match_init(mode)
	menuitem(1, "restart match", restart_match)
	music(0)
	match_persistent_init(mode)
	floor_init(1)
end

function restart_match()
	match_init(gamemode)
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
	
	
	--gamestate
	floor_level = 1
	gamemode=mode
    if mode==2 then
		clk[1]=3
	end
	
	init_floor_dimens()
	
end

function floor_init(floor)
    clear_floor()
	--trapdoor
	trpdrx,trpcooldown,play_state,cratesbroken,cratetotal,switchtotal,firecount,loadincool,loadoutcool,leave_state=upsp"0,60,0,0,10,3,0,0,0,1"
	
    trpopen,switchclear,floor_won
    =true,  false,      false

	if (switchtotal == 0) switchclear = true
	floor_type = gen_floor_type(floor)
	gen_floor_mods(floor)
	
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

function clear_map()
	for i=0,17 do
		for f=0,17 do
			mset(i, f, 0)
		end
	end
end
	
function clear_floor()
	o,
	crates,
	switches,
	fires,
	items
    ={},{},{},{},{}
	clear_map()
end

function next_level_init()
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
			play_state,p.control = 2,true
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

--[[

should only be run once
before next play_state
change is performed

]]
function end_stage()
    if (floor_level==15 and gamemode==1) or (clk[1]==0and clk[2]==0 and clk[3]==0) then
        music(-1)
        if not floor_won then
            floor_won=true
            endscore=floor_level
            name_arr={0,0,0}
            if #windows==0 then
                add_win(
                    {76,68,0,0,0},
                    {32,8,88,99,8},
                    1,0,1)
                    
                upd_lbd(gamemode)
                
            end
        end
    else
        next_level_init()
    end
end

function level_state_process()
    local levelstatetickarray = {
        loadin_floor_tick,
        start_floor_tick,
        playing_floor_tick,
        postwin_floor_tick,
        end_floor_tick,
        end_stage,
        run
    }
    levelstatetickarray[play_state+1]()
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



function match_loop()
	glob_dest_crate = false
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

