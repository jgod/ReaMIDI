dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")


-- Console for selecting notes
-- variables are...

--     p          c           v            l            tsn            tsd 
--   pitch     channel      velocity     length      timesig num   timesig denom

--     e2n                  nn                       ts
-- every 2nd note     named note (name)    time sig string, eg "3/4"

--                 nth(n)
--      type "nth(3)" for every 3rd note/chord 

-- so input "l<2 and v>5 and c==1 and tns==5 and tsd==8" should select notes of length smaller than 2
-- (beats) with a velocity greater than 5 on channel 1 if the time sig is 5/8

-- Works from the arrange or the MIDI editor.
function nth(x)
  return (nct%x==1) 
end

local function eval(str) 
  return load('return ('..str..')')() 
end 

p, c, v, l, tsn, tsd, ts, e2n=nil --need globals for load() to work
nn=""
nc=0
nct=0 --note count time dependant
function console(str)
  local target,notes=getTargetNotes(false, false)
  -- see midi.lua for available note parameters
  local cnt=0
  e2n=false
  if #notes>0 then
    local n
    local tolerance=0.07 -- in quarter notes
    for i=1,#notes,1 do
      nc=nc+1
      n=notes[i]
      if i>1 and n.startpos>notes[i-1].startpos+tolerance and n.tk==notes[i-1].tk then
        nct=nct+1
      end
      nn=reaper.GetTrackMIDINoteName(n.tr_num-1,n.pitch,0)
      if nn==nil then nn="" else nn=string.lower(nn) end
      p=n.pitch  c=n.chan  v=n.vel  l=n.len  tsn=n.ts_num   tsd=n.ts_denom
      ts=tostring(n.ts_num).."/"..tostring(n.ts_denom)
      if eval(str) then
        selectEvent(n,true)
        cnt=cnt+1
      else
        selectEvent(n,false)
      end
      e2n=not e2n
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
  --if str:find('^[vladsnortedpcp%d%<%>%=%s%.%~_]+$')~=nil then
  if str~="" then console(str) else exit=true end
  --else
  --  if exit==false then getValues() end
  --end
end
--retvals=trimWs(retvals)

reaper.Undo_BeginBlock()
if exit==false then getValues() end
reaper.UpdateArrange()
reaper.Undo_EndBlock("Select Console", -1)
