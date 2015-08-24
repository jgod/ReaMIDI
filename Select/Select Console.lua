dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")


-- Console for selecting notes
-- variables are...

--     p          c           v            l            tsn            tsd 
--   pitch     channel      velocity     length      timesig num   timesig denom

-- so input "l<2 and v>5 and c==1 and tns=5 and tsd=8" will select notes of length smaller than 2
-- (beats) with a velocity greater than 5 on channel 1 if the time sig is 5/8

-- Works rom the arrange of the MIDI editor.

local function eval(str) 
  return load('return '..str)() 
end 

p, c, v, l, tsn, tsd=nil --need globals for load() to work
function console(str)
  local target,notes=getTargetNotes(false)
  -- tr=tr, tk=tk, idx=cnt, meas=measure, meas_start=meas_start,beat=beat, 
  -- ts_num=num,ts_denom=denom, qn_in_meas=qnpm, sel=sel, mute=mute, osq=sq, sq=sq, 
  -- eq=eq, len=eq-sq, 
  -- pitch=pitch, sel=sel, chan=chan, vel=vel
  local cnt=0
  if #notes>0 then
    local n
    local tolerance=0.07 -- in quarter notes
    for i=1,#notes,1 do
      n=notes[i]
      p=n.pitch  c=n.chan  v=n.vel  l=n.len  tsn=n.ts_num   tsd=n.ts_denom
      if eval(str) then
        selectEvent(n,true)
        cnt=cnt+1
      else
        selectEvent(n,false)
      end
    end
    reaper.TrackCtl_SetToolTip(tostring(cnt).." note(s) selected", 800,2, true)
  else
    reaper.TrackCtl_SetToolTip("No target notes (need selected, active MIDI take(s) or active MIDI editor)", 800,2, true)
  end
end

local exit=false

function getValues()
  ok,retvals=""
  
  ok, retvals=reaper.GetUserInputs("Select Console",1,"Condition(s):","")
  if not ok then exit=true end
  local str=string.lower(retvals)
  if str:find('^[vladsnortedpcp%d%<%>%=%s%.%~_]+$')~=nil then
    console(str)
  else
    if exit==false then getValues() end
  end
end
--retvals=trimWs(retvals)

reaper.Undo_BeginBlock()
if exit==false then getValues() end
reaper.UpdateArrange()
reaper.Undo_EndBlock("Select Console", -1)
