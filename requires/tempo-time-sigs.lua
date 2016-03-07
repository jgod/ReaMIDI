if _DEF_TEMPO_TIME_~=true then
_DEF_TEMPO_TIME_=true

-- more direct way to enter time signatures

-- v1.1 - 22 July 2015 - added ':' sections

-- example inputs:

-- 3/4
-- will enter 3/4 time sig at current tempo at current cursor position (nearest measure)

-- 3/4,6/8
-- puts 3/4 at current cursor position (nearest measure) and 6/8 at next measure

-- 3/4>3,6/8
-- 3/4 at current position, 6/8 three measures later.

-- 3/4>3,6/8*200
-- same as before, but pattern repeated 200 times

-- 3/4>3,6/8*100 : 4/4>3,3/4 : 3/4>3,6/8*100
-- add different sections by separating with a colon

dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/strings.lua")

_DBG=false
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


function restoreTimeSigsFromCurrentPos(measure_offset)
  if #tempo_time_markers>0 then
    for i=#tempo_time_markers,1,-1 do --table in reverse order
      DBG("i="..i)
      local t=tempo_time_markers[i]
      DBG("t.measurepos: "..t.measurepos)
      DBG("measure_offset: "..measure_offset)
      
      reaper.SetTempoTimeSigMarker(0, -1, -1, t.measurepos+measure_offset, 0, t.bpm, t.timesig_num, t.timesig_denom, t.lineartempo)
    end
  end
end







--ifdef
end