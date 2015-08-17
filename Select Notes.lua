dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\target.lua")

local target, takes=getTargetTakes() --from target.lua

-- tr=tr, tk=tk, idx=cnt, meas=measure, meas_start=meas_start,beat=beat, 
-- ts_num=num,ts_denom=denom, qn_in_meas=qnpm, sel=sel, mute=mute, osq=sq, sq=sq, 
-- eq=eq, len=eq-sq, 
-- pitch=pitch, sel=sel, chan=chan, vel=vel
if target==targets.MIDIEditor then
  local notes=getNotes(takes,true,false)
  if #notes>0 then
    local n
    local tolerance=0.07 -- in quarter notes
    for i=1,#notes,1 do 
      n=notes[i]
      -- notes that are within the tolerance of start of measure
      -- respects time signatures
      if math.abs(n.startpos-n.meas_startpos)<tolerance or 
                  math.abs(n.startpos-n.meas_startpos)>n.qn_in_meas-tolerance then
        selectEvent(n,true)
      else
        selectEvent(n,false)
      end
    end
    createItem(n.tk,true,notes)
    --setNotes(notes)
  end
end

-- local cp = getCursorPositionQN()
reaper.UpdateArrange()