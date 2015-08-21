dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")


-- tr=tr, tk=tk, idx=cnt, meas=measure, meas_start=meas_start,beat=beat, 
-- ts_num=num,ts_denom=denom, qn_in_meas=qnpm, sel=sel, mute=mute, osq=sq, sq=sq, 
-- eq=eq, len=eq-sq, 
-- pitch=pitch, sel=sel, chan=chan, vel=vel

local target,notes=getTargetNotes(false)
_DBG=true
if #notes>0 then
  local n
  local tolerance=0.07 -- in quarter notes
  for i=1,#notes,1 do 
    n=notes[i]
    DBG("n.ts_num: "..n.ts_num.."   n.ts_denom: "..n.ts_denom)
    -- notes that are within the tolerance of start of measure
    -- and it's a waltz - boom cha cha!
    if (math.abs(n.startpos-n.meas_startpos)<tolerance or 
                math.abs(n.startpos-n.meas_startpos)>n.qn_in_meas-tolerance) 
                and (n.ts_num==3 and n.ts_denom==4) then
      
      
      selectEvent(n,true)
    else
      selectEvent(n,false)
    end
  end
  --createItem(n.tk,true,notes)
  --setNotes(notes)
  DBG("\n\n")
end


-- local cp = getCursorPositionQN()
reaper.UpdateArrange()