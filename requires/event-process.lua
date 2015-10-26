if _DEF_MIDI_PROCESS_~=true then
_DEF_MIDI_PROCESS_=true

dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\strings.lua")




function nth(...)
  local offs=0
  local args=table.pack(...)
  x=args[1]
  if #args==2 then
    offs=tonumber(args[2])
  end
  return ((ect-offs)%x==1) 
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
  local tsa=e.ts_denom/4 -- don't adjust tolerance by this to avoid
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
  bpos_qn=e.meas_startpos+(x-1)/tsa
    -- range extends left beyond measure start
  if x-tol_l<=1 then
    DBG("Poss early notes in prev measure")
    -- CHECK qn vs beats for different time sigs here too!!!
    if ((e.startpos-e.meas_startpos)>e.qn_in_meas-math.abs(x-1-tol_l)) then
      DBG("Early beat before bar")
      return true
    end
  end
  
  return (((e.startpos-bpos_qn)<tol_r) and 
            (bpos_qn-e.startpos)<tol_l)
end


function qn(x)
  if x<(0+tolerance) then
    return (math.abs(e.startpos-e.meas_startpos)<tolerance or 
                math.abs(e.startpos-e.meas_startpos)>n.qn_in_meas-tolerance)
  else
    return (e.startpos-(e.meas_startpos+(x)))<tolerance and
                 ((e.meas_startpos+(x))-e.startpos<tolerance)
  end 
end


local run_legato=false
function leg()
  if run_legato==false then
    dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\legato.lua")
  end
  run_legato=true
end


function lim(val,low_lim,upp_lim)
  if val>=low_lim and val<=upp_lim then return val end
  if val<low_lim then return low_lim else return upp_lim end
end


function ran(x,y,z)
  return x==lim(x,y,z)
end


--need globals for load() to work
tolerance=0.07 -- in quarter notes
rand=math.random
p, c, v, l, tsn, tsd, ts, e2n=nil 
nn=""
all=true
ec=0
ect=0 --event count time dependant
function eventProcess(str, act, final, select_if_true)
  local target,events=getTargetEvents(false, false)
  -- see midi.lua for available event parameters
  local cnt=0
  e2n=false
  if #events>0 then
    local last_tk
    local tk_events={}
    if #events>0 then last_tk=events[1].tk end
    for i=1,#events,1 do
      ec=ec+1
      e={}
      e=events[i]
      if i==1 or (i>1 and e.startpos>events[i-1].startpos+tolerance and e.tk==events[i-1].tk) then
        ect=ect+1
      end
      --nn=reaper.GetTrackMIDINoteName(n.tr_num-1,n.pitch,0)
      --if nn==nil then nn="" else nn=string.lower(nn) end
      --p=n.pitch  c=n.chan+1  v=n.vel  l=n.len  tsn=n.ts_num   tsd=n.ts_denom
      e.ts=tostring(e.ts_num).."/"..tostring(e.ts_denom)
      if eval(str) then
        if act~="" then
          process(act)
          -- setting channel only seems to work reliably when MIDI editor
          -- is set to all channels
          -- if select_if_true then selectEvent(e,true) end
          tk_events[#tk_events+1]=e
        else
          if select_if_true then selectEvent(e,true) end
        end
        cnt=cnt+1
      else
        if select_if_true then selectEvent(e,false) end
      end
      e2n=not e2n
      if e.tk~=last_tk then
        if #tk_events>0 then 
          setEvents(tk_events)
        end
        tk_events={}
        reaper.MIDI_Sort(last_tk) 
      end
      last_tk=e.tk
    end
    if #tk_events>0 then 
      setEvents(tk_events) 
      reaper.MIDI_Sort(tk_events[1].tk) 
    end
    reaper.TrackCtl_SetToolTip(tostring(cnt).." event(s) filtered/processed", 800,2, true)
  else
    reaper.TrackCtl_SetToolTip("No target events (need selected MIDI take/item(s) or active MIDI editor)", 800,2, true)
  end
  reaper.UpdateArrange()
end



--ifdef
end