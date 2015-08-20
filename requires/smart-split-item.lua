if _DEF_SPLIT_MIDI_~=true then
_DEF_SPLIT_MIDI_=true


dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

function uberSplitItem(item, split_pos)
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
  
  --
  -- just realised this is all a bit stupid and I should maybe
  -- finding out how to copy an item, changing the start and end
  -- position and just deleting notes from the right one if they
  -- are before item start
  --
  local n
  
  local notes
  for i=1,#tks,1 do
    notes=getNotes({tks[i].tk},false,false)
    local ntc={}
    for ii=1,#notes,1 do
      n=notes[ii]
      if n.startpos<reaper.TimeMap2_timeToQN(0,split_pos) and n.endpos>reaper.TimeMap2_timeToQN(0,split_pos) then
        tks[i].altered=true
        ntc[#ntc+1]=n
        reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
            reaper.MIDI_GetPPQPosFromProjQN(n.tk, reaper.TimeMap2_timeToQN(0,split_pos)),
              n.chan, n.pitch,n.vel,nil,true)
      end
    end
    tks[i].notes=deepcopy(notes) 
    tks[i].ntc=deepcopy(ntc)
  end
  
  for i=1,#tks,1 do
    if tks[i].altered==true then
      tk=reaper.GetMediaItemTake(item,tks[i].tk_num)
      ntc=tks[i].ntc
      for ii=1,#ntc,1 do
        n=ntc[ii]
        -- TODO: restore original note lengths here
      end
    end
  end
  
  --right hand side of split item returned here
  --don't need to do anything with it
  local rit=reaper.SplitMediaItem(item,split_pos)
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
    DBG(tpos.." : ".. pos.." : "..(pos+len))
    if tpos>pos and tpos<(pos+len) then
      --uberSplitItem(itt,tpos)
      its[#its+1]=itt
    end
  end
end

if #its>1 then
  for i=1,#its,1 do
    uberSplitItem(its[i],tpos)
  end
end
reaper.UpdateArrange()
          
        

--ifdef
end