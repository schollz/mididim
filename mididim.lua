-- mididim v0.1.0
-- record midi loops
--
-- llllllll.co/t/mididim
--
--
--
--    ▼ instructions below ▼

mode_debug=true

--json
print(_VERSION)
print(package.cpath)
if not string.find(package.cpath,"/home/we/dust/code/mididim/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/mididim/lib/?.so"
end
json=require("cjson")

include("lib/utils")
musicutil=require "musicutil"
lattice=require "lattice"
mididim=include("lib/mididim")

dev_list={}

function init()
  -- connect to the midi devices
  local mididims={}
  for _,dev in pairs(midi.devices) do
    print("connected to "..dev.name)
    table.insert(dev_list,dev.name)
    local m=midi.connect(dev.port)
    mididims[dev.name]=mididim:new({m=m,name=dev.name})
    -- m.event is a special function that runs on incoming midi msgs
    m.event=function(data)
      local d=midi.to_msg(data)
      mididims[dev.name]:msg(d)
    end
  end

  -- setup parameters
  params:add{type="option",id="selected",name="selected",
    options=dev_list,
    action=function(v)
    end
  }

  latticeclock=lattice:new()
  local division=1/16
  latticeclock:new_pattern{
    division=division,
    action=function(t)
      local beat=t/latticeclock.ppqn -- get beat by dividing by parts-per-quarternote
      for k,v in pairs(mididims) do
        v:play(beat)
      end
    end
  }
  latticeclock:start()

  -- update drawing
  clock.run(redrawer)
end

function key(k,z)
  if k==2 and z==1 then
    mididims[dev_list[params:get("selected")]]:play_toggle()
  elseif k==3 and z==2 then
    mididims[dev_list[params:get("selected")]]:rec_toggle()
  end
end

function enc(k,d)
  if k==3 then
    mididims[dev_list[params:get("selected")]]:loop_change(math.sign(d))
  elseif k==2 then
    params:delta("selected",math.sign(d))
  end
end

function redraw()
  screen.clear()
  screen.font_size(8)
  for i,v in ipairs(dev_list) do
    screen.level(7)
    if i==params:get("selected") then
      screen.level(15)
    end
    screen.move(16,20+(i-1))
    local playing=""
    if mididims[v].is_playing then
      playing="play"
    elseif mididims[v].is_recording then
      playing="rec"
    end
    screen.text(v.." ("..mididims[v].loop_size.."): "..playing)
  end
  screen.update()
end

function redrawer()
  while true do
    clock.sleep(1/15)
    redraw()
  end
end
