if _DEF_SPLIT_MIDI_~=true then
_DEF_SPLIT_MIDI_=true


dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

function uberSplitItem(item, split_pos, extend_split_item, select_left, select_right)
  local tk
  local tks={tk,tk_num}
  local is_midi=false
  for i=1,reaper.GetMediaItemNumTakes(item),1 do
    tk=reaper.GetMediaItemTake(item,i-1)
    if reaper.TakeIsMIDI(tk)==true then
      is_midi=true
      tks[#tks+1]={}
      tks[#tks].tk=tk
      tks[#tks].tk_num=i-1
      tks[#tks].altered=false
    end
  end
  if is_midi==false then
    _=reaper.SplitMediaItem(item,split_pos)
    reaper.SetMediaItemSelected(item, false)
	  return
  end
  
  local n
  
  local rea=0.0000000001  --rounding error adjust
  
  --local notes={}
  local spQN=reaper.TimeMap2_timeToQN(0,split_pos)
  local ntc,notes={}
  for i=1,#tks,1 do
    notes=getNotes({tks[i].tk},false,false)
  
    for ii=1,#notes,1 do
      n=notes[ii]
      -- adjust for rounding error thing where 8<8
      if n.startpos+rea<spQN and n.endpos-rea>spQN then
        ntc[#ntc+1]=n
        reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, spQN),
              n.chan, n.pitch,n.vel,nil,true)
      end
    end
  end
  
  
  --right hand side of split item returned here
  local rit=reaper.SplitMediaItem(item,split_pos)
  
  --_DBG=true
  local last_note={endpos=-1,tk=-1}
  local ispos
  local l_note=0 -- el for longest
  --restore shortened notes in left (original) take to original length
  for i=1,#ntc,1 do
    n=ntc[i]
    -- have to move the item end with the extended notes or we break the note with
    -- the furthest end time (it becomes very, very long (oomment the MIDI_SetItemExtents
    -- lines out to see!))
    if n.tk~=last_note.tk or n.endpos>l_note then
      l_note=n.endpos
      ispos=reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      reaper.MIDI_SetItemExtents(item,reaper.TimeMap2_timeToQN(0,ispos),
           n.endpos)
    end
    
    reaper.MIDI_SetNote(n.tk,n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos),
            n.chan,n.pitch,n.vel,nil,true)
    if i~=1 and n.tk~=last_note.tk then reaper.MIDI_Sort() end
    last_note.tk=n.tk
  end
  if extend_split_item==false then 
    reaper.MIDI_SetItemExtents(item,reaper.TimeMap2_timeToQN(0,ispos),
         reaper.TimeMap2_timeToQN(0,split_pos))
  end
  --unselect left item
  if not select_left then reaper.SetMediaItemSelected(item, false) end
  if not select_right then reaper.SetMediaItemSelected(rit, false) end
end  
        

--ifdef
end