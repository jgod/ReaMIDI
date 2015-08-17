local last_take=nil

function doIt()
  --reaper.ShowConsoleMsg("In doIt()\n")
  local ame=reaper.MIDIEditor_GetActive()
  local mode=reaper.MIDIEditor_GetMode(ame)
  if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
    tk=reaper.MIDIEditor_GetTake(ame)
	if last_take~=nil then 
	  if last_take~=tk then -- sometimes crashes on undo
		tr=reaper.GetMediaItemTake_Track(tk)
		if reaper.CountSelectedTracks(0)>0 then
			reaper.Main_OnCommand(40297,0)
		end
		reaper.SetTrackSelected(tr, true)
	  end
	end
	last_take=tk
  end
  reaper.defer(doIt)
end

doIt()
