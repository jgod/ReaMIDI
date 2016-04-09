local last_take=nil
local every_nth=20 -- don't run 60 times a second
local counter=every_nth

function loop()
  if counter>=every_nth then
    counter=0
    local ame=reaper.MIDIEditor_GetActive()
    local mode=reaper.MIDIEditor_GetMode(ame)
    if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
      tk=reaper.MIDIEditor_GetTake(ame)
      if not reaper.ValidatePtr(tk, 'MediaItem_Take*') then tk=nil end
      if last_take~=nil and tk~=nil then 
        if last_take~=tk then
          tr=reaper.GetMediaItemTake_Track(tk)
          reaper.SetOnlyTrackSelected(tr)
        end
      end
      last_take=tk
    end
  end
  counter=counter+1
  reaper.defer(loop)
end

loop()