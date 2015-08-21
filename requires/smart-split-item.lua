if _DEF_SPLIT_MIDI_~=true then
_DEF_SPLIT_MIDI_=true


dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

function uberSplitItem(item, split_pos, extend_split_item)
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
  
  --local notes={}
  local ntc,notes={}
  for i=1,#tks,1 do
    notes=getNotes({tks[i].tk},false,false)
    for ii=1,#notes,1 do
      n=notes[ii]
      if n.startpos<reaper.TimeMap2_timeToQN(0,split_pos) and n.endpos>reaper.TimeMap2_timeToQN(0,split_pos) then
        ntc[#ntc+1]=n
        reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, reaper.TimeMap2_timeToQN(0,split_pos)),
              n.chan, n.pitch,n.vel,nil,true)
      end
    end
  end
  
  
  --right hand side of split item returned here
  --don't need to do anything with it
  local rit=reaper.SplitMediaItem(item,split_pos)
  
  --_DBG=true
  local last_note={endpos=-1,tk=-1}
  local ispos
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
  reaper.SetMediaItemSelected(item, false)
end


local its={}
local itt
local tpos=reaper.GetCursorPosition()
local s=reaper.CountSelectedMediaItems(0)
if s>0 then
  --reaper.ShowConsoleMsg("Selected Items: "..s.."\n")
  for i=1,s,1 do
    itt=reaper.GetSelectedMediaItem(0,i-1)
    local pos=reaper.GetMediaItemInfo_Value(itt, "D_POSITION")
    local len=reaper.GetMediaItemInfo_Value(itt, "D_LENGTH")
    if tpos>pos and tpos<(pos+len) then
      its[#its+1]=itt
    end
  end
end

if #its>0 then
  for i=1,#its,1 do
    uberSplitItem(its[i],tpos,true)
  end
end
reaper.UpdateArrange()
          
        

--ifdef
end