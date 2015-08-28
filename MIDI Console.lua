dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\strings.lua")

-- MIDI Console for selecting and/or changing notes
-- variables are...

--     p          c           v            l            tsn            tsd 
--   pitch     channel      velocity     length      timesig num   timesig denom

--     e2n                  nn                       ts
-- every 2nd note     named note (name)    time sig string, eg "3/4"

--                 nth(n)
--      type "nth(3)" for every 3rd note/chord 

-- so input "l<2 and v>5 and c==1 and tns==5 and tsd==8" should select notes of length smaller than 2
-- (beats) with a velocity greater than 5 on channel 1 if the time sig is 5/8

-- if you follow that with a colon then you can change the selected note

-- eg   c==10:l=1
-- sets the length of everything on channel 10 to 1 QN

function nth(x)
  return (nct%x==1) 
end

local function eval(str) 
  return load('return ('..str..')')() 
end

local function process(str)
  load(str)()
end


local function lim(val,low_lim,upp_lim)
  if val>=low_lim and val<=upp_lim then return val end
  if val<low_lim then return low_lim else return upp_lim end
end


p, c, v, l, tsn, tsd, ts, e2n=nil --need globals for load() to work
nn=""
nc=0
nct=0 --note count time dependant
function console(str, act, select_if_true)
  local target,notes=getTargetNotes(false, false)
  -- see midi.lua for available note parameters
  local cnt=0
  e2n=false
  if #notes>0 then
    local n
    local tolerance=0.07 -- in quarter notes
    local last_tk
    local tk_notes={}
    if #notes>0 then last_tk=notes[1].tk end
    for i=1,#notes,1 do
      nc=nc+1
      n=notes[i]
      if i>1 and n.startpos>notes[i-1].startpos+tolerance and n.tk==notes[i-1].tk then
        nct=nct+1
      end
      nn=reaper.GetTrackMIDINoteName(n.tr_num-1,n.pitch,0)
      if nn==nil then nn="" else nn=string.lower(nn) end
      p=n.pitch  c=n.chan+1  v=n.vel  l=n.len  tsn=n.ts_num   tsd=n.ts_denom
      ts=tostring(n.ts_num).."/"..tostring(n.ts_denom)
      if eval(str) then
        if act~="" then
          process(act)
          -- setting channel only seems to work reliably when MIDI editor
          -- is set to all channels
          n.pitch=lim(p,0,127)   n.chan=lim(c-1,0,15)   n.vel=lim(v,0,127)   
          n.len=l  n.endpos=n.startpos+l n.sel=true
          tk_notes[#tk_notes+1]=n
        else
          if select_if_true then selectEvent(n,true) end
        end
        cnt=cnt+1
      else
        if select_if_true then selectEvent(n,false) end
      end
      e2n=not e2n
      if n.tk~=last_tk then
        if #tk_notes>0 then setNotes(tk_notes) end
        tk_notes={}
        reaper.MIDI_Sort(last_tk) 
      end
      last_tk=n.tk
    end
    if #tk_notes>0 then setNotes(tk_notes) reaper.MIDI_Sort(tk_notes[1].tk) end
    reaper.TrackCtl_SetToolTip(tostring(cnt).." note(s) selected", 800,2, true)
  else
    reaper.TrackCtl_SetToolTip("No target notes (need selected, active MIDI take(s) or active MIDI editor)", 800,2, true)
  end
end

local exit=false

function getValues()
  ok,retvals=""
  
  ok, retvals=reaper.GetUserInputs("MIDI Console",1,"Search:Action:","")
  if not ok then exit=true end
  local str=string.lower(retvals)
  
  if str~="" then 
    local sections=retvals:split(":")
    if #sections==1 then sections[2]="" end
    console(sections[1],sections[2],true) 
  else
    exit=true 
  end
end


reaper.Undo_BeginBlock()
if exit==false then getValues() end
reaper.UpdateArrange()
reaper.Undo_EndBlock("MIDI Console", -1)
