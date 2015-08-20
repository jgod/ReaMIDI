if _DEF_TARGET_~=true then
_DEF_TARGET_=true

targets={  
          MIDIEditor=1,
          Selected=2,
          ActiveTakes=3,
          AllTakes=4,
          SelectedItems=5,
          TrackItems=6,
          Project=7
}

function getTargetTakes()
  local target
  local ame=reaper.MIDIEditor_GetActive()
  local mode=reaper.MIDIEditor_GetMode(ame)
  local tks={}
  --reaper.ShowConsoleMsg("ME Mode: "..mode.."\n")
  if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
    tks[1]=reaper.MIDIEditor_GetTake(ame)
    target=targets.MIDIEditor
  else
    target=targets.SelectedItems
    local s=reaper.CountSelectedMediaItems(0)
    if s>0 then
      --reaper.ShowConsoleMsg("Selected Items: "..s.."\n")
      for i=0,s-1,1 do
        local it=reaper.GetSelectedMediaItem(0,i)
        local tk=reaper.GetActiveTake(it)
        local tr=reaper.GetMediaItemTake_Track(tk)
        local _,t_name=reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        --reaper.ShowConsoleMsg(t_name.."\n")
        if tk and reaper.TakeIsMIDI(tk) then
          tks[#tks+1]=tk
        end
      end
    end            
  end
  --reaper.ShowConsoleMsg("Number of takes: "..#tks.."\n")
  return target, tks
end


--ifdef
end