dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")


 --from target.lua

-- tr=tr, tk=tk, idx=cnt, meas=measure, meas_start=meas_start,beat=beat, 
-- ts_num=num,ts_denom=denom, qn_in_meas=qnpm, sel=sel, mute=mute, osq=sq, sq=sq, 
-- eq=eq, len=eq-sq, 
-- pitch=pitch, sel=sel, chan=chan, vel=vel
function createItemsFromSelectedNotes()
  local target, notes=getTargetNotes()
  
  if #notes==0 then return nil end
  local tk,n
  local tk_notes={}
  
  tk_notes[1]=notes[1]
  if #notes>1 then
    for i=2,#notes,1 do 
      n=notes[i]
      if n.tk~=tk_notes[#tk_notes].tk then
        createItem(tk_notes[#tk_notes].tk,true,tk_notes)
		deleteNotes(tk_notes)
        tk_notes={}
      end
      tk_notes[#tk_notes+1]=n
    end
  end
  if #tk_notes>0 then 
    createItem(tk_notes[1].tk,true,tk_notes)
	deleteNotes(tk_notes)
  end
end

createItemsFromSelectedNotes()
reaper.UpdateArrange()