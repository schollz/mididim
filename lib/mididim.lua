local Mididim={}

function Mididim:debug(s)
  if mode_debug==true then
    print("mididim: "..s)
  end
end

function Mididim:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:reset()
  return o
end

function Mididim:reset()
  self:debug("initializing")
  self.is_recording=false
  self.is_playing=false
  if self.quantize==nil then
    self.quantize=0
  end
  self.memory={}
end

function Mididim:start()
  self.is_playing=true
  for i,v in ipairs(self.memory) do
    self.memory[i].played=false
  end
end

function Mididim:stop()
  self.is_playing=false
end

function Mididim:rec_start()
  self.memory={}
  self.is_recording=true
end

function Mididim:rec_stop()
  self.is_recording=false
  -- change the first beat to be beat 1
  local firstbeat=0
  for i,v in ipairs(self.memory) do
    if i==1 then
      firstbeat=v.beat
    end
    self.memory[i].beat=v.beat-firstbeat+1
  end
end

function Mididim:loop(loop_size)
  self.loop_size=loop_size
end

function Mididim:msg(d)
  if self.is_recording then
    table.insert(self.memory,d)
  end
end

function Mididim:play(m,beat)
  for i,v in ipairs(self.memory) do
    if not v.played and math.abs(v.beat-beat)<=self.quantize then
      self.memory[i].played=true
      if v.type=="note_on" then
        m:note_on(v.note,v.velocity,v.ch)
      elseif v.type=="note_off" then
        m:note_off(v.note,v.velocity,v.ch)
      elseif v.type=="pitchbend" then
        m:pitchbend(v.val,v.ch)
      elseif v.type=="key_pressure" then
        m:key_pressure(v.note,v.val,v.ch)
      elseif v.type=="channel_pressure" then
        m:channel_pressure(v.val,v.ch)
      end
    end
  end
end

-- return Mididim

mode_debug=true
m=Mididim:new()
