_DBG=true
function DBG(str)
  if _DBG then reaper.ShowConsoleMsg(str.."\n") end
end

bus=0
num_receives=0
function getMidiSendOutputTrack(tr)
  local num_sends=reaper.GetTrackNumSends(tr,0)
  if num_sends>0 then
    local ok, str=reaper.GetTrackSendName(tr, 0, "")
    --DBG(str)
    -- 0s = idx, idx, tracktype
    local st=reaper.BR_GetMediaTrackSendInfo_Track(tr,0 ,0, 1)
    bus=reaper.BR_GetSetTrackSendInfo(tr, 0, 0, "I_MIDI_DSTBUS", false, 0)
    local tr_num=reaper.GetMediaTrackInfo_Value(st,"IP_TRACKNUMBER")
    if bus==-1 then return false end
    local dest_track=reaper.GetTrack(0,tr_num+bus-1)
    reaper.SetTrackSelected(dest_track,true)
    reaper.SetTrackSelected(tr,false)
    reaper.Main_OnCommand(40913,0) -- scroll selected track into view
    reaper.SetMixerScroll(dest_track)
    return true
  else
    return false 
  end
end

receive_bus=0
send_track_num=0
function getOriginatingMidiTrack(tr)
  local output_track_num=reaper.GetMediaTrackInfo_Value(tr,"IP_TRACKNUMBER")
  local send_track=reaper.BR_GetMediaTrackSendInfo_Track(tr, -1 , 0, 0)
  local bus=reaper.BR_GetSetTrackSendInfo(tr, -1, 0, "I_MIDI_SRCBUS", false, 0)
  if bus>-1 then send_track=tr end
  
  local send_track_num=reaper.GetMediaTrackInfo_Value(send_track,"IP_TRACKNUMBER")
  
  bus=output_track_num-send_track_num
 
  -- iterate through receives on track to get one(s) with MIDI bus
  -- then select and scroll to them
  num_receives=reaper.GetTrackNumSends(send_track,-1)
  local found=false
  for i=0,num_receives-1,1 do
    local receive_bus=reaper.BR_GetSetTrackSendInfo(send_track, -1, i, "I_MIDI_DSTBUS", false, 0)
    if receive_bus==bus then --==0 and 1 or bus then
      local orig_track=reaper.BR_GetMediaTrackSendInfo_Track(send_track, -1 , i, 0)
      reaper.SetTrackSelected(orig_track, true)
      found=true
    end
  end
  if found then reaper.SetTrackSelected(tr,false) end
  reaper.Main_OnCommand(40913,0) -- scroll selected track into view
end


function showOutputOrOrigMidiTrack()
  local sts=reaper.CountSelectedTracks(0)
  if sts==1 then
    local tr=reaper.GetSelectedTrack(0,0)
    if tr~=nil then
      ok=getMidiSendOutputTrack(tr)
      if not ok then
        ok = getOriginatingMidiTrack(tr)
      end     
    end
  end
end

reaper.Undo_BeginBlock()
showOutputOrOrigMidiTrack()
reaper.Undo_EndBlock("Find MIDI or Output Track", 0)
