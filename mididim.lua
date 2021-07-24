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
mididims={}
dev_list={}
metronome={level=0}

engine.name="PolyPerc"

function init()
  -- initiate metronome
  engine.release(0.15)
  -- connect to the midi devices

  for i,dev in ipairs(midi.devices) do
    if dev.name~="virtual" then
      print("connected to "..dev.name)
      table.insert(dev_list,dev.name)
      local m=midi.connect(dev.port)
      mididims[dev.name]=mididim:new({m=m,name=dev.name,id=i})
      -- m.event is a special function that runs on incoming midi msgs
      m.event=function(data)
        local d=midi.to_msg(data)
        mididims[dev.name]:msg(d)
      end
    end
  end

  -- setup parameters
  params:add{type="control",id="metronome",name="metronome",
    controlspec=controlspec.new(0,64,'lin',0,0,'',1/64),
    action=function(v)
    end
  }
  params:add{type="option",id="selected",name="selected",
    options=dev_list,
    action=function(v)
    end
  }

  latticeclock=lattice:new()
  latticeclock:new_pattern{
    division=1/96,
    action=function(t)
      local beat=t/latticeclock.ppqn -- get beat by dividing by parts-per-quarternote
      if beat==math.floor(beat) and params:get("metronome")>0 then
        engine.hz(util.linexp(0,64,60,4000,params:get("metronome")))
      end
      for k,v in pairs(mididims) do
        v:emit(beat)
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
  elseif k==3 and z==1 then
    mididims[dev_list[params:get("selected")]]:rec_toggle()
  end
end

function enc(k,d)
  if k==3 then
    mididims[dev_list[params:get("selected")]]:loop_change(math.sign(d))
  elseif k==2 then
    params:delta("selected",d)
  elseif k==1 then
    params:delta("metronome",d)
  end
end

function redraw()
  screen.clear()
  screen.font_size(8)
  for k,v in pairs(mididims) do
    screen.level(7)
    if v.id==params:get("selected") then
      screen.level(15)
    end
    local playing=""
    if v.is_playing then
      playing="play"
    elseif v.is_recording then
      playing="rec"
    end
    screen.move(16,20+(v.id-1)*10)
    screen.text(k.." ("..v.loop_size.."): "..playing)
  end
  -- draw metronome level
  screen.level(15)
  for ii=127,128 do
    screen.move(ii,64-params:get("metronome"))
    screen.line(ii,64)
  end
  screen.stroke()

  screen.update()
end

function redrawer()
  while true do
    clock.sleep(1/15)
    redraw()
  end
end
