_DBG=false
function DBG(str)
  if _DBG then reaper.ShowConsoleMsg(str.."\n") end
end



local function getInstrumentIdx(track)
  --TODO: use whitelist or blacklist or something to 
  --avoid returning VSTi MIDI plugins.
  --reaper-fxfolders.ini uses file paths names
  return reaper.TrackFX_GetInstrument(track)
end



local function showHideFX(track,fx_idx)
  -- showflag=0 for hidechain, =1 for show chain(index valid), =2 for hide floating window(index valid), 
  -- =3 for show floating window (index valid)
  local flag=reaper.TrackFX_GetFloatingWindow(track, fx_idx)==nil and 3 or 2
  reaper.TrackFX_Show(track,fx_idx,flag)
end


function openInstrument()
  local sts=reaper.CountSelectedTracks(0)

  if sts==1 then
    
    local tr=reaper.GetSelectedTrack(0,0)
    if tr~=nil then      
      local fx=reaper.TrackFX_GetInstrument(tr)
      if fx>-1 then
        showHideFX(tr,fx)
      else
        if reaper.GetTrackNumSends(tr,0)>0 then
          local ok, str=reaper.GetTrackSendName(tr, 0, "")
          DBG(str)
          -- 0s = idx, idx, tracktype
          local st=reaper.BR_GetMediaTrackSendInfo_Track(tr,0 , 0, 1)
          local bus=reaper.BR_GetSetTrackSendInfo(tr, 0, 0, "I_MIDI_DSTBUS", false, 0)
          if bus==-1 then reaper.ShowMessageBox("First send does not send MIDI","Action not performed",0) return end
          local fx=getInstrumentIdx(st)
          showHideFX(st,fx)
        end
      end
    end
  end
end

openInstrument()