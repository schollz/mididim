-- mididim v0.1.0
-- record midi loops
--
-- llllllll.co/t/mididim
--
--
--
--    ▼ instructions below ▼

musicutil=require "musicutil"
lattice=require "lattice"
mididim=include("lib/mididim")

function init()
  -- connect to the midi devices
  local mididims={}
  for _,dev in pairs(midi.devices) do
    print("connected to "..dev.name)
    local m=midi.connect(dev.port)
    mididims[dev.name]=mididim:new({m=m,name=dev.name})
    -- m.event is a special function that runs on incoming midi msgs
    m.event=function(data)
      local d=midi.to_msg(data)
      mididims[dev.name]:msg(d)
    end
  end

  latticeclock=lattice:new()
  local division=1/16
  latticeclock:new_pattern{
    division=division,
    action=function(t)
      local beat=t/latticeclock.ppqn -- get beat by dividing by parts-per-quarternote
      print("beat: "..beat)
      for k,v in pairs(mididims) do
        v:play(beat)
      end
    end
  }
  latticeclock:start()

end

