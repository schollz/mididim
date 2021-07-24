local Mididim={}

function Mididim:debug(s)
  if mode_debug==true then
    print("mididim ["..self.name.."]: "..s)
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
    self.quantize=1/16
  end
  self.on={}
  self.memory={}
  self.memory_lt={}
  self:reset_note_ons()
  self.loop_size=4
  self.last_beat=10000
  self.last_global_beat=0
end

function Mididim:reset_note_ons()
  for k,v in pairs(self.on) do
    self.m:note_off(v.note,v.velocity,v.ch)
    self.on[k]=nil
  end
  self.on={}
end

function Mididim:play_start()
  self:debug("start playing")
  self.is_playing=true
  self.beat=1000
end

function Mididim:play_stop()
  self:debug("stop playing")
  self.is_playing=false
  self:reset_note_ons()
end

function Mididim:play_toggle()
  if is_recording then
    self:rec_stop()
  end
  if not self.is_playing then
    self:play_start()
  else
    self:play_stop()
  end
end

function Mididim:rec_toggle()
  if is_playing then
    self:play_stop()
  end
  if self.is_recording then
    self:rec_stop()
  else
    self:rec_start()
  end
end

function Mididim:rec_start()
  self.memory={}
  self.memory_lt={}
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
  self.memory_lt=table.copy(self.memory)
end

function Mididim:loop(loop_size)
  self.loop_size=loop_size
end

function Mididim:loop_change(delta)
  self.loop_size=self.loop_size+delta
end

function Mididim:msg(d)
  if self.is_recording then
    if d.type=="note_on" or d.type=="note_off"
      or d.type=="pitchbend" or d.type=="key_pressure"
      or d.type=="channel_pressure" then
      d.beat=clock.get_beats()
      self:debug("recording "..d.type.." on beat "..d.beat)
      table.insert(self.memory,d)
    end
  end
end
-- tab.print(mididims['OP-1 Midi Device'])
-- tab.print(mididims['OP-1 Midi Device'].memory)

-- unique_notes returns a table of the unique notes in long-term memory
function Mididim:unique_notes()
  local have={}
  local notes={}
  for i,v in ipairs(self.memory_lt) do
    if v.type=="note_on" then
      if have[v.note]==nil then
        table.insert(notes,v.note)
        have[v.note]=true
      end
    end
  end
end

-- mutate_note will transform a note at position i in memory to new_note
function Mididim:mutate_note(i,new_note)
  if self.memory[i]==nil then
    do return end
  end
  if self.memory[i].type~="note_on" then
    do return end
  end
  local n=self.memory[i].note
  self.memory[i].note=new_note
  -- go through and replace the note_off with the new note
  for j,v in ipairs(self.memory) do
    if j>i and v.type=="note_off" and v.note==n then
      self.memory[j].note=new_note
    end
  end
end

function Mididim:emit(global_beat)
  if not self.is_playing then
    do return end
  end
  local beat=(global_beat-1)%self.loop_size+1 -- (beats in range [1,loop_size])
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
    if (not v.played) and beat-v.beat>-1/128 then
      self:debug(v.type.." "..v.note.." on beat "..beat)
      self.memory[i].played=true
      if v.type=="note_on" then
        self.m:note_on(v.note,v.velocity,v.ch)
        self.on[v.note]={note=v.note,velocity=v.velocity,ch=v.ch,beat=beat}
      elseif v.type=="note_off" then
        self.m:note_off(v.note,v.velocity,v.ch)
        self.on[v.note]=nil
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
