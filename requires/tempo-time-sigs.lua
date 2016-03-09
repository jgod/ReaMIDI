if _DEF_TEMPO_TIME_~=true then
_DEF_TEMPO_TIME_=true



dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/strings.lua")

_DBG=true
function DBG(str)
  if _DBG then reaper.ShowConsoleMsg(str==nil and "nil" or str.."\n") end
end

function getCurrentPositions()
  local cur_time=reaper.GetCursorPosition()
  local cur_qn=reaper.TimeMap_timeToQN(cur_time)
  local measure=reaper.TimeMap_QNToMeasures(0,cur_qn)
  return cur_time, cur_qn, measure
end


tempo_time_markers={}

function storeAndRemoveTimeSigsFromCurrentPos(cur_time)
  local num_tss=reaper.CountTempoTimeSigMarkers(0) -- 0=current project
  
  if num_tss>0 then
    for i=num_tss-1,0,-1 do
        local ok, timepos, measurepos, beatpos, bpm, timesig_num, 
                    timesig_denom, lineartempo=reaper.GetTempoTimeSigMarker(0, i)
        if timepos>=cur_time then
          --DBG("measureposOut:"..measureposOut)
          tempo_time_markers[#tempo_time_markers+1]={ok=ok,timepos=timepos,measurepos=measurepos,beatpos=beatpos,bpm=bpm,
                                                    timesig_num=timesig_num,timesig_denom=timesig_denom,lineartempo=lineartempo}
          reaper.DeleteTempoTimeSigMarker(0,i)
        end
    end
  end
end


function restoreTimeSigs(measure_offset,time)
  if #tempo_time_markers>0 then
    for i=#tempo_time_markers,1,-1 do --table in reverse order
      DBG("i="..i)
      local t=tempo_time_markers[i]
      DBG("t.measurepos: "..t.measurepos)
      DBG("measure_offset: "..measure_offset)
      if t.timepos>=time then
        reaper.SetTempoTimeSigMarker(0, -1, -1, t.measurepos+measure_offset, 0, t.bpm, t.timesig_num, t.timesig_denom, t.lineartempo)
      end
    end
  end
end







--ifdef
end