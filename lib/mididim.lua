local Mididim={}

function Mididim:debug(s)
  if mode_debug==true then
    print("mididim: "..s)
  end
end

function Mididim:new(o)
  -- need to set m
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
  self:reset_note_ons()
end

function Mididim:reset_note_ons()
  for k,v in pairs(self.on) do
    self.m:note_off(v.note,v.velocity,v.ch)
    self.on[k]=nil
  end
  self.on={}
end

function Mididim:start()
  self.is_playing=true
  self.beat=1000
end

function Mididim:stop()
  self.is_playing=false
end

function Mididim:rec_start()
  self.memory={}
  self.is_recording=true
  self.is_playing=false
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
    if d.type=="note_on" or d.type=="note_off"
      or d.type=="pitchbend" or d.type=="key_pressure"
      or d.type=="channel_pressure" then
      table.insert(self.memory,d)
    end
  end
end

function Mididim:play(global_beat)
  if not self.is_playing then
    do return end
  end
  local beat=global_beat%self.loop_size+1 -- (beats in range [1,loop_size])
  if beat<self.last_beat then
    -- new loop, reset everything
    for i,v in ipairs(self.memory) do
      self.memory[i].played=false
    end
    -- reset any playing notes
    self:reset_note_ons()
  end
  self.last_beat=beat
  for i,v in ipairs(self.memory) do
    if (not v.played) and math.abs(v.beat-beat)<=self.quantize then
      self.memory[i].played=true
      if v.type=="note_on" then
        self.m:note_on(v.note,v.velocity,v.ch)
        self.on[v.note]={note=v.note,velocity=v.velocity,ch=v.ch}
      elseif v.type=="note_off" then
        self.m:note_off(v.note,v.velocity,v.ch)
        self.off[v.note]=nil
      elseif v.type=="pitchbend" then
        self.m:pitchbend(v.val,v.ch)
      elseif v.type=="key_pressure" then
        self.m:key_pressure(v.note,v.val,v.ch)
      elseif v.type=="channel_pressure" then
        self.m:channel_pressure(v.val,v.ch)
      end
    end
  end
end

return Mididim
