local function DBG(str)
  --reaper.ShowConsoleMsg(str.."\n")
end


function getOrAddInputFxIdx(track, fx_name,fx_filename)
  local idx=reaper.TrackFX_AddByName(track,fx_name,true,1)
  DBG(idx)
  if idx==-1 or idx==nil then
    idx=reaper.TrackFX_AddByName(track,fx_filename,true,1)
    if idx==nil or idx==-1 then
      DBG("Can't find it")
      tr=nil
      return -1
    end
  end
  DBG("Found..."..fx_name)
  return idx|0x1000000
end


function isFirstSendMIDI(track)
  local bus=reaper.BR_GetSetTrackSendInfo(track, 0, 0, "I_MIDI_DSTBUS", false, 0)
  return not bus==-1      
end


function isMidiTrack(track)
  return reaper.TrackFX_GetInstrument(track)>-1 or isFirstSendMIDI(track)
end

local NOTE_MIN=0
local NOTE_MAX=1

local function process()
  local sts=reaper.CountSelectedTracks(0)
  local midi_tracks={}
  if sts>0 then
    for i=0,sts-1,1 do
      local tr=reaper.GetSelectedTrack(0,i)
      if isMidiTrack(tr) then
        midi_tracks[#midi_tracks+1]=tr
      end
    end
    for i=1,#midi_tracks,1 do
      local t=midi_tracks[i]
      local fx_idx=getOrAddInputFxIdx(t,"MIDI Note Filter","midi_note_filter")
      reaper.TrackFX_SetParamNormalized(t, fx_idx, NOTE_MIN, (i-1)*(1/#midi_tracks))
      reaper.TrackFX_SetParamNormalized(t, fx_idx, NOTE_MAX, (i-1)*(1/#midi_tracks)+(1/#midi_tracks))

    end
  end
  midiTracks={}
end


local timer=0

function loop()
  if timer>=15 then
    process()
    timer=0
  else
    timer=timer+1
  end
  reaper.defer(loop)
end

reaper.defer(loop)
