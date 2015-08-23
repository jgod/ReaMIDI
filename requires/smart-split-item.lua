if _DEF_SPLIT_MIDI_~=true then
_DEF_SPLIT_MIDI_=true


dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

function uberSplitItem(item, split_pos, catch_early_notes_limit, extend_right, select_left, select_right)
  --get list of midi takes
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
  local rit
  if is_midi==false then
    rit=reaper.SplitMediaItem(item,split_pos)
    reaper.SetMediaItemSelected(item, false)
	  return
  end
  
  local n
  --local notes={}
  local ntc,notes={}
  local spQN=reaper.TimeMap2_timeToQN(0,split_pos)
  _DBG=true
  DBG("spQN: "..spQN)
  local ENPOS=1000000 --big default value so first earliest note pos will be smaller
  local en_pos=ENPOS --earliest note pos, to extend right hand item left by
  for i=1,#tks,1 do
    notes=getNotes({tks[i].tk},false,false)
    if catch_early_notes_limit>0 then
      for ii=1,#notes,1 do
        n=notes[ii]
        if n.startpos>spQN-catch_early_notes_limit and n.startpos<en_pos then 
          en_pos=n.startpos
        end
      end
    end
    for ii=1,#notes,1 do
      n=notes[ii]
      if n.startpos<=spQN and n.endpos>spQN then
        ntc[#ntc+1]=n
        reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, en_pos),--reaper.TimeMap2_timeToQN(0,split_pos)),--reaper.TimeMap2_timeToQN(0,split_pos)),
              n.chan, n.pitch,n.vel,nil,true)
      end
    end
  end
  
  ---[[
  if catch_early_notes_limit>0 and en_pos<spQN then
    split_pos=reaper.TimeMap2_QNToTime(0,en_pos)
  else
    split_pos=reaper.TimeMap2_QNToTime(0,spQN)
  end
  
  --split_pos=reaper.TimeMap2_QNToTime(0,spQN)
  
  --right hand side of split item returned here
  rit=reaper.SplitMediaItem(item,split_pos)
  
  --_DBG=true
  local last_note={endpos=-1,tk=-1}
  local ispos,riepos
  local l_note=0
  --local e_note=10000 --longest and earliest
  
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
           l_note)
    end
    
    --[[if catch_early_notes_limit>0 then
      if n.tk~=last_note.tk or n.startpos<e_note then
        e_note=n.startpos
        riepos=reaper.GetMediaItemInfo_Value(rit, "D_POSITION")+reaper.GetMediaItemInfo_Value(rit,"D_LENGTH")
        reaper.MIDI_SetItemExtents(item,e_note, riepos)
      end
    end
    --]]
 
    reaper.MIDI_SetNote(n.tk,n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos),
            n.chan,n.pitch,n.vel,nil,true)
    if i~=1 and n.tk~=last_note.tk then reaper.MIDI_Sort() end
    last_note.tk=n.tk
  end
  if extend_right==false then 
    reaper.MIDI_SetItemExtents(item,reaper.TimeMap2_timeToQN(0,ispos), spQN)
  end
  --unselect left item
  if not select_left then reaper.SetMediaItemSelected(item, false) end
  if not select_right then reaper.SetMediaItemSelected(rit, false) end
end  
        

--ifdef
end