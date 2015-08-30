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
  return load([[return (]]..str..[[)]])() 
end


local function process(str)
  load(str)()
end

--_DBG=true
DBG("---------------------------------------------------")
local bpos_qn=0
function beat(...)
  local tsa=n.ts_denom/4 -- don't adjust tolerance by this to avoid
                         -- it being too small when ts_denom>4
                         -- except where range of beats is supplied
  local tol_l=tolerance
  local tol_r=tolerance
  local args=table.pack(...)
  for k,v in pairs(args) do
    if k==1 then x=v end
    if k==2 then 
      tol_l=(v/tsa)+tolerance
      tol_lqn=v+tolerance
      tol_r=(v/tsa)
    end
  end
  bpos_qn=n.meas_startpos+(x-1)/tsa
    -- range extends left beyond measure start
  if x-tol_l<=1 then
    DBG("Poss early notes in prev measure")
    -- CHECK qn vs beats for different time sigs here too!!!
    if ((n.startpos-n.meas_startpos)>n.qn_in_meas-math.abs(x-1-tol_l)) then
      DBG("Early beat before bar")
      return true
    end
  end
  
  return (((n.startpos-bpos_qn)<tol_r) and 
            (bpos_qn-n.startpos)<tol_l)
end


function qn(x)
  if x<(0+tolerance) then
    return (math.abs(n.startpos-n.meas_startpos)<tolerance or 
                math.abs(n.startpos-n.meas_startpos)>n.qn_in_meas-tolerance)
  else
   
    return (n.startpos-(n.meas_startpos+(x)))<tolerance and
                 ((n.meas_startpos+(x))-n.startpos<tolerance)
  end 
end

local run_legato=false
function leg()
  if run_legato==false then
    dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\legato.lua")
  end
  run_legato=true
end

local function lim(val,low_lim,upp_lim)
  if val>=low_lim and val<=upp_lim then return val end
  if val<low_lim then return low_lim else return upp_lim end
end


--need globals for load() to work
tolerance=0.07 -- in quarter notes
p, c, v, l, tsn, tsd, ts, e2n=nil 
nn=""
all=true
nc=0
n={}
nct=0 --note count time dependant
function console(str, act, final, select_if_true)
  local target,notes=getTargetNotes(false, false)
  -- see midi.lua for available note parameters
  local cnt=0
  e2n=false
  if #notes>0 then
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
          n.pitch=lim(p,0,127)   n.chan=lim(c-1,0,15)   n.vel=math.floor(lim(v,0,127))  
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
        if #tk_notes>0 then 
          if run_legato==true then 
            legato(tk_notes,false,false) 
          else
            setNotes(tk_notes)
          end
        end
        tk_notes={}
        reaper.MIDI_Sort(last_tk) 
      end
      last_tk=n.tk
    end
    if #tk_notes>0 then 
      if run_legato==true then 
        legato(tk_notes,false,false)
      else
        setNotes(tk_notes) 
        reaper.MIDI_Sort(tk_notes[1].tk) 
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
  
  ok, retvals=reaper.GetUserInputs("MIDI Console",1,"Search:Action:","")
  if not ok then exit=true end
  local str=string.lower(retvals)
  
  if str~="" then
    local sections=str:split(":")
    if #sections==1 then
      if str=="" then 
        str="all"
        console(str,"","",true)
      else
        if str=="h" or str=="help" then
          os.execute(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\docs\\help.html")
        end
      end        
    end
    if #sections==2 then
      if sections[1]=="" then sections[1]="all" end
      if sections[2]:find('^[cmd]+$')==nil then -- 2 sections, but second is really third - [c]opy/[m]ove/[d]elete command
        console(sections[1],sections[2],"",true)
      else
        console(sections[1],"",sections[2],"",true)
      end
    end
    if #sections==3 then
        console(sections[1],sections[2],sections[3],true)
    end
  else
    exit=true 
  end
end


reaper.Undo_BeginBlock()
if exit==false then getValues() end
reaper.UpdateArrange()
reaper.Undo_EndBlock("MIDI Console", -1)
