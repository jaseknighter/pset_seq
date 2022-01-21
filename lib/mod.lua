-- PSET SEQUENCER
-- sequence psets
-- @jaseknighter
-- after idea of @mlogger

-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod=require 'core/mods'
-- local textentry=require('textentry')

--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some x/y values
--

local state={
  -- x=1,
  -- is_running=false,
  -- advertise="false",
  -- archive="false",
  -- station="",
}

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in mainden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

local m={}

mod.hook.register("system_post_startup","pset seq mod setup",function()
  state.system_post_startup=true
end)

mod.hook.register("script_pre_init","broadcast mod init",function()
  m.pset_seq.init()
end)

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--


------------------------------
-- pset path and PSET exclusion setup
------------------------------

m.pset_seq = {}
m.pset_seq.pset_path = nil

-- set pset exclusions
function m.pset_seq.set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  for i=1,#pset_exclusion_tables,1
  do
    if #pset_exclusion_table_labels > 0 then
        params:add{type = "option", id = pset_exclusion_table_labels[i], name = pset_exclusion_table_labels[i],
        options = {"false", "true"}, default = 1,
          action = function(x) 
            local setting
            if x==1 then setting = true else setting = false end
            m.pset_seq.set_save_paramlist(pset_exclusion_tables[i], setting)  
          end
        }
    end
  end
end


------------------------------
-- main pset sequencer code
------------------------------
m.pset_seq.ticks_per_seq_cycle = clock.get_tempo() * 1/1
m.pset_seq.pset_seq_direction = "up"
m.pset_seq.pset_dir_len = nil

function m.pset_seq.set_pset_seq_timer()
  local arg_time = clock.get_tempo()
  m.pset_seq.pset_seq_ticks = 1
  -- local current_pset = first.min
  m.pset_seq.pset_seq_timer = metro.init(function() 
    if params:get("pset_seq_enabled") == 2 then
      local first = params:lookup_param("pset_first")
      local last = params:lookup_param("pset_last")
      local new_pset_id
        m.pset_seq.pset_seq_ticks = m.pset_seq.pset_seq_ticks + 1
      if m.pset_seq.pset_seq_ticks == m.pset_seq.ticks_per_seq_cycle then
        m.pset_seq.pset_seq_ticks = 1
        -- m.pset_seq.num_psets = last.value - first.value + 1
        local current_pset = params:get("load_pset")
        local mode = params:get("pset_seq_mode")
        if mode == 1 then
          new_pset_id = current_pset < last.value and current_pset + 1 or first.value
        elseif mode == 2 then
          if first.value == last.value then
            new_pset_id = first.value
          elseif  m.pset_seq.pset_seq_direction == "up" then
            new_pset_id = current_pset < last.value and current_pset + 1 or current_pset - 1
             m.pset_seq.pset_seq_direction = current_pset < last.value and  m.pset_seq.pset_seq_direction or "down"
          else
            new_pset_id = current_pset > first.value and current_pset - 1 or current_pset + 1
             m.pset_seq.pset_seq_direction =  current_pset > first.value and  m.pset_seq.pset_seq_direction or "up"
          end
        elseif mode == 3 then
          new_pset_id = math.random(1,m.pset_seq.num_psets) + first.value - 1
        end
        
        local old_mode = mode
        params:set("load_pset", new_pset_id)
      end
    end  
    if clock.get_tempo() ~= arg_time and m.pset_seq.initializing_pset_seq_timer == false then
      m.pset_seq.initializing_pset_seq_timer = true
      metro.free(m.pset_seq.pset_seq_timer.props.id)
      m.pset_seq.set_pset_seq_timer()
      m.pset_seq.initializing_pset_seq_timer = false
    end
  end, 1/arg_time, -1)
  m.pset_seq.pset_seq_timer:start()
  m.pset_seq.initializing_pset_seq_timer = false
end

function m.pset_seq.set_ticks_per_seq_cycle()
  m.pset_seq.ticks_per_seq_cycle = math.floor(clock.get_tempo() * (params:get("pset_seq_beats")/params:get("pset_seq_beats_per_bar")))
  m.pset_seq.pset_seq_ticks = 1
end 

function m.pset_seq.set_num_psets()
  local dir = util.scandir (m.pset_seq.pset_path)
  if #dir ~=  m.pset_seq.pset_dir_len then
    m.pset_seq.num_psets = 0
    for i=1,#dir,1
    do
      local j,k = string.find(dir[i],".pset")
      if (k and k == #dir[i]) then
        m.pset_seq.num_psets = m.pset_seq.num_psets + 1
      end
    end
    m.pset_seq.pset_dir_len = #dir
  end
end

m.pset_seq.get_num_psets = function()
  return m.pset_seq.num_psets
end

m.pset_seq.set_save_paramlist = function(paramlist, state)
  if paramlist and #paramlist > 0  then
    for i=1,#paramlist,1
    do
      if paramlist[i] then
        params:set_save(paramlist[i],state)
      end
    end
  end
end

------------------------------
-- pset sequencer init
------------------------------
m.pset_seq.init = function (pset_exclusion_tables, pset_exclusion_table_labels)
  m.pset_seq.inited = false 
  m.pset_seq.pset_path = _path.data .. norns.state.name .. "/"
  
  -- setup pset sequence parameters
  m.pset_seq.set_num_psets()
  
  local num_pset_exclusion_sets = pset_exclusion_table_labels and #pset_exclusion_table_labels+1 or 0
  
  params:add_group("PSET SEQUENCER",10+num_pset_exclusion_sets)
  
  function m.pset_seq.update_mod_midi()
    -- setup midi
    m.pset_seq.midi_devices={}
    m.pset_seq.midi_device_list={"none"}
    for _,dev in pairs(midi.devices) do
      local mod_midi_port = m.pset_seq.inited == false and 1 or params:get("mod_midi_port") 
      
      table.insert(m.pset_seq.midi_device_list,dev.name)
      m.pset_seq.midi_devices[dev.name]=midi.connect(mod_midi_port)
      m.pset_seq.midi_devices[dev.name].event=function(data)
        if dev.name~=m.pset_seq.midi_device_list[params:get("mod_midi_in")] then
          do return end
        end
        local msg=midi.to_msg(data)

        if msg.type == "program_change" then
          local new_pset = msg.val
          local first = params:get("pset_first")
          local last = params:get("pset_last")
          if new_pset >= first and new_pset <= last then
            params:set("load_pset",new_pset)
          else
            print("ERROR: program change value < first param or > last param")
          end
        end
      end
    end
  end

  m.pset_seq.update_mod_midi() 

  params:add_number("mod_midi_port","mod midi port",1,16,1)
  params:set_action("mod_midi_port", function()
    m.pset_seq.update_mod_midi() 
  end)
  
  params:add_option("mod_midi_in","mod midi in",m.pset_seq.midi_device_list,1)
  params:set_action("mod_midi_in", function()
    m.pset_seq.update_mod_midi() 
  end)
  
  


  params:add_option("pset_seq_enabled","pset seq enabled", {"false", "true"})
  params:set_action("pset_seq_enabled", function(x) 
    if x == 2 then
      m.pset_seq.initializing_pset_seq_timer = true
      metro.free(m.pset_seq.pset_seq_timer.props.id)
      m.pset_seq.set_pset_seq_timer()
      m.pset_seq.set_pset_last()
      m.pset_seq.set_pset_first()
      m.pset_seq.initializing_pset_seq_timer = false
    end
  end )

  params:add_option("pset_seq_mode","pset seq mode", {"loop", "up/down", "random"})
  params:add_number("load_pset", "load pset", 1, m.pset_seq.get_num_psets(),1,nil, false, false)

  params:set_action("load_pset", function(x) 
    m.pset_seq.set_num_psets()
    m.pset_seq.get_num_psets() 
    local param = params:lookup_param("load_pset")
    param.max = m.pset_seq.get_num_psets() 
    
    if x>param.max then 
      x = param.max 
      param.value = param.max 
    end
    params.value = x
    params:read(x)
    param.value = x
  
  end )
  
  params:add_number("pset_seq_beats", "pset seq beats", 1, 16, 4)
  params:set_action("pset_seq_beats", function() 
    m.pset_seq.set_ticks_per_seq_cycle() 
  end )
  params:add_number("pset_seq_beats_per_bar", "pset seq beats per bar", 1, 4, 1)
  params:set_action("pset_seq_beats_per_bar", function() m.pset_seq.set_ticks_per_seq_cycle() end )

  function m.pset_seq.set_pset_first(val)
    m.pset_seq.set_num_psets()    
    local first = params:lookup_param("pset_first")
    first.max = m.pset_seq.get_num_psets()

    if first.value == 0 then
      params:set("pset_first",1) 
    elseif first.value > first.max then 
      params:set("pset_first",first.max) 
    end

    if val then
      local clamped_val = util.clamp(val,1,params:get("pset_last"))
      if val > clamped_val then 
        params:set("pset_first",clamped_val) 
      end
    end
  end
    
  function m.pset_seq.set_pset_last(val)
    m.pset_seq.set_num_psets()    
    local last = params:lookup_param("pset_last")
    last.max = m.pset_seq.get_num_psets()
    
    if last.value == 0 or last.value > last.max then
      params:set("pset_last",last.max) 
    end
    if val then
      local clamped_val = util.clamp(val,params:get("pset_first"), last.max)
      if val < clamped_val then 
        params:set("pset_last", clamped_val) 
      end
    end
  end

  params:add_number("pset_first", "first", 1, m.pset_seq.get_num_psets(), 1)
  params:set_action("pset_first", function(val) 
    m.pset_seq.set_pset_first(val)
    m.pset_seq.set_pset_last()
  end )
  

  params:add_number("pset_last", "last", 1, m.pset_seq.get_num_psets(), m.pset_seq.get_num_psets())
  params:set_action("pset_last", function(val) 
    m.pset_seq.set_pset_last(val)
    m.pset_seq.set_pset_first()
  end )
  
  params:add_trigger("reset_first_lst_ranges","<<reset first/last ranges>>")
  params:set_action("reset_first_lst_ranges", function() 
    m.pset_seq.set_pset_last(val)
    m.pset_seq.set_pset_first()
  end )

  
  
  -- set default exclusions 
  -- INCLUDES HACK FOR FLORA to exclude plow screen params max level & max time by default until envelope PSET bug is fixed
  if m.pset_seq.pset_path == "/flora" then
    m.pset_seq.default_exclusions = {"pset_seq_enabled","pset_seq_mode","load_pset", "pset_seq_beats","pset_seq_beats_per_bar","plow1_max_level","plow1_max_time","plow2_max_level","plow2_max_time"}
  else
    m.pset_seq.default_exclusions = {"pset_seq_enabled","pset_seq_mode","load_pset", "pset_seq_beats","pset_seq_beats_per_bar", "pset_first", "pset_last"}
  end
  m.pset_seq.set_save_paramlist(m.pset_seq.default_exclusions, false)

  -- set the custom pset exclusions (defined in the script's main lua file, e.g., `flora.lua`)
  if pset_exclusion_tables then
    params:add_separator("pset exclusions")
    m.pset_seq.set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  end
  
  -- end pset sequence timer
  m.pset_seq.set_pset_seq_timer()
  m.pset_seq.inited = true
end


-------------------------------
-- mod integration
-------------------------------


m.key=function(n,z)
  if n==2 and z==1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
  if n==3 and z==1 then
    
  end
  mod.menu.redraw()
end

m.enc=function(n,d)
  if d>0 then 
    d=1 
  elseif d<0 then 
    d=-1 
  end
  state.x=util.clamp(state.x+d,1,4)
  mod.menu.redraw()
end

m.redraw=function()
  -- local yy=-8
  -- screen.clear()
  -- screen.level(state.x==1 and 15 or 5)
  -- screen.move(64,20+yy)
  -- screen.text_center(state.is_running and "online" or "offline")
  -- if state.station~="" then
  --   screen.level(5)
  --   screen.move(64,32+yy)
  --   screen.text_center("broadcast.norns.online/")
  --   screen.move(64,40+yy)
  --   screen.text_center(state.station..".mp3")
  -- end
  -- screen.level(state.x==2 and 15 or 5)
  -- screen.move(64,52+yy)
  -- screen.text_center("edit station name")
  -- screen.level(state.x==3 and 15 or 5)
  -- screen.move(35,62+yy)
  -- screen.text_center("advertise:"..state.advertise)
  -- screen.level(state.x==4 and 15 or 5)
  -- screen.move(36+64,62+yy)
  -- screen.text_center("archive:"..state.archive)
  screen.update()
end

m.init=function()
  
end -- on menu entry, ie, if you wanted to start timers

m.deinit=function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name,m)

--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api={}

api.get_state=function()
  return state
end

return api
