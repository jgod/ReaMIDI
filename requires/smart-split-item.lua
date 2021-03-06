if _DEF_SPLIT_MIDI_~=true then
_DEF_SPLIT_MIDI_=true


dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/midi.lua")

function uberSplitItem(item, split_pos, catch_early_notes_limit, extend_right, select_left, select_right)
  --get list of midi takes
  local tk
  local tks={tk,tk_num}
  local is_midi=false
  for i=1,reaper.GetMediaItemNumTakes(item),1 do
    tk=reaper.GetMediaItemTake(item,i-1)
    if tk~=nil and reaper.TakeIsMIDI(tk)==true then
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
    reaper.SetMediaItemSelected(item, select_left)
    reaper.SetMediaItemSelected(rit, select_right)
	  return
  end
  
  local n
  --local notes={}
  local rea=0.00001 -- small adjustment values -- making bigger fixes r.h.s. item notes note playing
  local ntc,notes={}
  local spQN=reaper.TimeMap2_timeToQN(0,split_pos)
  _DBG=true
  local en_pos=spQN-rea -- earliest note for early split
  --get earliest early note start for item
  if catch_early_notes_limit>0 then 
    for i=1,#tks,1 do
      notes=getNotes({tks[i].tk},false,false)
      for ii=1,#notes,1 do
        n=notes[ii]
        if n.startpos-rea>spQN-catch_early_notes_limit and n.startpos+rea<en_pos+rea then 
          en_pos=n.startpos-rea --subtracting rea stops first note in right item cutting previous notes off
        end
      end
    end
  else
    en_pos=spQN-rea
  end
  
  for i=1,#tks,1 do
    notes=getNotes({tks[i].tk},false,false)
    for ii=1,#notes,1 do
      n=notes[ii]
      if n.startpos+rea<spQN-catch_early_notes_limit and n.endpos+rea>en_pos then
        ntc[#ntc+1]=n
        reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, en_pos),
              n.chan, n.pitch,n.vel,nil,true)
      end
    end
  end
  
 
  if catch_early_notes_limit>0 and en_pos<spQN then
    split_pos=reaper.TimeMap2_QNToTime(0,en_pos-rea)
  else
    split_pos=reaper.TimeMap2_QNToTime(0,spQN)
  end
  
  --right hand side of split item returned here
  rit=reaper.SplitMediaItem(item,split_pos)
  if rit==nil then return end -- fixes (script) crash where impossible split not detect by initial cursor
                              -- position when early note split is on
  
  --_DBG=true
  local last_note={endpos=-1,tk=-1}
  local ispos,riepos
  local l_note=0
  
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
           n.endpos+rea)
    end
 
    reaper.MIDI_SetNote(n.tk,n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos),
            n.chan,n.pitch,n.vel,nil,true)
    if i~=1 and n.tk~=last_note.tk then reaper.MIDI_Sort(last_note.tk) end
    last_note.tk=n.tk
  end
  if extend_right==false then 
    reaper.MIDI_SetItemExtents(item,reaper.TimeMap2_timeToQN(0,ispos), spQN)
  end
  
  reaper.SetMediaItemSelected(item, select_left)
  reaper.SetMediaItemSelected(rit, select_right)
end  
        

--ifdef
end