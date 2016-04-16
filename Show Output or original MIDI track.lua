_DBG=true
function DBG(str)
  if _DBG then reaper.ShowConsoleMsg(str.."\n") end
end

local state_name="ReaMIDI_ShowOutputOrOriginalMIDITrack"
local state_key="last_MIDI_track"


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
    
    --store the track, for recall if when going back
    --to MIDI there are multiple MIDI tracks
    local guid=reaper.BR_GetMediaTrackGUID(tr)
    reaper.SetProjExtState(0,state_name,state_key,guid,true)
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
  local orig_tracks={}
  for i=0,num_receives-1,1 do
    local receive_bus=reaper.BR_GetSetTrackSendInfo(send_track, -1, i, "I_MIDI_DSTBUS", false, 0)
    if receive_bus==bus then --==0 and 1 or bus then
      orig_tracks[#orig_tracks+1]=reaper.BR_GetMediaTrackSendInfo_Track(send_track, -1 , i, 0)
      found=true
    end
  end
  if found then reaper.SetTrackSelected(tr,false) end
  
  --check for last stored MIDI orig track
  found=false
  local ok, guid=reaper.GetProjExtState(0, state_name, state_key)

  if guid~=nil then
    for i=1,#orig_tracks,1 do
      local ot=orig_tracks[i]
      if reaper.BR_GetMediaTrackGUID(ot)==guid then
        reaper.SetTrackSelected(ot, true)
        found=true
      end
    end
  end
  
  if not found then --just select the first one
    reaper.SetTrackSelected(orig_tracks[1], true)
  end
 
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
