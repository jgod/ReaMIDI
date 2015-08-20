local last_take=nil

function doIt()
  --reaper.ShowConsoleMsg("In doIt()\n")
  local ame=reaper.MIDIEditor_GetActive()
  local mode=reaper.MIDIEditor_GetMode(ame)
  if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
    
    tk=reaper.MIDIEditor_GetTake(ame)
	if last_take~=nil then 
	  if last_take~=tk then -- sometimes crashes on undo
    --reaper.adjustZoom(10, 1, false, -1) --worth a try :)
		tr=reaper.GetMediaItemTake_Track(tk)
		reaper.SetOnlyTrackSelected(tr)
	  end
	end
	last_take=tk
  end
  reaper.defer(doIt)
end

doIt()
